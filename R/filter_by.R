#' Creates a data frame with column name given by `by`, and values given
#' by the vector `x`, and then uses this table to do a filtering join,
#' joining on the `by` column to return all rows matching the `x` values
#' (scientificNames, taxonIDs, etc).
#'
#'
#' @param x a vector of values to filter on
#' @param by a column name in the taxa_tbl (following Darwin Core Schema terms).
#'   The filtering join is executed with this column as the joining variable.
#' @param provider from which provider should the hierarchy be returned?
#'  Default is 'itis'.
#' @param collect logical, default `TRUE`. Should we return an in-memory
#' data.frame (default, usually the most convenient), or a reference to
#' lazy-eval table on disk (useful for very large tables on which we may
#' first perform subsequent filtering operations.)
#' @param db a connection to the taxadb database. See details.
#' @param ignore_case should we ignore case (capitalization) in matching names?
#' default is `TRUE`.
#' @return a data.frame in the Darwin Core tabular format containing the
#' matching taxonomic entities.
#' @family filter_by
#' @importFrom dplyr mutate mutate_at collect
#' @importFrom rlang !! sym
#' @importFrom tibble as_tibble tibble
#' @importFrom magrittr %>%
#' @export
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#'
#' sp <- c("Trochalopteron henrici gucenense",
#'         "Trochalopteron elliotii")
#' filter_by(sp, "scientificName")
#'
#' filter_by(c("ITIS:1077358", "ITIS:175089"), "taxonID")
#'
#' filter_by("Aves", "class")
#'
#' }
#'
filter_by <- function(x,
                      by,
                      provider = c("itis", "ncbi", "col", "tpl",
                                   "gbif", "fb", "slb", "wd", "ott",
                                   "iucn"),
                      collect = TRUE,
                      db = td_connect(),
                      ignore_case = TRUE){

  provider <- match.arg(provider)
  db_tbl <- dplyr::mutate(taxa_tbl(provider, "dwc", db), input = !!sym(by))

  if(ignore_case){
    original <- tibble::tibble(input = x, sort = 1:length(x))
    x <- stringi::stri_trans_tolower(x)
    db_tbl <- dplyr::mutate_at(db_tbl, .var = "input", .fun = tolower)
  }

  input_tbl <- tibble::tibble(input = x, sort = 1:length(x))
  out <- td_filter(db_tbl, input_tbl, "input")

  if(ignore_case){  # restore original input case
    input <- "input"
    suppress_msg({
      out <- out %>% select(-input) %>%
        dplyr::inner_join(original, by = "sort", copy = TRUE)
    })
  }

  if (collect) return( dplyr::collect(out) )

  out
}

## A Filtering Join to filter external DB by a local table.
## We actually use right_join instead of semi_join, so unmatched names are kept, with NA
## Note that using right join, names appear in order of remote table, which we
## fix by arrange.
#' @importFrom dplyr right_join arrange
td_filter <- function(x,y, by){
  sort <- "sort"   # avoid complaint about NSE. We could do sym("sort") but this is cleaner.
  suppress_msg({   # bc MonetDBLite whines about upper-case characters
    safe_right_join(x, y, by = by, copy = TRUE) %>%
      dplyr::arrange(sort)
  })
}

## Manually copy query into DB, since RSQLite lacks right_join,
## and dplyr `copy` can only copy table "y"
#' @importFrom dbplyr remote_con
#' @importFrom DBI dbWriteTable
#' @importFrom dplyr left_join tbl
safe_right_join <- function(x, y, by = NULL, copy = FALSE, ...){

  if(copy){
    tmpname <-  paste0(sample(letters, 10, replace = TRUE), collapse = "")
    con <- dbplyr::remote_con(x)
    DBI::dbWriteTable(con, tmpname, y, temporary = TRUE)
    y <- dplyr::tbl(con, tmpname)
  }
  dplyr::left_join(y, x, by = by, ...)
}

# Thanks https://stackoverflow.com/questions/55083084
# @importFrom rlang sym !! :=
#lowercase_col <- function(df, col) {
#  dplyr::mutate(df, !!rlang::sym(col) := tolower(!!rlang::sym(col)))
#}
# input_table <- tibble::as_tibble(rlang::set_names(list(x), by)) %>%
# dplyr::mutate(sort = 1:length(x))


