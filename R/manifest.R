## What gets published alongside the data, so that a snapshot can be
## understood without reading this package's source: a machine-readable
## manifest and a human-readable README.

#' Describe a built snapshot
#'
#' @param version the snapshot version to describe
#' @param dir the build output directory, see [build_dir()]
#' @param db a duckdb connection
#' @return a data.frame with one row per published table, giving its
#'  provider, schema, row count, columns, file sizes and checksum, and the
#'  upstream release it was derived from.
#' @details Run after [td_build()].  The row counts and checksums are read
#' back off the written files rather than carried over from the build, so
#' the manifest describes what was actually published.
#' @export
#' @examples \dontrun{
#' td_manifest("2026")
#' }
td_manifest <- function(version = format(Sys.Date(), "%Y"),
                        dir = build_dir(),
                        db = td_connect()){

  out_dir <- file.path(dir, "out", version)
  files <- list.files(out_dir, pattern = "\\.parquet$", full.names = TRUE)
  if(length(files) == 0)
    stop("no snapshot found in ", out_dir, call. = FALSE)

  ## Group the parts belonging to each table.
  parts <- regmatches(basename(files),
    regexec("^(dwc|common)_(.+)_part_[0-9]+\\.parquet$", basename(files)))
  keep <- vapply(parts, length, integer(1L)) == 3L
  files <- files[keep]; parts <- parts[keep]
  schema <- vapply(parts, `[[`, character(1L), 2L)
  provider <- vapply(parts, `[[`, character(1L), 3L)

  rows <- lapply(unique(paste(provider, schema)), function(key){
    bits <- strsplit(key, " ")[[1]]
    p <- bits[[1]]; s <- bits[[2]]
    these <- files[provider == p & schema == s]
    glob <- file.path(out_dir, paste0(s, "_", p, "_part_*.parquet"))

    n <- DBI::dbGetQuery(db, paste0(
      "SELECT count(*) AS n FROM read_parquet('", glob, "')"))$n
    cols <- DBI::dbGetQuery(db, paste0(
      "DESCRIBE SELECT * FROM read_parquet('", glob, "')"))$column_name
    prov <- provenance_for(db, p)
    meta <- PROVIDER_META[[p]]

    data.frame(
      provider = p,
      schema = s,
      version = version,
      title = meta$title %||% NA_character_,
      rows = n,
      parts = length(these),
      bytes = sum(file.size(these)),
      columns = paste(cols, collapse = ", "),
      upstream_version = prov$upstream_version[[1]],
      source = prov$source[[1]],
      license = meta$license %||% NA_character_,
      sha256 = paste(vapply(these, file_sha256, character(1L)),
                     collapse = ","),
      stringsAsFactors = FALSE)
  })

  out <- do.call(rbind, rows)
  out[order(out$provider, out$schema), ]
}

`%||%` <- function(x, y) if(is.null(x)) y else x

## digest() would be another dependency; duckdb can hash a file it can read.
file_sha256 <- function(path){
  db <- td_connect()
  tryCatch(
    DBI::dbGetQuery(db, paste0(
      "SELECT sha256(content) AS h FROM read_blob('", path, "')"))$h[[1]],
    error = function(e) NA_character_)
}

#' Write the metadata published with a snapshot
#'
#' Writes `manifest.csv` and `README.md` into the snapshot directory, ready
#' to be uploaded alongside the Parquet files.
#'
#' @inheritParams td_manifest
#' @param repo the data repository the snapshot will be published to
#' @return the paths written, invisibly
#' @details The README states what the tables are, what the schema means,
#' where each provider's data came from and under what licence, so that
#' someone who finds the data without the package can still use it.
#' @export
#' @examples \dontrun{
#' td_write_metadata("2026")
#' }
td_write_metadata <- function(version = format(Sys.Date(), "%Y"),
                              dir = build_dir(),
                              repo = taxadb_repo(),
                              db = td_connect()){

  m <- td_manifest(version, dir, db)
  out_dir <- file.path(dir, "out", version)

  manifest_path <- file.path(out_dir, "manifest.csv")
  utils::write.csv(m, manifest_path, row.names = FALSE)

  readme_path <- file.path(out_dir, "README.md")
  writeLines(readme_lines(m, version, repo), readme_path)

  message("wrote ", basename(manifest_path), " and ", basename(readme_path))
  invisible(c(manifest_path, readme_path))
}

readme_lines <- function(m, version, repo){

  providers <- unique(m$provider)
  info <- taxadb_provider_info(providers)
  nc <- function(x) formatC(x, format = "d", big.mark = ",")

  tbl <- function(header, rows){
    c(paste0("| ", paste(header, collapse = " | "), " |"),
      paste0("|", paste(rep("---", length(header)), collapse = "|"), "|"),
      rows)
  }

  c(
"---",
"license: various-by-provider",
"---",
"",
paste0("# taxadb ", version),
"",
paste("Taxonomic name tables for", length(providers),
      "naming authorities, normalized to a common Darwin Core schema."),
"",
paste0("Built by the [taxadb](https://github.com/ropensci/taxadb) R package.",
       " Generated ", format(Sys.Date()), "."),
"",
"## Reading the data",
"",
"Each table is one or more Parquet files, named",
paste0("`", version, "/<schema>_<provider>_part_<n>.parquet`."),
"No special client is needed; anything that reads Parquet will do.",
"",
"```r",
"library(taxadb)",
'filter_name("Homo sapiens", provider = "itis")',
"```",
"",
"```r",
"# or without the package",
"library(duckdbfs)",
"library(dplyr)",
paste0('open_dataset("https://data.source.coop/', repo, '/', version,
       '/dwc_itis_part_0.parquet") |>'),
'  filter(scientificName == "Homo sapiens")',
"```",
"",
"```sql",
"-- or in plain SQL",
"SELECT * FROM read_parquet(",
paste0("  'https://data.source.coop/", repo, "/", version,
       "/dwc_itis_part_0.parquet')"),
"WHERE scientificName = 'Homo sapiens';",
"```",
"",
"## Schema",
"",
"There are two kinds of table. `dwc_<provider>` is the complete name list:",
"one row per name, accepted names and synonyms together. `common_<provider>`",
"is the vernacular names, one row per name with the language it is in.",
"A provider that publishes no vernacular names has no `common` table; `ott`",
"is the one such provider here.",
"",
"Every `dwc` table carries these columns, with the same meaning throughout:",
"",
tbl(c("column", "meaning"), c(
"| `taxonID` | Identifier for this name, prefixed by the provider, e.g. `ITIS:180092`. Empty where the provider mints no identifier for a synonym, which is the case for NCBI, OTT, FishBase and SeaLifeBase. |",
"| `scientificName` | The name, without authorship. Present at every rank: `Animalia` is a scientificName just as `Homo sapiens` is. |",
"| `taxonRank` | The rank the provider gives this name. Not limited to the seven below: NCBI and OTT recognize over forty. |",
"| `acceptedNameUsageID` | The `taxonID` of the accepted name. **Always populated**, on accepted names as well as synonyms, where it repeats the row's own `taxonID`. |",
"| `taxonomicStatus` | `accepted`, or what kind of synonym or other usage this is. Provider-specific terms are kept rather than flattened. |",
"| `kingdom`, `phylum`, `class`, `order`, `family`, `genus` | The classification, flattened from the provider's hierarchy. |",
"| `specificEpithet`, `infraspecificEpithet` | Epithets, where the name has them. |",
"| `vernacularName` | One common name, where the provider has one. |"
)),
"",
"Providers add their own columns beyond these; see `columns` in",
"`manifest.csv` for exactly what each table holds.",
"",
"### The one place this is stricter than Darwin Core",
"",
"Darwin Core leaves `acceptedNameUsageID` optional on an accepted name, and",
"most providers omit it there, reasoning that an accepted name is its own",
"accepted name. These tables always populate it, repeating the `taxonID`.",
"That way resolving any name to its accepted identifier is a single column",
"read with no special case, whether the name turned out to be a synonym or",
"not. Relatedly, a name the provider redirects nowhere is its own accepted",
"name even where the provider hedges about it, so GBIF's `doubtful` and",
"COL's `provisionally accepted` names are self-referencing too.",
"",
"## Providers",
"",
"These are **not** interchangeable, and should not be combined. Providers",
"represent independent taxonomic theories: the same name can be accepted by",
"one and a synonym of something else in another, so two providers can",
"contradict each other in ways that merging silently discards.",
"`col`, `gbif` and `ott` are themselves synthesis projects integrating other",
"checklists; the rest are primary authorities.",
"",
tbl(c("provider", "authority", "upstream release", "licence"),
    vapply(providers, function(p){
      i <- info[info$provider == p, ]
      u <- unique(m$upstream_version[m$provider == p])
      paste0("| `", p, "` | [", i$title, "](", i$url, ") | ",
             ifelse(is.na(u[[1]]), "unknown", u[[1]]), " | [", i$license,
             "](", i$license_url, ") |")
    }, character(1L))),
"",
"Each table is redistributed under its provider's terms, listed above and",
"in `manifest.csv`. **`fb` and `slb` are CC BY-NC**: those two may not be",
"used commercially. The others permit commercial use with attribution.",
"",
"## Tables in this release",
"",
tbl(c("table", "rows", "size", "parts"),
    vapply(seq_len(nrow(m)), function(i)
      paste0("| `", m$schema[i], "_", m$provider[i], "` | ",
             nc(m$rows[i]), " | ",
             format(m$bytes[i] / 1e6, digits = 3), " MB | ",
             m$parts[i], " |"),
      character(1L))),
"",
"## Provenance and checksums",
"",
"`manifest.csv` records, for every table, the upstream release it was built",
"from, its row count, its full column list, and a SHA-256 of each Parquet",
"part.",
"",
"The provider abbreviation and this release's version do not by themselves",
"say what went in, which is why the upstream release is recorded separately:",
"the GBIF table here is built from the most recent backbone GBIF has",
"published, which is dated 2023-08-28, and is therefore older than this",
"snapshot's version suggests.",
"",
"## How this was built",
"",
"Every table is derived from the provider's own distribution by",
"`taxadb::td_build()`, and checked against the schema rules above by",
"`taxadb::td_validate()` before publication. Both are ordinary exported",
"functions, so a table can be rebuilt or re-checked independently:",
"",
"```r",
paste0('td_build("itis", version = "', version, '")'),
'td_validate("itis")',
"```",
"",
"## Citation",
"",
"Cite the underlying provider, not this redistribution:",
"",
unlist(lapply(providers, function(p){
  i <- info[info$provider == p, ]
  paste0("- **", p, "**: ", i$citation)
})),
"",
"For the package and the schema:",
"",
"- Norman KEA, Chamberlain S, Boettiger C (2020). taxadb: A high-performance",
"  local taxonomic database interface. *Methods in Ecology and Evolution*,",
"  11(9), 1153-1159. doi:10.1111/2041-210X.13440",
""
)
}
