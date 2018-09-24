## FIXME Does not support lookup of non-species-level ids. Using taxonid schema would fix this.

#' Return taxonomic identifiers from a given namespace
#' 
#' @param name a character vector of species names. 
#' (Most authorities can also return ids for higher-level
#'  taxonomic names).
#' @inheritParams classification
#' @return a data.frame with columns of `id`, scientific 
#' `name`, and `rank` and a row for each species name queried.
#' 
#' @export
ids <- function(name = NULL,
                authority = c("itis", "ncbi", "col", "tpl",
                              "gbif", "fb", "slb", "wd"),
                collect = TRUE,
                db = td_connect()){
  
  out <- 
    dplyr::semi_join(
      taxa_tbl(authority = authority, 
               schema = "hierarchy", 
               db = db), 
      dplyr::tibble(species = name),
      copy = TRUE) 
  out <- dplyr::select(out, "id", "species")
  
  
  if(collect && inherits(db, "DBIConnection")){
    ## Return an in-memory object
    out <- dplyr::collect(out)
    DBI::dbDisconnect(db)
  }
  
  out
}
