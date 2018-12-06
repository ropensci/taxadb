context("get_ids")

test_that("we can use get_ids options", {

  db <- td_connect(test_db)

  bare <- get_ids("Homo sapiens", taxald_db = db)
  expect_identical(bare, "180092")

  some_ids <- get_ids(c("Homo sapiens", "Mammalia"),
                      format = "prefix", taxald_db = db)

  expect_identical(some_ids,  c("ITIS:180092", "ITIS:179913"))
  uri <- get_ids("Homo sapiens", db= "ncbi", format = "uri", taxald_db = db)
  expect_identical("https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=9606",
                   uri)
})


test_that("we can get ids without a DB", {

  db <- td_connect(test_db)

  bare <- get_ids("Homo sapiens", taxald_db = NULL)
  expect_identical(bare, "ITIS:180092")

})
