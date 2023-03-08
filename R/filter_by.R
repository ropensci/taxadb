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
#'  Default is 'itis', which can also be configured using `options(default_taxadb_provider=...")`.
#'  See `[td_create]` for a list of recognized providers.
#' @param schema One of "dwc" (for Darwin Core data) or "common"
#' (for the Common names table.)
#' @param version Which version of the taxadb provider database should we use?
#'  defaults to latest.  See [tl_import] for details.
#' @param collect logical, default `TRUE`. Should we return an in-memory
#' data.frame (default, usually the most convenient), or a reference to
#' lazy-eval table on disk (useful for very large tables on which we may
#' first perform subsequent filtering operations.)
#' @param db a connection to the taxadb database. See details.
#' @param ignore_case should we ignore case (capitalization) in matching names?
#' Can be significantly slower to run.
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
#'    Sys.setenv(TAXADB_HOME=file.path(tempdir(), "taxadb"))
#'    options("taxadb_default_provider"="itis_test")
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
                      provider = getOption("taxadb_default_provider", "itis"),
                      schema = c("dwc", "common"),
                      version = latest_version(),
                      collect = TRUE,
                      db = td_connect(),
                      ignore_case = FALSE){

  db_tbl <-taxa_tbl(provider, schema, version, db)
  if(ignore_case){
    out <- dplyr::filter(db_tbl,
                         dplyr::sql(paste0(by, " ilike ",
                                           paste0("'",x, "'"),
                                                  collapse=' OR ')))
  }
  else {
    out <- dplyr::filter(db_tbl, .data[[by]] %in% x)
  }

  if (collect) return( dplyr::collect(out) )
  out
}




# query



globalVariables(c(".data", "%ilike%"), package="taxadb")
## A Filtering Join to filter external DB by a local table.
## We actually use right_join instead of semi_join,
##so unmatched names are kept, with NA
## Note that using right join, names appear in order of remote table,
## which we fix by arrange.
#' @importFrom dplyr right_join arrange
td_filter <- function(x,y, by){
  sort <- "sort"   # avoid complaint about NSE.
                   #We could do sym("sort") but this is cleaner.
  dplyr::right_join(x, y, by = by, copy = TRUE) #%>%
    #dplyr::arrange(sort)
}





## Manually copy query into DB, since RSQLite lacks right_join,
## and dplyr `copy` can only copy table "y"
#' @importFrom dbplyr remote_con
#' @importFrom DBI dbWriteTable
#' @importFrom dplyr left_join tbl
safe_right_join <- function(x, y, by = NULL, copy = FALSE, ...){

  if(copy){
    con <- dbplyr::remote_con(x)
    if(inherits(con, "duckdb_connection")){
      dplyr::right_join(x, y, by = by, copy = copy, ...)
    } else if(inherits(con, "SQLiteConnection")){ ## only attempt on remote tables!
      tmpname <-  paste0(sample(letters, 10, replace = TRUE), collapse = "")
      DBI::dbWriteTable(con, tmpname, y, temporary = TRUE, overwrite = TRUE)
      y <- dplyr::tbl(con, tmpname)
    }
  }
  dplyr::left_join(y, x, by = by, copy = copy, ...)
}

# Thanks https://stackoverflow.com/questions/55083084
# @importFrom rlang sym !! :=
#lowercase_col <- function(df, col) {
#  dplyr::mutate(df, !!rlang::sym(col) := tolower(!!rlang::sym(col)))
#}
# input_table <- tibble::as_tibble(rlang::set_names(list(x), by)) %>%
# dplyr::mutate(sort = 1:length(x))


