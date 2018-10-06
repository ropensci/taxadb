context("taxald")

library(testthat)
library(taxald)
library(dplyr)


test_that("we can set up a db and call basic functions", {
  
  skip_if(TRUE)
  skip_on_travis()
  skip_on_cran()
  
  schema <- c("hierarchy", "taxonid", "synonyms")
  overwrite = TRUE
  td_create(authorities = "itis", schema = schema, overwrite = overwrite)
  td_create(authorities = "ncbi", schema = schema, overwrite = overwrite)
  td_create(authorities = "col", schema = schema)
  td_create(authorities = "tpl")
  td_create(authorities = "gbif", schema = c("hierarchy"))
  td_create(authorities = "fb")
  td_create(authorities = "slb")
  td_create(authorities = "wd")
  
  
  td_create(authorities = "all")

  
  
  df <- taxa_tbl(authority = "col", schema = "hierarchy")
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