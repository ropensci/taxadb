 
#' create a local taxonomic database
#'
#' @param path a location on your computer where the database should be installed.
#'  By default, will install to `.taxald` in your home directory.
#' @param authorities a list (character vector) of authorities to be included in the
#'  database. By default, will install all authorities.  Choose a subset for a faster
#'  install.  
#' @return path where database has been installed (invisibly)
#' @export
#'
#' @examples
#' \dontrun{
#'   # tmp <- tempdir()
#'   # create_taxadb(tmp, authorities = "itis")
#'
#' }
create_taxadb <- function(path = fs::path(fs::path_home(), ".taxald"),
                          authorities = c("itis", "ncbi", "col", "tpl",
                                          "gbif", "fb", "slb", "wd")){
  ## FIXME offer more fine-grained support over which authorities to install
  ## FIXME include some messaging about the large downloads etc?
  
  
  ## FIXME generate list of data files to download based on requested
  ## authorities
  
  ## FIXME eventually will pull from Zenodo, not piggyback
  tmp <- tempdir()
  piggyback::pb_download(dest = tmp, repo="cboettig/taxald")
  
  
  files <- fs::dir_ls("data/", glob="*.tsv.bz2")
  
  
  dbdir <- fs::dir_create(path)
  con <- DBI::dbConnect(MonetDBLite::MonetDBLite(), dbdir)
  db <- dbplyr::src_dbi(con)
  arkdb::unark(files, db, lines = 1e6)
  
  ## Clean up imported files
  fs::dir_delete(fs::path(tmp, "data"))
  
  ## Set id as primary key in each table?
  # tbls <- DBI::dbListTables(db$con)
  # lapply(tbls, function(table)
  # glue::glue("ALTER TABLE {table} ADD PRIMARY KEY ({key});", 
  #            table = table, key = "id"))
  
  DBI::dbDisconnect(db$con)
  
  invisible(dbdir)
}
## Consider shipping the original database pre-compressed?

#R.utils::bzip2("taxa.sqlite", remove = FALSE)
## Set up database connection from compressed file
#R.utils::bunzip2("taxa.sqlite.bz2", remove = FALSE)

