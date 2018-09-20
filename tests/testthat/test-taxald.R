context("taxald")

library(testthat)
library(taxald)
library(dplyr)


test_that("we can set up a db and call basic functions", {
  
  tmp <- tempdir()
  Sys.setenv(TAXALD_HOME=tmp)
  
  create_taxadb()

  df <- taxa_tbl(authority = "itis", schema = "hierarchy")
  chameleons <- df %>% filter(family == "Chamaeleonidae") %>% collect()
  
  df <- descendants(name = "Aves", rank = "class")
  species <- ids(df$species)
  hier <- classification(df$species)
  
  expect_is(df, "data.frame")
  expect_is(species, "data.frame")
  expect_is(hier, "data.frame")
  expect_is(chameleons, "data.frame")
  expect_gt(dim(df)[1], 1)
  expect_gt(dim(species)[1], 1)
  expect_gt(dim(hier)[1], 1)
  expect_gt(dim(chameleons)[1], 1)

})