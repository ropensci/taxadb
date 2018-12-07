#' Connect to the taxald database
#'
#' @param dbdir Path to the database.
#' @return Returns a `src_dbi` connection to the database
#' @details Primarily useful when a lower-level interface to the
#' database is required.  Most `taxald` functions will connect
#' automatically without the user needing to call this function.
#' @importFrom DBI dbConnect
#' @importFrom MonetDBLite MonetDBLite
#' @export
#' @examples \dontrun{
#'
#' db <- connect_db()
#'
#' }
td_connect <- function(dbdir = rappdirs::user_data_dir("taxald")){

  dbname <- file.path(dbdir, "monetdblite")

  ## Stop if monetdb is locked (monetdblite/.gdk_lock)
  ## CANNOT Just check if this file exists -- that breaks every connection!
  ## Stop if monetdb is pointing to another location from the same session

  db <- mget("td_db", envir = taxald_cache, ifnotfound = NA)[[1]]
  if (inherits(db, "DBIConnection")) {
    if (DBI::dbIsValid(db)) {
      return(db)
    }
  }

  dir.create(dbname, FALSE)
  db <- DBI::dbConnect(MonetDBLite::MonetDBLite(), dbname)
  assign("td_db", db, envir = taxald_cache)

  db
}

td_disconnect <- function(env = taxald_cache){
  db <- mget("td_db", envir = env, ifnotfound = NA)[[1]]
  if (inherits(db, "DBIConnection")) {
    DBI::dbDisconnect(db)
  }
}

taxald_cache <- new.env()
reg.finalizer(taxald_cache, td_disconnect, onexit = TRUE)


## dyplr automatially drops temporary table on disconnect
## Only need this to purge tables sooner.
td_clean <- function(db = td_connect()){
  tables <- DBI::dbListTables(db)
  drop <- tables[ !grepl("_", tables) ]
  lapply(drop, function(x) DBI::dbRemoveTable(db, x))
  invisible(TRUE)
}


