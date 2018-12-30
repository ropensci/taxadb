KNOWN_AUTHORITIES <- c("itis", "ncbi", "col", "tpl",
                       "gbif", "fb", "slb", "wd", "ott")
#' Return a reference to a given table in the taxadb database
#'
#' @param db a connection to the taxadb database. Default will
#' attempt to connect automatically.
#' @param schema the table schema on which we want to run the query
#' @importFrom dplyr tbl
#' @inheritParams classification
#' @export
taxa_tbl <- function(
  authority = KNOWN_AUTHORITIES,
  schema = c("hierarchy", "taxonid", "synonyms", "common", "long"),
  db = td_connect()){

  authority <- match.arg(authority)
  schema <- match.arg(schema)
  tbl_name <- paste(authority, schema, sep = "_")
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
      paste0("https://github.com/cboettig/taxadb/",
             "releases/download/v1.0.0/data.2f",
             tbl_name, ".tsv.bz2"),
             tmp)
    ## Wow, utils is hella slow!  ~ 60 s
    # utils::read.table(bzfile(tmp), header = TRUE, sep = "\t",
    #                   quote = "", stringsAsFactors = F)
    ## much better ~ 8 sec
    suppressWarnings(suppressMessages(
      readr::read_tsv(tmp,
      col_types = readr::cols(.default = readr::col_character()))
    ))
  } #, cache = memoise::cache_filesystem(Sys.getenv("TAXALD_HOME"))
)




# tibble doesn't like null arguments
#' @importFrom tibble lst tibble
null_tibble <- function(...){
  call <- Filter(Negate(is.null), tibble::lst(...))
  do.call(tibble::tibble, call)
}
