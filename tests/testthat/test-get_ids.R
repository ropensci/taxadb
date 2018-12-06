context("get_ids")

test_that("we can use get_ids options", {

  bare <- get_ids("Homo sapiens")
  expect_identical(bare, "ITIS:180092")
  some_ids <- get_ids(c("Homo sapiens", "Mammalia"), format = "prefix")
  expect_identical(some_ids,  c("ITIS:180092", "ITIS:179913"))
  uri <- get_ids("Homo sapiens", db= "ncbi", format = "uri")
  expect_identical("https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=9606",
                   uri)
})
