
#' Look up taxonomic information by scientific name
#'
#' @param name a character vector of scientific names, e.g. "Homo sapiens"
#' @inheritParams filter_by
#' @return a data.frame in the Darwin Core tabular format containing the
#' matching taxonomic entities.
#'
#' @details
#' Most but not all authorities can match against both species level and
#' higher-level (or lower, e.g. subspecies or variety) taxonomic names.
#' The rank level is indicated by `taxonRank` column.
#'
#' Most authorities include both known synonyms and accepted names in the
#' `scientificName` column, (with the status indicated by `taxonomicStatus`).
#' This is convenient, as users will typically not know if the names they
#' have are synonyms or accepted names, but will want to get the match to the
#' accepted name and accepted ID in either case.
#' @family filter_by
#' @export
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#'
#' sp <- c("Trochalopteron henrici gucenense",
#'         "Trochalopteron elliotii")
#' filter_name(sp)
#'
#' }
#'
filter_name <- function(name,
                provider =c("itis", "ncbi", "col", "tpl",
                            "gbif", "fb", "slb", "wd", "ott",
                            "iucn"),
                version = latest_release(),
                collect = TRUE,
                ignore_case = TRUE,
                db = td_connect()){

  filter_by(x = name,
            by = "scientificName",
            provider = match.arg(provider),
            version = version,
            collect = collect,
            db = db,
            ignore_case = ignore_case)
}

