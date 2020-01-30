
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
#'   }
#'
#'   #Clean a list of messy common names
#'   names <- clean_names(c("Steller's jay", "coopers Hawk"),
#'                 binomial_only = FALSE, remove_sp = FALSE, remove_punc = TRUE)
#'
#'   #Get cleaned common names from a provider and
#'   # search for cleaned names in that table
#'   taxa_tbl("itis", "common") %>%
#'   mutate_db(clean_names, "vernacularName", "vernacularNameClean",
#'             binomial_only = FALSE, remove_sp = FALSE, remove_punc = TRUE) %>%
#'   filter(vernacularNameClean %in% names)
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
    mem_quick_db <-
      memoise::memoise(quick_db,
                       cache = memoise::cache_filesystem(taxadb_dir()))
    return(mem_quick_db(tbl_name))
  }
  if (!has_table(tbl_name, db)){
    td_create(provider = provider, schema = schema, version = version, db = db)
  }
  dplyr::tbl(db, tbl_name)
}
## could memoise to disk, but for some reason quickdb is not memoising...


has_table <- function(table = NULL, db = td_connect()){
  if (is.null(db)) return(FALSE)
  else if (table %in% DBI::dbListTables(db)) return(TRUE)
  else FALSE
}

#' @importFrom memoise memoise cache_filesystem
#' @importFrom readr read_tsv
quick_db <-
  function(tbl_name){
    version <- gsub("(\\w+)_\\w+_\\w+", "\\1", tbl_name)
    filename <- gsub("\\w+_(\\w+_\\w+)", "\\1", tbl_name)
    #tmp <- tempfile(fileext = ".tsv.bz2")
    tmp <- file.path(taxadb_dir(), paste0(tbl_name, ".tsv.bz2"))
    if(!file.exists(tmp)){
      download.file(paste0(providers_download_url(filename, version), ".tsv.bz2"),
             tmp)
    }
    suppressWarnings(
      readr::read_tsv(tmp,
      col_types = readr::cols(.default = readr::col_character()))
    )
  }
