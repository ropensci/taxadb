remotes::install_github("cboettig/virtuoso")
remotes::install_github("cboettig/rdftools")


library(virtuoso)
library(readr)
library(rdftools)
library(dplyr)
library(taxald)
library(ISOcodes)


itis_long <- read_tsv("data/itis_long.tsv.bz2")

## Some langauage names have the same language code.
## ISOcodes puts duplicates in same column, we need a tidy look-up table
iso <- ISOcodes::ISO_639_2 %>%
  select(language = Name, code = Alpha_2) %>%
  na.omit() %>%
  separate(language, c("name", "name2", "name3", "name4", "name5"),
           sep = ";", extra="warn", fill = "right") %>%
  gather(key, language, -code) %>%
  select(-key) %>%
  na.omit()

itis_for_rdf <-
  itis_long %>%
  left_join(iso) %>%
  unite("common_name", common_name, code, sep = "@")

species <- itis_long %>% select(id, name, rank, common_name, update_date) %>% distinct()
classif <- itis_long %>% select(path_id, path, path_rank, path_rank_id, species_id = id) %>% distinct()
#readr::write_tsv(species, "species.tsv")
#readr::write_tsv(classif, "classif.tsv")
rdftools::write_nquads(species, "itis_species.nq.gz", prefix = "taxald:", key = "id")
rdftools::write_nquads(classif, "itis_classif.nq.gz", prefix = "taxald:", key = "path_id")



taxa_tbl("itis", "taxonid") %>%
  collect() %>%
  rdftools::write_nquads("itis_ids.nq.gz",
                         key_column = "id",
                         prefix = "taxald:")

taxa_tbl("ncbi", "taxonid") %>% collect() %>%
  rdftools::write_nquads("ncbi_ids.nq.gz",
                         key_column = "id",
                         prefix = "taxald:")
taxa_tbl("col", "taxonid") %>% collect() %>%
  rdftools::write_nquads("col_ids.nq.gz",
                         key_column = "id",
                         prefix = "taxald:")
taxa_tbl("gbif", "taxonid") %>% collect() %>%
  rdftools::write_nquads("gbif_ids.nq.gz",
                         key_column = "id",
                         prefix = "taxald:")
taxa_tbl("tpl", "taxonid") %>% collect() %>%
  rdftools::write_nquads("tpl_ids.nq.gz",
                         key_column = "id",
                         prefix = "taxald:")
taxa_tbl("fb", "taxonid") %>% collect() %>%
  rdftools::write_nquads("fb_ids.nq.gz",
                         key_column = "id",
                         prefix = "taxald:")
taxa_tbl("slb", "taxonid") %>% collect() %>%
  rdftools::write_nquads("slb_ids.nq.gz",
                         key_column = "id",
                         prefix = "taxald:")
taxa_tbl("wd", "taxonid") %>% collect() %>%
  rdftools::write_nquads("wd_ids.nq.gz",
                         key_column = "id",
                         prefix = "taxald:")
#virtuoso:::vos_delete_db()

library(virtuoso)
vos_start()
con <- vos_connect()
files <- fs::dir_ls(glob="*.nq.gz")
vos_import(con, files)


vos_query(con,
"SELECT * FROM <rdflib>
 WHERE {
    ?s ?p ?q
} LIMIT 200
")


vos_query(con,
"SELECT ?id ?name ?rank
 WHERE {
    ?id <taxald:name> ?name .
    ?id <taxald:rank> ?rank
} LIMIT 20
")

vos_query(con,
'SELECT ?id ?rank ?common
 WHERE {
    ?id <taxald:name> "Homo sapiens" .
    ?id <taxald:rank> ?rank .
    OPTIONAL { ?id <taxald:common_name> ?common . }
}
')

vos_query(con,
           'SELECT ?id ?species ?rank
  WHERE {
     ?id <taxald:name> ?species .
     ?id <taxald:rank> ?rank .
     ?id <taxald:common_name> "Human" .
 }
 ')

vos_query(con, 'SELECT ?id ?species ?rank
 WHERE {
    ?id <taxald:name> ?species .
    ?id <taxald:rank> ?rank .
    ?id <taxald:common_name> ?common_name .
    ?id <taxald:common_name> "Human" .
    FILTER langMatches(lang(?common_name), "en")
}
')

vos_query(con, 'SELECT ?id ?species ?common_name ?rank
 WHERE {
    ?id <taxald:name> ?species .
    ?id <taxald:rank> ?rank .
    ?id <taxald:common_name> ?common_name .
    FILTER(  ?common_name LIKE "%Cod%" ).
}
')


vos_query(con,
          'SELECT ?path ?rank
 WHERE {
    ?path_id <taxald:path> ?path .
    ?path_id <taxald:path_rank> ?rank

} LIMIT 20
')

vos_query(con,
          'SELECT ?id ?name ?common ?rank ?update_date
 WHERE {
    ?id <taxald:name> ?name .
    ?id <taxald:common_name> ?common .
    ?id <taxald:rank> ?rank .
    ?id <taxald:update_date> ?update_date

} LIMIT 20
')


vos_query(con,
          'SELECT DISTINCT ?p
FROM <rdflib>
 WHERE {
    ?s ?p ?o
  }
LIMIT 20
')
