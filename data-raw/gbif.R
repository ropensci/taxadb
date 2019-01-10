
library(tidyverse)
source("data-raw/helper-routines.R")

## Minimal pre-processing into static files is done in taxizedb-raw.R
piggyback::pb_download(repo="cboettig/taxadb", tag = "data") # raw data cache
coltypes <- cols(
  .default = col_character(),
  taxonID = col_double(),
  parentNameUsageID = col_double(),
  acceptedNameUsageID = col_double(),
  originalNameUsageID = col_double(),
  nameAccordingTo = col_character(),
  nomenclaturalStatus = col_character()
)
taxon <- read_tsv("taxizedb/gbif/taxon.tsv.bz2", col_types = coltypes)
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
## Note that even within GBIF, formatting of scientificNameAuthorship is highly non-standard (parens, abbrv, initials, etc)
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

## stri_paste respects NAs, avoids "GBIF:NA"
## de-duplicate avoids cases where an accepted name is also listed as a synonym.
dwc_gbif <-
  bind_rows(accepted, rest) %>%
  de_duplicate() %>%
  mutate(taxonID = stringi::stri_paste("GBIF:", taxonID),
         acceptedNameUsageID = stringi::stri_paste("GBIF:", acceptedNameUsageID))
dir.create("dwc", FALSE)
write_tsv(dwc_gbif, "dwc/gbif.tsv.bz2")

piggyback::pb_upload("dwc/gbif.tsv.bz2", repo="cboettig/taxadb", tag="v1.0.0")
