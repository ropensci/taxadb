
## A mapping in which synonym and accepted names are listed in the same row
syn_table <- function(taxon, accepted = "accepted"){

  suppress_msg({
  synonyms <- full_join(
    taxon %>%
      filter(taxonomicStatus != accepted) %>%
      select(synonym = scientificName,
             synonym_id = taxonID,
             taxonomicStatus,
             acceptedNameUsageID),
    taxon %>%
      filter(taxonomicStatus == accepted) %>%
      select(acceptedNameUsage = scientificName,
             acceptedNameUsageID,
             taxonRank,
             taxonomicStatus))
  })

}


#' synonyms
#'
#' Resolve provided list of names against all known synonyms
#' @inheritParams ids
#' @export
synonyms <- function(name = NULL,
                     authority = KNOWN_AUTHORITIES,
                     collect = TRUE,
                     db = td_connect()){
  ids(name, authority, collect, db) %>%
    syn_table()

}
