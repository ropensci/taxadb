## apt-get -y install mariadb-client postgresql-client
library(taxizedb) 
library(tidyverse)
library(stringr)

## taxizedb import method:
# col <- db_download_col()
# db_load_col(col, host="mariadb", user="root", pwd="password")
# col_db <- src_col(host="mariadb", user="root", password="password")

## Connect to our first table:
# col_taxa <- tbl(col_db, "_species_details") 

## We can skip past taxizedb MySQL dump, and access the arkdb files from taxizedb:
## This installs data for all taxizedb databases into the `taxadb` directory as flat files
piggyback::pb_download(repo="cboettig/taxadb")

col_taxa <- read_tsv("taxizedb/col/_species_details.tsv.bz2")

# drop LSIDs, URIs are better.  (Unfortunately neither 
# ID numbers or LSIDs seems to provide a resolvable prefix)
#drop <- grepl("\\w+_lsid$", names(col_taxa))
#col_taxa <- col_taxa[!drop]

col_taxa <- col_taxa %>% 
  select(taxon_id, kingdom_name, phylum_name, class_name, order_name,
         superfamily_name, family_name, genus_name, subgenus_name,
         species_name, infraspecies_name,  kingdom_id, phylum_id,
         class_id, order_id,  superfamily_id, family_id, genus_id,
         subgenus_id,  species_id,  infraspecies_id, is_extinct) %>% collect()


## Transform to long form
col_names <- col_taxa %>% 
  select(taxon_id, kingdom = kingdom_name, phylum = phylum_name, class = class_name, 
         order = order_name,  superfamily = superfamily_name, family = family_name, 
         genus = genus_name, subgenus = subgenus_name, 
         species = species_name, infraspecies = infraspecies_name)
col_ids <- col_taxa %>% 
  select(taxon_id, kingdom = kingdom_id, phylum = phylum_id, class = class_id, 
         order = order_id, superfamily = superfamily_id, family = family_id,
         genus = genus_id, subgenus = subgenus_id,  
         species = species_id,  infraspecies = infraspecies_id)

other <- col_taxa %>%  
  select(taxon_id, is_extinct) %>%
  mutate(is_extinct = as.logical(is_extinct))

col_long <- 
  left_join(
    col_ids %>% gather(path_rank, path_id, -taxon_id),
    col_names %>% gather(path_rank, path, -taxon_id)
  ) %>% 
  left_join(other) %>% 
  rename(id = taxon_id)


sci_names <- col_names %>% 
  select(id = taxon_id, genus, species) %>% 
  tidyr::unite(name, genus, species, sep = " ") %>% 
  mutate(rank = "species")

col_long <- 
  col_long %>% 
  left_join(sci_names) %>% 
  mutate_if(is.integer, function(x) paste0("COL:", x)) %>%
 select(id, name, rank, path, path_rank, path_id, is_extinct)

col_wide <- 
  col_long %>% 
  select(id, species = name, path, path_rank) %>% 
  distinct() %>%
  spread(path_rank, path) 

write_tsv(col_long, "data/col_long.tsv.bz2")
write_tsv(col_wide, "data/col_wide.tsv.bz2")

library(tidyverse)
col_wide <- read_tsv("data/col_hierarchy.tsv.bz2")

col_hierarchy <- col_wide %>% 
  select(id, kingdom, phylum, class, 
                    order, superfamily, family,
                    genus, subgenus,  
                    species,  infraspecies) %>% 
  mutate(species = str_trim(paste(genus, species, str_replace_na(infraspecies, ""))))
write_tsv(col_hierarchy, "data/col_hierarchy.tsv.bz2")

col_taxonid <- 
col_wide %>% 
  select(id, species) %>% 
  distinct() %>% 
  mutate(rank = "species") %>% 
  rename(name = species) 
write_tsv(col_taxonid, bzfile("data/col_taxonid.tsv.bz2", compression=9))

###############

col_sci <- read_tsv("taxizedb/col/_search_scientific.tsv.bz2")




#col_taxonid <- col_long %>% 
#  select(id, name, rank) %>%
#  distinct()

#col_hierarchy_long <- col_long %>% 
#  select(id, path_id, path, path_rank) %>% 
#  distinct() 
#write_tsv(col_hierarchy_long, bzfile("data/col_hierarchy_long.tsv.bz2", compression=9))

## Drop col_long, it is just right_join(col_taxonid, col_hierarchy_long)

## No synonyms available
#col_synonyms <- col_long %>% 
#  select(id, name, rank) %>% 
#  distinct()

#write_tsv(col_synonyms, bzfile("data/col_synonyms.tsv.bz2", compression=9))


