#' Connect to the taxadb database
#'
#' @param dbdir Path to the database.
#' @return Returns a `src_dbi` connection to the database
#' @details Primarily useful when a lower-level interface to the
#' database is required.  Most `taxadb` functions will connect
#' automatically without the user needing to call this function.
#' @importFrom DBI dbConnect
#' @importFrom MonetDBLite MonetDBLite
#' @export
#' @examples \dontrun{
#'
#' db <- connect_db()
#'
#' }
td_connect <- function(dbdir = rappdirs::user_data_dir("taxadb")){

  dbname <- file.path(dbdir, "monetdblite")

  ## Stop if monetdb is locked (monetdblite/.gdk_lock)
  ## CANNOT Just check if this file exists -- that breaks every connection!
  ## Stop if monetdb is pointing to another location from the same session

  db <- mget("td_db", envir = taxadb_cache, ifnotfound = NA)[[1]]
  if (inherits(db, "DBIConnection")) {
    if (DBI::dbIsValid(db)) {
      return(db)
    }
  }

  dir.create(dbname, FALSE)
  db <- DBI::dbConnect(MonetDBLite::MonetDBLite(), dbname)
  assign("td_db", db, envir = taxadb_cache)

  db
}

td_disconnect <- function(env = taxadb_cache){
  db <- mget("td_db", envir = env, ifnotfound = NA)[[1]]
  if (inherits(db, "DBIConnection")) {
    DBI::dbDisconnect(db)
  }
}

taxadb_cache <- new.env()
reg.finalizer(taxadb_cache, td_disconnect, onexit = TRUE)

