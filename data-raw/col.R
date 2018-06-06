## apt-get -y install mariadb-client postgresql-client
library(DBI)
library(dplyr)
library(dbplyr)
#remotes::install_github("ropensci/taxizedb")
library(taxizedb) 
library(readr)

col <- db_download_col()

## Working.  but why does db_load_col take forever every time!! Does this need to be re-run or not?
db_load_col(col, host="mariadb", user="root", pwd="password")

col_db <- src_col(host="mariadb", user="root", password="password")


col_taxa <- tbl(col_db, "_species_details")  %>%
  collect()  ## Main table with taxon_id and full rank
write_tsv(col_taxa, "data/col.tsv.bz2")

rm(col_taxa)

