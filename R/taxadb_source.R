## Where the data lives, and how we discover what is available.
##
## Snapshots are published as Parquet under a flat, versioned prefix:
##
##   s3://<repo>/<version>/<schema>_<provider>_part_<n>.parquet
##
## e.g. s3://cboettig/taxadb/2026/dwc_col_part_0.parquet
##
## Discovery is by glob against the object store, so adding a new version or
## provider upstream requires no change to this package.

TAXADB_REPO <- "cboettig/taxadb"
TAXADB_ENDPOINT <- "data.source.coop"

## Used only when the object store cannot be reached, so that examples,
## tests and offline use resolve to *something* rather than erroring.
TAXADB_FALLBACK_VERSION <- "2026"

#' The taxadb data repository
#'
#' @return the object-store prefix holding taxadb snapshots.
#' @details Override with `options(taxadb_repo=)` or the `TAXADB_REPO`
#' environment variable to read from a mirror or a staging repository.
#' @export
#' @examples
#' taxadb_repo()
taxadb_repo <- function(){
  getOption("taxadb_repo", Sys.getenv("TAXADB_REPO", TAXADB_REPO))
}

taxadb_endpoint <- function(){
  getOption("taxadb_endpoint", Sys.getenv("TAXADB_ENDPOINT", TAXADB_ENDPOINT))
}

#' Show the local taxadb directory
#'
#' @details Local snapshots downloaded by [td_download()] are stored here.
#' Override with the `TAXADB_HOME` environment variable.
#' @return path to the local taxadb data directory
#' @export
#' @examples
#' taxadb_dir()
taxadb_dir <- function(){
  Sys.getenv("TAXADB_HOME", tools::R_user_dir("taxadb"))
}

## The bundled test fixture, used by examples and tests so that they need
## neither network access nor a multi-hundred-MB download.
TEST_PROVIDER <- "itis_test"

is_test_provider <- function(provider) identical(provider, TEST_PROVIDER)

test_fixture <- function(schema){
  system.file("extdata", paste0(schema, "_", TEST_PROVIDER, ".parquet"),
              package = "taxadb", mustWork = TRUE)
}

#' Locate the Parquet files backing a taxadb table
#'
#' @inheritParams filter_by
#' @param local should we return the path to a local snapshot?  By default
#'  a local copy is used when one is present (see [td_download()]), and the
#'  remote snapshot is streamed otherwise.
#' @return a glob pattern (or file path) that `duckdb` can read
#' @export
#' @examples
#' taxadb_uri("itis_test")
taxadb_uri <- function(provider = getOption("taxadb_default_provider", "itis"),
                       schema = c("dwc", "common"),
                       version = latest_version(),
                       local = NULL){

  schema <- match.arg(schema)

  if(is_test_provider(provider)) return(test_fixture(schema))

  stem <- paste0(schema, "_", provider, "_part_*.parquet")
  local_glob <- file.path(taxadb_dir(), version, stem)

  if(is.null(local)) local <- length(Sys.glob(local_glob)) > 0
  if(local){
    if(length(Sys.glob(local_glob)) == 0)
      stop(paste0("No local snapshot of ", schema, "_", provider,
                  " (version ", version, ") found in ", taxadb_dir(),
                  ".\n  Run td_download(\"", provider, "\") first."),
           call. = FALSE)
    return(local_glob)
  }

  paste0("s3://", taxadb_repo(), "/", version, "/", stem)
}

## All snapshot files in the repository, as a data.frame of
## version / schema / provider / uri.  Memoised: one network round trip
## per session.
list_snapshots_uncached <- function(db = td_connect()){

  glob <- paste0("s3://", taxadb_repo(), "/*/*.parquet")
  if(!isTRUE(ensure_httpfs(db))) return(no_snapshots())
  files <- tryCatch(
    DBI::dbGetQuery(db, paste0("SELECT file FROM glob('", glob, "')"))$file,
    error = function(e) character(0))

  if(length(files) == 0) return(no_snapshots())

  base <- basename(files)
  ## <schema>_<provider>_part_<n>.parquet
  parts <- regmatches(base,
    regexec("^(dwc|common)_(.+)_part_[0-9]+\\.parquet$", base))
  ok <- vapply(parts, length, integer(1L)) == 3L

  if(!any(ok)) return(no_snapshots())

  parts <- parts[ok]
  data.frame(
    version  = basename(dirname(files[ok])),
    schema   = vapply(parts, `[[`, character(1L), 2L),
    provider = vapply(parts, `[[`, character(1L), 3L),
    uri      = files[ok],
    stringsAsFactors = FALSE)
}

no_snapshots <- function()
  data.frame(version = character(0), schema = character(0),
             provider = character(0), uri = character(0),
             stringsAsFactors = FALSE)

#' List the taxonomic snapshots available from the taxadb repository
#'
#' @param db a connection from [td_connect()]
#' @return a data.frame with one row per published Parquet file, giving its
#' `version`, `schema`, `provider` and `uri`.
#' @details Requires network access.  Results are cached for the session.
#' @export
#' @examples \dontrun{
#' list_snapshots()
#' }
list_snapshots <- function(db = td_connect()){
  cached <- mget("snapshots", envir = taxadb_cache, ifnotfound = NA)[[1]]
  if(is.data.frame(cached)) return(cached)
  out <- list_snapshots_uncached(db)
  if(nrow(out) > 0) assign("snapshots", out, envir = taxadb_cache)
  out
}

#' Versions of the taxadb data available
#'
#' @inheritParams list_snapshots
#' @return a character vector of available snapshot versions
#' @export
#' @examples \dontrun{
#' available_versions()
#' }
available_versions <- function(db = td_connect()){
  v <- unique(list_snapshots(db)$version)
  if(length(v) == 0) return(TAXADB_FALLBACK_VERSION)
  sort(v)
}

#' Name providers available for a given version
#'
#' @param version snapshot version, defaults to the latest available
#' @inheritParams list_snapshots
#' @return a data.frame of `provider` and the `schema`s published for it
#' @export
#' @examples \dontrun{
#' available_providers()
#' }
available_providers <- function(version = latest_version(),
                                db = td_connect()){
  s <- list_snapshots(db)
  s <- s[s$version == version, c("provider", "schema")]
  s <- unique(s)
  s[order(s$provider, s$schema), ]
}

#' The most recent taxadb snapshot version
#'
#' @inheritParams list_snapshots
#' @return the latest available version, as a character string
#' @details Versions are ordered as version numbers, not as strings. This
#' matters: as strings `"22.12"` sorts after `"2026"`, so a plain `max()`
#' would make an archival release from 2022 the default for every query once
#' it was published.
#' @export
#' @examples \dontrun{
#' latest_version()
#' }
latest_version <- function(db = td_connect()){
  version_max(available_versions(db))
}

## Order version labels numerically where we can, falling back to string
## order for anything numeric_version cannot parse. `"2026"` must come out
## above `"22.12"`, which string comparison gets backwards.
##
## The comparison is a plain loop rather than which.max() over a combined
## vector: c() on numeric_version objects returns a list on R < 4.6, so
## which.max() failed there ("'list' object cannot be coerced to type
## 'double'"). Comparing two numeric_versions at a time is portable.
version_max <- function(versions){
  if(length(versions) == 0) return(TAXADB_FALLBACK_VERSION)
  if(length(versions) == 1) return(versions)

  parsed <- lapply(versions, function(v)
    tryCatch(numeric_version(v, strict = TRUE),
             error = function(e) NULL, warning = function(w) NULL))
  ok <- !vapply(parsed, is.null, logical(1L))

  ## Prefer a parseable version over an unparseable one; among parseable
  ## ones take the numerically greatest.
  if(!any(ok)) return(max(versions))
  candidates <- versions[ok]
  best <- 1L
  for(i in seq_along(candidates))
    if(parsed[ok][[i]] > parsed[ok][[best]]) best <- i
  candidates[[best]]
}
