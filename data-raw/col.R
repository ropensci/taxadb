## apt-get -y install mariadb-client postgresql-client
library(taxizedb) 
library(tidyverse)


col <- db_download_col()

## Working.  but why does db_load_col take forever every time!! Does this need to be re-run or not?
#db_load_col(col, host="mariadb", user="root", pwd="password")
col_db <- src_col(host="mariadb", user="root", password="password")

col_taxa <- tbl(col_db, "_species_details") 

# drop LSIDs, URIs are better.  (Unfortunately neither 
# ID numbers or LSIDs seems to provide a resolvable prefix)
#drop <- grepl("\\w+_lsid$", names(col_taxa))
#col_taxa <- col_taxa[!drop]

col_taxa <- col_taxa %>% 
  select(taxon_id, kingdom_name, phylum_name, class_name, order_name,  superfamily_name, family_name, genus_name, subgenus_name, species_name, infraspecies_name,
       kingdom_id, phylum_id, class_id, order_id,  superfamily_id, family_id, genus_id, subgenus_id,  species_id,  infraspecies_id,
       is_extinct) %>% collect()


## Transform to long form
col_names <- col_taxa %>% select(taxon_id, kingdom = kingdom_name, phylum = phylum_name, class = class_name, 
                                 order = order_name,  superfamily = superfamily_name, family = family_name, 
                                 genus = genus_name, subgenus = subgenus_name, species = species_name, infraspecies = infraspecies_name)
col_ids <- col_taxa %>% select(taxon_id, kingdom = kingdom_id, phylum = phylum_id, class = class_id, 
                               order = order_id, superfamily = superfamily_id, family = family_id, genus = genus_id, 
                               subgenus = subgenus_id,  species = species_id,  infraspecies = infraspecies_id)
other <- col_taxa %>%  select(taxon_id, is_extinct)

other %>% mutate(is_extinct <- as.logical(is_extinct))

sci_names <- col_names %>% select(taxon_id, genus, species) %>% tidyr::unite(name, genus, species, sep = " ")
long_names <- col_names %>% gather(rank, path, -taxon_id) %>% left_join(sci_names) %>% select(taxon_id, name, path, rank)
long_ids <- col_ids %>% gather(rank, path_id, -taxon_id)


col_long <- long_names %>% 
  left_join(long_ids) %>% 
  left_join(other) %>% 
  arrange(taxon_id) %>% 
  mutate_if(is.integer, function(x) paste0("COL:", x))


## Prefix identifiers
col_wide <- col_taxa %>% 
  mutate_if(is.integer, function(x) paste0("COL:", x)) %>% 
  rename(kingdom = kingdom_name, phylum = phylum_name, class = class_name, 
         order = order_name,  superfamily = superfamily_name, 
         family = family_name, genus = genus_name, subgenus = subgenus_name,
         species = species_name, infraspecies = infraspecies_name)

write_tsv(col_long, "data/col_long.tsv.bz2")
write_tsv(col_wide, "data/col_wide.tsv.bz2")


