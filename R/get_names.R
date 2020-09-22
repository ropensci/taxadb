
#' get_names
#'
#' Translate identifiers into scientific names
#' @param id a list of taxonomic identifiers.
#' @inheritParams get_ids
#' @family get
#' @return a vector of names, of the same length as the input ids. Any
#' unmatched IDs will return as [NA]s.
#' @details
#' Like all taxadb functions, this function will run
#' fastest if a local copy of the provider is installed in advance
#' using `[td_create()]`.
#' @examples \donttest{
#'
#' \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'    options("taxadb_default_provider"="itis_test")
#'   }
#'
#' get_names(c("ITIS:1025094", "ITIS:1025103"), format = "prefix")
#'
#' }
#'
#' @export
#' @importFrom dplyr pull select collect distinct
get_names <- function(id,
                      db = getOption("taxadb_default_provider", "itis"),
                      version = latest_version(),
                      format = c("guess", "prefix", "bare", "uri"),
                      taxadb_db = td_connect()
                     ){
  format <- match.arg(format)
  n <- length(id)
  ver <- version

  prefix_ids <- switch(format,
                       prefix = id,
                       as_prefix(id, db)
                       )
  df <-
    filter_id(prefix_ids,
          provider = db,
          version = ver,
          collect = FALSE,
          db = taxadb_db) %>%
    dplyr::select("scientificName", "taxonID", "sort") %>%
    dplyr::distinct() %>%
    take_first_duplicate() %>%
    dplyr::collect() %>%
    arrange(sort)

  if(dim(df)[1] != n){
    stop(paste("Error in resolving possible duplicate names.",
               "Try the ids() function instead."),
         call. = FALSE)
  }
  df[["scientificName"]]
}

as_prefix <- function(x, provider){
  unname(vapply(x, id_to_prefix, character(1L), provider))
}

id_to_prefix <- function(x, provider){
  ## NAs
  if(is.na(x)) return(as.character(NA))
  ## Already prefix format
  if(grepl(paste0("^", toupper(provider), ":"),  x)) return(x)
  ## bare ids
  if(!grepl(":", x))
    return( paste(toupper(provider), x, sep=":") )
  ## URI format
  uri_to_prefix(x, provider)
}

uri_to_prefix <- function(x, provider){
  pre <- paste0(toupper(provider), ":")
  uri_bit <- prefixes$url_prefix[prefixes$id_prefix == pre]
  stringi::stri_replace_first_regex(x, uri_bit, pre)
}
