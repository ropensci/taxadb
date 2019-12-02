library(rfishbase) # 3.0
library(tidyverse)
library(stringi)
source(here::here("data-raw/helper-routines.R"))

preprocess_fb <- function(output_paths = c(dwc = "2019/dwc_fb.tsv.bz2",
                                           common = "2019/common_fb.tsv.bz2")
                          ){
  #### Fishbase
  fb <- as_tibble(rfishbase::load_taxa())
  fb_wide <- fb %>%
    select( id = SpecCode,
            species = Species,
            genus = Genus,
            subfamily = Subfamily,
            family = Family,
            order = Order,
            class = Class,
            superclass = SuperClass) %>%
    mutate(phylum = "Chorodata",
           kingdom = "Animalia",
           id = stri_paste("FB:", id))

  accepted <- fb_wide %>% select(id, species) %>% gather(rank, name, -id)
  species <- rfishbase:::fb_species()
  synonym_table <- rfishbase::synonyms(NULL) %>%
    left_join(species) %>%
    rename(id = SpecCode)  %>%
    mutate(id = stri_paste("FB:", id),
           SynCode = stri_paste("FB:", SynCode),
           TaxonLevel = tolower(TaxonLevel)) %>%
    select(id,
           accepted_name = Species,
           name = synonym,
           type = Status,
           synonym_id = SynCode,
           rank = TaxonLevel)

  #find accepted names that are actually useful synonym maps, create table with just synonyms
  synonyms <- synonym_table %>%
    filter(type == "accepted name", accepted_name != name) %>%
    select(-type) %>%
    mutate(type = "epithet synonym") %>%
    rename(name = "accepted_name", accepted_name = "name") %>%
    bind_rows(synonym_table %>% filter(type != "accepted name"))

  ## Merge taxon_id and synonym id
  fb_taxonid <- synonyms %>%
    rename(accepted_id = id, id = synonym_id) %>%
    select(id, name, rank, accepted_id, name_type = type) %>%
    bind_rows(mutate(accepted, accepted_id = id, name_type = "accepted")) %>%
    distinct()  %>% de_duplicate()

  ## Get common names
  fb_common <- common_names()

  #first english names
  comm_eng <- fb_common %>%
    filter(Language == "en") %>%
    n_in_group(group_var = "SpecCode", n = 1, wt = ComName)

  #get the rest
  comm_names <- fb_common %>%
    filter(!SpecCode %in% comm_eng$SpecCode) %>%
    n_in_group(group_var = "SpecCode", n = 1, wt = ComName) %>%
    bind_rows(comm_eng) %>%
    mutate(id = stri_paste("FB:", SpecCode)) %>%
    ungroup(SpecCode)

  ## Rename things to Darwin Core
  dwc <- fb_taxonid %>%
    rename(taxonID = id,
           scientificName = name,
           taxonRank = rank,
           taxonomicStatus = name_type,
           acceptedNameUsageID = accepted_id) %>%
    left_join(fb_wide %>%
                select(taxonID = id,
                       kingdom, phylum, class, order, family, genus,
                       specificEpithet = species
                       #infraspecificEpithet
                       ),
    by = "taxonID") %>%
    left_join(comm_names %>% select(taxonID = id, vernacularName = ComName))

  species <- stringi::stri_extract_all_words(dwc$specificEpithet, simplify = TRUE)
  dwc$specificEpithet <- species[,2]
  dwc$infraspecificEpithet <- species[,3]


  ################# Common name table #################
  #join common names with all sci name data
  common <- fb_common %>%
    mutate(taxonID = stri_paste("FB:", SpecCode)) %>%
    select(taxonID, vernacularName = ComName, language = Language) %>%
    inner_join(dwc %>% select(-vernacularName), by = "taxonID")

  # just want one sci name per accepted name ID, first get accepted names,
  # then pick a synonym for ID's that don't have an accepted name
  accepted_comm <- common %>% filter(taxonomicStatus == "accepted")
  # there's only one ID that doesn't have an accepted name
  rest_comm <- common %>%
    filter(!acceptedNameUsageID %in% accepted_comm$acceptedNameUsageID)
  # but there's only one synonym (and therefore one sciname)
  # so we can just keep all the entries (the table below is empty)
  common %>%
    filter(!acceptedNameUsageID %in% accepted_comm$acceptedNameUsageID) %>%
    group_by(acceptedNameUsageID) %>%
    filter(n_distinct(scientificName)>1)

  comm_table <- bind_rows(accepted_comm, rest_comm)

  write_tsv(dwc, output_paths["dwc"])
  write_tsv(comm_table, output_paths["common"])
  output_paths
}

# preprocess_fb()

# piggyback::pb_upload( "dwc/fb.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")
# piggyback::pb_upload("dwc/common_fb.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")

