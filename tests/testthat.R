library(testthat)
library(taxadb)

Sys.setenv(TAXADB_DRIVER="MonetDBLite")
test_check("taxadb")
