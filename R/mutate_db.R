#' Add new variables to a database
#'
#' [dplyr::mutate()] cannot pass arbitrary R functions over a
#' database connection. This function provides a way to work
#' around this, by querying the data in chunks
#' and applying the function to each chunk, which is then
#' appended back out to a temporary table.
#' @param .data A [dplyr::tbl] that uses a database connection, `tbl_dbi` class.
#' @param r_fn any R function that can be called on a vector (column)
#' of the table
#' @param col the name of the column to which the R function is applied.
#' (Note, [dplyr::mutate()] can operate on an arbitrary list of columns,
#' this function only operates on a single column at this time...)
#' @param new_column column name for the new column.
#' @param n the number of rows included in each chunk, see [DBI::dbFetch()]
#' @param ... named arguments to be passed to `r_fn`
#' @return a dplyr tbl connection to the temporary table in the database
#' @importFrom dplyr tbl
#' @export
#'
#'
mutate_db <- function(.data,
                      r_fn,
                      col,
                      new_column,
                      n = 5000L, ...){

  if(!inherits(.data, "tbl_dbi"))
    stop(paste("input must be a table from remote database connection"))

  db <- .data$src$con
  tbl <- as.character(.data$ops$x)

  tmp_tbl <-
    dbi_mutate(db = db,
               tbl = tbl,
               r_fn = r_fn, col = col, new_column = new_column,
               n = 5000L, tmp_tbl = tmp_tablename(), ...)
  dplyr::tbl(db, tmp_tbl)
}


#' DBI Mutate
#'
#' @inheritParams mutate_db
#' @param db a database connection, [DBI::DBIConnection-class]
#' @param tbl the name of a table
#' @param tmp_tbl a name for the temporary table created
#' @return the name of the temporary table created (invisibly).
#' @noRd
#' @importFrom DBI dbCreateTable dbGetQuery dbSendQuery dbFetch
#' @importFrom DBI dbWriteTable dbClearResult
#' @importFrom progress progress_bar
#'
dbi_mutate <- function(db, tbl, r_fn, col, new_column, n = 5000L,
                       tmp_tbl = tmp_tablename(), ...){

  ## Create a temporary table which will store our data, including new column
  schema <- DBI::dbGetQuery(db, paste0("SELECT * FROM \"", tbl, "\" LIMIT 1"))
  schema[[new_column]] <- r_fn(schema[[col]], ...)
  DBI::dbCreateTable(db, tmp_tbl, schema, temporary = TRUE, overwrite = TRUE)


  ## Send the query -- we'll then page over the results in chunks.
  res <- DBI::dbSendQuery(db, paste0("SELECT * FROM\"", tbl, '"'))

  ## Read table in by chunks & write out with mutated column
  p <- progress::progress_bar$new("[:spin] chunk :current", total = 100000)
  while (TRUE) {
    p$tick()
    chunk <- DBI::dbFetch(res, n = n)
    if (nrow(chunk) == 0) break
    chunk[[new_column]] <- r_fn(chunk[[col]], ...)
    DBI::dbWriteTable(db, tmp_tbl, chunk, append = TRUE)
  }
  DBI::dbClearResult(res)

  invisible(tmp_tbl)
}

tmp_tablename <- function(n=15)
  paste0("tmp_", paste0(sample(letters, n, replace = TRUE), collapse = ""))



## no need to join, new table is full copy of old table...
#fields <- DBI::dbListFields(db, tbl)
#dplyr::inner_join(dplyr::tbl(db,tmp_tbl), dplyr::tbl(db,tbl),
#                  by = fields)
