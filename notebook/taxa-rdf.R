remotes::install_github("cboettig/virtuoso")
remotes::install_github("cboettig/rdftools")

library(virtuoso)
library(readr)
library(rdftools)
library(dplyr)
library(taxald)

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
'SELECT ?id ?rank
 WHERE {
    ?id <taxald:name> "Homo sapiens" .
    ?id <taxald:rank> ?rank
} LIMIT 20
')

vos_query(con,
          'SELECT ?id ?name
 WHERE {
    ?id <taxald:name> ?name .
    ?id <taxald:rank> "kingdom"
} LIMIT 20
')

