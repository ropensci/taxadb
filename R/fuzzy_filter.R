#' Match names that start or contain a specified text string
#'
#' @param name vector of names (scientific or common, see `by`) to be matched against.
#' @param match should we match by names starting with the term or containing
#' the term anywhere in the name?
#' @inheritParams filter_by
#' @importFrom dplyr union mutate_at mutate select
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


  out <- filter_like(db_tbl, input, pattern[[1]])

  if(length(pattern) > 1){
    for(p in pattern[-1]){
      out <- dplyr::union(out, filter_like(db_tbl, input, p))
    }
  }

  if (collect) return( dplyr::collect(out) )

  out
}

globalVariables("%like%")

filter_like <- function(db_tbl, input, pattern){

  if(inherits(db_tbl, "tbl_dbi")){
  out <- db_tbl %>%
    dplyr::filter(input %like% pattern)
  } else {
    out <- db_tbl %>%
      dplyr::filter(grepl(gsub(pattern, "%", ""), input))
  }

  out %>%
    select(-input) %>%
    dplyr::distinct()
}





## Consider creating functions that are explicitly named to create more semantic
## code, rather than relying on setting the behavior in the `by` and `match`
## arguments to `fuzzy_filter`, e.g. :

#' return all taxa in which scientific name contains the text provided
#'
#' @export
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#' name_contains("Homo ")
#' }
#' @inheritParams fuzzy_filter
name_contains <- function(name,
                          provider = "itis",
                          db = td_connect(),
                          ignore_case = TRUE){

  fuzzy_filter(name,
               by = "scientificName",
               provider = provider,
               match = "contains",
               db = db,
               ignore_case = ignore_case)
}


#' scientific name starts with
#'
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#' name_contains("Homo ")
#' }
#' @inheritParams fuzzy_filter
#' @export
name_starts_with <- function(name,
                             provider,
                             db = td_connect(),
                             ignore_case = TRUE){

  fuzzy_filter(name,
               by = "scientificName",
               provider = provider,
               match = "starts_with",
               db = db,
               ignore_case = ignore_case)
}



#' common name starts with
#'
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#' common_starts_with("monkey")
#' }
#' @inheritParams fuzzy_filter
#' @export
common_starts_with <- function(name,
                             provider = "itis",
                             db = td_connect(),
                             ignore_case = TRUE){

  fuzzy_filter(name,
               by = "vernacularName",
               provider = provider,
               match = "starts_with",
               db = db,
               ignore_case = ignore_case)
}


#' common name starts with
#'
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#' common_contains("monkey")
#' }
#' @inheritParams fuzzy_filter
#' @export
common_contains <- function(name,
                            provider = "itis",
                            db = td_connect(),
                            ignore_case = TRUE){

  fuzzy_filter(name,
               by = "vernacularName",
               provider = provider,
               match = "contains",
               db = db,
               ignore_case = ignore_case)
}







