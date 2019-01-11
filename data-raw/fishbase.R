library(rfishbase) # 3.0
library(tidyverse)
library(stringi)
source("data-raw/helper-routines.R")

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

## Rename things to Darwin Core
fb <- fb_taxonid %>%
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
  by = "taxonID")

write_tsv(fb, "dwc/fb.tsv.bz2")



########

## Consider preserving stock code?
common <- rfishbase:::fb_tbl("comnames")  %>%
  left_join(species) %>%
  rename(id = SpecCode)  %>%
  select(id,
         species = Species,
         synonym = ComName,
         language = Language) %>%
  mutate(type = "common",
         id = stri_paste("FB:", id))


unescape_html <- function(str){
  xml2::xml_text(xml2::read_html(stri_paste("<x>", str, "</x>")))
}


fb_synonyms <-
common %>%
  bind_rows(synonyms)



###### sealifebase #######################



slb <- as_tibble(rfishbase::load_taxa(server = "sealifebase"))
slb_wide <- slb %>%
  select( id = SpecCode,
          genus = Genus,
          species = Species,
          subfamily = Subfamily,
          family = Family,
          order = Order,
          class = Class,
          phylum = Phylum,
          kingdom = Kingdom) %>%
  mutate(id = stri_paste("SLB:", id))

slb_accepted <- slb_wide %>% select(id, species) %>% gather(rank, name, -id)



species <- rfishbase:::fb_species(server = "sealifebase")
syn <- rfishbase::synonyms(NULL, server = "sealifebase")

slb_synonyms <- syn %>%
  left_join(species) %>%
  rename(id = SpecCode)  %>%
  mutate(id = stri_paste("SLB:", id),
         SynCode = stri_paste("SLB:", SynCode),
         TaxonLevel = tolower(TaxonLevel)) %>%
  select(id,
         accepted_name = Species,
         name = synonym,
         type = Status,
         synonym_id = SynCode,
         rank = TaxonLevel)

slb_taxonid <- slb_synonyms %>%
  rename(accepted_id = id, id = synonym_id) %>%
  select(id, name, rank, accepted_id, name_type = type) %>%
  bind_rows(mutate(slb_accepted, accepted_id = id, name_type = "accepted")) %>%
  distinct() %>% de_duplicate()



## Rename things to Darwin Core
slb <- slb_taxonid %>%
  rename(taxonID = id,
         scientificName = name,
         taxonRank = rank,
         taxonomicStatus = name_type,
         acceptedNameUsageID = accepted_id) %>%
  left_join(slb_wide %>%
              select(taxonID = id,
                     kingdom, phylum, class, order, family, genus,
                     specificEpithet = species
                     #infraspecificEpithet
              ),
            by = "taxonID")

write_tsv(slb, "dwc/slb.tsv.bz2")




