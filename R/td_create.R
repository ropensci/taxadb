
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
#' @param overwrite Should we overwrite existing tables? Default is `FALSE`.
#' Change to "ask" for interactive interface, or `TRUE` to force overwrite
#' (i.e. updating a local database upon new release.)
#' @param dbdir a location on your computer where the database
#' should be installed. Defaults to user data directory given by
#' [rappdirs::user_data_dir]().
#' @param db connection to a database.  By default, taxadb will set up its own
#' fast database connection.
#' @details
#'  Authorities recognized by taxadb are:
#'  - `itis`: Integrated Taxonomic Information System, <https://www.itis.gov/>
#'  - `ncbi`:  National Center for Biotechnology Information,
#'  <https://www.ncbi.nlm.nih.gov/taxonomy>
#'  - `col`: Catalogue of Life, <http://www.catalogueoflife.org/>
#'  - `tpl`: The Plant List, <http://www.theplantlist.org/>
#'  - `gbif`: Global Biodiversity Information Facility, <https://www.gbif.org/>
#'  - `fb` FishBase, <http://fishbase.org>
#'  - `slb`, SeaLifeBase, <http://sealifebase.org>
#'  - `wd`, Wikidata: <https://www.wikidata.org/>
#'  - `ott` OpenTree Taxonomy:
#'  <https://github.com/OpenTreeOfLife/reference-taxonomy>
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
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#'   ## Install the ITIS database
#'   td_create("itis")
#'
#'   ## force re-install:
#'   td_create("itis", overwrite = TRUE)
#'
#' }
td_create <- function(provider = "itis",
                      schema = c("dwc", "common"),
                      version = latest_version(),
                      overwrite = FALSE,
                      lines = 1e5,
                      dbdir =  taxadb_dir(),
                      db = td_connect(dbdir)
                      ){

  if(!dir.exists(dbdir))
    dir.create(dbdir, FALSE, TRUE)

  recognized_provider <- c("itis", "ncbi", "col", "tpl",
                           "gbif", "fb", "slb", "wd", "ott",
                           "iucn")
  if (any(provider == "all")) {
    provider <- recognized_provider
  }
  stopifnot(all(provider %in% recognized_provider))

  ## supports vectorized schema and provider lists.
  files <- unlist(lapply(schema, function(s)
    paste0(s, "_", provider, ".tsv.bz2")))
  #remove common name tables for providers without common names
  files <- files[!files %in% paste0(NO_COMMON, ".tsv.bz2")]
  dest <- file.path(dbdir, paste0(version, "_", files))

  new_dest <- dest
  new_files <- files

  if (!overwrite) {
    drop <- vapply(dest, file.exists, logical(1))
    new_dest <- dest[!drop]
    new_files <- files[!drop]
  }

  if (length(new_files) >= 1L) {
    ## FIXME eventually these should be Zenodo URLs
    urls <- providers_download_url(new_files, version)
    lapply(seq_along(urls), function(i)
      curl::curl_download(urls[i], new_dest[i]))
  }

  ## silence readr progress bar in arkdb
  progress <- getOption("readr.show_progress")
  options(readr.show_progress = FALSE)

  ## silence MonetDBLite complaints about reserved SQL characters
  suppress_msg({
  arkdb::unark(dest,
               db_con = db,
               lines = lines,
               streamable_table = arkdb::streamable_readr_tsv(),
               overwrite = overwrite,
               col_types = readr::cols(.default = "c"))
  })

  # reset readr progress bar.
  options(readr.show_progress = progress)

  ## Set id as primary key in each table? automatic in modern DBs
  ## like MonetDB and duckdb
  # lapply(DBI::dbListTables(db$con), function(table)
  # glue::glue("ALTER TABLE {table} ADD PRIMARY KEY ({key});",
  #            table = table, key = "id"))

  invisible(dbdir)
}

providers_download_url <- function(files, version = latest_version()){
  paste0("https://github.com/boettiger-lab/taxadb-cache/",
               "releases/download/", version, "/", files)
}



#' List available releases
#'
#' taxadb uses pre-computed cache files that are released on an annual
#' version schedule.
#'
#' @export
#' @examples
#' available_versions()
available_versions <- function(){

  ## check for cached version first
  avail_releases <- mget("avail_releases",
                         envir = taxadb_cache,
                         ifnotfound = NA)[[1]]
  if(!all(is.na(avail_releases)))
    return(avail_releases)

  ## FIXME consider using direct access of a metadata record file instead
  ## of relying on GitHub release tags to provide information about
  ## available versions

  ## Okay, check GH for a release
  req <- curl::curl_fetch_memory(paste0(
    "https://api.github.com/repos/",
    "boettiger-lab/taxadb-cache/releases"))
  json <- jsonlite::fromJSON(rawToChar(req$content))
  avail_releases <- json[["tag_name"]]

  ## Cache this so we don't hit GH every single time!
  assign("avail_releases", avail_releases, envir = taxadb_cache)

  avail_releases
}

latest_version <- function() {
  available_versions()[[1]]
}




