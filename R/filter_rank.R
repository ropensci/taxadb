
#' Get all members (descendants) of a given rank level
#'
#' @param name taxonomic scientific name (e.g. "Aves")
#' @param rank taxonomic rank name. (e.g. "class")
#' @inheritParams filter_by
#' @return a data.frame in the Darwin Core tabular format containing the
#' matching taxonomic entities.
#' @family filter_by
#' @export
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#'
#' filter_rank("Aves", "class")
#'
#' }
#'
filter_rank <- function(name,
                    rank,
                    provider = getOption("taxadb_default_provider", "itis"),
                    version = latest_version(),
                    collect = TRUE,
                    ignore_case = TRUE,
                    db = td_connect()){

  filter_by(x = name,
            by = rank,
            provider = provider,
            version = version,
            collect = collect,
            db = db,
            ignore_case = ignore_case)

}
