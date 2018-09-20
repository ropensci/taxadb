# FIXME consider a lightweight create_db that imports a single table,
# from a single schema, possibly directly into memory?


 
#' create a local taxonomic database
#'
#' @param path a location on your computer where the database should be installed.
#'  By default, will install to `.taxald` in your home directory.
#' @param authorities a list (character vector) of authorities to be included in the
#'  database. By default, will install `itis`.  See details for a list of recognized
#'  authorities. Use `authorities="all"` to install all available authorities automatically.
#' @param schema format of the database to import.
#' @param lines number of lines that can be safely read in to memory at once. Leave
#' at default or increase for faster importing if you have plenty of spare RAM. 
#' @param overwrite Should we overwrite existing tables? Default is `FALSE`.  Change
#'  to "ask" for interactive interface, or `TRUE` to force overwrite (i.e. updating
#'  a local database upon new release.)
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
#' @importFrom utils download.file
#' @importFrom DBI dbConnect dbDisconnect
#' @importFrom arkdb unark
#' @importFrom MonetDBLite MonetDBLite
#' @examples
#' \dontrun{
#'   # tmp <- tempdir()
#'   # create_db(tmp, authorities = "itis")
#'
#' }
create_db <- function(authorities = "itis", 
                      schema = "hierarchy",
                      overwrite = FALSE,
                      lines = 1e6,
                      path = Sys.getenv("TAXALD_HOME", 
                                        file.path(path.expand("~"),
                                                 ".taxald"))){
  recognized_authorities = c("itis", 
                             "ncbi", 
                             "col", 
                             "tpl", 
                             "gbif", 
                             "fb", 
                             "slb", 
                             "wd")
  if(authorities == "all"){
    authorities <- recognized_authorities
  }
  
  stopifnot(all(authorities %in% recognized_authorities))
  
  ## FIXME include some messaging about the large downloads etc?
  
  ## FIXME generate list of data files to download based on requested
  if(length(schema) > 1){
    warning(paste("multiple schema formats requested; only using",
                  schema[[1]]))
    schema <- schema[[1]]
  }
  
  files <- paste0(authorities, "_", schema, ".tsv.bz2") 
  ## FIXME Confirm download first if corresponding tables already exist
  
  
  
  
  ## FIXME eventually these should be Zenodo URLs
  urls <- paste0("https://github.com/cboettig/taxald/releases/download/v1.0.0/",
         "data", ".2f", files)

  
  tmp <- tempdir()
  dir.create(file.path(tmp, "taxald"), FALSE)
  utils::download.file(urls, file.path(tmp, "taxald", files))
  
  dir.create(path, FALSE)
  con <- DBI::dbConnect(MonetDBLite::MonetDBLite(), path)
  
  ## silence readr progress bar in arkdb
  progress <- getOption("readr.show_progress")
  options(readr.show_progress = FALSE)
  
  arkdb::unark(file.path(tmp, "taxald", files), 
               db_con = con, 
               lines = 1e6, 
               overwrite = overwrite)
  
  # reset readr progress bar.
  options(readr.show_progress = progress)
  
  ## Clean up imported files
  unlink(file.path(tmp, "taxald"))
  
  ## Set id as primary key in each table? automatic in MonetDB
  # lapply(DBI::dbListTables(db$con), function(table)
  # glue::glue("ALTER TABLE {table} ADD PRIMARY KEY ({key});", 
  #            table = table, key = "id"))
  
  DBI::dbDisconnect(con)
  invisible(path)
}

#' @export
create_taxadb <- create_db

#R.utils::bzip2("taxa.sqlite", remove = FALSE)
## Set up database connection from compressed file
#R.utils::bunzip2("taxa.sqlite.bz2", remove = FALSE)

