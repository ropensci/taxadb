context("handling duplicates")

test_that("we can take first duplicate", {

  df <- data.frame(scentificName = c("bob", "bob", "alice"),
                   rank = c("subfamily", "family", "genus"),
                   sort = c(1,1,2), stringsAsFactors = FALSE)

  out <- take_first_duplicate(df)
  expect_equal(nrow(out), 2)


  ## minimal test for known regression in dplyr release candidate,
  ## https://github.com/tidyverse/dplyr/issues/4983
  #con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:" )
  #dplyr::copy_to(con, df, "test_count")
  #df_remote <- dplyr::tbl(con, "test_count")
  #count(df_remote, sort)


  ## check this on remote backends: RSQLite, duckdb etc
  con <- td_connect(driver = "RSQLite")
  dplyr::copy_to(con, df, "test_dups")
  df_remote <- dplyr::tbl(con, "test_dups")
  out2 <- collect(take_first_duplicate(df_remote))
  expect_equal(nrow(out2), 2)

})
