## apt-get -y install mariadb-client postgresql-client
library(taxizedb) 
library(tidyverse)

# ncbi_store <- db_download_ncbi()
# 
# db_load_ncbi() ## not needed for ncbi
# ncbi_db <- src_ncbi(ncbi_store)

ncbi_taxa <- 
  #inner_join((ncbi_db, "nodes"), tbl(ncbi_db, "names")) %>%
  inner_join(read_tsv("taxizedb/ncbi/nodes.tsv.bz2"), read_tsv("taxizedb/ncbi/names.tsv.bz2")) %>%
  select(tax_id, parent_tax_id, rank, name_txt, unique_name, name_class) #%>%
  #collect()


ncbi_ids <- ncbi_taxa %>% 
  select(tsn = tax_id, parent_tsn = parent_tax_id) %>%
  distinct() %>% 
  mutate(tsn = paste0("NCBI:", tsn),
         parent_tsn = paste0("NCBI:", parent_tsn))

## note: NCBI doesn't have rank ids
ncbi <- ncbi_taxa %>% 
  select(id = tax_id, name = name_txt, rank, name_type = name_class) %>%
  mutate(id = paste0("NCBI:", id)) 

rm(ncbi_taxa)

## Recursively JOIN on id = parent 
## FIXME do properly with recursive function and dplyr programming calls
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
  left_join(rename(ncbi_ids, p11 = parent_tsn), by = c("p10" = "tsn")) %>%
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

rm(ncbi_ids)
## expect_true: confirm we have resolved all ids
all(recursive_ncbi_ids[[length(recursive_ncbi_ids)]] == "NCBI:1")

long_hierarchy <- 
  recursive_ncbi_ids %>% 
  tidyr::gather(dummy, path_id, -tsn) %>% 
  select(id = tsn, path_id) %>% 
  distinct() %>%
  arrange(id) 

rm(recursive_ncbi_ids)

expand <- ncbi %>% 
  select(path_id = id, path = name, path_rank = rank, path_type = name_type) 

ncbi_long <- ncbi %>% 
  filter(name_type == "scientific name") %>% 
  select(-name_type) %>%  
  inner_join(long_hierarchy) %>%
  inner_join(expand)

ncbi_longid <- ncbi_long %>%
  select(id, name, rank, type = path_type)


## Example query: how many species of fishes do we know?
#fishes <- ncbi_long %>% 
#  filter(path == "fishes", rank == "species") %>% 
#  select(id, name, rank) %>% distinct()
# 33,082 known species

## Wide-format classification table (scientific names only)
ncbi_wide <- 
  ncbi_long %>% 
  filter(path_type == "scientific name", rank == "species") %>% 
  select(id, species = name, path, path_rank) %>% 
  distinct() %>%
  filter(path_rank != "no rank") %>% ## Wide format includes named ranks only
  filter(path_rank != "superfamily") %>%  
  # ncbii has a few duplicate "superfamily" with both as "scientific name"
  # This is probably a bug in there data as one of these should be "synonym"(?)
  spread(path_rank, path)



### 
ncbi_taxonid <- ncbi_long %>% 
  select(id = path_id, name = path, rank = path_rank, type = path_type) %>%
  filter(type == "scientific name") %>%
  select(-type) %>%
  distinct() 

## Synonyms table including all scientific names.
## makes table longer, but gives us only one column to match against
ncbi_synonyms <- ncbi_long %>% 
  select(id = path_id, given_name = path, name_type = path_type) %>% 
  filter(name_type != "scientific name") %>%
  distinct() %>% 
  left_join(ncbi_taxonid, by = c("id"))

ncbi_synonyms <- ncbi_synonyms %>% 
  rename(accepted_name = name, name = given_name) %>%
  select(name, accepted_name, id, rank, name_type)


#write_tsv(ncbi_long,"data/ncbi_long.tsv.bz2")
#write_tsv(ncbi_wide, "data/ncbi_hierarchy.tsv.bz2")


write_tsv(ncbi_synonyms, "data/ncbi_synonyms.tsv.bz2")
write_tsv(ncbi_taxonid, "data/ncbi_taxonid.tsv.bz2")
write_tsv(ncbi_longid, "data/ncbi_longid.tsv.bz2")

