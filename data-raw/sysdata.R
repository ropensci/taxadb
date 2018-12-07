
library(readr)
library(dplyr)
library(usethis)
prefixes <- readr::read_tsv("https://zenodo.org/record/1250572/files/prefixes.tsv")
prefixes <- prefixes %>% dplyr::mutate(url_prefix =
                                  dplyr::recode(url_prefix,
                                         "https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?id=" =
                                         "http://ncbi.nlm.nih.gov/taxonomy/"))
usethis::use_data(prefixes, internal = TRUE, overwrite = TRUE)
