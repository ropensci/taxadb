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
taxonCache %>% filter(grepl(":", pathNames))


taxonCache %>% filter(!grepl("(:|-|_)", id)) -> error

taxonCache %>% filter(grepl("\\s", id)) -> error


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
split_taxa <- 
  function(df, pattern = "\\s*\\|\\s*"){
    out <- map_dfr(transpose(df), function(row){ 
      ranks <- setNames(as.list(
        str_split(row$value, pattern)[[1]]),
        str_to_lower(str_split(row$type, pattern)[[1]])
      )
      names(ranks) <- guess(names(ranks))
      bind_cols(row, as_tibble(ranks))
    })
  }

guess <- function(x){
  x <- str_replace_na(x, "unknown") # Fixme should be unique name?
  x[x==""] <- "unknown"
  make.unique(x)
}


## Small example works despite differing numbers of pipes!
taxonCache %>%
  rename(value = path, type=pathNames) %>% 
  filter(str_detect(name, "Gadus morhua"))  %>% 
  split_taxa()

# 3052673 rows.  3,052,673
taxa <- taxonCache %>%
  rename(value = path, type=pathNames) %>% 
  split_taxa()

# write_tsv(taxa, "data/taxonRankCache.tsv.gz") ## default compression
## serious compression ~ about the same.  
write_tsv(taxa, gzfile("data/taxonRankCache.tsv.gz", compression = 9))

write_tsv(taxonCache, bzfile("data/taxonCache.tsv.bz2", compression=9))
