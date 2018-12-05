## Drop in replacements for taxize functions

#' get_ids
#'
#' A drop-in replacement for `[taxize::get_ids()]`
#' @param names a list of scientific names (which may
#'   include higher-order ranks in most authorities).
#' @param db abbreviation code for the authority.  See details.
#' @param format Format for the returned: bare identifier, one of
#' `bare` (e.g. `9606`, default, matching `taxize::get_ids()`),
#' `prefix` (e.g. `NCBI:9606`), or `uri`
#' (e.g. `https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=9606`).
#' @param ... additional arguments passed to `ids()`
#' @details Note that some taxize authorities: `nbn`, `tropicos`, and `eol`,
#' are not recognized by taxald and will throw an error here. Meanwhile,
#' taxald recognizes several authorities not known to `[taxize::get_ids()]`.
#' Both include `itis`, `ncbi`, `col`, and `gbif`.
#'
#' Like all taxald functions, this function will run
#' fastest if a local copy of the authority is installed in advance
#' using `[td_create()]`.
#' @examples \donttest{
#' get_ids("Homo sapiens")
#' get_ids(c("Homo sapiens", "Mammalia"), format = "prefix")
#' get_ids("Homo sapiens", db= "ncbi", format = "uri")
#' }
#' @export
get_ids <- function(names,
                    db = c("itis", "ncbi", "col", "tpl",
                           "gbif", "fb", "slb", "wd"),
                    format = c("bare", "prefix", "uri"),
                    ...){
  format <- match.arg(format)
  # be compatible with common space delimiters
  names <- gsub("[_|-|\\.]", " ", names)
  out <- ids(name = names, authority = db,
             pull = TRUE, collect = TRUE, ...)
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

