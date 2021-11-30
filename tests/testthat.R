library(testthat)
library(taxadb)

## Optionally we can select backend for testing: duckdb, MonetDBLite, or RSQLite
## Sys.setenv("TAXADB_DRIVER"="MonetDBLite")
test_check("taxadb")
