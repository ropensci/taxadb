context("handling duplicates")

df <- data.frame(scentificName = c("bob", "bob", "alice"),
                 rank = c("subfamily", "family", "genus"),
                 sort = c(1, 1, 2), stringsAsFactors = FALSE)

test_that("we can take first duplicate", {

  out <- take_first_duplicate(df)
  expect_equal(nrow(out), 2)

})

test_that("take_first_duplicate works in db connection", {

  db <- DBI::dbConnect(duckdb::duckdb())

  df_db <-
    df %>%
    dplyr::copy_to(
      dest = db,
      name = "test-changes"
    )

  out <- take_first_duplicate(df_db)
  expect_equal(nrow(out), 2)

  DBI::dbDisconnect(db)

})

