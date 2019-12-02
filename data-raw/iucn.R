library(tidyverse)
library(fs)
library(vroom)

## Go to the Redlist website, create a user, login, and set search options to include taxonomy, synoynms, and common names
## Bird data is rate-limited -- filter for Passerine birds, & then for all other birds to get it in two separate downloads
## Then also download all other vertabrates & invertabrates
## Unzip all downloads to a location specified in path


preprocess_iucn <- function(path = "~/Documents/data/redlist-downloads-2019-11-25",
                            output_paths = c(dwc = "2019/dwc_iucn.tsv.bz2",
                                             common = "2019/common_iucn.tsv.bz2")
){

  taxonomy <- dir_ls(path, type="file", recurse = TRUE, regexp = "taxonomy[.]csv") %>%
    vroom(delim=",", col_types = readr::cols(.default = "c"))
  synonyms <- dir_ls(path, type="file", recurse = TRUE, regexp = "synonyms[.]csv") %>%
    vroom(delim=",", col_types = readr::cols(.default = "c"))
  common <- dir_ls(path, type="file", recurse = TRUE, regexp = "common_names[.]csv")  %>%
    vroom(delim=",", col_types = readr::cols(.default = "c"))


  ## waaay faster to use stringi
  fix_case <- function(x) stringi::stri_trans_totitle(x) ## tools::toTitleCase(tolower(x))

  taxa <- taxonomy %>%
    select(taxonID =internalTaxonId,
           scientificName,
           kingdom = kingdomName,
           phylum = phylumName,
           class = className,
           order = orderName,
           family = familyName,
           genus = genusName,
           specificEpithet = speciesName,
           infraspecificEpithet = infraName,
           nameAccordingTo = authority) %>%
    mutate(acceptedNameUsageID = taxonID,
           taxonomicStatus = "accepted") %>%
    mutate(kingdom = fix_case(kingdom),
           phylum = fix_case(phylum),
           class = fix_case(class),
           order = fix_case(order),
           family = fix_case(family))

  syns <- synonyms %>%
    rename(taxonID = internalTaxonId, nameAccordingTo = speciesAuthor) %>%
    mutate(taxonomicStatus = "synonym", synonym = paste(genusName, speciesName)) %>%
    ## Synonyms are still `scientificName`s with diff taxonomicStatus.
    ## They inherit the higher taxonomy of their acceptedNameUsage
    select(taxonID, taxonomicStatus, synonym, nameAccordingTo, scientificName) %>%
    left_join( select(taxa, -taxonID, -taxonomicStatus, -nameAccordingTo)) %>%
    rename(acceptedNameUsage = scientificName) %>% rename(scientificName = synonym)

  vernacular <- common %>%
    filter(main == "true") %>%
    select(acceptedNameUsageID = internalTaxonId, vernacularName = name)

  dwc_iucn <-
    bind_rows(taxa, syns)  %>%
    left_join(vernacular) %>%
    mutate(taxonID = stringi::stri_paste("IUCN:", taxonID),
           acceptedNameUsageID = stringi::stri_paste("IUCN:", acceptedNameUsageID))

  common_iucn <- common %>%
    select(taxonID = internalTaxonId, vernacularName = name, language) %>%
    mutate(language = stringi::stri_extract_first_words(language)) %>%
    left_join( select(taxa, -taxonomicStatus, -nameAccordingTo)) %>%
    mutate(taxonID = stringi::stri_paste("IUCN:", taxonID),
           acceptedNameUsageID = stringi::stri_paste("IUCN:", acceptedNameUsageID))


  dir.create(dirname(output_paths["dwc"]), FALSE)
  write_tsv(dwc_iucn, output_paths["dwc"])
  write_tsv(common_iucn, output_paths["common"])

}

#piggyback::pb_upload("dwc/dwc_iucn.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")
#piggyback::pb_upload("dwc/common_iucn.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")

