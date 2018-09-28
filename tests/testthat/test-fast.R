context("fast")

library(testthat)
library(taxald)
library(dplyr)


test_that("setup-free calls to basic functions", {
  
  df <- taxa_tbl(authority = "itis", schema = "hierarchy", db = NULL)
  chameleons <- filter(df, family == "Chamaeleonidae")
  
  df <- descendants(name = "Aves", rank = "class", db = NULL)
  species <- ids(df$species, db = NULL)
  hier <- classification(df$species, db = NULL)
  
  expect_is(df, "data.frame")
  expect_is(species, "data.frame")
  expect_is(hier, "data.frame")
  expect_is(chameleons, "data.frame")
  expect_gt(dim(df)[1], 1)
  expect_gt(dim(species)[1], 1)
  expect_gt(dim(hier)[1], 1)
  expect_gt(dim(chameleons)[1], 1)

})