# Queries based on fully joined records
library(dplyr)
library(taxadb)


all_ids <- function(name = NULL,
                collect = TRUE,
                db = td_connect()){
  sort <- TRUE # dummy name
  input_table <- dplyr::tibble(name, sort = 1:length(name))

  full <-
  dplyr::full_join(select(taxa_tbl("itis", "taxonid"),
                          "itis" = "accepted_id", "name", "rank"),
                   select(taxa_tbl("ncbi", "taxonid"),
                          "ncbi" = "accepted_id", "name", "rank"),
                  by = c("name", "rank")) %>%
  dplyr::full_join(select(taxa_tbl("ott", "taxonid"),
                          "ott" = "accepted_id", "name", "rank"),
                   by = c("name", "rank")) %>%
  dplyr::full_join(select(taxa_tbl("iucn", "taxonid"),
                          "iucn" = "id", "name", "rank"),
                   by = c("name", "rank")) %>%
  dplyr::full_join(select(taxa_tbl("wd", "taxonid"),
                          "wd" = "id", "name", "rank"),
                   by = c("name", "rank")) %>%
  dplyr::full_join(select(taxa_tbl("gbif", "taxonid"),
                          "gbif" = "accepted_id", "name", "rank"),
                   by = c("name", "rank")) %>%
  dplyr::full_join(select(taxa_tbl("col", "taxonid"),
                          "col" = "accepted_id", "name", "rank"),
                   by = c("name", "rank")) %>%
  dplyr::full_join(select(taxa_tbl("fb", "taxonid"),
                          "fb" = "accepted_id", "name", "rank"),
                   by = c("name", "rank")) %>%
  dplyr::full_join(select(taxa_tbl("slb", "taxonid"),
                          "slb" = "accepted_id", "name", "rank"),
                   by = c("name", "rank")) %>%
  dplyr::full_join(select(taxa_tbl("tpl", "taxonid"),
                          "tpl" = "id", "name", "rank"),
                   by = c("name", "rank"))

  # paste("SELECT * INTO newtable FROM", show_query(full))

  ## replace synonym with accepted name in each case first?

  ## Use right_join, so unmatched names are kept, with NA
  out <-
    dplyr::right_join(
      full,
      input_table,
      by = "name",
      copy = TRUE) %>%
    dplyr::arrange(sort) %>%
    select(-sort)

  if (collect && inherits(out, "tbl_lazy")) {
    ## Return an in-memory object
    return( dplyr::collect(out) )
  }

  out
}

