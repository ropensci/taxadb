## apt-get -y install mariadb-client postgresql-client
library(DBI)
library(dplyr)
library(dbplyr)
#remotes::install_github("ropensci/taxizedb")
library(taxizedb) 
library(readr)


gbif <- db_download_gbif()
itis <- db_download_itis()
tpl <- db_download_tpl()
col <- db_download_col()
ncbi <- db_download_ncbi()

## Working.  but why does db_load_col take forever every time!! Does this need to be re-run or not?
db_load_col(col, host="mariadb", user="root", pwd="password")
db_load_tpl(tpl, user = "postgres", pwd = "password", host = "postgres")
## Need to fix locale issue
db_load_itis(itis, user = "postgres", pwd = "password", host = "postgres")
## not needed:
db_load_ncbi()
db_load_gbif()

col_db <- src_col(host="mariadb", user="root", password="password")
tpl_db <- src_tpl(user = "postgres", password = "password", host = "postgres")
itis_db <- src_itis(user = "postgres", password = "password", host = "postgres")
gbif_db <- src_gbif(gbif)
ncbi_db <- src_ncbi(ncbi)

ncbi_taxa <- inner_join(tbl(ncbi_db, "nodes"), tbl(ncbi_db, "names")) %>%
  select(tax_id, parent_tax_id, rank, name_txt, unique_name, name_class) %>%
  collect()
write_tsv(ncbi_taxa, "data/ncbi.tsv.bz2")
rm(ncbi_taxa)

tpl_taxa <- tbl(tpl_db, "plantlist")  %>%
  collect()  ## Only table
write_tsv(tpl_taxa, "data/tpl.tsv.bz2")
rm(tpl_taxa)

gbif_taxa <- tbl(gbif_db, "gbif")  %>%
  collect() ## Only table
write_tsv(gbif_taxa, "data/gbif.tsv.bz2")
rm(gbif_taxa)

col_taxa <- tbl(col_db, "_species_details")  %>%
  collect()  ## Main table with taxon_id and full rank
write_tsv(col_taxa, "data/col.tsv.bz2")
rm(col_taxa)


itis_taxa <- 
left_join(
  inner_join(
    tbl(itis_db, "taxonomic_units") %>% select(tsn, parent_tsn, rank_id, complete_name) %>% distinct(),
    tbl(itis_db, "taxon_unit_types") %>% select(rank_id, rank_name)  %>% distinct()
  ), 
  tbl(itis_db, "hierarchy") %>% select(tsn, parent_tsn, hierarchy_string)
) %>% 
  arrange(tsn) %>% 
  select(tsn, complete_name, rank_name, rank_id, parent_tsn, hierarchy_string) %>%
  collect()

## write at compression 9 for best compression
write_tsv(itis_taxa, "data/itis.tsv.bz2")

## gunzip, compression 6. A default that offers widespread implementation
## quite fast compression / decompression, achieves nearly as small files as bz2,
## better than .zip or fst
system.time({
write_tsv(itis_taxa, "data/itis.tsv.gz")
})

rm(itis_taxa)



#
#itis_units %>% select(tsn, rank_id, complete_name, taxon_author_id, credibility_rtng, completeness_rtng, update_date)
