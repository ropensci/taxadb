library(dplyr)
library(stringi)
library(readr)
source("data-raw/helper-routines.R")

## extracted from: https://doi.org/10.15468/39omei

  preprocess_gbif <- function(year = "2019", dir = file.path(tempdir(), "gbif")){

  dir.create(dir, FALSE, FALSE)
  download.file("http://rs.gbif.org/datasets/backbone/backbone-current.zip",
                file.path(dir, "backbone.zip"))
  unzip(file.path(dir, "backbone.zip"), exdir=dir)

  ## a better read_tsv
  read_tsv <- function(...) readr::read_tsv(..., quote = "", col_types = readr::cols(.default = "c"))

  ## And here we go!
  taxon <- read_tsv(file.path(dir, "Taxon.tsv"))
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
  vern <-  read_tsv(file.path(dir, "VernacularName.tsv"))
  #join common names with all sci name data
  common <- vern %>% select(taxonID, vernacularName, language) %>%
    inner_join(bind_rows(accepted, rest), by = "taxonID") %>%
    distinct() %>%
    mutate(taxonID = stringi::stri_paste("GBIF:", taxonID),
           acceptedNameUsageID = stringi::stri_paste("GBIF:", acceptedNameUsageID))

  #first english names,
  ##why doesn't this return a unique list of taxonID without distinct()??
  comm_eng <- common %>%
    filter(language == "en") %>%
    n_in_group(group_var = "taxonID", n = 1, wt = vernacularName)

  #get the rest
  comm_names <- vern %>%
    filter(!taxonID %in% comm_eng$taxonID) %>%
    n_in_group(group_var = "taxonID", n = 1, wt = vernacularName) %>%
    bind_rows(comm_eng)


  ## include vernacularName from commonName table

  ## stri_paste respects NAs, avoids "GBIF:NA"
  ## de-duplicate avoids cases where an accepted name is also listed as a synonym.
  dwc_gbif <-
    bind_rows(accepted, rest) %>%
    left_join(comm_names %>% select(taxonID, vernacularName), by = "taxonID") %>%
    mutate(taxonID = stringi::stri_paste("GBIF:", taxonID),
           acceptedNameUsageID = stringi::stri_paste("GBIF:", acceptedNameUsageID))

  dir.create("dwc", FALSE)
  write_tsv(dwc_gbif, "dwc/dwc_gbif.tsv.bz2")
  write_tsv(dwc_gbif, "dwc/common_gbif.tsv.bz2")

}

#piggyback::pb_upload("dwc/dwc_gbif.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag="dwc")
#piggyback::pb_upload("dwc/common_gbif.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")
