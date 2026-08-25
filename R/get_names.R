
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
#'    Sys.setenv(TAXADB_HOME = file.path(tempdir(), "taxadb"))
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
                      provider = getOption("taxadb_default_provider", "itis"),
                      version = latest_version(),
                      format = c("guess", "prefix", "bare", "uri"),
                      taxadb_db = td_connect(),
                      db = NULL
                     ){

  if(is.character(db)) {
    warning("Using `db` to specify the provider is deprecated")
    provider <- db
  }

  format <- match.arg(format)
  n <- length(id)

  prefix_ids <- switch(format,
                       prefix = id,
                       as_prefix(id, provider)
                       )
  df <-
    filter_id(prefix_ids,
          provider = provider,
          version = version,
          collect = FALSE,
          db = taxadb_db) %>%
    right_join(tibble(taxonID = prefix_ids, sort=seq_along(prefix_ids)),
              by = "taxonID", copy=TRUE) %>%
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
  ## Already prefix format.  `itis_test` carries real ITIS identifiers, so
  ## the prefix to expect is the provider's own, without the _test suffix.
  pre <- id_prefix(provider)
  if(grepl(paste0("^", pre), x)) return(x)
  ## bare ids
  if(!grepl(":", x)) return(paste0(pre, x))
  ## URI format
  uri_to_prefix(x, provider)
}

id_prefix <- function(provider)
  paste0(toupper(sub("_test$", "", provider)), ":")

uri_to_prefix <- function(x, provider){
  pre <- id_prefix(provider)
  uri_bit <- prefixes$url_prefix[prefixes$id_prefix == pre]
  ## A provider with no registered URI form leaves the id as we found it.
  ## stri_replace with a zero-length pattern returns nothing at all, which
  ## failed vapply's type check rather than reporting anything useful.
  if(length(uri_bit) != 1 || is.na(uri_bit)) return(x)
  ## Matched literally, not as a regex: these URI prefixes contain '?' and
  ## '&', which as a pattern made ITIS's never match its own identifiers.
  stringi::stri_replace_first_fixed(x, uri_bit, pre)
}
