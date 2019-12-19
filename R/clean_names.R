#' Clean taxonomic names
#'
#' A utility to sanitize taxonomic names to increase
#' probability of resolving names.
#'
#' @param names a character vector of taxonomic names (usually species names)
#' @param fix_delim Should we replace separators `.`, `_`, `-`
#' with spaces? e.g. 'Homo.sapiens' becomes 'Homo sapiens'.
#' logical, default TRUE.
#' @param binomial_only Attempt to prune name to a binomial name, e.g.
#'  Genus and species (specific epithet), e.g. `Homo sapiens sapiens`
#'  becomes `Homo sapiens`. logical, default [TRUE].
#' @param remove_sp Should we drop unspecified species epithet designations?
#' e.g. `Homo sp.` becomes `Homo` (thus only matching against genus level ids).
#' logical, default [TRUE].
#' @param ascii_only should we coerce strings to ascii characters?
#' (see [stringi::stri_trans_general()])
#' @param lowercase should names be coerced to lower-case to provide
#'  case-insensitive matching?
#' @param remove_punc replace all punctuation but apostrophes with a space,
#' remove apostrophes
#' @details Current implementation is limited to handling a few
#' common cases. Additional extensions may be added later.
#' A goal of the `clean_names` function is that any
#' modification rule of the name strings be precise, atomic, and
#' toggle-able, rather than relying on clever but more opaque rules and
#' arbitrary scores. This utility should always be used with care, as
#' indiscriminate modification of names may result in successful but inaccurate
#' name matching. A good pattern is to only apply this function to the subset
#' of names that cannot be directly matched.
#'
#' @importFrom stringi stri_replace_all_regex stri_extract_all_words
#' @importFrom stringi stri_trim stri_split_regex stri_trans_general
#' @export
#'
#' @examples
#' clean_names(c("Homo sapiens sapiens", "Homo.sapiens", "Homo sp."))
#'
clean_names <-
  function(names,
           fix_delim = TRUE,
           binomial_only = TRUE,
           remove_sp = TRUE,
           ascii_only = TRUE,
           lowercase = TRUE,
           remove_punc = FALSE){
    if(lowercase)
      names <- stringi::stri_trans_tolower(names)
    if(ascii_only)
      names <- stringi::stri_trans_general(names,"latin-ascii")
    if(fix_delim)
      names <- set_space_delim(names)
    if(binomial_only)
      names <- binomial_names(names)
    if(remove_sp)
      names <- drop_sp.(names)
    if(remove_punc)
      names <- drop_punc(names)
    names
  }

## Name cleaning utilities

set_space_delim <- function(x)
  stringi::stri_replace_all_regex(x, "(_|-|\\.)", " ") %>%
  stringi::stri_trim()

drop_sp. <- function(x){
  # drop: cladophora sp2, cladophora sp., cladophora ssp.
  stringi::stri_replace_all_regex(x, "\\ssp[s\\d\\.]?$", "")

}
binomial_names <- function(x){
  s <-
    stringi::stri_split_regex(x, "/", simplify = TRUE)[,1] %>%
    stringi::stri_extract_all_words(simplify = TRUE)
  if(dim(s)[2] > 1)
    stringi::stri_trim(paste(s[,1], s[,2]))
  else
    stringi::stri_trim(s[,1])
}
drop_parenthetical <- function(x){
  stringi::stri_trim(stringi::stri_replace_all_regex(x, "\\(.+\\)", ""))
}
drop_punc <- function(x){
  #replace everything but letters and apostrophes with a space"
  names <- stringi::stri_replace_all_regex(x, "[^[:alnum:][:space:]']", " ")
  #remove apostrophes
  names <- stringi::stri_replace_all_regex(x, "[']", "")
}
