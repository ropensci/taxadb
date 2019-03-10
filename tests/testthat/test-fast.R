context("fast")

library(testthat)
library(taxadb)
library(dplyr)


test_that("setup-free calls to basic functions", {

  df <- taxa_tbl(provider = "itis", db = NULL)
  chameleons <- filter(df, family == "Chamaeleonidae")

  df <- by_rank(name = "Aves", rank = "class", db = NULL)
  species <- by_name(df$scientificName, db = NULL)

  expect_is(df, "data.frame")
  expect_is(species, "data.frame")
  expect_is(chameleons, "data.frame")
  expect_gt(dim(df)[1], 1)
  expect_gt(dim(chameleons)[1], 1)

})
