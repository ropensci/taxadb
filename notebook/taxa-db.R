
library(geiger)
data(primates)
species <- gsub("_", " ", primates$phy$tip.label)


library(tictoc)
tic()
out <- right_join(tbl(con, "col_hierarchy"), df, copy = TRUE) %>% collect()
toc()
  
#sqlite <- src_sqlite("taxa.sqlite")
#tic()
#out <- right_join(tbl(sqlite, "col_wide"), df, copy = TRUE) %>% collect()
#toc()


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
