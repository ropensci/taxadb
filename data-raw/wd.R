
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
         path_rank_id = paste0("WD:", path_rank_id))



## add rank names
wd_long <- wd_long %>%
  left_join(wd_ranks) %>%
  left_join(rename(wd_ranks,
                   path_rank_id = rank_id,
                   path_rank = rank))

write_tsv(wd_long, "data/wd_long.tsv.bz2")

library(tidyverse)
wd_long <- read_tsv("data/wd_long.tsv.bz2")

pre_spread <-
  wd_long %>%
  filter(rank == "species") %>%
  select(id, species = name, path, path_rank) %>%
  distinct() %>%
  filter(!is.na(path_rank))

## Some species names / ids have multiple ranks at the same level (i.e. is part of two suborders)
## In order to spread, we use this trick to just take the first of these in that case.
pre_spread <- pre_spread %>% mutate(row = 1:n())
tmp <- pre_spread %>% select(id, row) %>% group_by(id) %>% top_n(1)
uniques <- left_join(tmp, pre_spread, by = c("row", "id"))


wd_wide <- uniques %>% spread(path_rank, path)
write_tsv(wd_wide, bzfile("data/wd_hierarchy.tsv.bz2", compression=9))


## Debug info: use this to up the duplicated ranks.
has_duplicate_rank <- pre_spread %>%
  group_by(id, path_rank) %>%
  summarise(l = length(path)) %>%
  filter(l>1)
dups <- pre_spread %>%
  semi_join(select(has_duplicate_rank, id, path_rank))

dups

#write_tsv(wd_wide, "data/wd_hierarchy.tsv.bz2")


id_map <- wd_taxon %>%
  select(id, same_as) %>%
  tidyr::separate(same_as, letters, sep="\\|")

## Show object sizes
# pryr::object_size(wd_links) # 1.12 GB
# pryr::object_size(wd_taxon) # 580 MB
# pryr::object_size(wd_long) # 1.22 GB

# lapply(ls(), function(x) pryr::object_size(get(x)))

wd_long <- read_tsv("data/wd_long.tsv.bz2")
wd_long %>%
  select(id, name, rank) %>%
  distinct() %>% write_tsv("data/wd_taxonid.tsv.bz2")


dummy_synonyms <- tibble(id = NA, accepted_name = NA, name = NA, type = NA, synonym_id = NA, rank = NA)
write_tsv(dummy_synonyms, "data/wd_synonyms.tsv.bz2")


