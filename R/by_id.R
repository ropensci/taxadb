
#' Get all members (descendants) of a given rank level
#' @inheritParams by_name
#' @param id taxonomic id, in prefix format
#' @param type id type.  Can be taxonID or `acceptedNameUsageID`. Use `acceptedNameUsageID`
#' to return all rows for which this ID is the accepted ID, including both synonyms and
#' and accepted names (since both all synonyms of a name share the same `acceptedNameUsageID`.)
#' Use taxonID (default) to only return those rows for which the Scientific name
#' corresponds to the taxonID.
#'
#' Some providers (e.g. ITIS) assign taxonIDs to synonyms, most others only assign IDs to
#' accepted names.  In the latter case, this means requesting `taxonID` will only match
#' accepted names, while requesting matches to the `acceptedNameUsageID` will also return
#' any known synonyms.  See examples.
#' @return a data.frame with id and name of all matching species
#' @export
#' @importFrom stats setNames
#' @importFrom dplyr semi_join select filter distinct
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#'
#' by_id(c("ITIS:1077358", "ITIS:175089"))
#' by_id("ITIS:1077358", type="acceptedNameUsageID")
#'
#' }
by_id <- function(id,
                  provider = known_providers,
                  type = c("taxonID", "acceptedNameUsageID"),
                  collect = TRUE,
                  db = td_connect()){

    type <- match.arg(type)
    name <- id

    df <- data.frame(setNames(list(name), type),
                     stringsAsFactors = FALSE)
    taxa <- taxa_tbl(provider = provider,
                     schema = "dwc",
                     db = db)
    ## semi_join loses NAs ?
    ## semi_join faster than right join?
    suppress_msg({
    out <- dplyr::right_join(taxa,
                             df,
                             copy = TRUE,
                             by = type)
    })

  if(collect && inherits(out, "tbl_lazy"))
    return(dplyr::collect(out))

  out
}





# @importFrom rlang !! := UQ quo enquo
# @importFrom magrittr %>%
