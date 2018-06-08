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

write_tsv(fb_wide, "data/fb_wide.tsv.bz2")



slb <- as_tibble(rfishbase::load_taxa(server = "https://fishbase.ropensci.org/sealifebase"))
slb_wide <- slb %>% 
  select( id = SpecCode, 
          genus = Genus, 
          species = Species, 
          subfamily = SubFamily, 
          family = Family,
          order = Order, 
          class = Class,
          common_name = FBname) %>%
  mutate(id = paste0("SLB:", id)) %>%
  select(id, species, genus, subfamily, 
         family, order, class, common_name)

write_tsv(slb_wide, "data/slb_wide.tsv.bz2")



## Get common names and alternate / misspelled names too
ids <- gsub("^FB:", "", fb_wide$id)

valid <- vector("list", 7)
common <- vector("list", 7)
for(i in 7){
  start <- (i-1)*5000+1
  end <- (i-1)*5000
  id_int <- ids[start:end]
  common[[i]] <- rfishbase::common_names(id_int, limit = 5000)
  valid[[i]] <- rfishbase::validate_names(id_int, limit = 5000)
  
}
