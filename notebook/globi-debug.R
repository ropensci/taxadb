

## MISC
#library(pryr)
#pryr::object_size(taxa)

## ugh, really slow, really should be done with tidyr::separate,
##  but would require at least grouping by pipe-length
## (this is also potentially fragile.)

#' @importFrom purrr transpose map_dfr
#' @importFrom dplyr as_tibble left_join select
#' @importFrom stringr str_to_lower str_split


#out <- map_dfr(transpose(df), split_taxa)
split_taxa <- function(row, pattern = "\\s*\\|\\s*"){ 
  ranks <- setNames(as.list(
    str_split(row$path, pattern)[[1]]),
    str_to_lower(str_split(row$pathNames, pattern)[[1]])
  )
  names(ranks) <- guess(names(ranks))
  bind_cols(row, as_tibble(ranks))
}

guess <- function(x){
  x <- str_replace_na(x, "unknown") # Fixme should be unique name?
  x[x==""] <- "unknown"
  make.unique(x)
}

## DEBUG taxonCache

library(tidyverse)
read_tsv("https://zenodo.org/record/1250572/files/taxonCache.tsv.gz", quote="")

dup_id <- 
  taxonCache %>% select(id) %>% group_by(id) %>% 
  summarise(n_id = length(id)) %>% filter(n_id > 1) 

trouble <- taxonCache %>% semi_join(select(dup_id, id))


## Small example works despite differing numbers of pipes!
tmp <- taxonCache %>%
  filter(str_detect(name, "Gadus morhua"))  %>% 
  transpose() %>% 
  map_dfr(longform) %>% 
  distinct()

## Note we have disagreement:
tmp %>% filter(pathNames == "kingdom")
tmp %>% filter(path == "Actinopterygii")
tmp %>% filter(pathNames == "class")
