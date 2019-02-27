context("test connections")

test_that("we can detect locked connections", {

  skip("not implemented yet")
  dbpath <- file.path(test_db, "monetdblite")
  dir.create(dbpath, FALSE, TRUE)
  lockfile <- file.path(dbpath, ".gdk_lock")
  write("", lockfile)
  expect_error(td_connect(test_db), "Cannot connect")

})


test_that("we can use alternative DBs, such as SQLite", {

  skip_on_cran()
  skip_on_appveyor()
  skip_on_travis() #hmMMM?

  ## NOTE: SQLite joins are waaaay slower than MonetDBLite
  dbdir <- tempdir()
  dbname <- file.path(dbdir, "taxadb.sqlite")

  db <- DBI::dbConnect(RSQLite::SQLite(), dbname = dbname)

  ## new readr bug https://github.com/tidyverse/readr/issues/939
  setOldClass(c("spec_tbl_df", "data.frame"))

  ## and here we go.
  td_create(schema = "hierarchy", db = db)
  itis <- taxa_tbl(provider = "itis",
                   schema = "hierarchy",
                   db = db)
  DBI::dbDisconnect(db)
  unlink(dbname)
})
