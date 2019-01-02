
#' synonyms
#'
#' Resolve provided list of names against all known synonyms
#' @inheritParams ids
#' @export
synonyms <- function(name = NULL,
                     authority = KNOWN_AUTHORITIES,
                     collect = TRUE,
                     db = td_connect()){

  syn_ids <- taxa_tbl(authority = authority,
                     schema = "synonyms",
                     db = db)

  out <- dplyr::right_join(syn_ids,
                           tibble::tibble(name),
                           by = "name",
                           copy = TRUE)


  ## ITIS seems to map synonyms that are obviously species names into higher ranks??

  if (collect && inherits(out, "tbl_lazy")) {
    ## Return an in-memory object
    out <- dplyr::collect(out)
  }

  out

}
