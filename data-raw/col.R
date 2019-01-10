library(taxizedb)
library(tidyverse)
library(stringr)
source("data-raw/helper-routines.R")


search_all <- read_tsv("taxizedb/col/_search_all.tsv.bz2")
scientific_name_status <- read_tsv("taxizedb/col/scientific_name_status.tsv.bz2")

#  search_scientific <- read_tsv("taxizedb/col/_search_scientific.tsv.bz2")
#  natural_keys <- read_tsv("taxizedb/col/_natural_keys.tsv.bz2")
#  synonym_name_element <- read_tsv("taxizedb/col/synonym_name_element.tsv.bz2")
#  synonym <- read_tsv("taxizedb/col/synonym.tsv.bz2")
#  scientific_name_element <- read_tsv("taxizedb/col/taxonomic_rank.tsv.bz2")
#  taxonomic_rank <-read_tsv("taxizedb/col/taxonomic_rank.tsv.bz2")

## search_all has:
#  7,469,592 rows
#  3,526,372 distinct ids
master <-  search_all %>%
  rename(name_status_id = name_status) %>%
  left_join(bind_rows(scientific_name_status, data_frame(id = 0, name_status = "other")),
            by = c("name_status_id" = "id"))

rm(search_all, scientific_name_status)

col_accepted_id <- master %>%
  filter(name_status == "accepted name") %>%
  select(id, name, rank) %>% distinct()


all_synonyms <- master %>%
  filter(name_status != "accepted name") %>%
  select(synonym_id = id, name, rank, id = accepted_taxon_id, type = name_status) %>%
  distinct()

mapped_synonyms <- all_synonyms %>% filter(id > 0)
## type == "other" (NA) names are not resolved. Includes common names, etc.
synonyms <- mapped_synonyms %>%
  left_join(select(col_accepted_id, accepted_name = name, id)) %>%
  select(id, accepted_name, name, type, rank, synonym_id)


species_details <- read_tsv("taxizedb/col/_species_details.tsv.bz2")
hierarchy <- species_details %>%
  select(id = taxon_id, kingdom = kingdom_name, phylum = phylum_name, class = class_name,
         order = order_name,  superfamily = superfamily_name, family = family_name,
         genus = genus_name, subgenus = subgenus_name,
         species = species_name, infraspecies = infraspecies_name)

hierarchy %>%
  mutate(id = paste0("COL:", id)) %>%
  write_tsv("data/col_hierarchy.tsv.bz2")

rm(heirarchy, species_details, master)



col_taxonid <- synonyms %>%
  rename(accepted_id = id, id = synonym_id) %>%
  select(id, name, rank, accepted_id, name_type = type) %>%
  bind_rows(mutate(col_accepted_id, accepted_id = id, name_type = "accepted")) %>%
  distinct() %>%
  mutate(accepted_id = paste0("COL:", accepted_id),
         id = paste0("COL:", id)) %>%
  select(id, name, rank, name_type, accepted_id) %>%
  de_duplicate()

write_tsv(col_taxonid, "data/col_taxonid.tsv.bz2")




## NOTES:

## 3,367,875 rows with accepted_name
accepted <- master %>% filter(name_status == "accepted name")  %>% distinct()
## but only 1,612,913 distinct rows of id,name,rank,group.
## This is because each species is basically listed twice, with name_element as Genus and then as species.
duplicates <- accepted %>% count(id) %>% arrange(desc(n)) %>% filter(n>1) %>% pull(id)
multi_id <- accepted %>% filter(id %in% duplicates) %>% arrange(id)


## Omitting group we see 1,603,420 , ie. 9,493 names have the same id, same species name, but different groups:
## This is due to duplicates with NA group and real group
same_id_diff_group <- accepted %>% select(id, group) %>% distinct() %>% count(id) %>% arrange(desc(n)) %>% filter(n>1) %>% pull(id)
accepted %>% filter(id %in% same_id_diff_group) %>% arrange(id) %>% select(id, name, group, rank, source_database_name) %>% distinct()

## Even after omitting group, 201 have duplicate ids, i.e. multiple "accepted name" names mapping to the same id: e.g.
#
# 10750775 Adelocephala (Oiticicia) purpurascens intensiva        subspecies
# 10750775 Adelocephala (Oiticicia) purpurascens subsp. intensiva subspecies

col_accepted_id <- master %>% filter(name_status == "accepted name") %>% select(id, name, rank) %>% distinct()

duplicate_id <- col_accepted_id %>% count(id) %>% arrange(desc(n)) %>% filter(n > 1) %>% pull(id)
col_accepted_id %>% filter(id %in% duplicate_id) %>% arrange(id)


## Why so many more accepted names than are distinct for this set?
master %>% filter(name_status == "accepted name") %>% select(id, name, rank, name_status, group, accepted_taxon_id, source_database_name) %>% distinct()

x %>%  select(id, name, rank, name_status, group, accepted_taxon_id, source_database_name)






col_ids <- species_details %>%
  select(taxon_id, kingdom = kingdom_id, phylum = phylum_id, class = class_id,
         order = order_id, superfamily = superfamily_id, family = family_id,
         genus = genus_id, subgenus = subgenus_id,
         species = species_id,  infraspecies = infraspecies_id)
