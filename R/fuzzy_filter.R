#' Match names that start or contain a specified text string
#'
#'
#' @param match should we match by names starting with the term or containing
#' the term anywhere in the name?
#' @inheritParams filter_by
#' @importFrom dplyr bind_rows filter collect mutate
#' @details Note that fuzzy filter will be fast with an single or small number
#' of names, but will be slower if given a very large vector of names to match,
#' as unlike other `by_` commands, fuzzy matching requires separate SQL calls for
#' each name. As fuzzy matches should all be confirmed manually in any event, e.g.
#' not every common name containing "monkey" belongs to a primate species.
#'
#' This method utilizes the database operation `%like%` to filter tables without
#' loading into memory.  Note that this does not support the use of regular
#' expressions at this time.
#' @export
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#'
#' ## match any common name containing:
#' name <- c("woodpecker", "monkey")
#' fuzzy_filter(name, "vernacularName", "itis")
#'
#' ## match scientific name
#' fuzzy_filter("Homo ", "scientificName", "itis",
#'              match = "starts_with")
#' }
#'
fuzzy_filter <- function(name,
                         by = c("scientificName", "vernacularName"),
                         provider = c("itis", "ncbi", "col", "tpl",
                                      "gbif", "fb", "slb", "wd", "ott",
                                      "iucn"),
                         match = c("contains", "starts_with"),
                         db = td_connect(),
                         ignore_case = TRUE,
                         collect = TRUE){

  by <- match.arg(by)
  provider <- match.arg(provider)
  match <- match.arg(match)

  db_tbl <- dplyr::mutate(taxa_tbl(provider, "dwc", db),
                          input = !!sym(by))
  input <- "input" # NSE

  if(ignore_case){
    name <- stringi::stri_trans_tolower(name)
    db_tbl <- dplyr::mutate_at(db_tbl, .var = "input", .fun = tolower)
  }

  pattern <- switch(match,
                         starts_with = paste0(name, "%"),
                         contains =  paste0("%", name, "%"))
  ## Not fast, but 10x faster than alternatives, see notebook/fuzzy-matching.Rmd

  out <- db_tbl %>%
    dplyr::filter(input %like% pattern[[1]]) %>%
    select(-input) %>%
    dplyr::distinct()

  if(length(pattern) > 1){
    for(p in pattern[-1]){
      out <- dplyr::union(out,
                   db_tbl %>%
                     dplyr::filter(input %like% p) %>%
                     select(-input) %>%
                     dplyr::distinct()
      )
    }
  }

  if (collect) return( dplyr::collect(out) )

  out
}
globalVariables("%like%")


## Consider creating functions that are explicitly named to create more semantic
## code, rather than relying on setting the behavior in the `by` and `match`
## arguments to `fuzzy_filter`, e.g. :
name_contains <- function(name,
                          provider,
                          db = td_connect,
                          ignore_case = TRUE){

  fuzzy_filter(name,
               by = "scientificName",
               provider = provider,
               match = "contains",
               db = db,
               ignore_case = ignore_case)
}

name_starts_with <- function(name,
                             provider,
                             db = td_connect,
                             ignore_case = TRUE){

  fuzzy_filter(name,
               by = "scientificName",
               provider = provider,
               match = "starts_with",
               db = db,
               ignore_case = ignore_case)
}



