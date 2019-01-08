## Use taxizedb to download all data from original sources and establish in native database formats
## Then, use arkdb to extract all tables as tsv.bz2 files

## This script requires a postgres database and mariadb database be already set up
## and available using the user name, password, and connection addresses given below.

## Instead of running this code, cached copies of the extracted databases are avialable
## as a piggyback from the github repo.  Simply run:
##     piggyback::pb_download(repo = "cboettig/taxadb")


## Also need:
## apt-get -y install mariadb-client postgresql-client
library(readr)
library(arkdb)
library(taxizedb)
library(magrittr)

#### ITIS ###########
itis_store <- db_download_itis()
#db_load_itis(itis_store, user = "postgres", pwd = "password", host = "postgres") # locale issues
itis_db <- src_itis(user = "postgres", password = "password", host = "postgres")
ark(itis_db, fs::dir_create("taxizedb/itis"), streamable_table = streamable_readr_tsv(), lines = 1e5L)

#### TPL ##############
tpl <- db_download_tpl()
db_load_tpl(tpl, user = "postgres", pwd = "password", host = "postgres")
tpl_db <- src_tpl(user = "postgres", password = "password", host = "postgres")
ark(tpl_db, fs::dir_create("taxizedb/tpl"), streamable_table = streamable_readr_tsv(), lines = 1e5L)

##### NCBI ################
ncbi_store <- db_download_ncbi()
db_load_ncbi() ## not needed for ncbi
ncbi_db <- src_ncbi(ncbi_store)
ark(ncbi_db, fs::dir_create("taxizedb/ncbi"), streamable_table = streamable_readr_tsv(), lines = 1e5L)


### COL ###################
col <- db_download_col()
#db_load_col(col, host="mariadb", user="root", pwd="password")  ## Slow to rerun
col_db <- src_col(host="mariadb", user="root", password="password")
ark(col_db, fs::dir_create("taxizedb/col"), streamable_table = streamable_readr_tsv(), lines = 1e5L)


#### GBIF ############
#gbif <- db_download_gbif()
#db_load_gbif()## not needed
#gbif_db <- src_gbif(gbif)
#ark(gbif_db, fs::dir_create("taxizedb/gbif"), streamable_table = streamable_readr_tsv(), lines = 1e5L)


## GBIF DIRECT ###

## extracted from: https://doi.org/10.15468/39omei
download.file("http://rs.gbif.org/datasets/backbone/backbone-current.zip",
              "taxizedb/gbif/backbone.zip")
unzip("taxizedb/gbif/backbone.zip", exdir="taxizedb/gbif")
taxon <- read_tsv("taxizedb/gbif/Taxon.tsv")
common <- read_tsv("taxizedb/gbif/VernacularName.tsv")
fs::dir_ls("taxizedb/gbif/") %>% fs::file_delete()
## Cache original file:
write_tsv(taxon, "taxizedb/gbif/taxon.tsv.bz2")
write_tsv(common, "taxizedb/gbif/vernacular.tsv.bz2")


library(fs)
library(magrittr)
library(piggyback)
## ENSURE GitHub PAT is available for uploading -- developers only.
fs::dir_ls("taxizedb", type = "file", recursive = TRUE) %>%
  piggyback::pb_upload()
