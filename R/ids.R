
#' Return taxonomic identifiers from a given namespace
#'
#' @param name a character vector of species names, e.g. "Homo sapiens"
#' (Most but not all authorities can also return ids for higher-level
#'  taxonomic names).
#' @param provider from which provider should the hierachy be returned?
#'  Default is 'itis'.
#' @param collect logical, default `TRUE`. Should we return an in-memory
#' data.frame (default, usually the most convenient), or a reference to
#' lazy-eval table on disk (useful for very large tables on which we may
#' first perform subsequent filtering operations.)
#' @param db a connection to the taxadb database. See details.
#' @return a data.frame with columns of `id`, scientific
#' `name`, and `rank`, and `accepted_id` (if data includes synonyms)
#'  and a row for each species name queried.
#'
#' @details
#' Some authorities (ITIS, COL, FB/SLB, NCBI) provide synonyms as well.  These
#' are included in the name list search.  The data.frame returned will then
#' include an `accepted_id` column, providing the synonym for the requested table.
#' In this case, the `id` column corresponds to the id for either the name column --
#' that is, if the name is a synonym, this is the id for the synonym; if the name
#' is accepted, this id is the same as the accepted id.  NCBI does not issue ids
#' for known synonyms, so the id is missing for synonym names in this case.
#'
#' @export
#' @importFrom dplyr quo tibble filter right_join
#' @importFrom rlang !!
#' @importFrom magrittr %>%
ids <- function(name = NULL,
                provider = KNOWN_AUTHORITIES,
                collect = TRUE,
                db = td_connect()){

  # Dummy vars for NSE
  sort <- TRUE #
  input <- ""

  ## Create the input table.
  ## We will (temporarily) copy this to disk to join against the database
  ## Filtering joins are much much faster than filtering, particularly
  ## for large numbers of input names, when we use MonetDB(Lite)
  input_table <- dplyr::tibble(
    ## base::tolower() fails on certain non UTF8
    input = stringi::stri_trans_tolower(name),
    sort = 1:length(name))

  ## Could be pre-computed to avoid the performance hit here.
  db_table <-
    taxa_tbl(provider, "dwc", db) %>%
  ## Could consider other cleaning
  ## when run in backend DB, uses the DB's built-in lowercase SQL command:
    mutate(input = tolower(scientificName))

  ## Use right_join, so unmatched names are kept, with NA
  ## Using right join, names appear in order of provider!

  suppress_msg({   # bc MonetDBLite whines about upper-case characters
  out <-
    dplyr::right_join(
      db_table,
      input_table,
      by = "input",
      copy = TRUE) %>%
    dplyr::arrange(sort) # enforce original order
    ## maintain the 'sort' and input columns, as they can be useful,
    ## even though these are not dwc columns.
    # select(-sort, input)
  })
  ## A known synonym can match two different valid names!
  ## 'Trochalopteron henrici gucenense' is a synonym for:
  ## 'Trochalopteron elliotii'  and also for  'Trochalopteron henrici'
  ## (according to ITIS)

  if (collect && inherits(out, "tbl_lazy")) {
    ## Return an in-memory object
    return( dplyr::collect(out) )
  }

  out
}




## FIXME abstract this to filter on id / name / generic column?
accepted_name <- function(id = NULL,
                provider = KNOWN_AUTHORITIES,
                collect = TRUE,
                db = td_connect()){
  sort <- TRUE # dummy name
  input_table <- dplyr::tibble(taxonID = id, sort = 1:length(id))

  ## Use right_join, so unmatched names are kept, with NA
  ## Means names appear in order of provider, so we must arrange
  ## after-the-fact to match the query order
  out <-
    dplyr::right_join(
      taxa_tbl(provider, "dwc", db),
      input_table,
      by = "taxonID",
      copy = TRUE) %>%
    dplyr::arrange(sort) %>%
    select(-sort)

  if (collect && inherits(out, "tbl_lazy")) {
    ## Return an in-memory object
    return( dplyr::collect(out) )
  }

  out
}


#clean_db_names <- function(provider, db = td_connect()){
## Could be pre-computed to avoid the performance hit here.
#db_table <-
#  taxa_tbl(provider, "dwc", db) %>%
#  mutate(input = tolower(scientificName),
#         name1 = splitpart(input, " ", 1L),
#         name2 = splitpart(input, " ", 2L))

#}





