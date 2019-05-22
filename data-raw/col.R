library(dplyr)
library(readr)
library(stringi)
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

## scientificNameAuthorship tagged on to scientificName, and in inconsistent format. trim it off.
taxa <- taxon %>%
  mutate(taxonomicStatus = forcats::fct_recode(taxonomicStatus, "accepted" = "accepted name")) %>%
  select(taxonID, scientificName, acceptedNameUsageID, taxonomicStatus, taxonRank,
         kingdom, phylum, class, order, family, genus, specificEpithet, infraspecificEpithet,
         taxonConceptID, isExtinct, nameAccordingTo, namePublishedIn, scientificNameAuthorship)

taxa <- bind_rows(
  taxa %>%
    filter(!is.na(scientificNameAuthorship)) %>%
    mutate(scientificName =
           stri_trim(stri_replace_first_fixed(scientificName, scientificNameAuthorship, ""))),
  taxa %>%
    filter(is.na(scientificNameAuthorship))
)



## For accepted names, set acceptedNameUsageID to match taxonID, rather NA
accepted <-
  filter(taxa, taxonomicStatus == "accepted") %>%
  mutate(acceptedNameUsageID = taxonID)
rest <-
  filter(taxa, taxonomicStatus != "accepted") %>%
  filter(!is.na(acceptedNameUsageID)) # We drop un-mapped synonyms, as they are not helpful

##Common Names

#common name table
comm_table <- vern %>% select(taxonID, vernacularName, language) %>%
  left_join(bind_rows(accepted, rest) %>% 
              select(taxonID, acceptedNameUsageID, scientificName, taxonomicStatus, taxonRank), 
            by = "taxonID")

write_tsv(comm_table, "common/common_col.tsv.bz2")

#add a common name to the master dwc table
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
  left_join(comm_names %>% select(taxonID, vernacularName), by = "taxonID") %>%
  mutate(taxonID = stringi::stri_paste("COL:", taxonID),
         acceptedNameUsageID = stringi::stri_paste("COL:", acceptedNameUsageID))
dir.create("dwc", FALSE)
write_tsv(dwc_col, "dwc/col.tsv.bz2")


#library(piggyback)
#piggyback::pb_upload("dwc/col.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")
#piggyback::pb_upload("common/common_col.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")
