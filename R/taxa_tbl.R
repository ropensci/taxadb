#' Return a reference to a given table in the taxadb database
#'
#' @inheritParams filter_by
#' @return a lazy `dplyr` table backed by the requested Parquet snapshot.
#' @details The returned table is a `duckdb` view over Parquet, so it can be
#' manipulated with any `dplyr` verb and is only ever read to the extent your
#' query requires.  Unless a local copy has been installed with
#' [td_download()], the data is streamed from remote storage on demand.
#' @importFrom dplyr tbl
#' @export
#' @examples
#' \donttest{
#'   \dontshow{options("taxadb_default_provider" = "itis_test")}
#'
#'   ## default schema is the Darwin Core table
#'   taxa_tbl()
#'
#'   ## common names table
#'   taxa_tbl(schema = "common")
#'
#'   \dontshow{options("taxadb_default_provider" = NULL)}
#' }
taxa_tbl <- function(
  provider = getOption("taxadb_default_provider", "itis"),
  schema = c("dwc", "common"),
  version = latest_version(),
  db = td_connect()){

  schema <- match.arg(schema)

  if(is.null(db)) db <- td_connect()

  uri <- taxadb_uri(provider, schema, version)
  tbl_name <- view_name(provider, schema, version, uri)

  if(!has_table(tbl_name, db)) duckdb_view(uri, tbl_name, db)

  dplyr::tbl(db, tbl_name)
}

## A local snapshot and a remote one must not share a view name, or switching
## between them within a session would silently keep the stale view.
view_name <- function(provider, schema, version, uri){
  if(is_test_provider(provider)) return(paste0(schema, "_", provider))
  suffix <- if(grepl("^s3://", uri[[1]])) "" else "_local"
  paste0(schema, "_", provider, "_", version, suffix)
}

has_table <- function(table = NULL, db = td_connect()){
  if (is.null(db)) return(FALSE)
  table %in% DBI::dbListTables(db)
}

## Register a Parquet glob (or file list) as a duckdb view.
#' @importFrom DBI dbExecute dbListTables
duckdb_view <- function(uri, tbl_name, db = td_connect()){

  if(all(tbl_name %in% DBI::dbListTables(db))) return(invisible(db))

  files <- paste0("[", paste0("'", uri, "'", collapse = ", "), "]")
  query <- paste0("CREATE OR REPLACE VIEW \"", tbl_name, "\" AS ",
                  "SELECT * FROM read_parquet(", files, ");")

  tryCatch(DBI::dbExecute(db, query),
           error = function(e)
             stop(paste0("Could not read ", paste(uri, collapse = ", "),
                         "\n  ", conditionMessage(e)), call. = FALSE))

  invisible(db)
}
