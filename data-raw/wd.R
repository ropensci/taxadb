
# WikiData
# https://doi.org/10.5281/zenodo.1213476
# 

## Map all ranks to wikidata rank_ids
## https://github.com/globalbioticinteractions/nomer/blob/39ff250fbcc573d4ff69ae6053d530edb5a94b4f/nomer/src/main/resources/org/globalbioticinteractions/nomer/match/taxon_rank_links.tsv
## Maps wikidata rank_ids to ranks 
download.file("https://github.com/globalbioticinteractions/nomer/raw/45543c100c4b4c3a892250768ffe0bb7ef6569fe/nomer/src/main/resources/org/globalbioticinteractions/nomer/util/taxon_ranks.tsv", "wd_taxon_ranks.tsv")
wd_ranks <- read_tsv("wd_taxon_ranks.tsv") %>% select(rank_id = id, rank = name)

download.file("https://zenodo.org/record/1213477/files/wikidata-taxon-info20171227.tsv.gz", "wd-taxon.tsv.gz")
download.file("https://zenodo.org/record/1213477/files/links-globi-wd-ott.tsv.gz", "wd-links.tsv.gz")
## Not 20 GB.
library(tidyverse)
wd_links <- read_tsv("wd-links.tsv.gz", col_names = c("id", "same_as"), quote="")
wd_taxon <- read_tsv("wd-taxon.tsv.gz", col_names = c("id", "name", "rank_id", "parent", "same_as"), quote = "")

## Lets create the tables...  ugh, it's recursive join time again  on id = parent
## Some wd_taxon have two parent ids... ugh
wd_taxon %>% dplyr::filter(grepl("\\|", parent))

wd_taxon <- wd_taxon %>% 
  separate(parent, c("parent", "parent2"), sep="\\|", 
                      extra = "drop", fill = "right") 

## 105 distinct ranks!
wd_taxon %>% select(rank_id) %>% distinct()

wd_taxon %>% select(id, parent) -> wd_ids

hierarchy <- wd_ids
for(i in 1:105){
  p <- paste0("p",i)
  n <- names(hierarchy)
  names(hierarchy) <- gsub("parent", p, n)
  hierarchy <- left_join(hierarchy, wd_ids, by = setNames("id", p))
  if(all(is.na(hierarchy$parent))) break
}

# 
# write_tsv(hierarchy, "wd_hierarchy.tsv.gz")

long_hierarchy <- 
  hierarchy %>% 
  tidyr::gather(dummy, path_id, -id) %>% 
  select(id, path_id) %>% 
  distinct() %>%
  arrange(id) 

expand <- wd_taxon %>% 
  select(path_id = id, path = name, path_rank_id = rank_id) 

wd_long <- wd_taxon %>% 
  select(id, name, rank_id) %>%  
  inner_join(long_hierarchy) %>%
  inner_join(expand)

## let's prefix ids
wd_long <- wd_long %>% 
  mutate(id = paste0("WD:", id),
         rank_id = paste0("WD:", rank_id),
         path_id = paste0("WD:", path_id),
         path_rank_id = paste0("WD", path_rank_id))

## add rank names
wd_long <- wd_long %>% 
  left_join(wd_ranks) %>% 
  left_join(rename(wd_ranks, 
                   path_rank_id = rank_id,
                   path_rank = rank))
write_tsv(wd_long, "data/wd_long.tsv.bz2")


id_map <- wd_taxon %>% 
  select(id, same_as) %>% 
  tidyr::separate(same_as, letters, sep="\\|")

## Show object sizes
# pryr::object_size(wd_links) # 1.12 GB
# pryr::object_size(wd_taxon) # 580 MB
# pryr::object_size(wd_long) # 1.22 GB

# lapply(ls(), function(x) pryr::object_size(get(x)))
