context("handling duplicates")

test_that("we can take first duplicate", {

  df <- data.frame(scentificName = c("bob", "bob", "alice"),
                   rank = c("subfamily", "family", "genus"),
                   sort = c(1,1,2), stringsAsFactors = FALSE)

  out <- take_first_duplicate(df)
  expect_equal(nrow(out), 2)

})

