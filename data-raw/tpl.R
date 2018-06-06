## apt-get -y install mariadb-client postgresql-client
library(taxizedb) 
library(tidyverse)

tpl <- db_download_tpl()


db_load_tpl(tpl, user = "postgres", pwd = "password", host = "postgres")


tpl_db <- src_tpl(user = "postgres", password = "password", host = "postgres")

tpl_taxa <- tbl(tpl_db, "plantlist")  %>%
  collect()  ## Only table
write_tsv(tpl_taxa, "data/tpl.tsv.bz2")
rm(tpl_taxa)
