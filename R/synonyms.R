synonyms <- function(name = NULL, 
                     authority = c("itis", "ncbi", "col", "tpl",
                                         "gbif", "fb", "slb", "wd"),
                     collect = TRUE,
                     db = td_connect()){
  
  

  syn_ids <- taxa_tbl(authority = authority,
                     schema = "synonyms", 
                     db = db)
  
  matching_syn <- dplyr::semi_join(syn_ids, 
                                   tibble::tibble(name), 
                                   copy = TRUE)
  
  matching_syn <- select(matching_syn,
                         "synonym_id" = "id",
                         "synonym" = "name",
                         "accepted_id")
  
  accepted_ids <- taxa_tbl(authority, 
                           schema = "taxonid", 
                           db = db)
  
  out <- dplyr::right_join(accepted_ids, 
                          matching_syn,
                          by = c("id" = "accepted_id"))
  
  ## ITIS seems to map synonyms that are obviously species names into higher ranks??
  
  if(collect && inherits(out, "tbl_lazy")){ 
    ## Return an in-memory object
    out <- dplyr::collect(out)
  }
  
  out
  
}
