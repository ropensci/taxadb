## get_ids() and get_names() are documented as inverses across all three
## identifier formats.  Each of these round trips was broken.

test_that("identifiers round trip in every format", {
  withr::local_options(taxadb_default_provider = "itis_test")
  for(fmt in c("prefix", "bare", "uri")){
    id <- get_ids("Homo sapiens", format = fmt)
    expect_false(is.na(id), info = fmt)
    expect_identical(get_names(id), "Homo sapiens", info = fmt)
  }
})

test_that("get_names returns NA for an unmatched id rather than erroring", {
  withr::local_options(taxadb_default_provider = "itis_test")
  out <- get_names(c("ITIS:180092", "ITIS:99999999"))
  expect_length(out, 2)
  expect_identical(out[[1]], "Homo sapiens")
  expect_true(is.na(out[[2]]))
})

test_that("get_names accepts bare ids for the test provider", {
  withr::local_options(taxadb_default_provider = "itis_test")
  ## The provider is itis_test but its identifiers are ITIS:, so the prefix
  ## to add to a bare id is the provider's own without the _test suffix.
  expect_identical(get_names("180092"), "Homo sapiens")
})
