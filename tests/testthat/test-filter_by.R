context("filter_by")


test_that("filter_common", {
  df <- filter_common("Angolan Giraffe")
  expect_is(df, "data.frame")
  match <- df %>%
    dplyr::filter(taxonID == "ITIS:1012250") %>%
    dplyr::pull(scientificName)
  expect_identical(match, "Giraffa giraffa angolensis")
})

test_that("filter_by", {

   sp <- c("Trochalopteron henrici gucenense",
           "Trochalopteron elliotii")
   sci <- filter_by(sp, "scientificName", ignore_case = TRUE)
   expect_gt(dim(sci)[1], 1)
   expect_is(sci, "data.frame")

   ids <- filter_by(c("ITIS:1077358", "ITIS:175089"), "taxonID")
   expect_is(ids, "data.frame")
   expect_gt(dim(ids)[1], 1)

   ids <- filter_by(c("ITIS:1077358", "ITIS:175089"), "acceptedNameUsageID")
   expect_is(ids, "data.frame")
   expect_gt(dim(ids)[1], 1)

   ranks <- filter_by("Trochalopteron", "genus")
   expect_is(ranks, "data.frame")
   expect_gt(dim(ranks)[1], 1)

})



test_that("filter_name", {

  sp <- c("Trochalopteron henrici gucenense",
          "Trochalopteron elliotii")
  sci <- filter_name(sp,  ignore_case = TRUE)
  expect_gt(dim(sci)[1], 1)
  expect_is(sci, "data.frame")
})


test_that("filter_id", {
  ids <- filter_id(c("ITIS:1077358", "ITIS:175089"))
  expect_is(ids, "data.frame")
  expect_gt(dim(ids)[1], 1)

  ids <- filter_id(c("ITIS:1077358", "ITIS:175089"), type = "acceptedNameUsageID")
  expect_is(ids, "data.frame")
  expect_gt(dim(ids)[1], 1)
})

test_that("filter_rank", {
  ranks <- filter_rank("Trochalopteron", "genus")
  expect_is(ranks, "data.frame")
  expect_gt(dim(ranks)[1], 1)
})

test_that("filter_common", {

  filter_common("man", "itis")

  expect_warning(x <- filter_common("man", "wd"),
                 "provider wd does not provide common names")
  expect_null(x)

})



