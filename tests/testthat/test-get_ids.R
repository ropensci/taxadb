context("get_ids")

test_that("we can use get_ids options", {

  bare <- get_ids("Homo sapiens", format="bare", provider = "itis_test")
  expect_identical(bare, "180092")

  some_ids <- get_ids(c("Homo sapiens", "Sapajus apella"),
                      format = "prefix", provider = "itis_test")

  expect_identical(some_ids,  c("ITIS:180092", "ITIS:944156"),)
  uri <- get_ids("Homo sapiens", format = "uri", provider =  "itis_test")
  expect_identical("http://www.itis.gov/servlet/SingleRpt/SingleRpt?search_topic=TSN&search_value=180092",
                   uri)
})



test_that("NA handling", {

  x <- i_or_na(character(0L), 1)
  expect_true(is.na(x))

})

