context("clean_names")

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

