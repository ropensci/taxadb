library(tictoc)
library(dplyr)

db <- connect_db()

## a species list of all Primates in COL
species <- tbl(db, "col_hierarchy") %>% 
  #filter(order == "Primates") %>% 
  filter(class == "Mammalia") %>%
  select(species) %>% collect() %>% pull(species)

length(species)

tic()
out <- right_join(tbl(db, "itis_taxonid"), 
                  tibble(name = species), copy = TRUE) %>% collect()
toc()

tic()
out <- right_join(tbl(db, "itis_long"), 
                  tibble(name = species), copy = TRUE) %>% 
        select(id, name, rank) %>% distinct() %>%
  collect()
toc()



# hmm, why can't we union these?
stack <- dplyr::union_all(tbl(db, "itis_long"), 
                          tbl(db, "col_long"))

stack # Error: Cannot pass NA to dbQuoteIdentifier()



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
