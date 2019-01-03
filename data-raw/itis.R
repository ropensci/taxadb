library(tidyverse)

## all available flat files in original formats
piggyback::pb_download(repo = "cboettig/taxadb")

## not that rank_id isn't a unique id by itself!
rank_tbl <-
  read_tsv("taxizedb/itis/taxon_unit_types.tsv.bz2") %>%
  select(kingdom_id, rank_id, rank_name) %>%
  collect() %>%
  unite(rank_id, -rank_name, sep = "-") %>%
  mutate(rank_name =
           stringr::str_remove_all(
            stringr::str_to_lower(rank_name),"\\s"))

hierarch <-
  read_tsv("taxizedb/itis/taxonomic_units.tsv.bz2") %>%
  mutate(rank_id = paste(kingdom_id, rank_id, sep="-")) %>%
  select(tsn, parent_tsn, rank_id, complete_name) %>% distinct()

itis_taxa <-
  left_join(
    inner_join(hierarch, rank_tbl, copy = TRUE),
    read_tsv("taxizedb/itis/hierarchy.tsv.bz2") %>%
      select(tsn, parent_tsn, hierarchy_string)
  ) %>%
  arrange(tsn) %>%
  select(tsn, complete_name, rank_name,
         rank_id, parent_tsn, hierarchy_string) %>%
  left_join(
            select(read_tsv("taxizedb/itis/vernaculars.tsv.bz2"),
                   tsn, vernacular_name, language))  %>%
 left_join(
            select(read_tsv("taxizedb/itis/taxonomic_units.tsv.bz2"),
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

itis <- itis_taxa

## transforms we do in R
itis$hierarchy_string <- gsub("(\\d+)", "ITIS:\\1",
                                   gsub("-", " | ",
                                        itis$hierarchy_string))
itis <- itis %>% rename(hierarchy = hierarchy_string)


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

system.time({
  write_tsv(itis_long, bzfile("data/itis_long.tsv.bz2", compression=9))
})


## Wide-format classification table (scientific names only)
itis_hierarchy <-
  itis_long %>%
  filter(rank == "species", name_usage == "valid") %>%
  select(id, species = name, path, path_rank) %>%
  distinct() %>%
  spread(path_rank, path)



## write at compression 9 for best compression
system.time({
  write_tsv(itis_hierarchy, bzfile("data/itis_hierarchy.tsv.bz2", compression=9))
})


####
## accepted == valid
### https://www.itis.gov/submit_guidlines.html#usage

taxonid <- itis_long %>%
  select(id, name, rank, name_usage, update_date) %>%
  distinct()  %>%
  arrange(id)

synonyms <- taxonid %>%
  filter(name_usage %in% c("not accepted", "invalid")) %>%
  mutate(name_usage = "synonym")

accepted <- taxonid %>%
  filter(name_usage %in% c("accepted", "valid")) %>%
   mutate(accepted_id = id,
          name_usage = "accepted")


## For deduplicate_ids() function, drop cases where synonym == accepted name
source("data-raw/helper-routines.R")


## A single name column which contains both synonyms and accepted names
## Useful for matching since we usually don't know what we have.
itis_taxonid <-
  read_tsv("taxizedb/itis/synonym_links.tsv.bz2") %>%
  rename(id = tsn, accepted_id = tsn_accepted) %>%
  mutate(id = paste0("ITIS:", id),
         accepted_id = paste0("ITIS:", accepted_id)) %>%
  mutate(update_date = as_date(update_date)) %>%
  right_join(synonyms) %>%
  bind_rows(accepted) %>%
  select(id, name, rank, accepted_id, name_type = name_usage, update_date) %>%
  de_duplicate()

## A mapping in which synonym
itis_synonyms <- full_join(
  itis_taxonid %>%
    filter(name_usage == "synonym") %>%
    select(synonym = name, synonym_id = id, accepted_id),
  itis_taxonid %>%
    filter(name_usage == "accepted") %>%
    select(-id, -name_usage)) %>%
  select(name, synonym, synonym_id, accepted_id, rank, update_date)


write_tsv(itis_synonyms, "data/itis_synonyms.tsv.bz2")
write_tsv(itis_taxonid, "data/itis_taxonid.tsv.bz2")




