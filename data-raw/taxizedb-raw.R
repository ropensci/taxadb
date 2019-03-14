library(readr)
library(arkdb)
library(magrittr)


#### ITIS DIRECT:
dir.create("taxizedb/itis", FALSE, TRUE)
download.file("https://www.itis.gov/downloads/itisSqlite.zip", "taxizedb/itis/itisSqlite.zip")
unzip("taxizedb/itis/itisSqlite.zip", exdir="taxizedb/itis")
dbname <- list.files(list.dirs("taxizedb/itis", recursive=FALSE), pattern="[.]sqlite", full.names = TRUE)
db <- DBI::dbConnect(RSQLite::SQLite(), dbname = dbname)
arkdb::ark(db, "taxizedb/itis", arkdb::streamable_readr_tsv(), lines = 1e6L)


dir.create("taxizedb/tpl", FALSE, TRUE)
download.file("https://github.com/cboettig/taxadb/releases/download/data/taxizedb.2ftpl.2fplantlist.tsv.bz2",
              "taxizedb/tpl/plantlist.tsv.bz2")

### NCBI Direct:
dir.create("taxizedb/ncbi", FALSE, TRUE)
download.file("ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdmp.zip", "taxizedb/ncbi/taxdmp.zip")
unzip("taxizedb/ncbi/taxdmp.zip", exdir="taxizedb/ncbi")


### COL DIRECT ###
# All snapshots available from: http://www.catalogueoflife.org/DCA_Export/archive.php
dir.create("taxizedb/col", FALSE, TRUE)
download.file("http://www.catalogueoflife.org/DCA_Export/zip-fixed/2018-annual.zip",
              "taxizedb/col/2018-annual.zip")
unzip("taxizedb/col/2018-annual.zip", exdir="taxizedb/col")
taxon <- read_tsv("taxizedb/col/taxa.txt", col_types = cols(.default = col_character()), quote = "")
vernacular <- read_tsv("taxizedb/col/vernacular.txt", col_types = cols(.default = col_character()), quote = "")
reference <- read_tsv("taxizedb/col/reference.txt", col_types = cols(.default = col_character()), quote = "")

## Not useful to us, also not very complete:
## distribution <- read_tsv("taxizedb/col/distribution.txt", col_types = cols(.default = col_character()), quote = "")     # occurrance, but sparse & coarse
## speciesprofile <- read_tsv("taxizedb/col/speciesprofile.txt", col_types = cols(.default = col_character()), quote = "") # habitat
# description <- read_tsv("taxizedb/col/description.txt", col_types = cols(.default = col_character()), quote = "") ## occurance countries



## GBIF DIRECT ###
## extracted from: https://doi.org/10.15468/39omei
dir.create("taxizedb/gbif", FALSE, TRUE)
download.file("http://rs.gbif.org/datasets/backbone/backbone-current.zip",
              "taxizedb/gbif/backbone.zip")
unzip("taxizedb/gbif/backbone.zip", exdir="taxizedb/gbif")
taxon <- read_tsv("taxizedb/gbif/Taxon.tsv")
common <- read_tsv("taxizedb/gbif/VernacularName.tsv")
fs::dir_ls("taxizedb/gbif/") %>% fs::file_delete()
## Cache original file:
write_tsv(taxon, "taxizedb/gbif/taxon.tsv.bz2")
write_tsv(common, "taxizedb/gbif/vernacular.tsv.bz2")


## Optional: cache compressed extracted files
#library(fs)
#library(piggyback)
## ENSURE GitHub PAT is available for uploading -- developers only.
#fs::dir_ls("taxizedb", type = "file", recursive = TRUE) %>%
#  piggyback::pb_upload(repo = "boettiger-lab/taxadb-cache", tag = "2019-03")
