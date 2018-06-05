## apt-get -y install mariadb-client postgresql-client
library(DBI)
library(dplyr)
library(dbplyr)
#remotes::install_github("ropensci/taxizedb")
library(taxizedb) 
library(readr)


itis_store <- db_download_itis()
## Need to fix locale issue
#db_load_itis(itis_store, user = "postgres", pwd = "password", host = "postgres")
itis_db <- src_itis(user = "postgres", password = "password", host = "postgres")


itis_taxa <- 
  left_join(
    inner_join(
      tbl(itis_db, "taxonomic_units") %>% select(tsn, parent_tsn, rank_id, complete_name) %>% distinct(),
      tbl(itis_db, "taxon_unit_types") %>% select(rank_id, rank_name)  %>% distinct()
    ), 
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

itis <- collect(itis_taxa)

itis <- itis %>%
  mutate(rank_name = stringr::str_remove_all(
                       stringr::str_to_lower(rank_name),
                       "\\s"))


itis$hierarchy_string <- gsub("(\\d+)", "ITIS:\\1",
                                   gsub("-", " | ", 
                                        itis$hierarchy_string))
itis <- itis %>% rename(hierarchy = hierarchy_string)


## Go into long form as well


## write at compression 9 for best compression
write_tsv(itis_taxa, "data/itis.tsv.bz2")

system.time({
  write_tsv(itis_taxa, "data/itis.tsv.gz")
})




