# FROM: Poelen, Jorrit H. (2018). Global Biotic Interactions: Taxon Graph (Version 0.3.1) [Data set]. 
# Zenodo. http://doi.org/10.5281/zenodo.1213465


library(tidyverse)

#' @importFrom readr read_tsv
prefixes <- read_tsv("https://zenodo.org/record/1213465/files/prefixes.tsv")
taxonCache <- read_tsv("https://zenodo.org/record/1213465/files/taxonCache.tsv.gz")
taxonMap <- read_tsv("https://zenodo.org/record/1213465/files/taxonMap.tsv.gz")



#n_pipes <- taxonCache %>% purrr::transpose() %>% map_int( ~length(str_split(.x$path, pattern)[[1]]))
#taxonCache$n_pipes <- n_pipes


#' @importFrom purrr transpose map_dfr
#' @importFrom dplyr as_tibble left_join select
#' @importFrom stringr str_to_lower str_split
split_taxa <- 
  function(df, pattern = "\\s*\\|\\s*"){
    out <- map_dfr(transpose(df), function(row){ 
      as_tibble(setNames(as.list(
        c(row$id, str_split(row$value, pattern)[[1]])),
        c("id", guess(str_to_lower(str_split(row$type, pattern)[[1]])))
      ), validate=FALSE) # allow duplicate column names
    })
    left_join(select(df, -value, -type), out, by="id")
  }

guess <- function(x){
  x <- str_replace_na(x, "unknown") # Fixme should be unique name?
  x[x==""] <- "unknown"
  make.unique(x)
}

## Small example works despite differing numbers of pipes!
taxonCache %>%
  rename(value = path, type=pathNames) %>% 
  distinct(id, .keep_all = TRUE) %>% 
  filter(str_detect(name, "Gadus morhua")) %>% 
  split_taxa()


## Small example works despite differing numbers of pipes!
taxonCache %>%
  rename(value = path, type=pathNames) %>% 
  distinct(id, .keep_all = TRUE) %>% 
#  filter(str_detect(name, "Gadus")) %>%
  split_taxa()

## dbplyr partial match  
#filter(name  %like% "%Mammalia%")

