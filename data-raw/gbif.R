
library(tidyverse)
source("data-raw/helper-routines.R")

piggyback::pb_download(repo="cboettig/taxadb", tag = "data") # raw data cache
taxon <- read_tsv("taxizedb/gbif/taxon.tsv.bz2")

gbif_taxa <- taxon %>%
  select(id = taxonID, scientificName, rank= taxonRank,
         kingdom, phylum, class, order, family, genus,
         canonicalName, genericName, taxonomicStatus,
         specificEpithet, infraspecificEpithet,
         accepted_id = acceptedNameUsageID,
         original_id = originalNameUsageID)  %>%
  rename(species = specificEpithet,
         epithet = infraspecificEpithet) %>%
  mutate(species = paste(genus, species, epithet))

    ## canonicalName appears to be: Genus + specificEpithet + infraspecificEpithet
## i.e. SpecificEpithet ~ a name at the "species" rank
## Scientific name is ~ canonical name + citation parenthetical

## ~  273,132 species have epithets in the canonical names


gbif_wide <- gbif_taxa  %>%
  filter(taxonomicStatus == "accepted") %>%
  select(id,
         kingdom, phylum, class, order, family, genus, species, epithet,
         genericName) %>%
  mutate(id = paste0("GBIF:", id))
write_tsv(gbif_wide, "data/gbif_hierarchy.tsv.bz2")
rm(gbif_wide)

gbif_taxa <-
  gbif_taxa %>%
  select(id,
         name = canonicalName,
         rank = rank,
         name_type = taxonomicStatus,
         accepted_id)
# when taxonomicStatus == accepted, accepted_id = NA, we want it to = id.
# If name is not accepted, we will only keep it if we can map the synonym to an accepted ID:
accepted <- filter(gbif_taxa, name_type == "accepted") %>% mutate(accepted_id = id)
rest <- filter(gbif_taxa, name_type != "accepted") %>% filter(!is.na(accepted_id))

gbif_taxonid <- bind_rows(accepted, rest) %>%
  de_duplicate() %>%
  mutate(id = paste0("GBIF:", id),
         accepted_id = paste0("GBIF:", accepted_id))
write_tsv(gbif_taxonid, "data/gbif_taxonid.tsv.bz2")



## A mapping in which synonym
gbif_synonyms <- full_join(
  gbif_taxonid %>%
    filter(name_type != "accepted") %>%
    select(synonym = name, synonym_id = id, accepted_id, name_type),
  gbif_taxonid %>%
    filter(name_type == "accepted") %>%
    select(-id))  %>%
    select(name, synonym, synonym_id, accepted_id, rank, name_type) %>%
  mutate(synonym_id = paste0("GBIF:", id),
         accepted_id = paste0("GBIF:", accepted_id))

write_tsv(gbif_synonyms, "data/gbif_synonyms.tsv.bz2")

fs::dir_ls("data") %>% pb_upload(repo="cboettig/taxadb", tag="v1.0.0")

# gbif_synonyms <- gbif_long %>%
#   filter(taxonomicStatus != "accepted") %>%
#   select(synonym_id = id, accepted_name = name, rank, name = genericName, type = taxonomicStatus) %>%
#   distinct()
#
# syn_temp <- left_join(gbif_synonyms, select(gbif_synonyms, id = synonym_id, name), by = c("accepted_name" = "name"))


#write_tsv(gbif_synonyms, "data/gbif_synonyms.tsv.bz2")



