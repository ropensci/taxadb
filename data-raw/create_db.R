# remotes::install_github("cboettig/arkdb")

library(arkdb)

files <- fs::dir_ls("data/", glob="*.tsv.bz2")
db <- unark(files, dbname = "data/taxa.sqlite", lines = 1e6)

R.utils::bzip2("data/taxa.sqlite")

