## FIXME Does not support lookup of non-species-level ids. Using taxonid schema would fix this.

#' Return taxonomic identifiers from a given namespace
#'
#' @param name a character vector of species names, e.g. "Homo sapiens"
#' (Most but not all authorities can also return ids for higher-level
#'  taxonomic names).
#' @param authority from which authority should the hierachy be returned?
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
                authority = c("itis", "ncbi", "col", "tpl",
                              "gbif", "fb", "slb", "wd"),
                collect = TRUE,
                db = td_connect()){
  sort <- TRUE # dummy name
  input_table <- dplyr::tibble(name, sort = 1:length(name))

  ## Use right_join, so unmatched names are kept, with NA
  ## Using right join, names appear in order of authority!
  out <-
    dplyr::right_join(
      taxa_tbl(authority, "taxonid", db),
      input_table,
      by = "name",
      copy = TRUE) %>%
    dplyr::arrange(sort) %>%
    select(-sort)

  if (collect && inherits(out, "tbl_lazy")) {
    ## Return an in-memory object
    return( dplyr::collect(out) )
  }

  out
}





## FIXME abstract this to filter on id / name / generic column?
accepted_name <- function(id = NULL,
                authority = c("itis", "ncbi", "col", "tpl",
                              "gbif", "fb", "slb", "wd"),
                collect = TRUE,
                db = td_connect()){
  sort <- TRUE # dummy name
  input_table <- dplyr::tibble(id, sort = 1:length(id))

  ## Use right_join, so unmatched names are kept, with NA
  ## Means names appear in order of authority, so we must arrange
  ## after-the-fact to match the query order
  out <-
    dplyr::right_join(
      taxa_tbl(authority, "taxonid", db),
      input_table,
      by = "id",
      copy = TRUE) %>%
    dplyr::arrange(sort) %>%
    select(-sort)

  if (collect && inherits(out, "tbl_lazy")) {
    ## Return an in-memory object
    return( dplyr::collect(out) )
  }

  out
}

