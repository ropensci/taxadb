
#' create a local taxonomic database
#'

#' @param provider a list (character vector) of provider(s) to be included in the
#'  database. By default, will install `itis`.  See details for a list of
#'  recognized provider.
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
#' `[tools::R_user_dir()]`.
#' @param db connection to a database.  By default, taxadb will set up its own
#' fast database connection.
#' @details
#'  Authorities currently recognized by taxadb are:
#'  - `itis`: Integrated Taxonomic Information System, `https://www.itis.gov`
#'  - `ncbi`:  National Center for Biotechnology Information,
#'  <https://www.ncbi.nlm.nih.gov/taxonomy>
#'  - `col`: Catalogue of Life, <http://www.catalogueoflife.org/>
#  - `tpl`: The Plant List, <http://www.theplantlist.org/>
#'  - `gbif`: Global Biodiversity Information Facility, <https://www.gbif.org/>
#  - `fb`: FishBase, `http://fishbase.org`
#  - `slb`: SeaLifeBase, <http://sealifebase.org>
#  - `wd`: Wikidata: https://www.wikidata.org
#'  - `ott`: OpenTree Taxonomy:
#'  <https://github.com/OpenTreeOfLife/reference-taxonomy>
#'  - `iucn`: IUCN Red List, https://iucnredlist.org
#'  - `itis_test`: a small subset of ITIS, cached locally with the package for testing purposes only
#' @return path where database has been installed (invisibly)
#' @export
#' @importFrom DBI dbConnect dbDisconnect dbListTables
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
                      overwrite = NULL,
                      lines = NULL,
                      dbdir =  NULL,
                      db = td_connect()
                      ){

  assert_deprecated(overwrite, lines)

  prov = prov_cache()
  for(p in provider) {
    for(s in schema) {
      meta <- parse_schema(p, version, s, prov)
      paths <- cache_urls(meta$url, meta$id)
      tablename <- paste0("v", version, "_", s, "_", p)
      db <- duckdb_view(paths, tablename, db)
    }
  }
  invisible(db)
}



