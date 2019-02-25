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
