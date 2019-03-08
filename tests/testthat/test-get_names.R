
context("get_names()")

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

test_that("we can handle more intensive comparisons", {
  library(dplyr)

  db <- td_connect(test_db)

  itis_id <- taxa_tbl("itis") %>% pull(taxonID)
  itis_accepted_id <-  taxa_tbl("itis", db = db) %>% pull(acceptedNameUsageID)
  itis_accepted_name <- get_names(itis_accepted_id, "itis",
                                  format="prefix", taxadb_db = db)
  itis_name <- get_names(itis_id, "itis", format = "prefix", taxadb_db = db)

  ## In ITIS: All IDs should resolve to one unique name
  expect_equal(sum(is.na(itis_name)), 0)
  expect_equal(length(itis_name), length(itis_id))

  ## This need not be true of acceptedNameUsage and acceptedNameUsageID --
  ## some names will have no known accepted ID.

  ### Tested on oher dbs too, but slow so skip for now
#  gbif_accepted_id <-  taxa_tbl("gbif") %>% pull(acceptedNameUsageID)
#  gbif_accepted_name <- get_names(gbif_accepted_id, "gbif", format="prefix")

#  gbif_id <- taxa_tbl("gbif") %>% pull(taxonID)
#  gbif_name <- get_names(gbif_id, "gbif", format = "prefix")

#  expect_equal(sum(is.na(gbif_name)), 0)
#  expect_equal(length(gbif_name), length(gbif_id))


})
