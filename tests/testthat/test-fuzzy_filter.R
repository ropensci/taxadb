context("fuzzy filter")

test_that("we can fuzzy match scientific and common names", {

  name <- c("woodpecker", "monkey")
  df <- fuzzy_filter(name, "vernacularName", "itis_test")
  expect_is(df, "data.frame")
  expect_gt(dim(df)[1], 1)


  df <- fuzzy_filter("Homo ", "scientificName", "itis_test",
                match = "starts_with", ignore_case = FALSE)
  expect_is(df, "data.frame")
  expect_gte(dim(df)[1], 1)



})

test_that("we can fuzzy match scientific and common names", {

  name <- c("woodpecker", "monkey")
  df <- common_contains(name, "itis_test")
  expect_is(df, "data.frame")
  expect_gte(dim(df)[1], 1)
  df <- common_starts_with(name, "itis_test")
  expect_is(df, "data.frame")


  df <- name_starts_with("Homo ", "itis_test",
                     ignore_case = FALSE)
  expect_is(df, "data.frame")
  expect_gte(dim(df)[1], 1)
  df <- name_contains("Homo", "itis_test")
  expect_is(df, "data.frame")
  expect_gte(dim(df)[1], 1)


})
