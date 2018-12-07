context("test connections")

test_that("we can detect locked connections", {

  dbpath <- file.path(test_db, "monetdblite")
  dir.create(dbpath, FALSE, TRUE)
  lockfile <- file.path(dbpath, ".gdk_lock")
  write("", lockfile)
  expect_error(td_connect(test_db), "Cannot connect")

})


test_that("we can use alternative DBs, such as SQLite", {

  skip_on_cran()

  ## NOTE: SQLite joins are waaaay slower than MonetDBLite
  dbdir <- tempdir()
  dbname <- file.path(dbdir, "taxald.sqlite")

  db <- DBI::dbConnect(RSQLite::SQLite(), dbname = dbname)
  td_create("hierarchy", db = db)
  itis <- taxa_tbl(authority = "itis",
                   schema = "hierarchy",
                   db = db)
  DBI::dbDisconnect(db)
  unlink(dbname)
})
