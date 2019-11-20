
#install.packages('rredlist')
library(rredlist)
library(tidyverse)
library(httr)
source("data-raw/helper-routines.R")

downloads <- tempdir()
dir <- file.path(downloads, "iucn")
dir.create(dir, FALSE, FALSE)


## Public token from Redlist API website examples:
key <- "9bb4facb6d23f48efbf424bb05c0c1ef1cf6f468393bc745d42179ac4aca5fee"

## How many pages of records?
x <- GET(paste0("http://apiv3.iucnredlist.org/api/v3/speciescount?token=",key))
max <- ceiling(as.numeric(content(x)$count) / 10000) - 1

## Get em all
links <- paste0("http://apiv3.iucnredlist.org/api/v3/species/page/",
                0:max,
                "?token=", key)



system.time({
  full_content <- links %>% map(GET)
})


full <- full_content %>%
      purrr::map_df(function(obj){
          httr::content(obj) %>%
          getElement("result") %>%
          purrr::map_df(function(x){
            x %>% purrr::flatten() %>% tibble::as.tibble()
          })
      })



sentence_case <- function(x) {
  Hmisc::capitalize(str_to_lower(x))
  #gsub("(. )([A-Z])(.+)", "\\1\\U\\2\\L\\3", x)
}
hierarchy <- full %>% select(id = taxonid, kingdom = kingdom_name, phylum = phylum_name,
                             class = class_name, order = order_name, family = family_name,
                             genus = genus_name, species = scientific_name) %>%
  mutate_if(is.character, sentence_case) %>%
  mutate(id = paste0("IUCN:", id))

dir.create("data", FALSE)
write_tsv(hierarchy, "data/iucn_hierarchy.tsv.bz2")



## ~ 10 hours to run
system.time({
  syn_list <- vector("list", length = length(full$scientific_name))
  #for(i in seq_along(full$scientific_name)){

  sofar <- 1
  for(i in sofar:length(full$scientific_name)){
    syn_list[[i]] <- tryCatch(rredlist::rl_synonyms(full$scientific_name[[i]], key),
                              error = function(e) list(),
                              finally = NULL)
  }
})

syn_table <- syn_list %>% map_dfr("result") %>% as_tibble()
syn_table %>% select(accepted_id, accepted_name, synonym) %>% write_tsv("data/iucn_synonyms.tsv.bz2")


taxonid <- hierarchy %>%
  select(id, name = species) %>% mutate(rank = "species", name_type = "accepted name") %>%
  bind_rows(syn_table %>%
              select(id = accepted_id, name = synonym) %>%
              mutate(id = paste0("IUCN:", id),
                     rank = "species",
                     name_type = "synonym")
  ) %>%
  de_duplicate()
write_tsv(taxonid, "data/iucn_taxonid.tsv.bz2")



## ~ 10 hours to run
system.time({
  common_list <- vector("list", length = length(full$scientific_name))
  #for(i in seq_along(full$scientific_name)){

  sofar <- 1
  for(i in sofar:length(full$scientific_name)){
    common_list[[i]] <- tryCatch(rredlist::rl_common_names(full$scientific_name[[i]], key),
                                 error = function(e) list(),
                                 finally = NULL)
  }
})

null_as_na_name <- function(x){ if(is.null(x$name)) return(as.character(NA)); x$name}

names <- map_chr(common_list, null_as_na_name)
common <- common_list %>% map_dfr(function(x) as_tibble(x$result))

null_as_na_result <- function(x){ if(length(x) == 0)
  return(tibble(taxonname = as.character(NA), primary=NA, language=as.character(NA)))
  x
  }

common <- common_list %>%
  map_dfr(function(x)
  data.frame(name = null_as_na_name(x), as_tibble(null_as_na_result(x$result)),
             stringsAsFactors = FALSE)
  ) %>%
  as_tibble() %>%
  rename(scientific_name = name, commonname = taxonname) %>%
  left_join(select(full, id = taxonid, scientific_name)) %>%
  mutate(id = paste0("IUCN:", id)) %>%
  select(id, scientific_name, commonname, primary, language)

write_tsv(common, "data/iucn_common.tsv.bz2")

##### Rename things to Darwin Core
library(taxadb)

#get accepted common names
common <- read_tsv("data/iucn_common.tsv.bz2") %>%
  filter(!is.na(commonname), primary == TRUE) %>%
  n_in_group(group_var = "id", n = 1, wt = commonname)

taxonid <-
  collect(taxa_tbl("iucn", "taxonid")) %>%
  distinct() %>%
  ## IUCN doesn't give IDs to synonyms, didn't have an accepted_id
  mutate(accepted_id = id,
         name_type = dplyr::recode_factor(name_type, "accepted name" = "accepted"))

wide <- collect(taxa_tbl("iucn", "hierarchy")) %>% distinct()
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
            by = "taxonID") %>%
  left_join(read_tsv("data/iucn_common.tsv.bz2") %>%
              filter(!is.na(commonname), primary == TRUE) %>%
              n_in_group(group_var = "id", n = 1, wt = commonname) %>%
              select(taxonID = id, vernacularName = commonname), by = "taxonID")

species <- stringi::stri_extract_all_words(dwc$specificEpithet, simplify = TRUE)
dwc$specificEpithet <- species[,2]
dwc$infraspecificEpithet <- species[,3]
dwc$taxonID[dwc$taxonomicStatus != "accepted"] <- as.character(NA)

write_tsv(dwc, "dwc/dwc_iucn.tsv.bz2")

##library(piggyback)
##fs::dir_ls(glob = "data/iucn*", recursive = TRUE) %>% piggyback::pb_upload(tag = "v1.0.0")

#Common names table

#not all acceptedNameUsageID's have an accepted sciname, but we want to preserve as many ID's as possible
#so first get the ones that do have an accepted id
dwc_accepted <- dwc %>% filter(taxonomicStatus == "accepted")

#then randomly pick a synonym sciname for the rest of the ID's
dwc_rest <- dwc %>%
  filter(!acceptedNameUsageID %in% dwc_accepted$acceptedNameUsageID) %>%
  n_in_group(group_var = "acceptedNameUsageID", n = 1, wt = scientificName)

#then join with the common names
comm_table <- read_tsv("data/iucn_common.tsv.bz2") %>%
  drop_na (commonname) %>%
  select(acceptedNameUsageID = id, vernacularName = commonname, language) %>%
  inner_join(bind_rows(dwc_accepted, dwc_rest) %>% select(-vernacularName))

write_tsv(comm_table, "dwc/common_iucn.tsv.bz2")
#piggyback::pb_upload("common/common_iucn.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")
