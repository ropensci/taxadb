
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
#' @param taxald_db a connection to the taxald database. See details.
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
#' 
#' If setting `collect = FALSE`, consider calling `taxald_db = connect_db()`
#' in a separate call and passing the resulting connection object, `taxald_db`
#' explicitly to all subsequent `taxald` functions.  This will allow them
#' to re-use the existing connection, which can also be used in conjunction
#' with the returned results for further on-disk queries. In general, this will
#' only be desirable when tables are extremely large or availablity memory is 
#' extremely limited. Under most use cases, the defaults for `collect` and 
#' `taxald_db` should be appropriate.  
#' @export
#' @importFrom dplyr right_join tibble collect
#' 
classification <- function(species = NULL, 
                           id = NULL, 
                           authority = c("itis", "ncbi", "col", "tpl",
                                         "gbif", "fb", "slb", "wd"),
                           collect = TRUE,
                           taxald_db = connect_db()){
  
  out <- dplyr::right_join(taxa_tbl(authority = authority,
                                    schema = "hierarchy", 
                                    db = taxald_db), 
                           null_tibble(id, species), 
                           copy = TRUE)
  
  if(collect){ ## Return an in-memory object
    out <- dplyr::collect(out)
    DBI::dbDisconnect(taxald_db$con)
  }
  
  out
  
}


## FIXME Does not support lookup of non-species-level ids. Using taxonid schema would fix this.
#' Return taxonomic identifiers from a given namespace
#' 
#' @param name a character vector of species names. 
#' (Most authorities can also return ids for higher-level
#'  taxonomic names).
#' @inheritParams classification
#' @return a data.frame with columns of `id`, scientific 
#' `name`, and `rank` and a row for each species name queried.
#' 
#' @export
ids <- function(name = NULL,
                authority = c("itis", "ncbi", "col", "tpl",
                              "gbif", "fb", "slb", "wd"),
                collect = TRUE,
                taxald_db = connect_db()){
  
  out <- 
    dplyr::right_join(
      taxa_tbl(authority = authority, 
               schema = "hierarchy", 
               db = taxald_db), 
      dplyr::tibble(species = name),
      copy = TRUE) %>% 
    dplyr::select("id", "species")
  
  
  if(collect){ ## Return an in-memory object
    out <- dplyr::collect(out)
    DBI::dbDisconnect(taxald_db$con)
  }
  
  out
}


#' Get all members (descendants) of a given rank level
#' @inheritParams classification
#' @param rank taxonomic rank name.
#' @param name taxonomic name (e.g. "Aves")
#' @param schema table schema to use (WIP)
#' @return a data.frame with id and name of all matching species
#' @export
#' @importFrom stats setNames
# @importFrom rlang !! := UQ quo enquo
#' @importFrom magrittr %>%
#' @importFrom dplyr right_join select filter distinct
descendants <- function(name = NULL, 
                        rank = NULL, 
                        id = NULL,
                        authority = c("itis", "ncbi", "col", "tpl",
                                      "gbif", "fb", "slb", "wd"),
                        collect = TRUE,
                        taxald_db = connect_db(),
                        schema = "hierarchy"){

  ## technically could guess rank from name most but not all time
  ## could still do this as join rather than a filter with appropriate table construction
  if(schema == "hierarchy"){
    df <- data.frame(setNames(list(name),  rank))
    df$id <- id
    out <- dplyr::right_join(
      taxa_tbl(authority = authority,
               schema = "hierarchy", 
               db = taxald_db),
      df,
      copy = TRUE, by = rank)
    
    #quo_rank <- quo(rank)
    #out <- 
    #  taxa_tbl(authority = authority,
    #         schema = "hierarchy", 
    #         db = taxald_db) %>%
    #  dplyr::filter(!!quo_rank == name)
  }
  
  
  ## schema=long probably isn't the most efficient table to use
  ## we could use the heirarchy table, though it will need NSE escapes
  
  else if(schema == "long"){
    df <- tibble(path_rank = rank, path_name = name)
    out <- dplyr::right_join(
        taxa_tbl(authority = authority, 
                 schema = "long", 
                 db = taxald_db), 
        df, 
        copy = TRUE) %>%
      dplyr::select("id", "name", "rank") %>% 
      dplyr::filter(rank == "species") %>%
      dplyr::select("id", "name") %>% 
      dplyr::distinct()
  }
  
  
  if(collect){ ## Return an in-memory object
    out <- dplyr::collect(out)
    DBI::dbDisconnect(taxald_db$con)
  }
  
  out
  
}

