## apt-get -y install mariadb-client postgresql-client
library(DBI)
library(dplyr)
library(dbplyr)
#remotes::install_github("ropensci/taxizedb")
library(taxizedb) 
library(readr)


gbif <- db_download_gbif()
db_load_gbif()## not needed
gbif_db <- src_gbif(gbif)


gbif_taxa <- tbl(gbif_db, "gbif")  %>%
  collect() ## Only table
write_tsv(gbif_taxa, "data/gbif.tsv.bz2")
rm(gbif_taxa)


