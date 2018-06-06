## apt-get -y install mariadb-client postgresql-client
library(DBI)
library(dplyr)
library(dbplyr)
#remotes::install_github("ropensci/taxizedb")
library(taxizedb) 
library(readr)

col <- db_download_col()

## Working.  but why does db_load_col take forever every time!! Does this need to be re-run or not?
#db_load_col(col, host="mariadb", user="root", pwd="password")
col_db <- src_col(host="mariadb", user="root", password="password")


col_taxa <- tbl(col_db, "_species_details")  %>%
  collect()  ## Main table with taxon_id and full rank

# drop LSIDs, URIs are better.  (Unfortunately neither 
# ID numbers or LSIDs seems to provide a resolvable prefix)

drop <- grepl("\\w+_lsid$", names(col_taxa))
col_taxa <- col_taxa[!drop]

col_taxa <-
col_taxa %>% 
  select(taxon_id, kingdom_name, phylum_name, class_name, order_name,  superfamily_name, family_name, genus_name, subgenus_name, species_name, infraspecies_name,
       kingdom_id, phylum_id, class_id, order_id,  superfamily_id, family_id, genus_id, subgenus_id,  species_id,  infraspecies_id,
       is_extinct, status)

## Prefix identifiers
col_taxa <- col_taxa %>% 
  mutate_if(is.integer, function(x) paste0("COL:", x))

write_tsv(col_taxa, "data/col.tsv.bz2")


