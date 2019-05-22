library(dplyr)
library(stringi)
library(readr)
source("data-raw/helper-routines.R")

dir.create("taxizedb/gbif", FALSE, TRUE)
download.file("http://rs.gbif.org/datasets/backbone/backbone-current.zip",
              "taxizedb/gbif/backbone.zip")
unzip("taxizedb/gbif/backbone.zip", exdir="taxizedb/gbif")

coltypes <- cols(
  .default = col_character(),
  taxonID = col_double(),
  parentNameUsageID = col_double(),
  acceptedNameUsageID = col_double(),
  originalNameUsageID = col_double(),
  nameAccordingTo = col_character(),
  nomenclaturalStatus = col_character()
)
taxon <- read_tsv("taxizedb/gbif/Taxon.tsv", col_types = coltypes)

# refs <- vroom::vroom("taxizedb/gbif/Reference.tsv")


## canonicalName appears to be: Genus + specificEpithet + infraspecificEpithet
## i.e. SpecificEpithet ~ a name at the "species" rank
## Scientific name is ~ canonical name + citation parenthetical
## Darwin Core defines ScientificName as: 	The full scientific name,
## with authorship and date information if known. When forming part of an
## Identification, this should be the name in lowest level taxonomic rank
## that can be determined. This term should not contain identification
## qualifications, which should instead be supplied in the IdentificationQualifier term.

## This is unfortunate as author & date formatting introduces a huge
## amount of variation that is difficult to resolve against, and best treated as a separate field.

## genericName and canonicalName are not Darwin Core Taxon properties
## Note that even within GBIF, formatting of scientificNameAuthorship
## is highly non-standard (parens, abbrv, initials, etc)
gbif <- taxon %>%
  select(taxonID,
         scientificName = canonicalName,
         taxonRank,
         taxonomicStatus,
         acceptedNameUsageID,
         kingdom, phylum, class, order, family, genus, specificEpithet, infraspecificEpithet,
         parentNameUsageID,
         originalNameUsageID,
         scientificNameAuthorship)

## acceptedNameUsageID should be included on all accepted names.
accepted <- filter(gbif, taxonomicStatus == "accepted") %>% mutate(acceptedNameUsageID = taxonID)
rest <- filter(gbif, taxonomicStatus != "accepted") %>% filter(!is.na(acceptedNameUsageID))


##Common Names
## Get common names
vern <- read_tsv("taxizedb/gbif/VernacularName.tsv")

#common name table
comm_table <- vern %>% select(taxonID, vernacularName, language) %>%
  left_join(bind_rows(accepted, rest), by = "taxonID") %>%
  mutate(taxonID = stringi::stri_paste("GBIF:", taxonID),
         acceptedNameUsageID = stringi::stri_paste("GBIF:", acceptedNameUsageID)) %>%
  #drop names that don't have an accepted ID 
  drop_na(acceptedNameUsageID)

write_tsv(comm_table, "common/common_gbif.tsv.bz2")

#first english names,
##why doesn't this return a unique list of taxonID without distinct()??
comm_eng <- vern %>%
  filter(language == "en") %>%
  n_in_group(group_var = "taxonID", n = 1, wt = vernacularName)

#get the rest
comm_names <- vern %>%
  filter(!taxonID %in% comm_eng$taxonID) %>%
  n_in_group(group_var = "taxonID", n = 1, wt = vernacularName) %>%
  bind_rows(comm_eng)

## stri_paste respects NAs, avoids "GBIF:NA"
## de-duplicate avoids cases where an accepted name is also listed as a synonym.
dwc_gbif <-
  bind_rows(accepted, rest) %>%
  left_join(comm_names %>% select(taxonID, vernacularName), by = "taxonID") %>%
  mutate(taxonID = stringi::stri_paste("GBIF:", taxonID),
         acceptedNameUsageID = stringi::stri_paste("GBIF:", acceptedNameUsageID))
dir.create("dwc", FALSE)
write_tsv(dwc_gbif, "dwc/gbif.tsv.bz2")

#piggyback::pb_upload("dwc/gbif.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag="dwc")
#piggyback::pb_upload("common/common_gbif.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")