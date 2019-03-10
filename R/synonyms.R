## FIXME consider renaming to get_synonyms?


#' synonyms
#'
#' Resolve provided list of names against all known synonyms
#' @inheritParams by_name
#' @importFrom dplyr left_join
#' @export
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#'
#' sp <- c("Trochalopteron henrici gucenense",
#'         "Trochalopteron elliotii")
#' synonyms(sp)
#'
#' }
#'
synonyms <- function(name,
                     provider = c("itis", "ncbi", "col", "tpl",
                                  "gbif", "fb", "slb", "wd", "ott",
                                  "iucn"),
                     collect = TRUE,
                     db = td_connect()){


  the_id_table <- by_name(name, provider = provider, db = db)

  ## Get both accepted names & synonyms for anything with an acceptedNameUsageID
  suppress_msg({
    syn <-
      taxa_tbl(provider = provider, db = db) %>%
      dplyr::right_join(the_id_table %>%
                   select(acceptedNameUsageID),
                 by = "acceptedNameUsageID",
                 copy = TRUE) %>%
      dplyr::select("scientificName", "acceptedNameUsageID",
             "taxonomicStatus", "taxonRank") %>%
      syn_table()

  })
  ## Join that back onto the id table
  out <- the_id_table %>%
    dplyr::select("scientificName", "sort", "acceptedNameUsageID") %>%
    dplyr::left_join(syn, by = "acceptedNameUsageID", copy = TRUE) %>%
    distinct() %>%
    dplyr::select("acceptedNameUsage", "synonym", "taxonRank")   # reorder

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

  suppress_msg({

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

