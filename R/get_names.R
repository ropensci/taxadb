## Drop in replacements for taxize functions


## FIXME get_ids objects to having duplicated names.
##  ( duplicate_as_unresolved() drops the duplicates?
## duplicated names should be okay!

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
#' @param ... additional arguments passed to `filter_by()`
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
#' @importFrom dplyr pull
get_names <- function(id,
                      db = known_providers,
                      format = c("guess", "prefix", "bare", "uri"),
                      taxadb_db = td_connect(),
                      ...){
  format <- match.arg(format)
  db <- match.arg(db)
  n <- length(id)

  ## FIXME call:
  # by_id(prefix_ids) %>% select("scientificName", "taxonID", "sort") %>% distinct() %>% take_first_duplicate() %>% collect()

  prefix_ids <- switch(format,
                       prefix = id,
                       as_prefix(id, db)
                       )



  input_table <- tibble::tibble("taxonID" = prefix_ids,
                        sort = 1:n)

  suppress_msg({   # bc MonetDBLite whines about upper-case characters
    out <-
      dplyr::right_join(
        taxa_tbl(db, db = taxadb_db),
        input_table,
        by = "taxonID",
        copy = TRUE) %>%
      dplyr::select("scientificName", "taxonID", "sort") %>%
      dplyr::distinct() %>%
      dplyr::arrange(sort)
  })

  ## A taxonID may appear in multple rows when the scientificName
  ## it corresponds is a synonym of multiple taxa.  But the
  ## taxonID, scientificName pair is still unique.

  ## However, some databases (e.g. COL) list multiple accepted names:
  df <- take_first_duplicate(out) %>% collect()


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
