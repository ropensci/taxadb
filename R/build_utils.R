## Shared machinery for rebuilding taxadb snapshots from provider archives.
##
## Everything here runs inside duckdb.  The providers publish hierarchies as
## (taxonID, parentNameUsageID) edges of unbounded depth; the taxadb tables
## want them flattened into kingdom..genus columns.  A recursive CTE walks
## the edges once, so depth needs neither guessing nor a chain of self-joins.

#' Where build inputs and outputs are kept
#'
#' @return path to the taxadb build directory
#' @details Provider archives are large and slow to fetch, so they are cached
#' here between builds.  Override with the `TAXADB_BUILD_DIR` environment
#' variable.
#' @export
#' @examples
#' build_dir()
build_dir <- function(){
  Sys.getenv("TAXADB_BUILD_DIR",
             file.path(tools::R_user_dir("taxadb", "cache"), "build"))
}

## Download `url` to `dir`, unless we already have it.  Returns the path.
fetch_archive <- function(url, file = basename(url), dir = build_dir()){
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  dest <- file.path(dir, file)
  if(file.exists(dest) && file.size(dest) > 0){
    message("using cached ", file)
    return(dest)
  }
  message("downloading ", url)
  part <- paste0(dest, ".part")
  ok <- utils::download.file(url, part, mode = "wb", quiet = FALSE)
  if(ok != 0 || !file.exists(part)) stop("failed to download ", url)
  file.rename(part, dest)
  dest
}

## Extract an archive into a fresh subdirectory of the build dir and return
## the path.  Handles the .zip / .tar.gz split across providers.
extract_archive <- function(path, dir = build_dir(), name = NULL){
  if(is.null(name)) name <- sub("\\.(zip|tgz|tar\\.gz|gz)$", "", basename(path))
  out <- file.path(dir, name)
  if(dir.exists(out) && length(list.files(out, recursive = TRUE)) > 0){
    message("using already-extracted ", name)
    return(out)
  }
  dir.create(out, showWarnings = FALSE, recursive = TRUE)
  message("extracting ", basename(path))
  if(grepl("\\.zip$", path)) utils::unzip(path, exdir = out)
  else utils::untar(path, exdir = out)
  out
}

## Find one file inside an extracted archive by name, wherever it landed:
## providers vary on whether the archive has a top-level directory.
archive_file <- function(dir, pattern){
  hits <- list.files(dir, pattern = pattern, recursive = TRUE,
                     full.names = TRUE, ignore.case = TRUE)
  if(length(hits) == 0)
    stop("could not find a file matching '", pattern, "' under ", dir,
         call. = FALSE)
  ## Shallowest match wins, so that a stray copy in a nested directory does
  ## not shadow the real one.
  hits[order(nchar(hits))][[1]]
}

## The seven Darwin Core rank columns taxadb flattens the hierarchy into.
DWC_RANKS <- c("kingdom", "phylum", "class", "order", "family", "genus")

## Guard against cycles in provider hierarchies, which do occur.  Deeper
## than this and we are certainly going in circles: NCBI, the deepest
## provider, tops out near 40.
MAX_DEPTH <- 60

## Flatten a parent-child hierarchy into Darwin Core rank columns.
##
## `edges` must be a table of (taxonID, parentNameUsageID); `nodes` a table
## of (taxonID, taxonRank, scientificName).  Both are SQL table names.
##
## Every node is its own depth-0 ancestor, so a genus row gets its own name
## in `genus`, matching how the providers present their own denormalized
## tables.  Where a lineage names more than one taxon at the same rank --
## routine in OTT, which places mammals in both Mammalia and Sarcopterygii
## as "class" -- the nearest ancestor wins, tie-broken by name so the
## result is reproducible rather than whatever the join order happened to be.
classify_sql <- function(edges = "edges", nodes = "nodes",
                         ranks = DWC_RANKS){

  pick <- paste0(
    "  first(n.scientificName ORDER BY a.depth, n.scientificName) ",
    "FILTER (n.taxonRank = '", ranks, "') AS \"", ranks, "\"",
    collapse = ",\n")

  paste0(
"WITH RECURSIVE anc(taxonID, ancestorID, depth) AS (
    SELECT taxonID, taxonID, 0 FROM ", edges, "
  UNION ALL
    SELECT a.taxonID, e.parentNameUsageID, a.depth + 1
    FROM anc a JOIN ", edges, " e ON a.ancestorID = e.taxonID
    WHERE e.parentNameUsageID IS NOT NULL
      AND e.parentNameUsageID <> a.ancestorID
      AND a.depth < ", MAX_DEPTH, "
)
SELECT a.taxonID,\n", pick, "
FROM anc a JOIN ", nodes, " n ON a.ancestorID = n.taxonID
GROUP BY a.taxonID")
}

## Materialize the classification as a table named `into`.
build_classification <- function(db, edges = "edges", nodes = "nodes",
                                 into = "classification",
                                 ranks = DWC_RANKS){
  message("  flattening hierarchy ...")
  DBI::dbExecute(db, paste0("CREATE OR REPLACE TABLE ", into, " AS ",
                            classify_sql(edges, nodes, ranks)))
  invisible(into)
}

## Prefix bare provider identifiers, respecting NULLs: an id column of
## 'PROVIDER:NA' strings is a recurring way for these tables to go wrong.
prefix_id <- function(column, prefix){
  paste0("CASE WHEN ", column, " IS NULL THEN NULL ELSE ",
         "concat('", prefix, ":', ", column, ") END")
}

## Write a query out as a taxadb snapshot, in the published layout:
##   <dir>/<version>/<schema>_<provider>_part_<n>.parquet
## Snapshots are written as a single part unless they exceed `part_rows`.
write_snapshot <- function(db, query, provider, schema, version,
                           dir = file.path(build_dir(), "out"),
                           part_rows = 5e6){

  out_dir <- file.path(dir, version)
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  n <- DBI::dbGetQuery(db,
    paste0("SELECT count(*) AS n FROM (", query, ")"))$n
  if(n == 0) stop("refusing to write an empty ", schema, "_", provider,
                  call. = FALSE)

  stem <- paste0(schema, "_", provider, "_part_")
  ## Clear any parts from an earlier build, or a shrinking table would
  ## leave stale parts behind to be globbed up alongside the new ones.
  unlink(Sys.glob(file.path(out_dir, paste0(stem, "*.parquet"))))

  if(n <= part_rows){
    dest <- file.path(out_dir, paste0(stem, "0.parquet"))
    DBI::dbExecute(db, paste0("COPY (", query, ") TO '", dest,
                              "' (FORMAT parquet, COMPRESSION zstd);"))
  } else {
    ## duckdb names its own parts inside a directory; move them into the
    ## flat published layout afterwards.
    tmp <- file.path(out_dir, paste0(stem, "tmp"))
    unlink(tmp, recursive = TRUE)
    DBI::dbExecute(db, paste0(
      "COPY (", query, ") TO '", tmp, "' (FORMAT parquet, ",
      "COMPRESSION zstd, FILE_SIZE_BYTES '512MB');"))
    parts <- sort(list.files(tmp, pattern = "\\.parquet$", full.names = TRUE))
    for(i in seq_along(parts))
      file.rename(parts[[i]],
                  file.path(out_dir, paste0(stem, i - 1L, ".parquet")))
    unlink(tmp, recursive = TRUE)
  }

  written <- Sys.glob(file.path(out_dir, paste0(stem, "*.parquet")))
  message("  wrote ", schema, "_", provider, ": ",
          format(n, big.mark = ","), " rows in ", length(written),
          " part(s), ",
          format(sum(file.size(written)) / 1e6, digits = 4), " MB")
  invisible(written)
}

## Select list for the dwc schema, in a fixed column order so that every
## provider's table looks the same.  `extra` names provider-specific
## columns to keep after the required ones.
dwc_select <- function(extra = character(0)){
  ## `order` and `class` are reserved words; quote every term rather than
  ## remembering which.
  paste0("\"", c(DWC_REQUIRED, DWC_RANKS,
                 "specificEpithet", "infraspecificEpithet",
                 "vernacularName", extra), "\"", collapse = ", ")
}

## Split a binomial into its epithets, given the genus the taxon sits in.
##
## Providers that publish a Taxon table give `specificEpithet` directly, but
## NCBI and OTT publish only whole name strings.  `n` picks which word after
## the genus to take: 1 for the specific epithet, 2 for the infraspecific.
##
## Two guards keep this from inventing epithets.  The name must actually
## begin with the genus, so "uncultured bacterium" yields nothing.  And the
## word taken must look like a Latin epithet -- lowercase, possibly
## hyphenated -- which rejects the open-nomenclature placeholders that
## `clean_names()` also strips from user input (`sp.`, `spp.`, `cf.`), and
## rejects specimen vouchers: NCBI carries thousands of names shaped like
## "Megaselia sp. BIOUG32195-A06", where neither word is an epithet.
epithet_sql <- function(name, genus, n = 1){
  rest <- paste0("trim(substr(", name, ", length(", genus, ") + 2))")
  word <- paste0("split_part(", rest, ", ' ', ", n, ")")
  paste0(
    "CASE WHEN ", genus, " IS NOT NULL AND ", name, " IS NOT NULL",
    " AND starts_with(", name, ", concat(", genus, ", ' '))",
    " AND regexp_full_match(", word, ", '[a-z][a-z-]+')",
    " AND NOT regexp_full_match(", word, ", 'sp|spp|ssp|cf|aff|var|subsp|nr')",
    " THEN ", word, " END")
}
