context("taxadb")

library(testthat)
library(taxadb)
library(dplyr)


test_that("we can set up a db and call basic functions", {



  td_create(dbdir = test_db)
  db <- td_connect(test_db)

  df <- taxa_tbl(authority = "itis",
                 db = db)

  chameleons <- df %>%
    filter(family == "Chamaeleonidae") %>%
    collect()

  df <- descendants(name = "Aves",
                    rank = "class",
                    db = db)


  species <- ids(df$scientificName,
                 db = db)

  # FIXME
  ## confirm order did not change
  # expect_identical(df$scientificName, species$scientificName)

  hier <- classification(df$scientificName,
                         db = db)

  expect_is(df, "data.frame")
  expect_is(species, "data.frame")
  expect_is(hier, "data.frame")
  expect_is(chameleons, "data.frame")
  expect_gt(dim(df)[1], 1)
  expect_gt(dim(hier)[1], 1)
  expect_gt(dim(chameleons)[1], 1)

})
