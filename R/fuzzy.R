## Fuzzy matching should do more than starts_with and contains


search <- function(name = NULL,
                   provider = KNOWN_AUTHORITIES,
                   match = c("exact", "starts_with", "contains"),
                   format = c("bare", "prefix", "uri"),
                   db = td_connect()){
  match <- match.arg(match)
  switch(match,
         exact = get_ids(names = name,
                         provider = provider,
                         format = format,
                         db = db),
         starts_with = fuzzy_ids(name = name,
                                 provider = provider,
                                 match = match,
                                 format = format,
                                 db = db),
         contains = fuzzy_ids(name = name,
                              provider = provider,
                              match = match,
                              format = format,
                              db = db),

         )
}


#' Clean taxonomic names
#'
#' A utility to sanitize taxonomic names to increase probability of resolving names.
#'
#' @param names a character vector of taxonomic names (usually species names)
#' @param fix_delim Should we replace separators `.`, `_`, `-`
#' with spaces? e.g. 'Homo.sapiens' becomes 'Homo sapiens'.
#' logical, default TRUE.
#' @param binomial_only Attempt to prune name to a binomial name, e.g.
#'  Genus and species (specific epithet), e.g. `Homo sapiens sapiens`
#'  becomes `Homo sapiens`. logical, default TRUE.
#' @param remove_sp Should we drop unspecified species epithet designations?
#' e.g. `Homo sp.` becomes `Homo` (thus only matching against genus level ids).
#' logical, default TRUE.
#' @details Current implementation is limited to handling a few common cases.
#' Additional extensions may be added later. A goal of the `clean_names` function
#' is that any modification rule of the name strings be precise, atomic, and
#' toggle-able, rather than relying on clever but more opaque rules and
#' arbitrary scores. This utility should always be used with care, as
#' indiscriminant modification of names may result in successful but inaccurate
#' name matching. A good pattern is to only apply this function to the subset
#' of names that cannot be directly matched.
#'
#'
#' @importFrom stringi stri_replace_all_regex stri_extract_all_words
#' @importFrom stringi stri_trim stri_split_regex
#' @export
#' @examples
#' clean_names(c("Homo sapiens sapiens", "Homo.sapiens", "Homo sp."))
clean_names <-
  function(names,
           fix_delim = TRUE,
           binomial_only = TRUE,
           remove_sp = TRUE){
  if(fix_delim)
    names <- set_space_delim(names)
  if(remove_sp)
    names <- drop_sp.(names)
  if(binomial_only)
    names <- binomial_names(names)
  names

}

## Name cleaning utilities

set_space_delim <- function(x)
  stringi::stri_replace_all_regex(x, "(_|-|\\.)", " ") %>%
  stringi::stri_trim()

drop_sp. <- function(x)
  stringi::stri_replace_all_regex(x, "\\ssp\\.?$", "")

binomial_names <- function(x){
  s <-
    stringi::stri_split_regex(x, "/", simplify = TRUE)[,1] %>%
    stringi::stri_extract_all_words(simplify = TRUE)
  stringi::stri_trim(paste(s[,1], s[,2]))
}
drop_author_year <- function(x){
  stringi::stri_replace_all_regex(x, "\\(.+)", "")
}

#' @importFrom dplyr bind_rows filter collect mutate
fuzzy_ids <- function(name = NULL,
                      provider = KNOWN_AUTHORITIES,
                      match = c("starts_with", "contains"),
                      format = c("bare", "prefix", "uri"),
                      db = td_connect()){

  name <- set_space_delim(name)
  match <- match.arg(match)
  name_pattern <- switch(match,
                    starts_with = paste0(name, "%"),
                    contains =  paste0("%", name, "%"))
  ## Not fast, but 10x faster than alternatives, see notebook/fuzzy-matching.Rmd
  out <- do.call(dplyr::bind_rows,
    lapply(name_pattern,
          function(pattern){

            taxa_tbl(provider, "dwc", db) %>%
            dplyr::filter(name %like% pattern) %>%
            dplyr::collect() %>%
            dplyr::mutate(input_name = gsub("%", "", pattern))
            })
         ) %>%
    dplyr::distinct()

  out


}

globalVariables("%like%")
