# remotes::install_github("cboettig/arkdb")

# Fixme: "order" is a reserved name in SQL.  
## MonetDb SQL also complains about capitalized names

library(arkdb)
library(DBI)
library(MonetDBLite)
library(fs)
library(dbplyr)

## FIXME currently only *_wide tables have id as unique to row.  
#files <- fs::dir_ls("data/", glob="*wide.tsv.bz2")
files <- fs::dir_ls("data/", glob="*.tsv.bz2")



# test if MonetDBLite can handle the imports directly:
# dbWriteTable(con, "mtcars2", csvfile)

dbdir <- fs::dir_create("taxadb")
db <- dbplyr::src_dbi(dbConnect(MonetDBLite::MonetDBLite(), dbdir))

unark(files, db, lines = 1e6)

## Set id as primary key in each table.  

tbls <- DBI::dbListTables(db$con)

lapply(tbls, function(table)
glue::glue("ALTER TABLE {table} ADD PRIMARY KEY ({key});", 
           table = table, key = "id"))

DBI::dbDisconnect(db$con)

R.utils::bzip2("taxa.sqlite", remove = FALSE)

## Set up database connection from compressed file
R.utils::bunzip2("taxa.sqlite.bz2", remove = FALSE)

