
## FIXME get_ids objects to having duplicated names.
##  ( duplicate_as_unresolved() drops the duplicates?
## duplicated names should be okay!

#' get_ids
#'
#' A drop-in replacement for `[taxize::get_ids()]`
#' @param names a list of scientific names (which may
#'   include higher-order ranks in most authorities).
#' @param db abbreviation code for the provider.  See details.
#' @param format Format for the returned identifier, one of
#'   - `prefix` (e.g. `NCBI:9606`, the default), or
#'   - `bare` (e.g. `9606`, used in `taxize::get_ids()`),
#'   - `uri` (e.g.
#'   `http://ncbi.nlm.nih.gov/taxonomy/9606`).
#' @param taxadb_db Connection to from `[td_connect]()`.
#' @param ignore_case should we ignore case (capitalization) in matching names?
#' default is `TRUE`.
#' @param ... additional arguments (currently ignored)
#' @return a vector of IDs, of the same length as the input names Any
#' unmatched names or multiply-matched names will return as [NA]s.
#' To resolve multi-matched names, use [by_name()] instead to return
#' a table with a separate row for each separate match of the input name.
#' @seealso by_name
#' @family get
#' @details Note that some taxize authorities: `nbn`, `tropicos`, and `eol`,
#' are not recognized by taxadb and will throw an error here. Meanwhile,
#' taxadb recognizes several authorities not known to `[taxize::get_ids()]`.
#' Both include `itis`, `ncbi`, `col`, and `gbif`.
#'
#' Like all taxadb functions, this function will run
#' fastest if a local copy of the provider is installed in advance
#' using `[td_create()]`.
#' @examples \donttest{
#' get_ids("Homo sapiens")
#' get_ids(c("Homo sapiens", "Mammalia"), format = "prefix")
#' get_ids("Homo sapiens", db= "ncbi", format = "uri")
#' }
#' @export
#' @importFrom dplyr pull
#' @importFrom tibble column_to_rownames
get_ids <- function(names,
                    db = known_providers,
                    format = c("prefix", "bare", "uri"),
                    taxadb_db = td_connect(),
                    ignore_case = TRUE,
                    ...){
  format <- match.arg(format)
  n <- length(names)

  # be compatible with common space delimiters
  names <- gsub("[_|-|\\.]", " ", names)

  df <- by_name(name = names,
                provider = db,
                collect = TRUE,
                ignore_case = ignore_case,
                db = taxadb_db)

  df <- duplicate_as_unresolved(df)

  if(dim(df)[1] != n){
    stop(paste("Error in resolving possible duplicate names.",
               "Try the by_name() function instead."),
         .call = FALSE)
  }

  ##
  if("acceptedNameUsageID" %in% names(df)){
    out <- dplyr::pull(df, "acceptedNameUsageID")
  } else {
    out <- dplyr::pull(df, "taxonID")
  }

  ## Format ID as requested
  switch(format,
         "uri" = prefix_to_uri(out),
         "prefix" = out,
         strip_prefix(out))
}

strip_prefix <- function(x) gsub("^\\w+:", "", x)

i_or_na <- function(x, i){
  if(length(x) < i) return(as.character(NA))
  x[[i]]
}

replace_na <- function(x, replace=""){
  ifelse(is.na(x), replace, x)
}
replace_empty <- function(x){
  ifelse(x=="", NA, x)
}

prefix_to_uri <- function(x){
  # Use look-behind to keep the ":" and split after it.
  bits <- strsplit(x, "(?<=:)", perl = TRUE)
  input <- tibble(
    id_prefix = vapply(bits, `[[`, character(1L), 1),
    id = vapply(bits, i_or_na, character(1L), 2))
  resolved <- dplyr::left_join(input, prefixes, "id_prefix")

  ## append prefixes, respecting NAs
  out <- paste0(replace_na(resolved$url_prefix), replace_na(resolved$id))
  replace_empty(out)
}

