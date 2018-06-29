
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


#' Return the full classification hierarchy for requested species or ids
#' 
#' @param species a character vector of species names, typically 
#'  specified as (`Genus species` or `Genus species epithet`)
#' @param id alternately users can provide a vector of species ids.
#'  IDs must be prefixed matching the requested authority.  See `id`
#'  column returned by most `taxald` functions for examples.
#' @param authority from which authority should the hierachy be returned?
#'  Default is 'itis'.  
#' @param collect logical, default `TRUE`. Should we return an in-memory
#' data.frame (default, usually the most convenient), or a reference to
#' lazy-eval table on disk (useful for very large tables on which we may
#' first perform subsequent filtering operations.) 
#' @return a data.frame with one row for each requested species, 
#'  giving the species id, and column for each of the unique-rank
#'  levels of the species.  Note that the different authorities recognize
#'  a range of different ranks.
#'  
#' @details Some authorities recognize multiple values of the same rank
#' level, (i.e. a species may be assigned to two different "suborders").  
#' In this case, only one has been included in the "hierarchy" schema.
#' Likewise, some authorities (i.e. NCBI) use some unnamed rank levels 
#' (i.e. a scientific name is associated with a clade, but the clade is 
#' not associated with any traditionally recognized rank). In these cases, 
#' see the "long" schema for more complete classification.  
#' @export
#' @importFrom dplyr right_join tibble collect
#' 
hierarchy <- function(species = NULL, 
                      id = NULL, 
                      authority = c("itis", "ncbi", "col", "tpl",
                                    "gbif", "fb", "slb", "wd"),
                      collect = TRUE){
  
  ## Simply put input into a table so we can do joins
  if(is.null(id) & !is.null(species)){
    df <- dplyr::tibble(species)
  } else if(!is.null(id) & is.null(species)){
    df <- dplyr::tibble(id)
  } else  if(!is.null(id) & !is.null(species)){
    df <- dplyr::tibble(id, species)
  } else {
    stop("id or species list must be provided")
  }
  
  ## A `join` is theoretically the fastest way to query for a large number
  ## of matches (instead of `filter( %in% )` / or  `WHERE %IN%`)
  out <- dplyr::right_join(taxa_tbl(authority = authority,
                                    schema = "hierarchy"), 
                           df, copy = TRUE)
  
  ## Return an in-memory object
  if(collect){
    dplyr::collect(out)
  } else{ 
    out
  }
  
}

#' Return taxonomic identifiers from a given namespace
#' 
#' @param name a character vector of species names. 
#' (Most authorities can also return ids for higher-level
#'  taxanomic names).
#' @inheritParams hierarchy
#' @return a data.frame with columns of `id`, scientific 
#' `name`, and `rank` and a row for each species name queried.
#' 
#' @export
ids <- function(name = NULL,
                authority = c("itis", "ncbi", "col", "tpl",
                              "gbif", "fb", "slb", "wd"),
                schema = "taxonid",
                collect = TRUE){

  
  out <- dplyr::right_join(
    taxa_tbl(authority = authority, 
             schema = "taxonid"), 
             dplyr::tibble(name),
             copy = TRUE) 
  
  ## Return an in-memory object
  if(collect){
    dplyr::collect(out)
  } else{ 
    out
  }
}


#' Get all members (descendents) of a given rank level
#' @inheritParams hierarchy
#' @param rank taxonomic rank name.
#' @param name taxonomic name (e.g. "Aves")
#' @return a data.frame with id and name of all matching species
#' @export
#' 
#' @importFrom magrittr %>%
#' @importFrom dplyr right_join select filter distinct
descendents <- function(name = NULL, 
                        rank = NULL, 
                        id = NULL,
                        authority = c("itis", "ncbi", "col", "tpl",
                                      "gbif", "fb", "slb", "wd"),
                        collect = TRUE){
  authority <- match.arg(authority)
  df <- tibble(rank = rank, name = name)
  out <- dplyr::right_join(
      taxa_tbl(authority = authority, schema = "long"), 
      df, 
      copy = TRUE) %>%
    dplyr::select(id, name, rank) %>% 
    dplyr::filter(rank == "species") %>%
    dplyr::select(id, name) %>% 
    dplyr::distinct()
  
  ## Return an in-memory object
  if(collect){
    dplyr::collect(out)
  } else{ 
    out
  }
}


utils::globalVariables(c("id", "name", "rank"))

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


#' Return a reference to a given table in the taxald database
#' 
#' @param db a connection to the taxald database. Default will
#' attempt to connect automatically.
#' @importFrom dplyr tbl
#' @inheritParams hierarchy
#' @export 
taxa_tbl <- function(
  authority = c("itis", "ncbi", "col", "tpl",
                "gbif", "fb", "slb", "wd"), 
  schema = c("hierarchy", "taxonid", "synonyms", "common", "long"),
  db = connect_db()){
  
  authority <- match.arg(authority)
  schema <- match.arg(schema)
  tbl_name <- paste(authority, schema, sep = "_")
  
  dplyr::tbl(db, tbl_name)
}
