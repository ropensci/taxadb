library(rfishbase)
library(tidyverse)

fb <- as_tibble(rfishbase::load_taxa())
fb_wide <- fb %>% 
  select( id = SpecCode, 
          genus = Genus, 
          species = Species, 
          subfamily = SubFamily, 
          family = Family,
          order = Order, 
          class = Class,
          common_name = FBname) %>%
  mutate(phylum = "Chorodata", 
         kingdom = "Animalia",
         id = paste0("FB:", id)) %>%
  select(id, species, genus, subfamily, 
          family, order, class, phylum,
          kingdom, common_name)
id_int <- gsub("^FB:", "", fb_wide$id)

common <- rfishbase::common_names(id_int, limit = 35000)
valid <- rfishbase::validate_names(id_int, limit = 35000)