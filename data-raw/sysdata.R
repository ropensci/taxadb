
library(readr)
library(dplyr)
library(usethis)
prefixes <- readr::read_tsv("https://zenodo.org/record/1250572/files/prefixes.tsv")
prefixes <- prefixes %>% dplyr::mutate(url_prefix =
                                  dplyr::recode(url_prefix,
                                         "https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=" =
                                         "http://ncbi.nlm.nih.gov/taxonomy/"))
prefixes <- bind_rows(
  prefixes,
  tibble(id_prefix ="IUCN:",
         url_prefix = "http://apiv3.iucnredlist.org/api/v3/species/id/",
         url_suffix = "?token='YOUR TOKEN'")
)

usethis::use_data(prefixes, internal = TRUE, overwrite = TRUE)
