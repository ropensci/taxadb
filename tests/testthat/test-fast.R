context("fast")

library(testthat)
library(taxadb)
library(dplyr)


test_that("setup-free calls to basic functions", {

  skip_on_cran()
  skip_if_offline()

  suppressWarnings({
  df <- taxa_tbl(provider = "itis_test", db = NULL)
  sp <- filter(df, family == "Hominidae")

  expect_is(df, "tbl")
  expect_is(sp, "tbl")

  df <- filter_rank(name = "Hominidae", rank = "family", provider = "itis_test", db = NULL)
  species <- filter_name("Pan troglodytes", provider = "itis_test", db = NULL)
  })


})
