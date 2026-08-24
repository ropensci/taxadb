#' Rebuild taxadb snapshots from the providers
#'
#' Runs a provider's preprocessing end to end: fetch the provider's own
#' distribution, normalize it to the taxadb Darwin Core schema, and write
#' the Parquet snapshot.
#'
#' @param provider one or more providers to build. See [taxadb_providers()].
#' @param version the snapshot version to write, defaults to the year.
#' @param dir directory for build inputs and outputs, see [build_dir()].
#' @param validate should each table be checked with [td_validate()] after
#'  it is written?  Default `TRUE`.
#' @param db a duckdb connection
#' @param ... passed to the individual provider builder, e.g. `archive` to
#'  use an already-downloaded copy.
#' @return a data.frame of the validation results, invisibly if `validate`
#'  is `FALSE` the paths written.
#' @details Snapshots are published for the providers so that most users
#' never need to run this.  It is here so that a user who needs a fresher
#' snapshot than the published one, or who wants to check how a table was
#' derived, can rebuild it themselves rather than asking someone to.
#'
#' Builds are done entirely in `duckdb`, out of core, so they are bounded by
#' disk rather than memory.  The archives are large: COL and GBIF are around
#' 500MB and 1GB compressed respectively, and are cached in `dir` between
#' builds.
#'
#' `iucn` cannot be built without credentials; see [build_iucn()].
#' @export
#' @examples \dontrun{
#' ## rebuild one provider
#' td_build("itis")
#'
#' ## rebuild everything that can be built without credentials
#' td_build(taxadb_providers())
#' }
td_build <- function(provider = "itis",
                     version = format(Sys.Date(), "%Y"),
                     dir = build_dir(),
                     validate = TRUE,
                     db = td_connect(),
                     ...){

  unknown <- setdiff(provider, names(BUILDERS))
  if(length(unknown))
    stop("no builder for provider(s): ", paste(unknown, collapse = ", "),
         "\n  known: ", paste(names(BUILDERS), collapse = ", "),
         call. = FALSE)

  paths <- list()
  for(p in provider){
    paths[[p]] <- BUILDERS[[p]](version = version, dir = dir, db = db, ...)
  }

  if(!validate) return(invisible(unlist(paths)))

  ## Validate what was written, not the published copy, by pointing the
  ## reader at the build output.
  home <- Sys.getenv("TAXADB_HOME")
  Sys.setenv(TAXADB_HOME = file.path(dir, "out"))
  on.exit(Sys.setenv(TAXADB_HOME = home), add = TRUE)

  checks <- list()
  for(p in provider) for(s in c("dwc", "common")){
    if(length(Sys.glob(taxadb_uri(p, s, version, local = TRUE))) == 0) next
    checks[[paste(p, s)]] <-
      td_validate(p, s, version, db)
  }
  out <- do.call(rbind, checks)
  failed <- out[!out$pass, ]
  if(nrow(failed) > 0)
    warning("taxadb rules violated by the tables just built:\n",
            paste0("  ", failed$provider, " ", failed$schema, ": ",
                   failed$rule, " -- ", failed$note, collapse = "\n"),
            call. = FALSE)
  out
}

## Providers we know how to rebuild.  `slb` shares FishBase's schema, and
## `iucn` is here so that td_build("iucn") gives the credentials message
## rather than "no builder".
BUILDERS <- list(
  itis = function(...) build_itis(...),
  ncbi = function(...) build_ncbi(...),
  col  = function(...) build_col(...),
  gbif = function(...) build_gbif(...),
  ott  = function(...) build_ott(...),
  fb   = function(...) build_fishbase(provider = "fb", ...),
  slb  = function(...) build_fishbase(provider = "slb", ...),
  iucn = function(...) build_iucn(...)
)

#' Providers taxadb can rebuild
#'
#' @param credentialed include providers that need credentials to build?
#'  Default `FALSE`.
#' @return a character vector of provider abbreviations
#' @details Unlike [available_providers()], which reports what is published,
#' this reports what [td_build()] knows how to derive from the provider's own
#' distribution.
#' @export
#' @examples
#' taxadb_providers()
taxadb_providers <- function(credentialed = FALSE){
  p <- names(BUILDERS)
  if(!credentialed) p <- setdiff(p, "iucn")
  p
}
