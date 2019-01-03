library(rfishbase) # 3.0
library(tidyverse)
souce("data-raw/helper-routines.R")

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
         id = paste0("FB:", id))

write_tsv(fb_wide, "data/fb_hierarchy.tsv.bz2")

accepted <- fb_wide %>% select(id, species) %>% gather(rank, name, -id)

species <- rfishbase:::fb_species()
synonym_table <- rfishbase::synonyms(NULL) %>%
  left_join(species) %>%
  rename(id = SpecCode)  %>%
  mutate(id = paste0("FB:", id),
         SynCode = paste0("FB:", SynCode),
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


write_tsv(synonyms, "data/fb_synonyms.tsv.bz2")

## Merge taxon_id and synonym id
fb_taxonid <- synonyms %>%
  rename(accepted_id = id, id = synonym_id) %>%
  select(id, name, rank, accepted_id, name_type = type) %>%
  bind_rows(mutate(accepted, accepted_id = id, name_type = "accepted")) %>%
  distinct()  %>% de_duplicate()

write_tsv(fb_taxonid, "data/fb_taxonid.tsv.bz2")


########

## Consider preserving stock code?
common <- rfishbase:::fb_tbl("comnames")  %>%
  left_join(species) %>%
  rename(id = SpecCode)  %>%
  select(id,
         species = Species,
         synonym = ComName,
         language = Language) %>%
  mutate(type = "common")


unescape_html <- function(str){
  xml2::xml_text(xml2::read_html(paste0("<x>", str, "</x>")))
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
  mutate(id = paste0("SLB:", id))

write_tsv(slb_wide, "data/slb_hierarchy.tsv.bz2")


slb_accepted <- slb_wide %>% select(id, species) %>% gather(rank, name, -id)



species <- rfishbase:::fb_species(server = "sealifebase")
syn <- rfishbase::synonyms(NULL, server = "sealifebase")

slb_synonyms <- syn %>%
  left_join(species) %>%
  rename(id = SpecCode)  %>%
  mutate(id = paste0("SLB:", id),
         SynCode = paste0("SLB:", SynCode),
         TaxonLevel = tolower(TaxonLevel)) %>%
  select(id,
         accepted_name = Species,
         name = synonym,
         type = Status,
         synonym_id = SynCode,
         rank = TaxonLevel)

write_tsv(slb_synonyms, "data/slb_synonyms.tsv.bz2")


slb_taxonid <- slb_synonyms %>%
  rename(accepted_id = id, id = synonym_id) %>%
  select(id, name, rank, accepted_id, name_type = type) %>%
  bind_rows(mutate(slb_accepted, accepted_id = id, name_type = "accepted")) %>%
  distinct() %>% de_duplicate()

write_tsv(slb_taxonid, "data/slb_taxonid.tsv.bz2")




