#' Install a local copy of a taxadb snapshot
#'
#' Downloads the Parquet files for the requested provider(s) into
#' [taxadb_dir()], so that subsequent queries read from local disk instead
#' of streaming from remote storage.
#'
#' @inheritParams filter_by
#' @param provider a character vector of provider(s) to download. See
#'  [available_providers()] for the providers published in a given version.
#' @param overwrite should we re-download files that are already present?
#'  Default `FALSE`.
#' @return the local paths of the downloaded files, invisibly.
#' @details Streaming is fast enough for most interactive use and requires no
#' setup, so a local copy is optional.  Install one when you will make many
#' queries against the same table, when you need to work offline, or when you
#' want a snapshot pinned on disk for reproducibility.
#'
#' Snapshots are large: the Darwin Core tables for `col` and `gbif` are each
#' several hundred MB.  Use `available_providers()` to see what is published,
#' and delete a local copy with `unlink(taxadb_dir(), recursive = TRUE)`.
#' @export
#' @examples \dontrun{
#' ## Install a local copy of ITIS. Writes to taxadb_dir() and downloads
#' #  tens of MB, so this is never run unattended.
#' td_download("itis")
#' }
td_download <- function(provider = getOption("taxadb_default_provider", "itis"),
                        schema = c("dwc", "common"),
                        version = latest_version(),
                        overwrite = FALSE,
                        db = td_connect()){

  snapshots <- list_snapshots(db)
  if(nrow(snapshots) == 0)
    stop(paste("Could not reach the taxadb data repository at",
               taxadb_repo()), call. = FALSE)

  want <- snapshots[snapshots$version == version &
                    snapshots$provider %in% provider &
                    snapshots$schema %in% schema, ]

  if(nrow(want) == 0)
    stop(paste0("No snapshot found for provider(s) ",
                paste(provider, collapse = ", "),
                " in version ", version,
                ".\n  See available_providers(\"", version, "\")."),
         call. = FALSE)

  dest_dir <- file.path(taxadb_dir(), version)
  dir.create(dest_dir, showWarnings = FALSE, recursive = TRUE)
  dest <- file.path(dest_dir, basename(want$uri))

  for(i in seq_len(nrow(want))){
    if(file.exists(dest[[i]]) && !overwrite) next
    message("downloading ", basename(want$uri[[i]]), " ...")
    ## COPY, rather than download.file(), so that we need no separate
    ## HTTP stack: duckdb is already streaming these bytes.
    DBI::dbExecute(db, paste0(
      "COPY (SELECT * FROM read_parquet('", want$uri[[i]], "')) TO '",
      dest[[i]], "' (FORMAT parquet, COMPRESSION zstd);"))
  }

  ## Any view built against the remote copy is now stale for this table.
  for(v in unique(paste0(want$schema, "_", want$provider, "_", version)))
    if(has_table(v, db)) DBI::dbExecute(db, paste0("DROP VIEW \"", v, "\";"))

  invisible(dest)
}

#' Create a local taxadb database
#'
#' @description Superseded by [td_download()].
#' @inheritParams td_download
#' @param overwrite passed to [td_download()]
#' @param lines deprecated, ignored.
#' @param dbdir deprecated, ignored.
#' @return the local paths of the downloaded files, invisibly.
#' @details `taxadb` no longer needs to import data before querying it:
#' tables are read directly from Parquet, streamed from remote storage or
#' from a local copy.  `td_create()` is retained as an alias for
#' [td_download()], which installs a local copy.
#' @export
#' @examples \dontrun{
#' td_create("itis")
#' }
td_create <- function(provider = getOption("taxadb_default_provider", "itis"),
                      schema = c("dwc", "common"),
                      version = latest_version(),
                      overwrite = FALSE,
                      lines = NULL,
                      dbdir = NULL,
                      db = td_connect()){

  assert_deprecated(lines, dbdir)
  td_download(provider = provider, schema = schema, version = version,
              overwrite = overwrite, db = db)
}
