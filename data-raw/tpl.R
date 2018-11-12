## apt-get -y install mariadb-client postgresql-client
library(taxizedb) 
library(tidyverse)

# tpl <- db_download_tpl()
# 
# 
# db_load_tpl(tpl, user = "postgres", pwd = "password", host = "postgres")
# 
# 
# tpl_db <- src_tpl(user = "postgres", password = "password", host = "postgres")
# 
# tpl_taxa <- tbl(tpl_db, "plantlist")  %>%
#   collect()  ## Only table
#write_tsv(tpl_taxa, "data/tpl.tsv.bz2")

tpl_taxa <- read_tsv("taxizedb/tpl/plantlist.tsv.bz2")

tpl_wide <- tpl_taxa %>% 
  select(id, species, genus, family, major_group, 
         infraspecific_rank, infraspecific_epithet,  
         genus_hybrid_marker, species_hybrid_marker,
         kewid, ipni_id,
         confidence_level) %>% 
mutate(species = paste(genus, species),
       id = paste0("TPL:", id),
       ipni_id = paste0("IPNI:", ipni_id))

write_tsv(tpl_wide, "data/tpl_wide.tsv.bz2")


tpl_long <- tpl_wide %>% 
  gather(path_rank, path, -id, -kewid, -ipni_id, -confidence_level) %>%
  left_join(select(tpl_wide, id, name=species)) %>% 
  mutate(rank = "species") %>%
  select(id, name, rank, path, path_rank, confidence_level, kew_id=kewid, ipni_id)

write_tsv(tpl_long, "data/tpl_long.tsv.bz2")


## taxonid
tpl_long %>% select(id, name, rank) %>% distinct() %>% write_tsv("data/tpl_taxonid.tsv.bz2")

# test parsing
tmp <- read_tsv("data/tpl_wide.tsv.bz2")
