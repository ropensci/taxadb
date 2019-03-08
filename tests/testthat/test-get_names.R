
context("get_names()")
library(dplyr)

test_that("we can convert various ids to prefixes", {
  x <- id_to_prefix(1, "ott")
  expect_identical(x, "OTT:1")

  x <- id_to_prefix("OTT:1", "ott")
  expect_identical(x, "OTT:1")

  x <- id_to_prefix("1", "ott")
  expect_identical(x, "OTT:1")



  x <- id_to_prefix("https://tree.opentreeoflife.org/opentree/ottol@1", provider = "ott")
  expect_identical(x, "OTT:1")
})



test_that("we can convert id vectors to prefixes", {
  x <- as_prefix("OTT:1", "ott")
  expect_identical(x, "OTT:1")

  x <- as_prefix(list(5,
                      "https://tree.opentreeoflife.org/opentree/ottol@6",
                      "OTT:1"
                      ), "ott")
  expect_identical(x, c("OTT:5", "OTT:6", "OTT:1"))

})

test_that("Only repeated sort ids should be de-duplicated", {
  df <- tibble(sort = 1:26, scientificName = LETTERS) %>%
    bind_rows(tibble(sort = 1:3, scientificName =LETTERS[1:3]))

  out <- take_first_duplicate(df)
  expect_equal(dim(out)[1], 26)
})

test_that("de-duplication does not drop input", {

  ## same sci name multiple times is ok:
  df <- tibble(sort = 1:26, scientificName = LETTERS) %>%
    bind_rows(tibble(sort = 27:29, scientificName =LETTERS[1:3]))
  out <- take_first_duplicate(df)
  expect_equal(dim(out)[1], 29)

  df <- tibble(sort = 1:26, scientificName = c(LETTERS[1:13], LETTERS[1:13]))
  out <- take_first_duplicate(df)
  expect_equal(dim(out)[1], 26)

  df <- tibble(sort = 1:26, scientificName = LETTERS)
  out <- take_first_duplicate(df)
  expect_equal(dim(out)[1], 26)

})




test_that("we can handle more intensive comparisons: ITIS", {

  db <- td_connect(test_db)

  itis_id <- taxa_tbl("itis", db = db) %>% pull(taxonID)
  itis_accepted_id <-  taxa_tbl("itis", db = db) %>% pull(acceptedNameUsageID)

  system.time({
  itis_accepted_name <- get_names(itis_accepted_id, "itis",
                                  format="prefix", taxadb_db = db)
  })

  system.time({
  itis_name <- get_names(itis_id, "itis", format = "prefix", taxadb_db = db)
  })

  ## In ITIS: All IDs should resolve to one unique name
  expect_equal(sum(is.na(itis_name)), 0)
  expect_equal(length(itis_name), length(itis_id))
})


  ## This need not be true of acceptedNameUsage and acceptedNameUsageID --
  ## some names will have no known accepted ID.

test_that("we can handle more intensive comparisons: COL", {

  skip("testing all of COL is slow, using unit-test instead...")
  db <- td_connect(test_db)

  ### Tested on oher dbs too, but slow so skip for now
  col_accepted_id <-  taxa_tbl("col", db = db) %>% pull(acceptedNameUsageID)

  system.time({
  col_accepted_name <- get_names(col_accepted_id, "col",
                                 format="prefix", taxadb_db = db)
  })

  col_id <- taxa_tbl("col", db = db) %>% pull(taxonID)

  system.time({
  col_name <- get_names(col_id, "col",
                        format = "prefix", taxadb_db = db)
  })
  expect_equal(sum(is.na(col_name)), 0)
  expect_equal(length(col_name), length(col_id))


})
