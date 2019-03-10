#' Connect to the taxadb database
#'
#' @param dbdir Path to the database.
#' @return Returns a `src_dbi` connection to the default MonetDBLite database
#' @details This function provides a MonetDBLite database connection for
#' `taxadb`. Note that `taxadb` functions provide drop-in support for most
#' relational database connections as an alternative to the MonetDBLite
#' option -- simply supply a different `src_dbi` connection in place of
#' the one returned by `td_connect()`.
#'
#' The MonetDBLite connection provided by this function is set as the default
#' option because it can be automatically installed as an embedded database
#' from R, much like SQLite, without requiring a seperate server instance.
#' MonetDBLite is much faster (particularly for joins) and more feature-rich
#' than SQLite (e.g. supporting windowing functions). One drawback of the
#' embeded database is the inability to support concurrent connections from
#' multiple R sessions.  Either limit access to the local database to a
#' single R session at a time, or provide an alternative TAXADB_HOME path
#' to start a second session with a separate database.  Alternatively,
#' some users may prefer a free-standing server connection to support concurrent
#' connections.  We recommend MonetDB (server version) for this for the
#' best performance. `taxadb` will work with other database connections such
#' as Postgres or MariaDB, but queries (filtering joins) will be much slower
#' on these non-columnar databases.
#'
#' For performance reasons, this function will also cache and restore the
#' existing database connection, making repeated calls to `td_connect()` much
#' faster and more failsafe than repeated calls to [DBI::dbConnect]
#'
#'
#' @importFrom DBI dbConnect dbIsValid
#' @importFrom MonetDBLite MonetDBLite
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
td_connect <- function(dbdir = taxadb_dir()){

  dbname <- file.path(dbdir, "monetdblite")
  db <- mget("td_db", envir = taxadb_cache, ifnotfound = NA)[[1]]
  if (inherits(db, "DBIConnection")) {
    if (DBI::dbIsValid(db)) {
      return(db)
    }
  }

  dir.create(dbname, FALSE)

  tryCatch(
    db <- DBI::dbConnect(MonetDBLite::MonetDBLite(), dbname),
    error = function(e){
      if(grepl("Database lock", e))
        stop(paste("Local taxadb database is locked by another R session.\n",
                 "Try closing that session first or set the TAXADB_HOME\n",
                  "environmental variable to a new location.\n"),
             call. = FALSE)
      else stop(e)
    },
    finally = return(NULL)
  )


  assign("td_db", db, envir = taxadb_cache)
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
