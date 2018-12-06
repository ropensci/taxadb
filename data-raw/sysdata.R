

prefixes <- readr::read_tsv("https://zenodo.org/record/1250572/files/prefixes.tsv")
usethis::use_data(prefixes, internal = TRUE)
