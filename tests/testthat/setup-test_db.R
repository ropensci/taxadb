

taxadb:::td_disconnect()
test_db <- file.path(tempdir(), "taxadb")
#dir.create(test_db, showWarnings = FALSE)
Sys.setenv(TAXADB_HOME=test_db)
Sys.setenv(TAXADB_DRIVER="MonetDBLite")

## Consider adding some minimal subset of, say, ITIS data file that
## would allow offline testing.  Currently pretty much all tests first
## require some access to the online data caches

