
testthat::test_that("mutate_db works on databases", {

  skip_on_cran()
  skip_if(Sys.getenv("TAXADB_DRIVER") == "RSQLite")

  ## Input table with clean names
  ## Let's get some matches, amazing how bad this is.  Need wikidata synonyms
  taxa <- taxa_tbl("itis_test") %>%
    mutate_db(clean_names, "scientificName", "input")
  expect_is(taxa, "tbl")

})

