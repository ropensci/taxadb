#' Add new variables to a database
#'
#' [dplyr::mutate()] cannot pass arbitrary R functions over a database connection.
#' This function provides a way to work around this, by querying the data in chunks
#' and applying the function to each chunk, which is then appended back out to a
#' temporary table.
#' @param db a database connection, [DBI::DBIConnection()]
#' @param tbl the name of a table
#' @param r_fn any R function that can be called on a vector (column) of the table
#' @param col the name of the column to which the R function is applied.
#' (Note, [dplyr::mutate()] can operate on an arbitrary list of columns, this function
#' only operates on a single column at this time...)
#' @param new_column column name for the new column.
#' @param n the number of rows included in each chunk, see [DBI::dbFetch()]
#' @importFrom DBI dbCreateTable dbGetQuery dbSendQuery dbFetch
#' @importFrom DBI dbWriteTable dbClearResult
#' @importFrom progress progress_bar
#'
#' @export
db_mutate <- function(db, tbl, r_fn, col, new_column, n = 5000L){

  ## Create a temporary table which will store our data, including new column
  tmp_tbl <- paste0("tmp_", paste0(sample(letters, 10, replace = TRUE), collapse = ""))
  schema <- DBI::dbGetQuery(db, paste("SELECT * FROM", tbl, "LIMIT 1"))
  schema[[new_column]] = r_fn(schema[[col]])
  DBI::dbCreateTable(db, tmp_tbl, schema, temporary = TRUE)


  ## Send the query -- we'll then page over the results in chunks.
  res <- DBI::dbSendQuery(db, paste("SELECT * FROM", tbl))

  ## Read table in by chunks & write out with mutated column
  p <- progress::progress_bar$new("[:spin] chunk :current", total = 100000)
  while (TRUE) {
    p$tick()
    chunk <- DBI::dbFetch(res, n = n)
    if (nrow(chunk) == 0) break
    chunk[[new_column]] = r_fn(chunk[[col]])
    DBI::dbWriteTable(db, tmp_tbl, chunk, append=TRUE)
  }
  DBI::dbClearResult(res)

  ## no need to join, new table is full copy of old table...
  #fields <- DBI::dbListFields(db, tbl)
  #dplyr::inner_join(dplyr::tbl(db,tmp_tbl), dplyr::tbl(db,tbl),
  #                  by = fields)


  ## for return object we could:
  ## - return the name of the temporary table (or maybe that should be an argument?)
  ## - return a tibble connection to the tmp_tbl: `dplyr::tbl(db, tmp_tbl)`
  ## - perform a join to add column to existing original table
  dplyr::tbl(db, tmp_tbl)
}

