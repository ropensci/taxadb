context("test connections")



test_that("we can use alternative DBs, such as SQLite", {
  
  skip_if(TRUE)
  skip_on_travis()
  skip_on_cran()
  
## NOTE: SQLite joins are waaaay slower than MonetDBLite
dbdir <- rappdirs::user_data_dir("taxald")
dir.create(dbdir, showWarnings = FALSE)
dbname <- file.path(dbdir, "taxald.sqlite")

db <- DBI::dbConnect(RSQLite::SQLite(), dbname = dbname)
                     
  
  td_create(db = db)
  td_create("ncbi", db = db)

  itis <- taxa_tbl(authority = "itis", 
                 schema = "hierarchy", 
                 db = db)
  ncbi <- taxa_tbl(authority = "ncbi", 
                 schema = "hierarchy", 
                 db = db)

  birds <- descendants(name = "Aves", 
                    rank = "class", 
                    db = db)
  mammals <- descendants(name = "Mammalia", 
                    rank = "class", 
                    db = db)
  
  ids <- ids(birds$species, 
                 db = db)
  hier <- classification(birds$species, 
                         db = db)

})