
#' create a local taxonomic database
#'

#' @param provider a list (character vector) of provider to be included in the
#'  database. By default, will install `itis`.  See details for a list of
#'  recognized provider. Use `provider="all"` to install all
#'  available provider automatically.
#' @inheritParams filter_by
#' @param lines number of lines that can be safely read in to memory at once.
#' Leave at default or increase for faster importing if you have
#' plenty of spare RAM.
#' @param overwrite Should we overwrite existing tables? Default is `TRUE`.
#' Change to "ask" for interactive interface, or `TRUE` to force overwrite
#' (i.e. updating a local database upon new release.)
#' @param dbdir a location on your computer where the database
#' should be installed. Defaults to user data directory given by
#' `[rappdirs::user_data_dir]`.
#' @param db connection to a database.  By default, taxadb will set up its own
#' fast database connection.
#' @details
#'  Authorities currently recognized by taxadb are:
#'  - `itis`: Integrated Taxonomic Information System, `https://www.itis.gov`
#'  - `ncbi`:  National Center for Biotechnology Information,
#'  <https://www.ncbi.nlm.nih.gov/taxonomy>
#'  - `col`: Catalogue of Life, <http://www.catalogueoflife.org/>
#'  - `tpl`: The Plant List, <http://www.theplantlist.org/>
#'  - `gbif`: Global Biodiversity Information Facility, <https://www.gbif.org/>
#'  - `fb`: FishBase, `http://fishbase.org`
#'  - `slb`: SeaLifeBase, <http://sealifebase.org>
#'  - `wd`: Wikidata: https://www.wikidata.org
#'  - `ott`: OpenTree Taxonomy:
#'  <https://github.com/OpenTreeOfLife/reference-taxonomy>
#'  - `iucn`: IUCN Red List, https://iucnredlist.org
#'  - `itis_test`: a small subset of ITIS, cached locally with the package for testing purposes only
#' @return path where database has been installed (invisibly)
#' @export
#' @importFrom utils download.file
#' @importFrom DBI dbConnect dbDisconnect dbListTables
#' @importFrom arkdb unark streamable_readr_tsv
#' @importFrom readr cols
#' @importFrom curl curl_download curl_fetch_memory
#' @importFrom jsonlite fromJSON
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=file.path(tempdir(), "taxadb"))
#'    options("taxadb_default_provider"="itis_test")
#'
#'   }
#'   ## Install the ITIS database
#'   td_create()
#'
#'   ## force re-install:
#'   td_create( overwrite = TRUE)
#'
#' }
td_create <- function(provider = getOption("taxadb_default_provider", "itis"),
                      schema = c("dwc", "common"),
                      version = latest_version(),
                      overwrite = TRUE,
                      lines = 1e5,
                      dbdir =  taxadb_dir(),
                      db = td_connect(dbdir)
                      ){



  dest <- tl_import(provider, schema, version)
  tablenames <- names(dest)
  ## silence readr progress bar in arkdb
  progress <- getOption("readr.show_progress")
  options(readr.show_progress = FALSE)

  ## silence MonetDBLite complaints about reserved SQL characters
  suppress_msg({
  arkdb::unark(dest,
               tablenames = tablenames,
               db_con = db,
               lines = lines,
               streamable_table = arkdb::streamable_readr_tsv(),
               overwrite = overwrite,
               col_types = readr::cols(.default = "c"))
  })

  # reset readr progress bar.
  options(readr.show_progress = progress)
  invisible(dbdir)
}



