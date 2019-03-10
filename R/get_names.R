
#' get_names
#'
#' Translate identifiers into scientific names
#' @param id a list of taxonomic identifiers.
#' @param db abbreviation code for the provider.  See details.
#' @param format Format for the input identifier, one of
#'   - `guess` Will determine the prefix automatically, but will be
#'   slower than if you specify this in advance!
#'   - `prefix` (e.g. `NCBI:9606`), Preferred (fastest) format.
#'   - `bare` (e.g. `9606`), (But must mach provider `db`!)
#'   - `uri` (e.g. `http://ncbi.nlm.nih.gov/taxonomy/9606`).
#' @param taxadb_db Connection to from `[td_connect]()`.
#' @param ignore_case should we ignore case (capitalization) in matching names?
#' default is `TRUE`.
#' @family get
#' @return a vector of names, of the same length as the input ids. Any
#' unmatched IDs will return as [NA]s.
#' @details
#' Like all taxadb functions, this function will run
#' fastest if a local copy of the provider is installed in advance
#' using `[td_create()]`.
#' @examples \donttest{
#' get_names(180092)
#' get_names(c("ITIS:180092", "ITIS:179913"))
#' get_names(c("ITIS:180092", "ITIS:179913"), format = "prefix")
#' }
#' @export
#' @importFrom dplyr pull select collect distinct
get_names <- function(id,
                      db = c("itis", "ncbi", "col", "tpl",
                             "gbif", "fb", "slb", "wd", "ott",
                             "iucn"),
                      format = c("guess", "prefix", "bare", "uri"),
                      ignore_case = TRUE,
                      taxadb_db = td_connect(),
                      ...){
  format <- match.arg(format)
  db <- match.arg(db)
  n <- length(id)


  prefix_ids <- switch(format,
                       prefix = id,
                       as_prefix(id, db)
                       )
  df <-
    by_id(prefix_ids,
          provider = db,
          collect = FALSE,
          ignore_case = ignore_case,
          db = taxadb_db) %>%
    dplyr::select("scientificName", "taxonID", "sort") %>%
    dplyr::distinct() %>%
    take_first_duplicate() %>%
    dplyr::collect()

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
  if(is.na(x)) return(NA)
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
