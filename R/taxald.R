
## Look up id given a species name
## Look up a heirarchy given a species name or species id
## Return all species names / species ids belonging to a higher level rank
## 
## Look up a scientific name at any rank level.
## 
## Look up ids for higher ranks (when available)
## Look up synonyms
## Crosswalk / compare taxonomy across authorities in common format


## Consider memoizing

#' @importFrom dplyr right_join tibble collect
#' 
hierarchy <- function(species = NULL, 
                      id = NULL, 
                      authority = c("itis", "ncbi", "col", "tpl",
                                    "gbif", "fb", "slb", "wd")){
  
  if(is.null(id) & !is.null(species)){
    df <- dplyr::tibble(species)
  } else if(!is.null(id) & is.null(species)){
    df <- dplyr::tibble(id)
  } else  if(!is.null(id) & !is.null(species)){
    df <- dplyr::tibble(id, species)
  } else {
    stop("id or species list must be provided")
  }
  
  
  out <- dplyr::right_join(taxa_tbl(authority = authority,
                                    schema = "hierarchy"), 
                           df, copy = TRUE)
  
  dplyr::collect(out)
  
}


ids <- function(name = NULL,
                authority = c("itis", "ncbi", "col", "tpl",
                              "gbif", "fb", "slb", "wd"),
                schema = "taxonid"){

  
  out <- dplyr::right_join(
    taxa_tbl(authority = authority, 
             schema = "taxonid"), 
             dplyr::tibble(name),
             copy = TRUE) 
    dplyr::collect(out)
}

descendents <- function(name = NULL, 
                        rank = NULL, 
                        id = NULL,
                        authority = c("itis", "ncbi", "col", "tpl",
                                      "gbif", "fb", "slb", "wd")){
  authority <- match.arg(authority)
  
  ## if we have rank and name, filter on the hierarchy table
  
}


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
#' @importFrom dbplyr src_dbi
#' @export
#' @examples \dontrun{
#' 
#' db <- connect_db()
#' 
#' }
connect_db <- function(dbdir = Sys.getenv("TAXALD_HOME", 
                                          fs::path(fs::path_home(),
                                                   ".taxald"))){
  con <- DBI::dbConnect(MonetDBLite::MonetDBLite(), dbdir)
  db <- dbplyr::src_dbi(con)
}



#' @importFrom dplyr tbl
taxa_tbl <- function(
  db = connect_db(),
  authority = c("itis", "ncbi", "col", "tpl",
                "gbif", "fb", "slb", "wd"), 
  schema = c("hierarchy", "taxonid", "synonyms", "common", "long")){
  
  authority <- match.arg(authority)
  schema <- match.arg(schema)
  tbl_name <- paste(authority, schema, sep = "_")
  
  dplyr::tbl(db, tbl_name)
}
