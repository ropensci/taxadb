
#' Return a reference to a given table in the taxadb database
#'
#' @importFrom dplyr tbl
#' @inheritParams filter_by
#' @export
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'    options("taxadb_default_provider"="itis_test")
#'   }
#'
#'   ## default schema is the dwc table
#'   taxa_tbl()
#'
#'   ## common names table
#'   taxa_tbl(schema = "common")
#'
#'
#'
#' }

taxa_tbl <- function(
  provider = getOption("taxadb_default_provider", "itis"),
  schema = c("dwc","common"),
  version = latest_version(),
  db = td_connect()){

  schema <- match.arg(schema)
  tbl_name <- paste0(version, "_", schema, "_", provider)

  if (is.null(db)){
    return(quick_db(tbl_name))
  }
  if (!has_table(tbl_name, db)){
    ## Doing td_create on the fly when a table is missing is kinda dodgy!
    ## We need a write-access connection for this. Also,
    ## td_create() closes the connection when done, so we have to re-open it
    dbw <- with_write_access(db)
    td_create(provider = provider, schema = schema, version = version, db = dbw)
    td_disconnect(dbw)
    db <- with_readonly(db)
  }
  dplyr::tbl(db, tbl_name)
}


has_table <- function(table = NULL, db = td_connect()){
  if (is.null(db)) return(FALSE)
  else if (table %in% DBI::dbListTables(db)) return(TRUE)
  else FALSE
}

#' @importFrom readr read_tsv
quick_db <-
  function(tbl_name){
    version <- gsub("(\\w+)_\\w+_\\w+", "\\1", tbl_name)
    schema <- gsub("\\w+_(\\w+)_\\w+", "\\1", tbl_name)
    provider <- gsub("\\w+_\\w+_(\\w+)", "\\1", tbl_name)
    tmp <- tl_import(provider, schema, version)

    suppressWarnings(
      readr::read_tsv(file(tmp),
      col_types = readr::cols(.default = readr::col_character()))
    )
  }





with_write_access <- function(db){
  if(!inherits(db, "duckdb_connection")) return(db)
  if(db@driver@read_only){
    dir <- dirname(db@driver@dbdir)
    db <- td_connect(dbdir = dir,
                     driver = "duckdb",
                     read_only = FALSE)
  }
  db
}


with_readonly <- function(db){
  if(inherits(db, "duckdb_connection")){
    if(db@driver@read_only){
      dir <- dirname(db@driver@dbdir)
      db <- td_connect(dbdir = dir,
                           driver = "duckdb",
                           read_only = TRUE)
    }
  } else if(inherits("SQLiteConnection")) {
    db <- DBI::dbConnect(db)
  } else {
    # Guess and hope for the best...
    db <- td_connect()
  }
  db
}



