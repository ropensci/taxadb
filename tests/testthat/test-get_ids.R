context("get_ids")

test_that("we can use get_ids options", {

  db <- td_connect(test_db)

  bare <- get_ids("Homo sapiens", taxadb_db = db)
  expect_identical(bare, "180092")

  some_ids <- get_ids(c("Homo sapiens", "Mammalia"),
                      format = "prefix", taxadb_db = db)

  expect_identical(some_ids,  c("ITIS:180092", "ITIS:179913"))
  uri <- get_ids("Homo sapiens", db= "ncbi", format = "uri", taxadb_db = db)
  expect_identical("http://ncbi.nlm.nih.gov/taxonomy/9606",
                   uri)
})


test_that("we can get ids without a DB", {

  db <- td_connect(test_db)

  bare <- get_ids("Homo sapiens", taxadb_db = NULL)
  expect_identical(bare, "180092")

})
