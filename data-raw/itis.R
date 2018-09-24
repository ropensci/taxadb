## apt-get -y install mariadb-client postgresql-client
library(taxizedb) 
library(tidyverse)

itis_store <- db_download_itis()
## Need to fix locale issue
#db_load_itis(itis_store, user = "postgres", pwd = "password", host = "postgres")
itis_db <- src_itis(user = "postgres", password = "password", host = "postgres")

## not that rank_id isn't a unique id by itself!
rank_tbl <- tbl(itis_db, "taxon_unit_types") %>% 
  select(kingdom_id, rank_id, rank_name) %>% 
  collect() %>% 
  unite(rank_id, -rank_name, sep = "-") %>% 
  mutate(rank_name = 
           stringr::str_remove_all(
            stringr::str_to_lower(rank_name),"\\s"))

hierarch <- 
  tbl(itis_db, "taxonomic_units") %>% 
  mutate(rank_id = paste(kingdom_id, rank_id, sep="-")) %>% 
  select(tsn, parent_tsn, rank_id, complete_name) %>% distinct()

itis_taxa <- 
  left_join(
    inner_join(hierarch, rank_tbl, copy = TRUE), 
    tbl(itis_db, "hierarchy") %>% select(tsn, parent_tsn, hierarchy_string)
  ) %>% 
  arrange(tsn) %>% 
  select(tsn, complete_name, rank_name, 
         rank_id, parent_tsn, hierarchy_string) %>%
  left_join(select(tbl(itis_db, "vernaculars"), 
                   tsn, vernacular_name, language))  %>%
 left_join(
           select(tbl(itis_db, "taxonomic_units"), 
                  tsn, update_date, name_usage)
  ) %>%
  rename(id = tsn, 
         parent_id = parent_tsn, 
         common_name = vernacular_name,
         name = complete_name,
         rank = rank_name)  %>% 
  mutate(id = paste0("ITIS:", id),
         rank_id = paste0("ITIS:", rank_id),
         parent_id = paste0("ITIS:", parent_id))

## Read in from database -- a little slow
itis <- collect(itis_taxa)

## transforms we do in R
itis$hierarchy_string <- gsub("(\\d+)", "ITIS:\\1",
                                   gsub("-", " | ", 
                                        itis$hierarchy_string))
itis <- itis %>% rename(hierarchy = hierarchy_string)


## Go into long form as well



## Go into long form:
longform <- function(row, pattern = "\\s*\\|\\s*"){ 
  row_as_df <- 
    data_frame(id = row$id,
               name = row$name,
               rank = row$rank,
               path_id = str_split(row$hierarchy, pattern)[[1]],
               common_name = row$common_name,
               language = row$language,
               update_date = row$update_date,
               name_usage = row$name_usage)
  
}

hier_expand <- itis %>% 
  select(id, path = name, path_rank = rank, path_rank_id = rank_id)

as_date <- function(x){
  class(x) <- "Date"
  x
}

itis_long <- itis %>%
  purrr::transpose() %>% 
  map_dfr(longform) %>% 
  left_join(hier_expand, by = c("path_id" = "id")) %>% 
  distinct() %>%
  select(id, name, rank, common_name, language, path, 
         path_rank, path_id, path_rank_id, name_usage, update_date) %>%
  mutate(update_date = as_date(update_date))




## write at compression 9 for best compression
system.time({
  write_tsv(itis_long, bzfile("data/itis_long.tsv.bz2", compression=9))
})


#itis_long <- read_tsv("data/itis_long.tsv.bz2")
## Wide-format classification table (scientific names only)
itis_wide <- 
  itis_long %>% 
  filter(rank == "species", name_usage == "valid") %>%
  select(id, species = name, path, path_rank) %>% 
  distinct() %>%
  spread(path_rank, path) 

# multiple common names for same id, not clear how to add. get first common name? 
# pipe string common names
#itis_long %>% select(id, common_name) %>% distinct()


## write at compression 9 for best compression
system.time({
  write_tsv(itis_wide, bzfile("data/itis_wide.tsv.bz2", compression=9))
})

#########################################################

## Database prep for ITIS
library(tidyverse)
itis_long <- read_tsv("data/itis_long.tsv.bz2")
itis_wide <- read_tsv("data/itis_wide.tsv.bz2")

fs::file_move("data/itis_wide.tsv.bz2", "data/itis_hierarchy.tsv.bz2")

## accepted == valid
### https://www.itis.gov/submit_guidlines.html#usage

taxonid <- itis_long %>% select(id, name, rank, name_usage, update_date) %>%
  distinct()  %>% arrange(id)

##  NEED map of synonym to accepted name!
synonyms <- taxonid %>% filter(name_usage %in% c("not accepted", "invalid")) %>% select(-name_usage)
itis_taxonid <- taxonid %>% filter(name_usage %in% c("accepted", "valid")) %>% select(-name_usage)


syn_table <- 
  read_tsv("taxizedb/itis/synonym_links.tsv.bz2", 
           col_names = c("id", "accepted_id", "update_date")) %>% 
  mutate(id = paste0("ITIS:", id), 
         accepted_id = paste0("ITIS:", accepted_id)) %>%
  right_join(synonyms)

write_tsv(syn_table, "data/itis_synonyms.tsv.bz2")

## assert ids are unique
itis_taxonid %>% pull(id) %>% duplicated() %>% any() %>% testthat::expect_false()

write_tsv(itis_taxonid, "data/itis_taxonid.tsv.bz2")


itis_paths  <- itis_long %>% select(id, path_id, path, path_rank, path_rank_id) %>%
  distinct() %>% arrange(id)


itis_names <- itis_long %>% select(id, name = common_name, language) %>% distinct() 








