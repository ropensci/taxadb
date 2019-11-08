context("clean_names")

test_that("set_space_delim", {
  x <- set_space_delim("Poa annua. ")
  expect_identical(x, "Poa annua")
})

test_that("drop_sp.", {
  x <- drop_sp.("Poa sp.")
  expect_identical(x, "Poa")
})

test_that("binomial_names", {
  x <- binomial_names("Homo")
  expect_identical(x, "Homo")

  x <- binomial_names("Homo sapiens sapiens")
  expect_identical(x, "Homo sapiens")

})

#  not an option in clean_names() yet
test_that("drop_parenthetical", {
  drop_parenthetical("Poa annua (Smith 1912)")
})

test_that("drop_punc", {
  x <- drop_punc("Stellar's jay")
  expect_identical(x, "Stellars jay")
})

test_that("clean_names", {
  x <- clean_names(" Poa annua, sp. (Smith 1912)", remove_punc = TRUE)
  expect_identical(x, "poa annua")
})
