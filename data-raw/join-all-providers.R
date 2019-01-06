# Queries based on fully joined records

any_id <- function(names){
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

}
