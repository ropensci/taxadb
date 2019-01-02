
#install.packages('rredlist')
library(rredlist)
library(tidyverse)
library(httr)

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

  full <- links %>%
    map_df(function(link){
      GET(link) %>%
        content() %>%
        getElement("result") %>%
        map_df(function(x){
          x %>% purrr::flatten() %>% as.tibble()
        })
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
  select(id, name = species) %>% mutate(rank = "species") %>%
  bind_rows(syn_table %>%
              select(id = accepted_id, name = synonym) %>%
              mutate(id = paste0("IUCN:", id), rank = "species")
  )
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


##library(piggyback)
##fs::dir_ls(glob = "data/iucn*", recursive = TRUE) %>% pb_upload(tag = "v1.0.0")
