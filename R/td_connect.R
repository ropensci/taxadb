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
#' `duckdb` would otherwise scan with one thread per core and let its buffer
#' pool grow to most of system RAM. For the selective scans `taxadb` makes
#' that is the wrong trade: each scanning thread holds a decompressed Parquet
#' row group, so memory grows with core count while the query gets no faster.
#' On a 128-core machine, looking up one name in the GBIF table peaked at
#' 1324 MB with duckdb's defaults and 322 MB capped at eight threads -- and
#' the capped run was faster (0.7s against 1.0s).
#'
#' So the connection caps threads at `TAXADB_THREADS` (8) or the core count,
#' whichever is lower. Raise it with `options(taxadb_threads=)` for bulk work
#' -- [td_build()] does this itself -- and set
#' `options(taxadb_memory_limit=)` to bound the buffer pool.
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

  ## Cap threads rather than leaving duckdb's one-per-core default: see the
  ## note in ?td_connect. Not a performance tweak -- it is what keeps memory
  ## use predictable on a many-core machine (ropensci/taxadb#95).
  threads <- getOption("taxadb_threads",
                       min(TAXADB_THREADS, parallel::detectCores(logical = FALSE),
                           na.rm = TRUE))
  DBI::dbExecute(db, paste0("SET threads=",
                            max(1L, as.integer(threads)), ";"))

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

## Query-time thread cap. Eight is where the memory/latency trade turned over
## in testing; more threads cost memory without buying speed on a selective
## scan.
TAXADB_THREADS <- 8L

taxadb_cache <- new.env()

assert_deprecated <- function(...) {
  if(!all(vapply(list(...), is.null, FALSE)))
    warning(paste("deprecated arguments will be removed",
                  "from future releases, see function docs"),
            call. = FALSE)
}
