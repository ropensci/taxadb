# FROM: Poelen, Jorrit H. (2018). Global Biotic Interactions: Taxon Graph (Version 0.3.2) [Data set]. 
# Zenodo. http://doi.org/10.5281/zenodo.1250572

library(tidyverse)

expect_none <- function(df){ testthat::expect_equal(dim(df)[[1]], 0) }


#' @importFrom readr read_tsv
dir.create("data", FALSE)
download.file("https://zenodo.org/record/1250572/files/prefixes.tsv", "data/prefixes.tsv")
download.file("https://zenodo.org/record/1250572/files/taxonCache.tsv.gz", "data/taxonCache.tsv.gz")
download.file("https://zenodo.org/record/1250572/files/taxonMap.tsv.gz", "data/taxonMap.tsv.gz")

prefixes <- read_tsv("data/prefixes.tsv", quote = "")
taxonCache <- read_tsv("data/taxonCache.tsv.gz", quote = "")
taxonMap <- read_tsv("data/taxonMap.tsv.gz", quote = "")


## DROP all duplicated keys in taxonCache
#first_of_dups <- function(df, id){}
taxonCache <- taxonCache %>% mutate(row = 1:n())
tmp <- taxonCache %>% select(id, row) %>% group_by(id) %>% top_n(1)
tmp2 <- left_join(tmp, taxonCache, by = c("row", "id"))
taxonCache <- tmp2


test <- TRUE
if(test){
  taxonCache %>% pull(id) %>% duplicated() %>% any() %>% testthat::expect_false()
  # Some ids lack ":"
  #taxonCache %>% filter(!grepl(":", id)) %>% expect_none()
  ## Some tests
  #taxonCache %>% filter(grepl(":", path)) %>% expect_none()  ## some paths are ids
  taxonCache %>% filter(grepl("\\s", id))  %>% expect_none()  
    
  pattern = "\\s*\\|\\s*"
  path_pipes <- taxonCache %>% purrr::transpose() %>%
    map_int( ~length(str_split(.x$path, pattern)[[1]]))
  pathName_pipes <- taxonCache %>% purrr::transpose() %>%
    map_int( ~length(str_split(.x$pathNames, pattern)[[1]]))
  pathIds_pipes <- taxonCache %>% purrr::transpose() %>%
    map_int( ~length(str_split(.x$pathIds, pattern)[[1]]))
  na_path <- is.na(taxonCache$path)
  na_pathNames <- is.na(taxonCache$pathNames)
  na_pathIds  <- is.na(taxonCache$pathIds)
  trouble <- which( !(path_pipes == pathName_pipes) & !na_path & !na_pathNames)
  expect_none(taxonCache[trouble,])
}
## This one is failing
## trouble <- which( !(pathIds_pipes == path_pipes) & !na_path & !na_pathIds)
##expect_none(taxonCache[trouble,])

## taxonCache <- taxonCache[-trouble,]


longform <- function(row, pattern = "\\s*\\|\\s*"){ 
  row_as_df <- 
    data_frame(id = row$id,
               name = row$name,
               rank = row$rank,
               path = str_split(row$path, pattern)[[1]],
               pathNames = str_split(row$pathNames, pattern)[[1]],
               pathIds = str_split(row$pathIds, pattern)[[1]],
               commonNames = row$commonNames,
               externalUrl = row$externalUrl,
               thumbnailUrl = row$thumbnailUrl)
               
}


# 3052673 rows.  3,052,673

system.time({
taxa <- taxonCache %>% 
  transpose() %>% 
  map_dfr(longform) %>% 
  distinct() 
})

## FIXME 
## - [ ] standardize case
## - [x] standardize rank names


taxon_rank_list <- read_tsv(paste0("https://raw.githubusercontent.com/",
  "globalbioticinteractions/nomer/master/nomer/src/main/resources/org/",
  "globalbioticinteractions/nomer/match/taxon_rank_links.tsv"))

rank_mapper <- taxon_rank_list %>% 
  select(pathNames = providedName, 
         rank_level_id = resolvedId, 
         rank_level = resolvedName)

globi_long <- inner_join(taxa, 
                    rank_mapper, 
                    copy = TRUE) %>% 
  arrange(id) %>%
  select(-pathNames) %>% # drop the uncorrected names
  select(id, 
         name,
         rank,
         path, 
         path_id = pathIds, 
         path_rank = rank_level, 
         path_rank_id = rank_level_id, 
         common_names = commonNames, 
         external_url = externalUrl, 
         thumbnail_url = thumbnailUrl)

## serious compression ~ about the same.  
write_tsv(globi_long, bzfile("data/globi_long.tsv.bz2", compression=9))

pre_spread <- 
  globi_long %>% 
  filter(rank == "species") %>%
  select(id, species = name, path, path_rank) %>% 
  distinct() 

## see debug: OTT, WORMS, NCBI, NBN & INAT contain non-unique rank names
pre_spread <- pre_spread %>% mutate(row = 1:n())
tmp <- pre_spread %>% select(id, row) %>% group_by(id) %>% top_n(1)
uniques <- left_join(tmp, pre_spread, by = c("row", "id"))



uniques %>% pull(id) %>% duplicated() %>% any() %>% testthat::expect_false()


globi_wide <- uniques %>% spread(path_rank, path) 
write_tsv(globi_wide, bzfile("data/globi_wide.tsv.bz2", compression=9))




#### DEBUG ##################


## Find all cases with duplicate identifiers!
has_duplicate_rank <- pre_spread %>% 
  group_by(id, path_rank) %>% 
  summarise(l = length(path)) %>% 
  filter(l>1)

dups <- pre_spread %>% 
  semi_join(select(has_duplicate_rank, id, path_rank))

dups

dups %>% select(id) %>% separate(id, c("source", "id")) %>% group_by(source) %>% tally()
# A tibble: 5 x 2
# source       n
# <chr>    <int>
#  1 INAT       88
# 2 NBN         28
# 3 NCBI       206
# 4 OTT    1406561
# 5 WORMS     6780
