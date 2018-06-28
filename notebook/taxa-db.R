
library(geiger)
data(primates)
df <- data_frame(species = gsub("_", " ", primates$phy$tip.label))

db <- connect_db()

library(tictoc)
tic()
out <- right_join(tbl(con, "col_hierarchy"), df, copy = TRUE) %>% collect()
toc()

## Look up id given a species name
## Look up a heirarchy given a species name or species id
## Return all species names / species ids belonging to a higher level rank
## 
## Look up a scientific name at any rank level.
## 
## Look up ids for higher ranks (when available)
## Look up synonyms
## Crosswalk / compare taxonomy across authorities in common format


## Consider memoizing
hierarchy <- function(species = NULL, 
                      id = NULL, 
                      authority = c("itis", "ncbi", "col", "tpl",
                                    "gbif", "fb", "slb", "wd")){
  
  right_join(taxa_tbl(authority, "hierarchy"), dplyr::tibble(species, id))
}


ids <- function(species = NULL, 
                name = NULL,
                authority = c("itis", "ncbi", "col", "tpl",
                              "gbif", "fb", "slb", "wd")){
  right_join(taxa_tbl(authority, "taxonid"), 
             dplyr::tibble(name))
}

descendents <- function(name = NULL, 
                        rank = NULL, 
                        id = NULL,
                        authority = c("itis", "ncbi", "col", "tpl",
                                      "gbif", "fb", "slb", "wd")){
  ## if we have rank and name, filter on the hierarchy table
  
}



connect_db <- function(dbdir = Sys.getenv("TAXALD_HOME", 
                                          fs::path(fs::path_home(),
                                                   ".taxald"))){
  con <- dbConnect(MonetDBLite::MonetDBLite(), dbdir)
  db <- dplyr::src_dbi(con)
}
    
taxald_table <- function(
  db,
  authority = c("itis", "ncbi", "col", "tpl",
                "gbif", "fb", "slb", "wd"), 
  schema = c("hierarchy", "taxonid", "synonyms")){
  
  authority <- match.arg(authority)
  schema <- match.arg(schema)
  tbl_name <- paste(authority, schema, sep = "_")
  
  dplyr::tbl(db, tbl_name)
}
  
#sqlite <- src_sqlite("taxa.sqlite")
#tic()
#out <- right_join(tbl(sqlite, "col_wide"), df, copy = TRUE) %>% collect()
#toc()


out <- right_join(tbl(con, "ncbi_taxonid"), df, copy = TRUE) %>% collect() %>% arrange(name)

# out <- right_join(tbl(con, "itis_taxonid"), df, copy = TRUE) %>% collect() %>% arrange(name)


out <- right_join(tbl(con, "ncbi_long"), df, copy = TRUE) %>% collect() %>% arrange(name)


## Support queries to preferred authority or multiple/all authorities 



## Install authorities in opt-in workflow
## Install layout / formats in opt-in style?


system.time({
  tbl(con, "taxa") %>% select(id, name, rank) %>% distinct()  %>% filter(name %like% "%Gadus%")

  })




tbl(con, "taxa") %>% filter(lower(name) %like% "gadus")
tbl(con, "taxa") %>% filter(name == "Gadus" & rank == "Genus")
tbl(con, "taxa") %>% filter(name %like% "%Gadus%" & rank == "Species")
tbl(con, "taxa") %>% filter(name == "Gadus morhua" & rank == "Species") %>% collect() -> cod

tbl(con, "taxa") %>% filter(name == "Pinus ponderosa")%>% collect() -> pine
tbl(con, "taxa") %>% filter(path == "Gymnospermia")
tbl(con, "taxa") %>% filter(path %like% "%Spermatophyta%")
tbl(con, "taxa") %>% filter(path %like% "%Angiospermae%")
tbl(con, "taxa") %>% filter(path %like% "%Coniferae%")
tbl(con, "taxa") %>% filter(name == "Coniferae")
tbl(con, "taxa") %>% filter(name == "Pinopsida") %>% summarise(n())
tbl(con, "taxa") %>% filter(pathIds == "NCBI:122248")
tbl(con, "taxa") %>% filter(name == "Allocebus trichotis")
