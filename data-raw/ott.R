library(tidyverse)
source("data-raw/helper-routines.R")

download.file("http://files.opentreeoflife.org/ott/ott3.0/ott3.0.tgz", "ott3.0.tgz")
untar("ott3.0.tgz", compressed = "gzip")

# Really would be nice if we followed the DAMN STANDARD. tsv is tab-delimited,
# not "\\t\\|\\t" delimited, people!

## we `select()` in order to drop columns consisting solely of pipe separators...
synonyms <- read_tsv("ott/synonyms.tsv") %>%
  select(name, uid, type, uniqname, sourceinfo)
taxonomy <- read_tsv("ott/taxonomy.tsv") %>%
  select(name, uid, parent_uid, rank, uniqname, sourceinfo, flags)


## sourceinfo is comma-separated list of identifiers which synonym resolves against
## (identifiers of accepted names, not just ids to the synonym, not listed)
## UIDs are OTT ids of the ACCEPTED NAMES.  no ids to synonym names

# synonyms involve a lot of types, but mostly "synonym".
## Does not include "accepted" names.
synonyms %>% count(type) %>% arrange(desc(n))



# taxonomy includes a lot of different flags,
# including "extinct", "environmental", & "incertae_sedis"
taxonomy %>% count(flags) %>% arrange(desc(n))

## Synonyms table: id, accepted_name, rank, name, name_type
ott_synonyms <- taxonomy %>%
  select(accepted_name = name, uid, rank) %>%
  right_join(synonyms) %>%
  select(id = uid, accepted_name, name, rank, name_type = type) %>%
  mutate(id = paste0("OTT:", id))
write_tsv(ott_synonyms, "data/ott_synonyms.tsv.bz2")

## TaxonID table
ott_taxonid <- bind_rows(
  taxonomy %>% select(id = uid, name, rank) %>%
    mutate(id = paste0("OTT:", id)) %>%
    mutate(accepted_id = id, name_type = "accepted_name"),
  synonyms %>%
    select(accepted_id = uid, name, name_type = type) %>%
    left_join(select(taxonomy, uid, rank),
              by = c("accepted_id" = "uid")) %>%
    mutate(id = NA, accepted_id = paste0("OTT:", accepted_id))
  ) %>%
  de_duplicate()


dir.create("data", FALSE)
write_tsv(ott_taxonid, "data/ott_taxonid.tsv.bz2")


rm(synonyms, ott_taxonid)

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
  filter(!is.na(path_rank)) %>%
### some duplicates occur with spaces in names:
  filter(!grepl(" ", path))  %>%
  filter(path_rank != "species") %>%
   mutate(id = paste0("OTT:", id))

## Many have multiple names at a given rank! e.g.
## kingdom Chloroplastida & Archaeplastida
## Use tidy_names()
dedup <- pre_spread %>%
  mutate(orig_rank = path_rank) %>%
  group_by(id, orig_rank) %>%
  mutate(path_rank = tidy_names(orig_rank, quiet= TRUE)) %>%
  ungroup() %>%
  select(-orig_rank)
rm(pre_spread, ott_long)

ott_wide <- dedup %>% spread(path_rank, path)
write_tsv(ott_wide, "data/ott_hierarchy.tsv.bz2")



##### Rename things to Darwin Core ########
library(taxadb)
source("data-raw/helper-routines.R")

taxonid <-
  collect(taxa_tbl("ott", "taxonid")) %>%
  distinct() %>%
  de_duplicate()

wide <- collect(taxa_tbl("ott", "hierarchy")) %>% distinct()
dwc <- taxonid %>%
  rename(taxonID = id,
         scientificName = name,
         taxonRank = rank,
         taxonomicStatus = name_type,
         acceptedNameUsageID = accepted_id) %>%
  left_join(wide %>%
              select(taxonID = id,
                     kingdom, phylum, class, order, family, genus,
                     specificEpithet = species
                     #infraspecificEpithet
              ),
            by = c("acceptedNameUsageID" =  "taxonID"))

species <- stringi::stri_extract_all_words(dwc$specificEpithet, simplify = TRUE)
dwc$specificEpithet <- species[,2]
dwc$infraspecificEpithet <- species[,3]

dwc <- dwc %>%
  ## CRAZY SLOW! use vectorized stringi operation instead(?)
  mutate(taxonomicStatus = dplyr::recode_factor(taxonomicStatus, "accepted_name" = "accepted"))


write_tsv(dwc, "dwc/ott.tsv.bz2")


## testing
dwc %>%
  filter(!is.na(infraspecificEpithet), taxonRank == "species", !is.na(genus)) %>%
  select(scientificName, taxonRank, taxonomicStatus, genus, specificEpithet, infraspecificEpithet)


#unlink("ott3.0.tgz")
#unlink("ott", recursive = TRUE)

###################


## Debug info: use this to view the duplicated ranks.
has_duplicate_rank <- pre_spread %>%
  group_by(id, path_rank) %>%
  summarise(l = length(path)) %>%
  filter(l>1)
dups <- pre_spread %>%
  semi_join(select(has_duplicate_rank, id, path_rank))

x = tidy_names(c("class", "class"))

dedup_ex <- dups  %>%
  mutate(orig_rank = path_rank) %>%
  group_by(id, orig_rank) %>%
  mutate(path_rank = tidy_names(orig_rank, quiet = TRUE)) %>%
  select(-orig_rank)
dedup_ex


rm(has_duplicate_rank, dups)

## Worse method, takes first among the duplicates
#pre_spread <- pre_spread %>% mutate(row = 1:n())
#tmp <- pre_spread %>% select(id, path_rank, row)
# %>% group_by(path_rank) %>% top_n(1)
#uniques <- left_join(tmp, pre_spread,
# by = c("row", "id",  "path_rank")) %>% ungroup()
