context("taxadb")

library(testthat)
library(taxadb)
library(dplyr)


test_that("we can set up a db and call basic functions", {

  td_create(dbdir = test_db)
  db <- td_connect(test_db)

  df <- taxa_tbl(provider = "itis",
                 db = db)

  chameleons <- df %>%
    filter(family == "Chamaeleonidae") %>%
    collect()

  df <- filter_rank(name = "Aves",
                    rank = "class",
                    db = db)  %>%
    filter(taxonomicStatus == "accepted")


  species <- filter_name(df$scientificName,
                 db = db) %>%
    filter(taxonomicStatus == "accepted")

  ## confirm order did not change
  expect_identical(df$scientificName, species$scientificName)


  expect_is(df, "data.frame")
  expect_is(species, "data.frame")
  expect_is(chameleons, "data.frame")
  expect_gt(dim(df)[1], 1)
  expect_gt(dim(chameleons)[1], 1)

  ## we can opt out of ignore_case on ids():
  species <- filter_name(df$scientificName,
                 db = db,
                 ignore_case = FALSE) %>%
    filter(taxonomicStatus == "accepted")
  expect_is(species, "data.frame")
  expect_gt(dim(species)[1], 1)


  ## filter_id() takes IDs instead of names:
  names <- filter_id(id = df$taxonID,
                 db = db)
  expect_is(names, "data.frame")
  expect_gt(dim(names)[1], 1)

  ## Test synonyms: We can
  ## get synonyms for the accepted names:
  syns <- synonyms(df$scientificName,
                 db = db)
  expect_is(syns, "data.frame")
  expect_gt(dim(syns)[1], 1)


})
