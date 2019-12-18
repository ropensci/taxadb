library(dplyr)
library(readr)
library(forcats)
library(stringi)
source("data-raw/helper-routines.R")

# All snapshots available from: http://www.catalogueoflife.org/DCA_Export/archive.php

preprocess_col <- function(url = paste0("http://www.catalogueoflife.org/DCA_Export/zip-fixed/",
                                        2019,
                                        "-annual.zip"),
                           output_paths = c(dwc = "2019/dwc_col.tsv.bz2",
                                            common = "2019/common_col.tsv.bz2")){

  dir = file.path(tempdir(), "col")
  dir.create(dir, FALSE, FALSE)
  download.file(url,
                file.path(dir, "col-annual.zip"))
  unzip(file.path(dir, "col-annual.zip"), exdir=dir)

  ## a better read_tsv
  read_tsv <- function(...) readr::read_tsv(..., quote = "",
                                            col_types = readr::cols(.default = "c"))


  taxon <- read_tsv(file.path(dir, "taxa.txt"))
  reference <- read_tsv(file.path(dir, "reference.txt"))

  ## scientificNameAuthorship tagged on to scientificName, and in inconsistent format. trim it off.
  taxa_tmp <- taxon %>%
    mutate(taxonomicStatus = forcats::fct_recode(taxonomicStatus, "accepted" = "accepted name")) %>%
    select(taxonID, scientificName, acceptedNameUsageID, taxonomicStatus, taxonRank,
           kingdom, phylum, class, order, family, genus, specificEpithet, infraspecificEpithet,
           taxonConceptID, isExtinct, nameAccordingTo, namePublishedIn, scientificNameAuthorship)

  taxa <- bind_rows(
    taxa_tmp %>%
      filter(!is.na(scientificNameAuthorship)) %>%
      mutate(scientificName =
             stri_trim(stri_replace_first_fixed(scientificName, scientificNameAuthorship, ""))),
    taxa_tmp %>%
      filter(is.na(scientificNameAuthorship))
  )

  ## For accepted names, set acceptedNameUsageID to match taxonID, rather NA
  accepted <-
    filter(taxa, taxonomicStatus %in% c("accepted", "provisionally accepted name")) %>%
    mutate(acceptedNameUsageID = taxonID)

  accepted_heirarchy <- select(accepted, -acceptedNameUsageID, -scientificName, -taxonomicStatus)
  rest <-
    filter(taxa, taxonomicStatus != "accepted") %>%
    filter(!is.na(acceptedNameUsageID)) %>%
    select(taxonID, scientificName, acceptedNameUsageID, taxonomicStatus) %>%
    left_join(accepted_heirarchy, by = c("acceptedNameUsageID" = "taxonID"))

  # We drop un-mapped synonyms, as they are not helpful


  vernacular <- read_tsv(file.path(dir, "vernacular.txt"))
  #First we create the separate common names table
  comm_table <- vernacular %>%
    select(taxonID, vernacularName, language) %>%
    inner_join(bind_rows(accepted), by = "taxonID") %>%
    mutate(taxonID = stringi::stri_paste("COL:", taxonID),
           acceptedNameUsageID = stringi::stri_paste("COL:", acceptedNameUsageID))


  # Also add a common name to the master dwc table
  # first english names,
  # #why doesn't this return a unique list of taxonID without distinct()??
  comm_eng <- vernacular %>%
    filter(language == "English") %>%
    n_in_group(group_var = "taxonID", n = 1, wt = vernacularName)

  #get the rest
  comm_names <- vernacular %>%
    filter(!taxonID %in% comm_eng$taxonID) %>%
    n_in_group(group_var = "taxonID", n = 1, wt = vernacularName) %>%
    bind_rows(comm_eng)  %>%
    select(taxonID, vernacularName)

  ## stri_paste respects NAs, avoids "<prefix>:NA"
  ## de-duplicate avoids cases where an accepted name is also listed as a synonym.
  dwc_col <-
    bind_rows(accepted, rest) %>%
    left_join(comm_names, by = "taxonID") %>%
    mutate(taxonID = stringi::stri_paste("COL:", taxonID),
           acceptedNameUsageID = stringi::stri_paste("COL:", acceptedNameUsageID))


  dir.create(dirname(output_paths["dwc"]), FALSE)
  write_tsv(dwc_col, output_paths["dwc"])
  write_tsv(comm_table, output_paths["common"])

  file_hash(output_paths)
}


#preprocess_col(year = "2019")
#library(piggyback)
#piggyback::pb_upload("dwc/dwc_col.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")
#piggyback::pb_upload("dwc/common_col.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")





##Common Names
#get ID's that have no accepted sciname
#syn_names <- rest %>%
#  filter(!acceptedNameUsageID %in% accepted$acceptedNameUsageID) %>%
#  n_in_group(group_var = "acceptedNameUsageID", n = 1, wt = scientificName)
