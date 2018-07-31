## Drop in replacements for taxize


get_ids <- function(names, db, ...){
  ids(name = names, authority = db, ...)
}


get_uid <- function(sciname, ...){
  ids(name = sciname, authority = "ncbi", ...)
}