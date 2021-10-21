context("fast")

library(testthat)
library(taxadb)
library(dplyr)


test_that("setup-free calls to basic functions", {

  skip_on_cran()
  skip_if_offline()

  df <- taxa_tbl(provider = "itis_test", db = NULL)
  sp <- filter(df, family == "Hominidae")

  suppressWarnings({
  df <- filter_rank(name = "Hominidae", rank = "family", provider = "itis_test", db = NULL)
  species <- filter_name("Pan troglodytes", provider = "itis_test", db = NULL)
  })

  expect_is(df, "data.frame")
  expect_is(sp, "data.frame")
  expect_gt(dim(df)[1], 1)
  expect_gt(dim(sp)[1], 1)

})
