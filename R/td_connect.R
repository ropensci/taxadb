#' Connect to the taxadb database
#'
#' @param dbdir Path to the database. no longer needed
#' @param driver deprecated, ignored.  driver will always be duckdb.
#' @param read_only deprecated, driver is always read-only.
#' @return Returns a DBI `connection` to the default duckdb database
#' @details This function provides a default database connection for
#' `taxadb`. Note that you can use `taxadb` with any DBI-compatible database
#' connection  by passing the connection object directly to `taxadb`
#' functions using the `db` argument. `td_connect()` exists only to provide
#' reasonable automatic defaults based on what is available on your system.
#'
#' For performance reasons, this function will also cache and restore the
#' existing database connection, making repeated calls to `td_connect()` much
#' faster and more failsafe than repeated calls to [DBI::dbConnect]
#'
#'
#' @importFrom DBI dbConnect dbIsValid
#' @export
#' @examples \donttest{
#' ## OPTIONAL: you can first set an alternative home location,
#' ## such as a temporary directory:
#' Sys.setenv(TAXADB_HOME=file.path(tempdir(), "taxadb"))
#'
#' ## Connect to the database:
#' db <- td_connect()
#'
#' }
td_connect <- function(dbdir = NULL,
                       driver = NULL,
                       read_only = NULL,
                       version = latest_version()){

  for(x in c(dbdir, driver, read_only)) {
    if(!is.null(x)) {
      warning(paste("arg", x, "is deprecated and will be ignored see docs\n",
                    "future releases will remove this arguments"))
    }
  }

  db_name <- paste("taxadb",version, sep="_")
  db <- mget(db_name, envir = taxadb_cache, ifnotfound = NA)[[1]]

  if(!inherits(db, "duckdb_connection")){
    db <- DBI::dbConnect(drv = duckdb::duckdb())
    assign(db_name, db, envir = taxadb_cache)
  }
  db
}

#' Disconnect from the taxadb database.
#'
#' @param db database connection
#' @details This function manually closes a connection to the `taxadb` database.
#'
#' @importFrom DBI dbConnect dbIsValid
# @importFrom duckdb duckdb
#' @export
#' @examples \donttest{
#'
#' ## Disconnect from the database:
#' td_disconnect()
#'
#' }
td_disconnect <- function(db = td_connect()){
  if(inherits(db, "duckdb_connection")) {
    DBI::dbDisconnect(db, shutdown=TRUE)
  }
  db_name <- ls(envir = taxadb_cache)
  for(cached in db_name) {
    db <- mget(cached, envir = taxadb_cache, ifnotfound = NA)[[1]]
    remove(list = cached, envir = taxadb_cache)
  }
}



taxadb_cache <- new.env()

#' disconnect the database
#' @param db optional, an existing pointer to the db, e.g. from [fb_conn()]
#' or [fb_import()].
#' @export
db_disconnect <- function(db = NULL){

}
