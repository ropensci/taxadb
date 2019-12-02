library(tidyverse)
library(fs)
source(here::here("data-raw/helper-routines.R"))



preprocess_ott <- function(url = "http://files.opentreeoflife.org/ott/ott3.2/ott3.2.tgz",
                            output_paths =
                              c(dwc = "2019/dwc_ott.tsv.bz2",
                                common = "2019/common_ott.tsv.bz2")
){

  dir = file.path(tempdir(), "ott")
  archive = file.path(dir, "ott.tgz")
  dir.create(dir, FALSE, FALSE)
  download.file(url,archive)
  hash <- file_hash(archive)

  message(paste(hash))

  basedir <- dirname(archive)

  untar(archive, exdir = basedir)
  dir <- fs::dir_ls(basedir, type="dir")

  ## defaulting to logicals is so annoying!
  read_tsv <- function(...) readr::read_tsv(..., quote = "", col_types = readr::cols(.default = "c"))


# Really would be nice if we followed the DAMN STANDARD. tsv is tab-delimited,
# not "\\t\\|\\t" delimited, people!

## we `select()` in order to drop columns consisting solely of pipe separators...
## ignore warnings
synonyms <- read_tsv(file.path(dir, "synonyms.tsv")) %>%
  select(name, uid, type, uniqname, sourceinfo)
taxonomy <- read_tsv(file.path(dir, "taxonomy.tsv")) %>%
  select(name, uid, parent_uid, rank, uniqname, sourceinfo, flags)


## sourceinfo is comma-separated list of identifiers which synonym resolves against
## (identifiers of accepted names, not just ids to the synonym, not listed)
## UIDs are OTT ids of the ACCEPTED NAMES.  no ids to synonym names

# synonyms involve a lot of types, but mostly "synonym".
## Does not include "accepted" names.
## synonyms %>% count(type) %>% arrange(desc(n))

# taxonomy includes a lot of different flags,
# including "extinct", "environmental", & "incertae_sedis"
## taxonomy %>% count(flags) %>% arrange(desc(n))

## DEPRECATED Synonyms table: id, accepted_name, rank, name, name_type
#ott_synonyms <- taxonomy %>%
#  select(accepted_name = name, uid, rank) %>%
#  right_join(synonyms) %>%
#  select(id = uid, accepted_name, name, rank, name_type = type) %>%
#  mutate(id = paste0("OTT:", id))

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
  ) #%>%
  #de_duplicate()

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

##### Rename things to Darwin Core ########


taxonid <-
  ott_taxonid %>%
  distinct() %>%
  de_duplicate()

wide <- ott_wide %>% distinct()
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


## note: stringi MUCH faster than recode_factor!
dwc <- dwc %>%
  mutate(taxonomicStatus =
           stringi::stri_replace_all(taxonomicStatus,
                                     "accepted",
                                     fixed="accepted_name")
         )


  write_tsv(dwc, output["dwc"])
  file_hash(output_paths)

}





