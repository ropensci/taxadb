context("filter_by")

## All tests only write to tempdir
test_db <- file.path(tempdir(), "taxadb")
Sys.setenv(TAXADB_HOME=test_db)
## Use locally cached version to allow for offline testing
options(taxadb_default_provider = "itis_test")


test_that("filter_common", {
  df <- filter_common("Tufted Capuchin")
  expect_is(df, "data.frame")
  match <- df %>%
    dplyr::filter(taxonID == "ITIS:944156") %>%
    dplyr::pull(scientificName)
  expect_identical(match, "Sapajus apella")
})

test_that("filter_by", {

   sp <- c("Sapajus apella",
           "Cebus niger")
   sci <- filter_by(sp, "scientificName", ignore_case = FALSE)
   expect_gt(dim(sci)[1], 1)
   expect_is(sci, "data.frame")

   ids <- filter_by(c("ITIS:944156", "ITIS:944402"), "taxonID")
   expect_is(ids, "data.frame")
   expect_gt(dim(ids)[1], 1)

   ids <- filter_by(c("ITIS:944156", "ITIS:944402"), "acceptedNameUsageID")
   expect_is(ids, "data.frame")
   expect_gt(dim(ids)[1], 0)

   ranks <- filter_by("Sapajus", "genus")
   expect_is(ranks, "data.frame")
   expect_gt(dim(ranks)[1], 0)

})



test_that("filter_name", {

  sp <- c("sapajus apella")
  sci <- filter_name(sp,  ignore_case = TRUE)
  expect_gt(dim(sci)[1], 0)
  expect_is(sci, "data.frame")
})


test_that("filter_id", {
  ids <- filter_id(c("ITIS:944156", "ITIS:944402"))
  expect_is(ids, "data.frame")
  expect_gt(dim(ids)[1], 1)

  ids <- filter_id(c("ITIS:944156", "ITIS:944402"), type = "acceptedNameUsageID")
  expect_is(ids, "data.frame")
  expect_gt(dim(ids)[1], 0)
})

test_that("filter_rank", {
  ranks <- filter_rank("Sapajus", "genus")
  expect_is(ranks, "data.frame")
  expect_gt(dim(ranks)[1], 1)
})

test_that("filter_common", {

  filter_common("man", "itis_test")

  expect_warning(x <- filter_common("man", "wd"),
                 "provider wd does not provide common names")
  expect_null(x)

})



