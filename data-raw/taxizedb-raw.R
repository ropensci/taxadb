
## apt -y install mariadb-client postgresql-client

library(arkdb)
library(taxizedb) # remotes::install_github("ropensci/taxizedb")

#### ITIS ###########
itis_store <- db_download_itis()
db_load_itis(itis_store, user = "postgres", pwd = "password", host = "postgres") # locale issues
itis_db <- src_itis(user = "postgres", password = "password", host = "postgres")
ark(itis_db, fs::dir_create("taxizedb/itis"), lines = 1e6L, overwrite = TRUE)

#### TPL ##############
tpl <- db_download_tpl()
db_load_tpl(tpl, user = "postgres", pwd = "password", host = "postgres")
tpl_db <- src_tpl(user = "postgres", password = "password", host = "postgres")
ark(tpl_db, fs::dir_create("taxizedb/tpl"), lines = 1e6L, overwrite = TRUE)

##### NCBI ################
ncbi_store <- db_download_ncbi()
db_load_ncbi() ## not needed for ncbi
ncbi_db <- src_ncbi(ncbi_store)
ark(ncbi_db, fs::dir_create("taxizedb/ncbi"), lines = 1e6L, overwrite = TRUE)

#### GBIF ############
gbif <- db_download_gbif()
db_load_gbif()## not needed
gbif_db <- src_gbif(gbif)
ark(gbif_db, fs::dir_create("taxizedb/gbif"), lines = 1e6L, overwrite = TRUE)

### COL ###################
#options(scipen = 100)
col <- db_download_col()
db_load_col(col, host="mariadb", user="root", pwd="password")  ## Slow to rerun
col_db <- src_col(host="mariadb", user="root", password="password")
ark(col_db, fs::dir_create("taxizedb/col"), lines = 1e6L, overwrite = TRUE)


## upload
fs::dir_ls("taxizedb", type = "file", recursive = TRUE) %>%
piggyback::pb_upload(repo = "cboettig/taxadb")
