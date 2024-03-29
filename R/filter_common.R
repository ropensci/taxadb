
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
#'    options("taxadb_default_provider"="itis_test")
#'    Sys.setenv(TAXADB_HOME=file.path(tempdir(), "taxadb"))
#'   }
#'
#' filter_common("Pied Tamarin")
#'
#' }
#'
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.unsetenv("TAXADB_HOME")
#'    options("taxadb_default_provider" = NULL)
#'   }

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
