
library(tidyverse)
library(DBI)
tidy1_con <- dbConnect(RSQLite::SQLite(), dbname="data/tidy_taxa.sql")

tbl(tidy1_con, "taxa")

itis <- read_tsv("data/itis.tsv.bz2")

recurse <- function(ids){
  id <- ids[length(ids)]
  parent <- filter(itis, tsn == id) %>% pull(parent_tsn)
  if(length(parent) < 1 )
    return(id)
  c(ids, recurse(parent))
}

all <- itis %>% 
  pull(tsn) %>% 
  map(recurse)


ncbi <- read_tsv("data/ncbi.tsv.bz2")
col <- read_tsv("data/col.tsv.bz2")
gbif <- read_tsv("data/gbif.tsv.bz2")

