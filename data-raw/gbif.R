
library(tidyverse)
source("data-raw/helper-routines.R")

piggyback::pb_download(repo="cboettig/taxadb", tag = "data") # raw data cache
taxon <- read_tsv("taxizedb/gbif/taxon.tsv.bz2")

gbif_taxa <- taxon %>%
  select(id = taxonID, scientificName, rank= taxonRank,
         kingdom, phylum, class, order, family, genus,
         canonicalName, genericName, taxonomicStatus,
         specificEpithet, infraspecificEpithet)  %>%
  rename(species = specificEpithet,
         epithet = infraspecificEpithet) %>%
  mutate(id = paste0("GBIF:", id),
         species = paste(genus, species, epithet))

## canonicalName appears to be: Genus + specificEpithet + infraspecificEpithet
## i.e. SpecificEpithet ~ a name at the "species" rank
## Scientific name is ~ canonical name + citation parenthetical

## ~  273,132 species have epithets in the canonical names


gbif_wide <- gbif_taxa  %>%
  filter(taxonomicStatus == "accepted") %>%
  select(id,
         kingdom, phylum, class, order, family, genus, species, epithet,
         genericName)
write_tsv(gbif_wide, "data/gbif_hierarchy.tsv.bz2")
rm(gbif_wide)

## Ids not available on higher-order ranks, so not listed
gbif_taxonid <-
  gbif_taxa %>%
  select(id,
         name = canonicalName,
         rank = rank,
         name_type = taxonomicStatus) %>%
  de_duplicate()

  write_tsv(gbif_taxonid, "data/gbif_taxonid.tsv.bz2")

# gbif_synonyms <- gbif_long %>%
#   filter(taxonomicStatus != "accepted") %>%
#   select(synonym_id = id, accepted_name = name, rank, name = genericName, type = taxonomicStatus) %>%
#   distinct()
#
# syn_temp <- left_join(gbif_synonyms, select(gbif_synonyms, id = synonym_id, name), by = c("accepted_name" = "name"))


#write_tsv(gbif_synonyms, "data/gbif_synonyms.tsv.bz2")



