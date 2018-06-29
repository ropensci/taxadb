library(rfishbase) # 3.0
library(tidyverse)

fb <- as_tibble(rfishbase::load_taxa())
fb_wide <- fb %>% 
  select( id = SpecCode, 
          genus = Genus, 
          species = Species, 
          subfamily = Subfamily, 
          family = Family,
          order = Order, 
          class = Class,
          superclass = SuperClass) %>%
  mutate(phylum = "Chorodata", 
         kingdom = "Animalia",
         id = paste0("FB:", id))

write_tsv(fb_wide, "data/fb_hierarchy.tsv.bz2")

species <- rfishbase:::fb_species()
synonyms <- rfishbase::synonyms(NULL) %>%
  left_join(species) %>% 
  rename(id = SpecCode)  %>% 
  select(id,
         species = Species,
         synonym,
         type = Status,
         syn_id = SynCode,
         rank = TaxonLevel, 
         tsn = TSN, 
         col = CoL_ID, 
         worms = WoRMS_ID, 
         zoobank = ZooBank_ID)



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

write_tsv(slb_wide, "data/slb_hierarchy.tsv.bz2")



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
