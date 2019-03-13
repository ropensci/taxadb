library(dplyr)
library(readr)
source("data-raw/helper-routines.R")

# All snapshots available from: http://www.catalogueoflife.org/DCA_Export/archive.php
dir.create("taxizedb/col", FALSE, TRUE)
download.file("http://www.catalogueoflife.org/DCA_Export/zip-fixed/2018-annual.zip",
              "taxizedb/col/2018-annual.zip")
unzip("taxizedb/col/2018-annual.zip", exdir="taxizedb/col")

char <- cols(.default = col_character())

taxon <- read_tsv("taxizedb/col/taxa.txt", col_types = char, quote = "")
vern <- read_tsv("taxizedb/col/vernacular.txt", col_types = char, quote = "")
#reference <- read_tsv("taxizedb/col/reference.txt", col_types = char, quote = "")

taxa <- taxon %>%
  select(taxonID, genericName, acceptedNameUsageID, taxonomicStatus, taxonRank,
         kingdom, phylum, class, order, family, genus, specificEpithet, infraspecificEpithet,
         taxonConceptID, isExtinct, nameAccordingTo, namePublishedIn) %>%
  rename(scientificName = genericName) %>%
  mutate(taxonomicStatus = forcats::fct_recode(taxonomicStatus, "accepted" = "accepted name"))

## acceptedNameUsageID should match taxonID for an accepted name

## acceptedNameUsageID should be included on all accepted names.
accepted <-
  filter(taxa, taxonomicStatus == "accepted") %>%
  mutate(acceptedNameUsageID = taxonID)
rest <-
  filter(taxa, taxonomicStatus != "accepted") %>%
  filter(!is.na(acceptedNameUsageID)) # We drop un-mapped synonyms, as they are not helpful

#first english names,
##why doesn't this return a unique list of taxonID without distinct()??
comm_eng <- vern %>%
  filter(language == "English") %>%
  n_in_group(group_var = "taxonID", n = 1, wt = vernacularName)

#get the rest
comm_names <- vern %>%
  filter(!taxonID %in% comm_eng$taxonID) %>%
  n_in_group(group_var = "taxonID", n = 1, wt = vernacularName) %>%
  bind_rows(comm_eng)

## stri_paste respects NAs, avoids "GBIF:NA"
## de-duplicate avoids cases where an accepted name is also listed as a synonym.
dwc_col <-
  bind_rows(accepted, rest) %>%
  de_duplicate() %>%
  left_join(comm_names %>% select(taxonID, vernacularName), by = "taxonID") %>%
  mutate(taxonID = stringi::stri_paste("COL:", taxonID),
         acceptedNameUsageID = stringi::stri_paste("COL:", acceptedNameUsageID))
dir.create("dwc", FALSE)
write_tsv(dwc_col, "dwc/col.tsv.bz2")


#library(piggyback)
#piggyback::pb_upload("dwc/col.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")

