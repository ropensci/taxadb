library(openssl)
library(fs)
library(EML)
library(tidyverse)
library(uuid)

file_hash <- function(x, method = openssl::sha256, ...){
  con <- lapply(x, file, ...)
  hash <- lapply(con, method)
  unlist(lapply(hash, as.character))
}

release <- "2019"
meta <- fs::dir_info(release) %>% 
  mutate(sha256 = map_chr(objects, file_hash, raw = TRUE),
         name = fs::path_file(path)) %>%
  select(path, size, sha256, dateCreated = modification_time)


dwc_terms <- 
  read_csv("https://github.com/tdwg/dwc/raw/master/vocabulary/term_versions.csv") %>% 
  select(attributeName = label, attributeDefinition = definition, definition = term_iri)

path <- meta$path[[1]] 

meta_dataset <- function(path){
  
  sha256 <- file_hash(path, openssl::sha256, raw = TRUE)
  info <- fs::file_info(path)
  
  attributeName = path %>% read_tsv(n_max = 1) %>% colnames()
  attrs <- data.frame(attributeName = attributeName) %>% left_join(dwc_terms)
  
}

