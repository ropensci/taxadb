# remotes::install_github("cboettig/arkdb")

library(arkdb)

## FIXME currently only *_wide tables have id as unique to row.  
files <- fs::dir_ls("data/", glob="*wide.tsv.bz2")
db <- unark(files, dbname = "taxa.sqlite", lines = 1e6)

## Set id as primary key in each table.  

tbls <- DBI::dbListTables(db$con)

lapply(tbls, function(table)
glue::glue("ALTER TABLE {table} ADD PRIMARY KEY ({key});", 
           table = table, key = "id"))

DBI::dbDisconnect(db$con)

R.utils::bzip2("taxa.sqlite", remove = FALSE)

## Set up database connection from compressed file
R.utils::bunzip2("taxa.sqlite.bz2", remove = FALSE)

