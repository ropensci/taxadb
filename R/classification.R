

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
#' @param db a connection to the taxald database. See details.
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
#' If setting `collect = FALSE`, consider calling `db = td_connect()`
#' in a separate call and passing the resulting connection object, `db`
#' explicitly to all subsequent `taxald` functions.  This will allow them
#' to re-use the existing connection, which can also be used in conjunction
#' with the returned results for further on-disk queries. In general, this will
#' only be desirable when tables are extremely large or availability memory is 
#' extremely limited. Under most use cases, the defaults for `collect` and 
#' `db` should be appropriate.  
#' @export
#' @importFrom dplyr semi_join tibble collect
#' 
classification <- function(species = NULL, 
                           id = NULL, 
                           authority = c("itis", "ncbi", "col", "tpl",
                                         "gbif", "fb", "slb", "wd"),
                           collect = TRUE,
                           db = td_connect()){
  
  out <- dplyr::semi_join(taxa_tbl(authority = authority,
                                   schema = "hierarchy", 
                                   db = db), 
                          null_tibble(id, species), 
                          copy = TRUE)
  
  if(collect && inherits(out, "tbl_lazy")){ 
    ## Return an in-memory object
    out <- dplyr::collect(out)
  }
  
  out
  
}
