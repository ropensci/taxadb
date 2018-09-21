
#' Get all members (descendants) of a given rank level
#' @inheritParams classification
#' @param rank taxonomic rank name.
#' @param name taxonomic name (e.g. "Aves")
#' @param schema table schema to use (WIP)
#' @return a data.frame with id and name of all matching species
#' @export
#' @importFrom stats setNames
# @importFrom rlang !! := UQ quo enquo
# @importFrom magrittr %>%
#' @importFrom dplyr semi_join select filter distinct
descendants <- function(name = NULL, 
                        rank = NULL, 
                        id = NULL,
                        authority = c("itis", "ncbi", "col", "tpl",
                                      "gbif", "fb", "slb", "wd"),
                        collect = TRUE,
                        db = td_connect(),
                        schema = "hierarchy"){
  
  ## technically could guess rank from name most but not all time
  ## could still do this as join rather than a filter with appropriate table construction
  
  if(schema == "hierarchy"){
    df <- data.frame(setNames(list(name),  rank), stringsAsFactors = FALSE)
    df$id <- id
    out <- dplyr::semi_join(
      taxa_tbl(authority = authority,
               schema = "hierarchy", 
               db = db),
      df,
      copy = TRUE, by = rank)
  }
  
  if(collect && inherits(db, "DBIConnection")){
    ## Return an in-memory object
    out <- dplyr::collect(out)
    DBI::dbDisconnect(db)
  }
  
  out
  
}

