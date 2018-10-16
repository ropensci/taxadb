
library(tidyverse)

# library(taxizedb)
## apt-get -y install mariadb-client postgresql-client

# gbif <- db_download_gbif()
# db_load_gbif()## not needed
# gbif_db <- src_gbif(gbif)

#gbif_taxa <- tbl(gbif_db, "gbif") %>% collect()


piggyback::pb_download(repo="cboettig/taxadb")
gbif_taxa <- read_tsv("taxizedb/gbif/gbif.tsv.bz2")

gbif_taxa <- gbif_taxa %>%
  ## Dear lord, who creates such wacky column names in the GBIF database?
  select(taxon_id = taxonID, scientificName, rank= taxonRank,
         kingdom, phylum, class = clazz, order = ordder, family, genus,
         canonicalName, genericName, taxonomicStatus,
         specificEpithet, infraspecificEpithet)

## canonicalName appears to be: Genus + specificEpithet + infraspecificEpithet
## i.e. SpecificEpithet ~ a name at the "species" rank
## Scientifi name is ~ canonical name + citation parenthetical

## ~  273,132 species have epithets in the canonical names

gbif_taxa <-
gbif_taxa %>%
  rename(species = specificEpithet,
         epithet = infraspecificEpithet) %>%
  mutate(taxon_id = paste0("GBIF:", taxon_id))


gbif_wide <- gbif_taxa %>%
  select(id = taxon_id,
         kingdom, phylum, class, order, family, genus, species, epithet,
         genericName, taxonomicStatus)
write_tsv(gbif_wide, "data/gbif_hierarchy.tsv.bz2")
rm(gbif_wide)





gbif_long <-
  gbif_taxa %>%
  select(id = taxon_id, name = canonicalName, rank = rank, genericName, taxonomicStatus)
write_tsv(gbif_long, "data/gbif_long.tsv.bz2")

gbif_long %>%
  filter(taxonomicStatus == "accepted") %>%
  select(id, name, rank) %>%
  distinct() %>%
write_tsv("data/gbif_taxonid.tsv.bz2")

gbif_synonyms <- gbif_long %>%
  filter(taxonomicStatus != "accepted") %>%
  select(id, accepted_name = name, rank, name = genericName, name_type = taxonomicStatus) %>%
  distinct()


write_tsv(gbif_synonyms, "data/gbif_synonyms.tsv.bz2")



