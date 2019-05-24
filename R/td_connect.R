#' Connect to the taxadb database
#'
#' @param dbdir Path to the database.
#' @param driver Default driver, one of "duckdb", "MonetDBLite", "RSQLite".
#'   `taxadb` will select the first one of those it finds available if a
#'   driver is not set. This fallback can be overwritten either by explicit
#'   argument or by setting the environmental variable `TAXADB_DRIVER`.
#' @return Returns a `src_dbi` connection to the default duckdb database
#' @details This function provides a default database connection for
#' `taxadb`. Note that you can use `taxadb` with any DBI-compatible database
#' connection  by passing the connection object directly to `taxadb`
#' functions using the `db` argument. `td_connect()` exists only to provide
#' reasonable automatic defaults based on what is available on your system.
#'
#' `duckdb` or `MonetDBLite` will give the best performance, and regular users
#' `taxadb` will work with the built-in `RSQlite`, and with other database connections
#' such as Postgres or MariaDB, but queries (filtering joins) will be much slower
#' on these non-columnar databases.
#'
#' For performance reasons, this function will also cache and restore the
#' existing database connection, making repeated calls to `td_connect()` much
#' faster and more failsafe than repeated calls to [DBI::dbConnect]
#'
#'
#' @importFrom DBI dbConnect dbIsValid
# @importFrom duckdb duckdb
#' @export
#' @examples \donttest{
#' ## OPTIONAL: you can first set an alternative home location,
#' ## such as a temporary directory:
#' Sys.setenv(TAXADB_HOME=tempdir())
#'
#' ## Connect to the database:
#' db <- connect_db()
#'
#' }
td_connect <- function(dbdir = taxadb_dir(),
                       driver = Sys.getenv("TAXADB_DRIVER")){

  dbname <- file.path(dbdir, "database")
  db <- mget("td_db", envir = taxadb_cache, ifnotfound = NA)[[1]]
  if (inherits(db, "DBIConnection")) {
    if (DBI::dbIsValid(db)) {
      return(db)
    }
  }

  dir.create(dbname, showWarnings = FALSE, recursive = TRUE)

  db <- db_driver(dbname, driver)
  #db <- monetdblite_connect(dbname)
  assign("td_db", db, envir = taxadb_cache)
  db
}

db_driver <- function(dbname, driver = Sys.getenv("TAXADB_DRIVER")){

  ## If a specific driver is requested, attempt to use that

  if (requireNamespace("duckdb", quietly = TRUE))
    duckdb <- getExportedValue("duckdb", "duckdb")
  if (requireNamespace("RSQLite", quietly = TRUE))
    SQLite <- getExportedValue("RSQLite", "SQLite")

  db <- switch(driver,
         duckdb = DBI::dbConnect(duckdb(),
                                 dbname = file.path(dbname,"duckdb")),
         MonetDBLite = monetdblite_connect(file.path(dbname,"MonetDBLite")),
         RSQLite = DBI::dbConnect(SQLite(),
                                  file.path(dbname, "taxadb.sqlite")),
         dplyr = NULL,
         "")
  if(!is.character(db))
    return(db)

  ## Otherwise, fall back based on what's available:
  if(requireNamespace("duckdb", quietly = TRUE))
    return(DBI::dbConnect(duckdb(), file.path(dbname,"duckdb")))
  if(requireNamespace("MonetDBLite", quietly = TRUE))
    return(monetdblite_connect(file.path(dbname,"MonetDBLite")))
  if(requireNamespace("RSQLite", quietly = TRUE))
    return(DBI::dbConnect(SQLite(),
                 file.path(dbname, "taxadb.sqlite")))
  ## nope, src_df() lacks DBI syntax
  NULL
}




# Provide an error handler for connecting to monetdblite if locked by another session
# @importFrom MonetDBLite MonetDBLite
monetdblite_connect <- function(dbname, ignore_lock = TRUE){


  if (requireNamespace("MonetDBLite", quietly = TRUE))
    MonetDBLite <- getExportedValue("MonetDBLite", "MonetDBLite")

  db <- tryCatch({
    if (ignore_lock) unlink(file.path(dbname, ".gdk_lock"))
    DBI::dbConnect(MonetDBLite(), dbname = dbname)
    },
    error = function(e){
      if(grepl("Database lock", e))
        stop(paste("Local taxadb database is locked by another R session.\n",
                   "Try closing that session first or set the TAXADB_HOME\n",
                   "environmental variable to a new location.\n"),
             call. = FALSE)
      else stop(e)
    },
    finally = NULL
  )
  db
}

td_disconnect <- function(env = taxadb_cache){
  db <- mget("td_db", envir = env, ifnotfound = NA)[[1]]
  if (inherits(db, "DBIConnection")) {
    suppressWarnings(
    DBI::dbDisconnect(db)
    )
  }
}

## Enironment to store the cached copy of the connection
## and a finalizer to close the connection on exit.
taxadb_cache <- new.env()
reg.finalizer(taxadb_cache, td_disconnect, onexit = TRUE)


taxadb_dir <- function(){
  Sys.getenv("TAXADB_HOME",  rappdirs::user_data_dir("taxadb"))
}
