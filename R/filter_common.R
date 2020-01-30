
#' Look up taxonomic information by common name
#'
#' @param name a character vector of common (vernacular English) names,
#' e.g. "Humans"
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
#' filter_common("Angolan Giraffe")
#'
#' }
#'
filter_common <- function(name,
                provider = getOption("taxadb_default_provider", "itis"),
                version = latest_version(),
                collect = TRUE,
                ignore_case = TRUE,
                db = td_connect()){

  if(!assert_has_common(provider)) return(NULL)

  filter_by(x = name,
            by = "vernacularName",
            provider = provider,
            schema = "common",
            version = version,
            collect = collect,
            db = db,
            ignore_case = ignore_case)
}

NO_COMMON <- c("common_wd", "common_ott", "common_tpl")

assert_has_common <- function(provider){

  if (paste0("common_", provider) %in% NO_COMMON){
    warning(paste("taxadb provider", provider,
                         "does not provide common names at this time."),
                   call. = FALSE)
    return(FALSE)
  }
  TRUE
}
