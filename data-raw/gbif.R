## apt-get -y install mariadb-client postgresql-client
library(taxizedb) 
library(tidyverse)

#gbif <- db_download_gbif()
#db_load_gbif()## not needed
#gbif_db <- src_gbif(gbif)


piggyback::pb_download(repo="cboettig/taxadb")
gbif_taxa <- read_tsv("taxizedb/gbif/gbif.tsv.bz2")

gbif_taxa <- tbl(gbif_db, "gbif") %>% 
  select(taxon_id = taxonID, scientificName, rank= taxonRank, 
         kingdom, phylum, class = clazz, order = ordder, family, genus,
         canonicalName, genericName, taxonomicStatus,
         specificEpithet, infraspecificEpithet) %>% 
  collect()

gbif_taxa <- 
gbif_taxa %>% 
  left_join(gbif_taxa %>% 
              filter(rank == "species") %>% 
              select(taxon_id, species = scientificName))


gbif_wide <- gbif_taxa %>% 
  select(id = taxon_id, 
         kingdom, phylum, class, order, family, genus, species,
         specific_epithet = specificEpithet, infraspecific_epithet = infraspecificEpithet,
         genericName, taxonomicStatus)
write_tsv(gbif_wide, "data/gbif_hierarchy.tsv.bz2")
rm(gbif_wide)

gbif_long <- 
  gbif_taxa %>% 
  select(id = taxon_id, name = scientificName, rank = rank, genericName, taxonomicStatus)
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



