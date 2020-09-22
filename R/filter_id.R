

#' Return a taxonomic table matching the requested ids
#'
#' @inheritParams filter_name
#' @param id taxonomic id, in prefix format
#' @param type id type.  Can be `taxonID` or `acceptedNameUsageID`,
#'  see details.
#'
#'
#' @details Use `type="acceptedNameUsageID"` to return all rows
#' for which this ID is the accepted ID, including both synonyms and
#' and accepted names (since both all synonyms of a name share the
#' same `acceptedNameUsageID`.) Use `taxonID` (default) to only return
#' those rows for which the Scientific name corresponds to the `taxonID.`
#'
#' Some providers (e.g. ITIS) assign taxonIDs to synonyms, most others
#' only assign IDs to accepted names.  In the latter case, this means
#' requesting `taxonID` will only match accepted names, while requesting
#' matches to the `acceptedNameUsageID` will also return any known synonyms.
#' See examples.
#' @family filter_by
#' @return a data.frame with id and name of all matching species
#' @export
#' @importFrom stats setNames
#' @importFrom dplyr semi_join select filter distinct
#' @examples
#' \donttest{
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'    options("taxadb_default_provider"="itis_test")
#'   }
#'
#' filter_id(c("ITIS:1077358", "ITIS:175089"))
#' filter_id("ITIS:1077358", type="acceptedNameUsageID")
#'
#' }
filter_id <- function(id,
                  provider = getOption("taxadb_default_provider", "itis"),
                  type = c("taxonID", "acceptedNameUsageID"),
                  version = latest_version(),
                  collect = TRUE,
                  db = td_connect()){

    filter_by(x = id,
              by = match.arg(type),
              provider = provider,
              version = version,
              collect = collect,
              db = db,
              ignore_case = FALSE)
  }
