# FROM: Poelen, Jorrit H. (2018). Global Biotic Interactions: Taxon Graph (Version 0.3.1) [Data set]. 
# Zenodo. http://doi.org/10.5281/zenodo.1213465

library(tidyverse)

expect_none <- function(df){ testthat::expect_equal(dim(df)[[1]], 0) }


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


# Some ids lack ":"
#taxonCache %>% filter(!grepl(":", id)) %>% expect_none()

## Some tests
taxonCache %>% filter(grepl(":", path)) %>% expect_none()
taxonCache %>% filter(grepl("\\s", id))  %>% expect_none()


## Expect same number of pipes in each entry:
pattern = "\\s*\\|\\s*"
path_pipes <- taxonCache %>% purrr::transpose() %>% map_int( ~length(str_split(.x$path, pattern)[[1]]))
pathName_pipes <- taxonCache %>% purrr::transpose() %>% map_int( ~length(str_split(.x$pathNames, pattern)[[1]]))
pathIds_pipes <- taxonCache %>% purrr::transpose() %>% map_int( ~length(str_split(.x$pathIds, pattern)[[1]]))
na_path <- is.na(taxonCache$path)
na_pathNames <- is.na(taxonCache$pathNames)
na_pathIds  <- is.na(taxonCache$pathIds)

trouble <- which( !(path_pipes == pathName_pipes) & !na_path & !na_pathNames)
expect_none(taxonCache[trouble,])

## This one is faling
trouble <- which( !(pathIds_pipes == path_pipes) & !na_path & !na_pathIds)
##expect_none(taxonCache[trouble,])
## taxonCache[trouble,]


longform <- function(row, pattern = "\\s*\\|\\s*"){ 
  row_as_df <- 
    data_frame(id = row$id,
               name = row$name,
               rank = row$rank,
               path = str_split(row$path, pattern)[[1]],
               pathNames = str_split(row$pathNames, pattern)[[1]],
               pathIds = str_split(row$pathIds, pattern)[[1]])
}

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

# 3052673 rows.  3,052,673

system.time({
taxa <- taxonCache[-trouble, ] %>% ## Skip troublesome rows
  transpose() %>% 
  map_dfr(longform) %>% 
  distinct() 
})


# ITIS:10824

# write_tsv(taxa, "data/taxa.tsv.bz2") ## default compression
## serious compression ~ about the same.  
dir.create("data")
write_tsv(taxa, bzfile("data/taxa.tsv.bz2", compression=9))





## MISC





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
