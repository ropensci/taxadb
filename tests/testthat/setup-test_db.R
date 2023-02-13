
## Optionally: Force a backend type, otherwise will use the best available
## (which is currently MonetDBLite, since it is suggested)
#Sys.setenv(TAXADB_DRIVER="MonetDBLite")
#Sys.setenv(TAXADB_DRIVER="RSQLite")
#Sys.setenv(TAXADB_DRIVER="duckdb")

## All tests only write to tempdir
Sys.setenv(CONTENTID_HOME=tempfile())

## Use locally cached version to allow for offline testing
#options(taxadb_default_provider = "itis_test")
