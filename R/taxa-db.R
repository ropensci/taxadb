
library(DBI)
library(dplyr)
library(MonetDBLite)
#dbdir <- fs::dir_create("taxadb")

dbdir <- Sys.getenv("TAXALD_HOME", fs::path(fs::path_home(), ".taxald"))
con <- dbConnect(MonetDBLite::MonetDBLite(), dbdir)



library(geiger)
data(primates)
df <- data_frame(name = gsub("_", " ", primates$phy$tip.label))

out <- right_join(tbl(con, "col_taxonid"), df, copy = TRUE) %>% collect()

out <- right_join(tbl(con, "ncbi_taxonid"), df, copy = TRUE) %>% collect() %>% arrange(name)

# out <- right_join(tbl(con, "itis_taxonid"), df, copy = TRUE) %>% collect() %>% arrange(name)


out <- right_join(tbl(con, "ncbi_long"), df, copy = TRUE) %>% collect() %>% arrange(name)


## Support queries to preferred authority or multiple/all authorities 

## Look up id given a species name
## Look up a heirarchy given a species name or species id
## Return all species names / species ids belonging to a higher level rank
## 
## Look up a scientific name at any rank level.
## 
## Look up ids for higher ranks (when available)
## Look up synonyms
## Crosswalk / compare taxonomy across authorities in common format


## Install authorities in opt-in workflow
## Install layout / formats in opt-in style?


system.time({
  tbl(con, "taxa") %>% select(id, name, rank) %>% distinct()  %>% filter(name %like% "%Gadus%")

  })


system.time({
  tbl(con, "taxa") %>% filter(name %like% "%Gadus%") %>% select(id, name, rank) %>% distinct() %>% explain()
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
