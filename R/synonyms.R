
#' synonyms
#'
#' Resolve provided list of names against all known synonyms
#' @inheritParams ids
#' @importFrom dplyr left_join
#' @export
synonyms <- function(name = NULL,
                     provider = known_providers,
                     collect = TRUE,
                     db = td_connect()){


  the_id_table <- ids(name, provider = provider, db = db)

  ## Get both accepted names & synonyms for anything with an acceptedNameUsageID
  taxadb:::suppress_msg({
    syn <-
      taxa_tbl(provider = provider, db = db) %>%
      dplyr::right_join(the_id_table %>%
                   select(acceptedNameUsageID),
                 by = "acceptedNameUsageID",
                 copy = TRUE) %>%
      dplyr::select(scientificName, acceptedNameUsageID,
             taxonomicStatus, taxonRank) %>%
      syn_table()

  })
  ## Join that back onto the id table
  out <- the_id_table %>%
    dplyr::select(input, sort, acceptedNameUsageID) %>%
    dplyr::left_join(syn, by = "acceptedNameUsageID", copy = TRUE) %>%
    # reorder
    dplyr::select("input", "acceptedNameUsage", "synonym",
           "acceptedNameUsageID","taxonRank", "sort")

  if (collect && inherits(out, "tbl_lazy")) {
    return( dplyr::collect(out) )
  }

  out

}


globalVariables(c("taxonomicStatus", "scientificName", "taxonID",
                  "taxonRank", "acceptedNameUsageID", "synonym", "input"))
## A mapping in which synonym and accepted names are listed in the same row

#' @importFrom dplyr full_join filter select
syn_table <- function(taxon, accepted = "accepted"){

  taxadb:::suppress_msg({

    dplyr::full_join(
      taxon %>%
        dplyr::filter(taxonomicStatus != "accepted") %>%
        dplyr::select(synonym = scientificName,
                      acceptedNameUsageID),
      taxon %>%
        dplyr::filter(taxonomicStatus == "accepted") %>%
        dplyr::select(acceptedNameUsage = scientificName,
                      acceptedNameUsageID,
                      taxonRank),
      by = "acceptedNameUsageID")
  })

}

