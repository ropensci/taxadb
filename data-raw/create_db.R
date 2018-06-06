library(readr)
library(dplyr)
library(DBI)
library(R.utils)

itis <- read_tsv("data/itis.tsv.bz2")
ncbi <- read_tsv("data/ncbi.tsv.bz2")

taxa <- bind_rows(itis, ncbi)

db_path <- "data/taxa.sql"
con <- dbConnect(RSQLite::SQLite(), dbname=db_path)
dbListTables(con)
dbWriteTable(con, "taxa", taxa)
dbDisconnect(con)
R.utils::bzip2(db_path)

