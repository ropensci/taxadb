

taxadb:::td_disconnect()
test_db <- file.path(tempdir(), "taxadb")
#dir.create(test_db, showWarnings = FALSE)
Sys.setenv(TAXADB_HOME=test_db)

