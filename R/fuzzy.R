## Fuzzy matching should do more than starts_with and contains


search <- function(name = NULL,
                   authority = KNOWN_AUTHORITIES,
                   match = c("exact", "starts_with", "contains"),
                   format = c("bare", "prefix", "uri"),
                   db = td_connect()){
  match <- match.arg(match)
  switch(match,
         exact = get_ids(names = name,
                         authority = authority,
                         format = format,
                         db = db),
         starts_with = fuzzy_ids(name = name,
                                 authority = authority,
                                 match = match,
                                 format = format,
                                 db = db),
         contains = fuzzy_ids(name = name,
                              authority = authority,
                              match = match,
                              format = format,
                              db = db),

         )
}


#
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
#' @importFrom stringi stri_replace_all_regex stri_extract_all_words
#' @importFrom stringi stri_trim stri_split_regex
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


#' @importFrom dplyr bind_rows filter collect mutate
fuzzy_ids <- function(name = NULL,
                      authority = KNOWN_AUTHORITIES,
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

            taxa_tbl(authority, "taxonid", db) %>%
            dplyr::filter(name %like% pattern) %>%
            dplyr::collect() %>%
            dplyr::mutate(input_name = gsub("%", "", pattern))
            })
         ) %>%
    dplyr::distinct()

  out


}

globalVariables("%like%")
