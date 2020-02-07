library(openssl)
library(fs)
library(EML)
library(tidyverse)
library(uuid)
library(here)
library(jsonlite)

file_hash <- function(x, method = openssl::sha256, ...){
  con <- lapply(x, file, ...)
  hash <- lapply(con, method)
  unlist(lapply(hash, as.character))
}

release <- here::here("2019")
meta <- fs::dir_info(release) %>%
  mutate(sha256 = map_chr(path, file_hash, raw = FALSE),
         name = fs::path_file(path),
         contentType = "text/tab-separated-values",
         contentEncoding = "bz2") %>%
  select(name, size, sha256,
         dateCreated = modification_time,
         contentType, contentEncoding, path)


## Lightweight file metadata
#write_csv(meta, here::here("data-raw/meta.csv"))
meta %>%
  select(-path) %>%
  mutate(size = as.character(size)) %>%
  write_json(here::here("data-raw/meta.json"),
             pretty = TRUE, auto_unbox=TRUE)


dwc_terms <-
  read_csv("https://github.com/tdwg/dwc/raw/master/vocabulary/term_versions.csv") %>%
  select(attributeName = label, attributeDefinition = definition, definition = term_iri) %>%
  distinct() %>%
  bind_rows(tibble(  #
    attributeName = "isExtinct",
    definition = "logical indicating whether this taxon is now extinct",
    attributeDefinition = definition))


path <- meta$path[[1]]

meta_dataset <- function(path){

  sha256 <- file_hash(path, openssl::sha256, raw = TRUE)
  info <- fs::file_info(path)

  attributeName = path %>% read_tsv(n_max = 1) %>% colnames()
  attrs <- tibble(attributeName = attributeName) %>% left_join(dwc_terms)

  set_attributes(attrs, )
  physical <- set_physical(path)


  dataTable <- eml$dataTable(
    entityName = basename(path),
    entityDescription = "List of recognized taxonomic names in the Darwin Core format",
    physical = physical,
    attributeList = attrList)

}


me <- list(individualName = list(givenName = "Carl",
                                 surName = "Boettiger"),
           electronicMailAddress = "cboettig@berkeley.edu",
           id = "http://orcid.org/0000-0002-1642-628X")
kari <- list(individualName = list(givenName = "Kari",
                                 surName = "Norman"),
           electronicMailAddress = "cboettig@gmail.com",
           id = "http://orcid.org/0000-0002-1642-628X")

dataset = eml$dataset(
  title = "",
  creator = me,
  contact = list(references="http://orcid.org/0000-0002-1642-628X"),
  pubDate = Sys.Date(),
  intellectualRights = "",
  abstract =  "",
  dataTable = dataTable,
  keywordSet = keywordSet,
  coverage = coverage,
  methods = methods
)


