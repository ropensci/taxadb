# FIXME consider a lightweight create_db that imports a single table,
# from a single schema, possibly directly into memory?


 
#' create a local taxonomic database
#'
#' @param path a location on your computer where the database should be installed.
#'  By default, will install to `.taxald` in your home directory.
#' @param authorities a list (character vector) of authorities to be included in the
#'  database. By default, will install `itis`.  See details for a list of recognized
#'  authorities.
#' @param schema format of the database to import.
#' @param lines number of lines that can be safely read in to memory at once. Leave
#' at default or increase for faster importing if you have plenty of spare RAM. 
#' @details 
#'  Authorities recognized by taxald are:
#'  - `itis` 
#'  - `ncbi`
#'  - `col`
#'  - `tpl`
#'  - `gbif`
#'  - `fb` FishBase, <http://fishbase.org>
#'  - `slb`, SeaLifeBase, <http://sealifebase.org>
#'  - `wd`, wikidata
#' @return path where database has been installed (invisibly)
#' @export
#' @aliases create_db create_taxadb
#' @examples
#' \dontrun{
#'   # tmp <- tempdir()
#'   # create_db(tmp, authorities = "itis")
#'
#' }
create_db <- function(authorities = "itis", 
                      schema = "hierarchy",
                      lines = 1e6,
                      path = Sys.getenv("TAXALD_HOME", 
                                        fs::path(fs::path_home(),
                                                 ".taxald"))){
  ## FIXME Overwrite / delete any existing database, after giving a warning if interactive
  
  ## FIXME offer more fine-grained support over which authorities to install
  recognized_authorities = c("itis", "ncbi", "col", "tpl", "gbif", "fb", "slb", "wd")
  stopifnot(all(authorities %in% recognized_authorities))
  ## FIXME include some messaging about the large downloads etc?
  
  
  ## FIXME generate list of data files to download based on requested
  files <- paste0(authorities, "_", schema, ".tsv.bz2") 
  
  
  ## FIXME eventually will pull from Zenodo, not piggyback
  tmp <- tempdir()
  piggyback::pb_download(paste0("data/", files), 
                         dest = tmp, 
                         repo = "cboettig/taxald")
  
  #globs <- paste(authorities, "_", schema, ".tsv.bz2")
  #files <- unname(unlist(lapply(globs, function(glob)
  #                  fs::dir_ls(fs::path(tmp, "data/"), glob = glob))))
  
  
  dbdir <- fs::dir_create(path)
  con <- DBI::dbConnect(MonetDBLite::MonetDBLite(), dbdir)
  db <- dbplyr::src_dbi(con)
  arkdb::unark(fs::path(tmp, "data", files), db, lines = 1e6)
  
  ## Clean up imported files
  fs::dir_delete(fs::path(tmp, "data"))
  
  ## Set id as primary key in each table? automatic in MonetDB
  # lapply(DBI::dbListTables(db$con), function(table)
  # glue::glue("ALTER TABLE {table} ADD PRIMARY KEY ({key});", 
  #            table = table, key = "id"))
  
  DBI::dbDisconnect(db$con)
  
  invisible(dbdir)
}

#' @export
create_taxadb <- create_db

#R.utils::bzip2("taxa.sqlite", remove = FALSE)
## Set up database connection from compressed file
#R.utils::bunzip2("taxa.sqlite.bz2", remove = FALSE)

