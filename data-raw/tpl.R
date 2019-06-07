## apt-get -y install mariadb-client postgresql-client
## remotes::install_github("ropensci/taxizedb")
library(taxizedb)
library(tidyverse)
library(stringi)
tpl <- db_download_tpl()
db_load_tpl(tpl, user = "postgres", pwd = "password", host = "postgres")
tpl_db <- src_tpl(user = "postgres", password = "password", host = "postgres")
#
tpl_taxa <- tbl(tpl_db, "plantlist")  %>% collect()  ## Only table
write_tsv(tpl_taxa, "data/tpl.tsv.bz2")

tpl_taxa <- read_tsv("taxizedb/tpl/plantlist.tsv.bz2")

## note: only has accepted names
# tpl_taxa %>% count(taxonomic_status_in_tpl)
tpl_dwc <- tpl_taxa %>%
  mutate(id = stri_paste("TPL:", id),
         scientificName = stri_paste(genus, species),
         taxonRank = "species",
         taxonomicStatus = "accepted",
         acceptedNameUsageID = id,
         kingdom = "plantae", phylum = NA, class = NA, order = NA)  %>%
  select(taxonID = id,
         scientificName,
         taxonRank,
         acceptedNameUsageID,
         kingdom, phylum, class, order, family, genus,
         specificEpithet = species,
         infraspecificEpithet = infraspecific_epithet,
         scientificNameAuthorship = authorship,
         namePublishedInYear = date,
         nomenclaturalStatus = nomenclatural_status_from_original_data_source)
write_tsv(tpl_dwc, "dwc/dwc_tpl.tsv.bz2")





