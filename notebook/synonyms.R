globalVariables(c("taxonomicStatus", "scientificName", "taxonID",
                  "taxonRank", "acceptedNameUsageID"))
## A mapping in which synonym and accepted names are listed in the same row

#' @importFrom dplyr full_join filter select
syn_table <- function(taxon, accepted = "accepted"){

  suppress_msg({
    synonyms <- dplyr::full_join(
      taxon %>%
        dplyr::filter(taxonomicStatus != accepted) %>%
        dplyr::select(synonym = scientificName,
                      synonym_id = taxonID,
                      taxonomicStatus,
                      acceptedNameUsageID),
      taxon %>%
        dplyr::filter(taxonomicStatus == accepted) %>%
        dplyr::select(acceptedNameUsage = scientificName,
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
                     provider = KNOWN_AUTHORITIES,
                     collect = TRUE,
                     db = td_connect()){
  ids(name, provider, collect, db) %>%
    syn_table()

}
