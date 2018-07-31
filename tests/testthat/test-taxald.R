library(taxald)
library(dplyr)
library(tictoc)


testthat::test_that("we can set up a db and call basic functions", {
  
  tmp <- tempdir()
  Sys.setenv(TAXALD_HOME=tmp)
  
  tic()
  create_taxadb()
  toc()
  
  tic()
  df <- taxa_tbl(authority = "itis", schema = "hierarchy")
  chameleons <- df %>% filter(family == "Chamaeleonidae") %>% collect()
  
  df <- descendants(name = "Aves", rank = "class")
  species <- ids(df$species)
  hier <- classification(df$species)
  
  testthat::expect_is(df, "data.frame")
  testthat::expect_is(species, "data.frame")
  testthat::expect_is(hier, "data.frame")
  testthat::expect_is(chameleons, "data.frame")
  
  testthat::expect_gt(dim(df)[1], 1)
  testthat::expect_gt(dim(species)[1], 1)
  testthat::expect_gt(dim(hier)[1], 1)
  testthat::expect_gt(dim(chameleons)[1], 1)
  toc()

})