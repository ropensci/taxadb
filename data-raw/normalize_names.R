## Follow-up to names_db.R processing

library(tidyverse)
library(DBI)
con <- dbConnect(RSQLite::SQLite(), dbname="data/taxa.sql")

taxon_rank_list <- read_tsv("https://raw.githubusercontent.com/globalbioticinteractions/nomer/master/nomer/src/main/resources/org/globalbioticinteractions/nomer/match/taxon_rank_links.tsv")

rank_mapper <- taxon_rank_list %>% 
  select(pathNames = providedName, 
         rank_level_id = resolvedId, 
         rank_level = resolvedName)

clean_taxa <- inner_join(tbl(con, "taxa"), 
                         rank_mapper, 
                         copy = TRUE) %>% 
  select(id, path, path_id = pathIds, rank_level, 
         rank_level_id, common_names = commonNames, 
         external_url = externalUrl, thumbnail_url = thumbnailUrl)

tidy_taxa <- clean_taxa %>% dplyr::collect()
write_tsv(tidy_taxa, bzfile("data/tidy_taxa.tsv.bz2", compression=9))

db_path <- "data/tidy_taxa.sql"
con2 <- dbConnect(RSQLite::SQLite(), dbname=db_path)
dbListTables(con2)
dbWriteTable(con2, "taxa", tidy_taxa)
zip("data/tidy_taxa.sql.zip", db_path)

piggyback::pb_push()
piggyback::pb_pull()



