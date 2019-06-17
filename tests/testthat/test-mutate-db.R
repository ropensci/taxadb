
testthat::test_that("mutate_db works on databases", {

  skip_on_cran()
  skip_if(Sys.getenv("TAXADB_DRIVER") == "RSQLite")
  library(dplyr)
  library(taxadb)
  td_create(c("itis", "ncbi"))

  chameleons <- taxa_tbl("ncbi") %>%
    filter(family == "Chamaeleonidae",
           taxonomicStatus != "accepted") %>%
    select(species = scientificName) %>%
    collect() %>%
    mutate(input = clean_names(species),
           sort = 1:length(species))

  ## Input table with clean names
  ## Let's get some matches, amazing how bad this is.  Need wikidata synonyms
  taxa <- taxa_tbl("itis") %>%
    mutate_db(clean_names, "scientificName", "input") %>%
    right_join(chameleons, copy = TRUE, by = "input") %>%
    arrange(sort)  %>%
    collect()

  ## lots of duplicate matches, pick the first one for now:
  matched <- taxa %>% select(acceptedNameUsageID, sort) %>% distinct() %>%
    group_by(sort) %>% top_n(1, acceptedNameUsageID)

  ## Some matches
  expect_is(matched, "data.frame")
  expect_gt(dim(matched)[1], 1)
  unmatched <- anti_join(chameleons, matched, by = "sort")
  unmatched

  ## Others not so much
  expect_is(unmatched, "data.frame")
  expect_gt(dim(unmatched)[1], 1)

})

