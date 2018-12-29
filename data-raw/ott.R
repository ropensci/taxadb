library(tidyverse)

download.file("http://files.opentreeoflife.org/ott/ott3.0/ott3.0.tgz", "ott3.0.tgz")
untar("ott3.0.tgz", compressed = "gzip")

readr::read_lines("ott/synonyms.tsv", n_max = 5)

# Really would be nice if we followed the DAMN STANDARD. tsv is tab-delimited,
# not "\\t\\|\\t" delimited, people!

## we `select()` in order to drop columns consisting solely of pipe separators...
synonyms <- read_tsv("ott/synonyms.tsv") %>%
  select(name, uid, type, uniqname, sourceinfo)
taxonomy <- read_tsv("ott/taxonomy.tsv") %>%
  select(name, uid, parent_uid, rank, uniqname, sourceinfo, flags)

unlink("ott3.0.tgz")
unlink("ott", recursive = TRUE)

## sourceinfo is comma-separated list of identifiers which synonym resolves against
## (identifiers of accepted names, not just ids to the synonym, not listed)
## UIDs are OTT ids of the ACCEPTED NAMES.  no ids to synonym names

# synonyms involve a lot of types, but mostly "synonym".  Does not include "accepted" names.
synonyms %>% count(type) %>% arrange(desc(n))



# taxonomy includes a lot of different flags,
# including "extinct", "environmental", & "incertae_sedis"
taxonomy %>% count(flags) %>% arrange(desc(n))

ott_taxonid <- bind_rows(
  taxonomy %>% select(id = uid, name, rank) %>%
    mutate(accepted_id = id, type = "accepted_name"),
  synonyms %>% select(accepted_id = uid, name) %>%
    mutate(id = NA, rank = NA)
) %>% mutate(id = paste0("OTT:", id))

dir.create("data", FALSE)
write_tsv(ott_taxonid, "data/ott_taxonid.tsv.bz2")

rm(synonyms)

max <- pull(taxonomy, rank) %>% unique() %>% length()

## Time to unpack another recursive taxonomy hierarchy
ids <- select(taxonomy, id = uid, parent = parent_uid)
hierarchy <- ids
for(i in 1:max){
  p <- paste0("p",i)
  n <- names(hierarchy)
  names(hierarchy) <- gsub("parent", p, n)
  hierarchy <- left_join(hierarchy, ids, by = setNames("id", p))
  if(all(is.na(hierarchy$parent))) break
}
rm(ids)
##
long_hierarchy <-
  hierarchy %>%
  tidyr::gather(dummy, path_id, -id) %>%
  select(id, path_id) %>%
  distinct() %>%
  arrange(id)

rm(hierarchy)


expand <- taxonomy %>%
  select(path_id = uid, path = name, path_rank = rank)
rm(taxonomy)

expand %>% pull(path_rank) %>% unique()

ott_long <- expand %>%
  select(id = path_id, name = path, rank = path_rank) %>%
  inner_join(long_hierarchy) %>%
  inner_join(expand) %>%
  filter(!grepl("no rank", rank)) %>%
  filter(!grepl("no rank", path_rank))

rm(expand, long_hierarchy)

pre_spread <-
  ott_long %>%
  filter(rank == "species") %>%
  select(id, species = name, path, path_rank) %>%
  distinct() %>%
  filter(!is.na(path_rank))

rm(ott_long)

### Some are duplicates
#ott_wide <- pre_spread %>% spread(path_rank, path)

#saveRDS(pre_spread, "pre_spread.rds")
#pre_spread <- readRDS("~/pre_spread.rds")

## Some species names / ids have multiple ranks at the same level (i.e. is part of two suborders)
## In order to spread, we use this trick to just take the first of these in that case.
pre_spread <- pre_spread %>% mutate(row = 1:n())
tmp <- pre_spread %>% select(id, path_rank, row) %>% group_by(path_rank) %>% top_n(1)
uniques <- left_join(tmp, pre_spread, by = c("row", "id",  "path_rank")) %>% ungroup()

uniques %>% pull(path_rank) %>% unique()

rm(pre_spread)
write_tsv(ott_wide, bzfile("data/ott_hierarchy.tsv.bz2", compression=9))


## Debug info: use this to view the duplicated ranks.
has_duplicate_rank <- pre_spread %>%
  group_by(id, path_rank) %>%
  summarise(l = length(path)) %>%
  filter(l>1)
dups <- pre_spread %>%
  semi_join(select(has_duplicate_rank, id, path_rank))

dups

rm(has_duplicate_rank, dups)
