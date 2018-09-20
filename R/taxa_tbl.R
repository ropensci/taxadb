
#' Return a reference to a given table in the taxald database
#' 
#' @param db a connection to the taxald database. Default will
#' attempt to connect automatically.
#' @param schema the table schema on which we want to run the query
#' @importFrom dplyr tbl
#' @inheritParams classification
#' @export 
taxa_tbl <- function(
  authority = c("itis", "ncbi", "col", "tpl",
                "gbif", "fb", "slb", "wd"), 
  schema = c("hierarchy", "taxonid", "synonyms", "common", "long"),
  db = connect_db()){
  
  authority <- match.arg(authority)
  schema <- match.arg(schema)
  tbl_name <- paste(authority, schema, sep = "_")
  if (is.null(db)) return(fastdb(tbl_name))
  
  
  dplyr::tbl(db, tbl_name)
}

#' @importFrom memoise memoise
#' @importFrom readr read_tsv
fastdb <- memoise::memoise(
  function(tbl_name){
    tmp <- tempfile(fileext = ".tsv.bz2")
    download.file(
      paste0("https://github.com/cboettig/taxald/",
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
  })

#' Connect to the taxald database
#' 
#' @param dbdir Path to the database. Defaults to `TAXALD_HOME` 
#' environmental variable, which defaults to `~/.taxald`.
#' @return Returns a `src_dbi` connection to the database
#' @details Primarily useful when a lower-level interface to the
#' database is required.  Most `taxald`` functions will connect
#' automatically without the user needing to call this function.
#' @importFrom DBI dbConnect
#' @importFrom MonetDBLite MonetDBLite
#' @export
#' @examples \dontrun{
#' 
#' db <- connect_db()
#' 
#' }
connect_db <- function(dbdir = Sys.getenv("TAXALD_HOME", 
                                          file.path(path.expand("~"),
                                                    ".taxald"))){

  DBI::dbConnect(MonetDBLite::MonetDBLite(), dbdir)

}




# tibble doesn't like null arguments
#' @importFrom tibble lst tibble
null_tibble <- function(...){
  call <- Filter(Negate(is.null), tibble::lst(...))
  do.call(tibble::tibble, call)
}
