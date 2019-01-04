
library(dplyr)
db <- src_sqlite("taxa.sqlite")

## Wikipedia says: The infraorder Brachyura contains 6,793 species in 93 families ...
tbl(db, "ncbi_wide") %>% filter(infraorder == "Brachyura") %>% summarise(n())
tbl(db, "itis_wide") %>% filter(infraorder == "Brachyura") %>% summarise(n())


## Most DBs don't have infraorder.  
tbl(db, "ncbi_wide") %>% filter(order == "Decapoda") %>% summarise(n())
tbl(db, "itis_wide") %>% filter(order == "Decapoda") %>% summarise(n())
tbl(db, "gbif_wide") %>% filter(order == "Decapoda") %>% summarise(n())
tbl(db, "col_wide") %>% filter(order == "Decapoda") %>% summarise(n())

tbl(db, "slb_wide") %>% filter(order == "Decapoda") %>% summarise(n())

## get all species with crab in the path
#tbl(db, "ncbi_long") %>% filter(path %like% "%crab%") %>% 
#  select(id, name, rank) %>% distinct() %>% filter(rank == "species") -> crabs

#tbl(db, "ncbi_long") %>% filter(id %in% pull(crabs,id))


#tmp <- crabs %>% left_join(tbl(db, "ncbi_long"), by = "id")

#collect() -> crabs
#crabs