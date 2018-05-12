# FROM: Poelen, Jorrit H. (2018). Global Biotic Interactions: Taxon Graph (Version 0.3.1) [Data set]. 
# Zenodo. http://doi.org/10.5281/zenodo.1213465

library(tidyverse)

#' @importFrom readr read_tsv
prefixes <- read_tsv("https://zenodo.org/record/1213465/files/prefixes.tsv", quote = "")
#taxonCache <- read_tsv("https://zenodo.org/record/1213465/files/taxonCache.tsv.gz", quote = "")
taxonMap <- read_tsv("https://zenodo.org/record/1213465/files/taxonMap.tsv.gz", quote = "")


#download.file("https://zenodo.org/record/1213465/files/prefixes.tsv", "data/prefixes.tsv")
#download.file("https://zenodo.org/record/1213465/files/taxonCache.tsv.gz", "data/taxonCache.tsv.gz")
#download.file("https://zenodo.org/record/1213465/files/taxonMap.tsv.gz", "data/taxonMap.tsv.gz")
#prefixes <- read_tsv("data/prefixes.tsv", quote = "")
#taxonCache <- read_tsv("data/taxonCache.tsv.gz", quote = "")
#taxonMap <- read_tsv("data/taxonMap.tsv.gz", quote = "")

taxonCache <- read_tsv("https://depot.globalbioticinteractions.org/tmp/taxon-0.3.2/taxonCache.tsv.gz", quote="")

taxonCache %>% filter(grepl(":", path))
taxonCache %>% filter(is.na(externalUrl))
taxonCache %>% filter(!grepl(":", id)) 
taxonCache %>% filter(grepl("_", id)) 
taxonCache %>% filter(grepl("\\s", id)) 


## fix alignment error on taxonCache when `id` is missing:
#noid <- taxonCache %>% filter(!grepl("(:|-|_)", id))
#hasid <- taxonCache %>% filter(grepl("(:|-|_)", id))
#names(noid) <- names(noid)[-1]
#noid <- bind_cols(id=rep(NA, dim(noid)[1]), noid) %>% select(-V1)
#taxonCache <- bind_rows(hasid, noid)

## Expect same number of pipes in each entry:
#path_pipes <- taxonCache %>% purrr::transpose() %>% map_int( ~length(str_split(.x$path, pattern)[[1]]))
#pathName_pipes <- taxonCache %>% purrr::transpose() %>% map_int( ~length(str_split(.x$pathNames, pattern)[[1]]))
#pathIds_pipes <- taxonCache %>% purrr::transpose() %>% map_int( ~length(str_split(.x$pathNames, pattern)[[1]]))
#na_path <- is.na(taxonCache$path)
#na_pathNames <- is.na(taxonCache$pathNames)

#good <-  which(!(!(path_pipes == pathName_pipes) & !na_path & !na_pathNames))
#trouble <- which( !(path_pipes == pathName_pipes) & !na_path & !na_pathNames)



#n_pipes <- taxonCache %>% purrr::transpose() %>% map_int( ~length(str_split(.x$path, pattern)[[1]]))
#taxonCache$n_pipes <- n_pipes

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

longform <- function(row, pattern = "\\s*\\|\\s*"){ 
  row_as_df <- 
    data_frame(path = str_split(row$path, pattern)[[1]],
               pathNames = str_split(row$pathNames, pattern)[[1]],
               pathIds = str_split(row$pathIds, pattern)[[1]])
}

## Small example works despite differing numbers of pipes!
tmp <- taxonCache %>%
  filter(str_detect(name, "Gadus morhua"))  %>% 
  transpose() %>% 
  map_dfr(longform) %>% 
  distinct()
View(tmp)

## Note we have disagreement:
tmp %>% filter(pathNames == "kingdom")
tmp %>% filter(path == "Actinopterygii")
tmp %>% filter(pathNames == "class")

# 3052673 rows.  3,052,673
taxa <- taxonCache %>%
  filter(str_detect(name, "Gadus morhua"))  %>% 
  transpose() %>% 
  map_dfr(longform) %>% 
  distinct() 




# write_tsv(taxa, "data/taxonRankCache.tsv.bz2") ## default compression
## serious compression ~ about the same.  
#write_tsv(taxa, bzfile("data/taxonRankCache.tsv.bz2", compression = 9))

write_tsv(taxonCache, bzfile("data/taxonCache.tsv.bz2", compression=9))
