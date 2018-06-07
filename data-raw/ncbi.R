## apt-get -y install mariadb-client postgresql-client
library(taxizedb) 
library(tidyverse)

ncbi_store <- db_download_ncbi()

db_load_ncbi() ## not needed for ncbi
ncbi_db <- src_ncbi(ncbi_store)

ncbi_taxa <- inner_join(tbl(ncbi_db, "nodes"), tbl(ncbi_db, "names")) %>%
  select(tax_id, parent_tax_id, rank, name_txt, unique_name, name_class) 

##########
#ncbi <- read_tsv("data/ncbi.tsv.bz2")

ncbi_ids <- ncbi_taxa %>% 
  select(tsn = tax_id, parent_tsn = parent_tax_id) %>%
  distinct() %>% 
  mutate(tsn = paste0("NCBI:", tsn),
         parent_tsn = paste0("NCBI:", parent_tsn)) %>% 
  collect()

##  iterate through all ids individually, possibly slow
#recurse <- function(ids){
#  id <- ids[length(ids)]
#  parent <- filter(ncbi_ids, tsn == id) %>% pull(parent_tsn)
#  if(length(parent) < 1 | id == parent)
#    return(id)
#  c(ids, recurse(parent))
#}
#tidy_ncbi <- ncbi_ids %>%  distinct() %>% slice(1:10) %>% pull(tsn) %>%  map(recurse)

## Possibly faster:  Recursively JOIN on id = parent 
## FIXME do properly with recursive function and dplyr programming calls

## can't do this before collect, creates stack overflow
recursive_ncbi_ids <- ncbi_ids %>% 
  left_join(rename(ncbi_ids, p2 = parent_tsn), by = c("parent_tsn" = "tsn")) %>%
  left_join(rename(ncbi_ids, p3 = parent_tsn), by = c("p2" = "tsn")) %>%
  left_join(rename(ncbi_ids, p4 = parent_tsn), by = c("p3" = "tsn")) %>%
  left_join(rename(ncbi_ids, p5 = parent_tsn), by = c("p4" = "tsn")) %>%
  left_join(rename(ncbi_ids, p6 = parent_tsn), by = c("p5" = "tsn")) %>%
  left_join(rename(ncbi_ids, p7 = parent_tsn), by = c("p6" = "tsn")) %>%
  left_join(rename(ncbi_ids, p8 = parent_tsn), by = c("p7" = "tsn")) %>%
  left_join(rename(ncbi_ids, p9 = parent_tsn), by = c("p8" = "tsn")) %>%
  left_join(rename(ncbi_ids, p10 = parent_tsn), by = c("p9" = "tsn")) %>%
  left_join(rename(ncbi_ids, p11 = parent_tsn), by = c("p10" = "tsn"))  %>%
  left_join(rename(ncbi_ids, p12 = parent_tsn), by = c("p11" = "tsn")) %>%
  left_join(rename(ncbi_ids, p13 = parent_tsn), by = c("p12" = "tsn")) %>%
  left_join(rename(ncbi_ids, p14 = parent_tsn), by = c("p13" = "tsn")) %>%
  left_join(rename(ncbi_ids, p15 = parent_tsn), by = c("p14" = "tsn")) %>%
  left_join(rename(ncbi_ids, p16 = parent_tsn), by = c("p15" = "tsn")) %>%
  left_join(rename(ncbi_ids, p17 = parent_tsn), by = c("p16" = "tsn")) %>%
  left_join(rename(ncbi_ids, p18 = parent_tsn), by = c("p17" = "tsn")) %>%
  left_join(rename(ncbi_ids, p19 = parent_tsn), by = c("p18" = "tsn")) %>%
  left_join(rename(ncbi_ids, p20 = parent_tsn), by = c("p19" = "tsn")) %>%
  left_join(rename(ncbi_ids, p21 = parent_tsn), by = c("p20" = "tsn")) %>%
  left_join(rename(ncbi_ids, p22 = parent_tsn), by = c("p21" = "tsn")) %>%
  left_join(rename(ncbi_ids, p23 = parent_tsn), by = c("p22" = "tsn")) %>%
  left_join(rename(ncbi_ids, p24 = parent_tsn), by = c("p23" = "tsn")) %>%
  left_join(rename(ncbi_ids, p25 = parent_tsn), by = c("p24" = "tsn")) %>%
  left_join(rename(ncbi_ids, p26 = parent_tsn), by = c("p25" = "tsn")) %>%
  left_join(rename(ncbi_ids, p27 = parent_tsn), by = c("p26" = "tsn")) %>%
  left_join(rename(ncbi_ids, p28 = parent_tsn), by = c("p27" = "tsn")) %>%
  left_join(rename(ncbi_ids, p29 = parent_tsn), by = c("p28" = "tsn")) %>%
  left_join(rename(ncbi_ids, p30 = parent_tsn), by = c("p29" = "tsn")) %>%
  left_join(rename(ncbi_ids, p31 = parent_tsn), by = c("p30" = "tsn")) %>%
  left_join(rename(ncbi_ids, p32 = parent_tsn), by = c("p31" = "tsn")) %>%
  left_join(rename(ncbi_ids, p33 = parent_tsn), by = c("p32" = "tsn")) %>%
  left_join(rename(ncbi_ids, p34 = parent_tsn), by = c("p33" = "tsn")) %>%
  left_join(rename(ncbi_ids, p35 = parent_tsn), by = c("p34" = "tsn")) %>%
  left_join(rename(ncbi_ids, p36 = parent_tsn), by = c("p35" = "tsn")) %>%
  left_join(rename(ncbi_ids, p37 = parent_tsn), by = c("p36" = "tsn")) %>%
  left_join(rename(ncbi_ids, p38 = parent_tsn), by = c("p37" = "tsn"))

## expect_true: confirm we have resolved all ids
all(recursive_ncbi_ids[[length(recursive_ncbi_ids)]] == "NCBI:1")


hierarchy <- 
  tidyr::unite(recursive_ncbi_ids, hierarchy, -tsn, sep = " | ") %>%
  rename(id = tsn) 

#write_tsv(hierarchy, "hierarchy.tsv")

## NCBI doesn't have rank ids
ncbi <- ncbi_taxa %>% 
  select(id = tax_id, 
         name = name_txt, 
         rank, 
         parent_id = parent_tax_id, 
         ncbi_name_class = name_class) %>%
  mutate(id = paste0("NCBI:", id),
         parent_id = paste0("NCBI:", parent_id)) %>%
left_join(hierarchy, copy = TRUE) # heirarchy is in mem, ncbi_taxa in DB. 

rm(list = c("hierarchy", "ncbi_ids", "recursive_ncbi_ids"))

ncbi <- collect(ncbi)
write_tsv(ncbi, "ncbi.tsv")


DBI::dbDisconnect(ncbi_db[[1]])

## Go into long form:
longform <- function(row, pattern = "\\s*\\|\\s*"){ 
  row_as_df <- 
    data_frame(id = row$id,
               name = row$name,
               rank = row$rank,
               path_id = unique(str_split(row$hierarchy, pattern)[[1]])
               )
}


hier_expand <- ncbi %>% 
  select(id, path = name, path_rank = rank, ncbi_name_class) 

write_tsv(hier_expand, "hier_expand.tsv")


#path_id <-  ncbi %>% filter(name == "Gadus morhua") %>% pull(hierarchy)
#path_id <- str_split(path_id, pattern)[[1]] %>% unique()
#hier_expand %>% filter(id %in% path_id)



tmp <- ncbi %>% 
#  filter(name == "Gadus morhua") %>%
  select(-ncbi_name_class) %>%
  purrr::transpose() %>% 
  map_dfr(longform) 

tmp <- write_tsv(tmp, "tmp.tsv")

#hier_expand <- read_tsv("hier_expand.tsv")
#tmp <- read_tsv("tmp.tsv")


ncbi_long <- tmp %>%
  left_join(hier_expand, by = c("path_id" = "id")) %>% 
  distinct() %>%
  select(id, name, rank, path, 
         path_rank, path_id, 
         ncbi_name_class) %>% 
  arrange(id, ncbi_name_class)

## Note: usually will want to filter this as
## filter(ncbi_name_class == "scientific_name")

## Consider: pulling ncbi_name_class==commonname into another column

system.time({
  write_tsv(ncbi_long, bzfile("data/ncbi_long.tsv.bz2", compression=9))
})




## benchmark alternate methods
# 402 secs compress, 55 sec decompress. 34.6 MB compressed
# system.time(write_tsv(ncbi, "data/ncbi.tsv.bz2"))
# system.time(ncbi <- read_tsv( "data/ncbi.tsv.bz2"))


# 43 secs compress, 43 sec decompress, 47 MB compressed
#system.time(write_tsv(ncbi, "data/ncbi.tsv.gz"))
#system.time(ex <- read_tsv( "data/ncbi.tsv.gz"))


## 1 sec i/o at 50%, ~ 5 sec i/o 100%.  file size @ 100% ~ 51.5 MB
#system.time(fst::write_fst(ncbi, "data/ncbi.fst", compress = 100))
#system.time(ex <- fst::read_fst("data/ncbi.fst"))

## w/o compression: 25 sec
#system.time(write_tsv(ncbi, "data/ncbi.tsv"))

