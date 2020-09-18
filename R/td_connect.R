#' Connect to the taxadb database
#'
#' @param dbdir Path to the database.
#' @param driver Default driver, one of "duckdb", "MonetDBLite", "RSQLite".
#'   `taxadb` will select the first one of those it finds available if a
#'   driver is not set. This fallback can be overwritten either by explicit
#'   argument or by setting the environmental variable `TAXADB_DRIVER`.
#' @param readonly logical, should the database be opened read_only? Prevents
#'  importing but will allow concurrent access from multiple sessions.
#' @return Returns a DBI `connection` to the default duckdb database
#' @details This function provides a default database connection for
#' `taxadb`. Note that you can use `taxadb` with any DBI-compatible database
#' connection  by passing the connection object directly to `taxadb`
#' functions using the `db` argument. `td_connect()` exists only to provide
#' reasonable automatic defaults based on what is available on your system.
#'
#' `duckdb` or `MonetDBLite` will give the best performance, and regular users
#' `taxadb` will work with the built-in `RSQlite`, and with other database
#' connections such as Postgres or MariaDB, but queries (filtering joins)
#' will be much slower on these non-columnar databases.
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
#' Sys.setenv(TAXADB_HOME=tempdir())
#'
#' ## Connect to the database:
#' db <- td_connect()
#'
#' }
td_connect <- function(dbdir = taxadb_dir(),
                       driver = Sys.getenv("TAXADB_DRIVER"),
                       readonly = FALSE){

  arkdb::local_db(dbdir = dbdir, driver = driver, readonly = readonly)
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
 arkdb::local_db_disconnect(db)
}


taxadb_dir <- function(){
  Sys.getenv("TAXADB_HOME",  rappdirs::user_data_dir("taxadb"))
}



