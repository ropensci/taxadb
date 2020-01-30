
## Optionally: Force a backend type, otherwise will use the best available
## (which is currently MonetDBLite, since it is suggested)
#Sys.setenv(TAXADB_DRIVER="MonetDBLite")
#Sys.setenv(TAXADB_DRIVER="RSQLite")

## All tests only write to tempdir
test_db <- file.path(tempdir(), "taxadb")
Sys.setenv(TAXADB_HOME=test_db)


## Use locally cached version to allow for offline testing
options(taxadb_default_provider = "itis_test")

