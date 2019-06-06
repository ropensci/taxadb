
#' Return a reference to a given table in the taxadb database
#'
#' @param db a connection to the taxadb database. Default will
#' attempt to connect automatically.
#' @param schema the table schema on which we want to run the query
#' @importFrom dplyr tbl
#' @inheritParams filter_by
#' @export
taxa_tbl <- function(
  provider = c("itis", "ncbi", "col", "tpl",
               "gbif", "fb", "slb", "wd", "ott",
               "iucn"),
  schema = c("dwc","common"),
  db = td_connect()){

  provider <- match.arg(provider)
  schema <- match.arg(schema)
  tbl_name <- paste0(schema, "_", provider)

  if (is.null(db)) return(quick_db(tbl_name))
  if (!has_table(tbl_name, db)) return(quick_db(tbl_name))

  dplyr::tbl(db, tbl_name)
}

has_table <- function(table = NULL, db = td_connect()){
  if(is.null(db)) return(FALSE)
  else if (table %in% DBI::dbListTables(db)) return(TRUE)
  else FALSE
}

#' @importFrom memoise memoise
#' @importFrom readr read_tsv
quick_db <- memoise::memoise(
  function(tbl_name){
    # FIXME -- use the same rappdirs location, not tmpfile!
    tmp <- tempfile(fileext = ".tsv.bz2")
    download.file(
      paste0(providers_download_url(tbl_name), ".tsv.bz2"),
             tmp)
    suppressWarnings(suppressMessages(
      readr::read_tsv(tmp,
      col_types = readr::cols(.default = readr::col_character()))
    ))
  } #, cache = memoise::cache_filesystem(Sys.getenv("TAXADB_HOME"))
)

## Memoized on install, so cache location must already exist.


# tibble doesn't like null arguments
#' @importFrom tibble lst tibble
null_tibble <- function(...){
  call <- Filter(Negate(is.null), tibble::lst(...))
  do.call(tibble::tibble, call)
}
