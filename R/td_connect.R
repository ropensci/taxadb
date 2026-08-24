#' Connect to the taxadb database
#'
#' @param dbdir Deprecated, ignored.
#' @param driver Deprecated, ignored. The driver is always `duckdb`.
#' @param read_only Deprecated, ignored.
#' @return a DBI `connection` to an in-process duckdb database, configured
#'  for anonymous streaming reads from the `taxadb` data repository.
#' @details `taxadb` reads Parquet snapshots directly from object storage
#' (<https://source.coop>) using `duckdb`'s `httpfs` extension, so no data
#' import step is required.  This function returns a connection with
#' `httpfs` loaded and the S3 endpoint configured for anonymous access.
#'
#' For performance reasons the connection is cached and reused, making
#' repeated calls to `td_connect()` much faster and more failsafe than
#' repeated calls to [DBI::dbConnect].
#'
#' Set `options(taxadb_threads=)` or `options(taxadb_memory_limit=)` to
#' constrain `duckdb`'s resource use.
#'
#' @importFrom DBI dbConnect dbIsValid dbExecute
#' @export
#' @examples \donttest{
#' db <- td_connect()
#' }
td_connect <- function(dbdir = NULL,
                       driver = NULL,
                       read_only = NULL){

  assert_deprecated(dbdir, driver, read_only)

  db_name <- "taxadb_conn"
  db <- mget(db_name, envir = taxadb_cache, ifnotfound = NA)[[1]]

  if(inherits(db, "duckdb_connection") && DBI::dbIsValid(db)) return(db)

  db <- DBI::dbConnect(duckdb::duckdb())
  configure_duckdb(db)
  assign(db_name, db, envir = taxadb_cache)
  db
}

## Load httpfs and point it at the taxadb object store for anonymous reads.
## Anonymous access needs only the endpoint settings -- no credentials, and
## no `CREATE SECRET`, which would fail on duckdb < 0.10.
configure_duckdb <- function(db){

  threads <- getOption("taxadb_threads", NULL)
  if(!is.null(threads))
    DBI::dbExecute(db, paste0("SET threads=", as.integer(threads), ";"))

  mem <- getOption("taxadb_memory_limit", NULL)
  if(!is.null(mem))
    DBI::dbExecute(db, paste0("SET memory_limit='", mem, "';"))

  ok <- tryCatch({
    DBI::dbExecute(db, "INSTALL httpfs;")
    DBI::dbExecute(db, "LOAD httpfs;")
    TRUE
  }, error = function(e) FALSE)

  if(!ok){
    warning(paste("Could not load the duckdb `httpfs` extension.",
                  "Streaming from remote storage will not be available;",
                  "only local snapshots can be read.\n",
                  "See `?td_download` to install a local copy."),
            call. = FALSE)
    return(invisible(db))
  }

  DBI::dbExecute(db, paste0("SET s3_endpoint='", taxadb_endpoint(), "';"))
  DBI::dbExecute(db, "SET s3_url_style='path';")
  DBI::dbExecute(db, "SET s3_use_ssl=true;")

  invisible(db)
}

#' Disconnect from the taxadb database.
#'
#' @param db database connection
#' @details This function manually closes a connection to the `taxadb` database.
#' @return invisible `TRUE`
#' @importFrom DBI dbDisconnect
#' @export
#' @examples \donttest{
#' td_disconnect()
#' }
td_disconnect <- function(db = td_connect()){
  if(inherits(db, "duckdb_connection")) {
    DBI::dbDisconnect(db, shutdown = TRUE)
  }
  for(cached in ls(envir = taxadb_cache)) {
    remove(list = cached, envir = taxadb_cache)
  }
  invisible(TRUE)
}

taxadb_cache <- new.env()

assert_deprecated <- function(...) {
  if(!all(vapply(list(...), is.null, FALSE)))
    warning(paste("deprecated arguments will be removed",
                  "from future releases, see function docs"),
            call. = FALSE)
}
