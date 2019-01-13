

#' Return the full classification hierarchy for requested species or ids
#'
#' @param species a character vector of species names, typically
#'  specified as (`Genus species` or `Genus species epithet`)
#' @param id alternately users can provide a vector of species ids.
#'  IDs must be prefixed matching the requested authority.  See `id`
#'  column returned by most `taxadb` functions for examples.
#' @inheritParams ids
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
#' @export
#' @importFrom dplyr semi_join tibble collect
#'
classification <- function(species = NULL,
                           id = NULL,
                           authority = KNOWN_AUTHORITIES,
                           collect = TRUE,
                           db = td_connect()){

  out <- dplyr::right_join(taxa_tbl(authority = authority,
                                   schema = "dwc",
                                   db = db),
                          null_tibble(id, scientificName = species),
                          copy = TRUE,
                          by = "scientificName")

  if(collect && inherits(out, "tbl_lazy")){
    ## Return an in-memory object
    out <- dplyr::collect(out)
  }

  out

}
