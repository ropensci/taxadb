## FIXME Does not support lookup of non-species-level ids. Using taxonid schema would fix this.

#' Return taxonomic identifiers from a given namespace
#'
#' @param name a character vector of species names, e.g. "Homo sapiens"
#' (Most but not all authorities can also return ids for higher-level
#'  taxonomic names).
#' @param pull logical, should we pull out the id column or return the full table?
#' @param authority from which authority should the hierachy be returned?
#'  Default is 'itis'.
#' @param collect logical, default `TRUE`. Should we return an in-memory
#' data.frame (default, usually the most convenient), or a reference to
#' lazy-eval table on disk (useful for very large tables on which we may
#' first perform subsequent filtering operations.)
#' @param db a connection to the taxald database. See details.
#' @return a data.frame with columns of `id`, scientific
#' `name`, and `rank` and a row for each species name queried.
#'
#' @details
#' NOTE on matching synonyms: Some authorities (like ITIS) issue separate synonym_ids
#' corresponding to synonym names. The `ids()` function *does not* return synonym ids.
#' Rather, if a name is recognized as a synonym, we will look up the appropriate
#' accepted name and the ID associated with the accepted name and return that.
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

  input_table <- dplyr::tibble(name)

  ## Use right_join, so unmatched names are kept, with NA
  ## Using right join, names appear in order of authority
  out <- dplyr::right_join(
      taxa_tbl(authority, "taxonid", db),
      input_table,
      by = "name",
      copy = TRUE)

  if (collect && inherits(out, "tbl_lazy")) {
    ## Return an in-memory object
    return( dplyr::collect(out) )
  }

  out
}



