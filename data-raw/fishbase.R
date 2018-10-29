library(rfishbase) # 3.0
library(tidyverse)




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

fb_taxonid <- fb_wide %>% select(id, species) %>% gather(rank, name, -id)
write_tsv(fb_taxonid, "data/fb_taxonid.tsv.bz2")


species <- rfishbase:::fb_species()
synonyms <- rfishbase::synonyms(NULL) %>%
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

write_tsv(synonyms, "data/fb_synonyms.tsv.bz2")

##Collapse taxonid and synonym 
# all the info we need is already in the synonym table
# multiple kinds of synonyms (see unique(ids_syn$type)), not sure what they all mean
ids_syn <- synonyms %>%
  select(id, rank, name, type, synonym_id) #can decide if we want to keep synonym_id
  

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
          subfamily = Subfamily, 
          family = Family,
          order = Order, 
          class = Class,
          phylum = Phylum,
          kingdom = Kingdom) %>%
  mutate(id = paste0("SLB:", id)) 

write_tsv(slb_wide, "data/slb_hierarchy.tsv.bz2")


slb_taxonid <- slb_wide %>% select(id, species) %>% gather(rank, name, -id)
write_tsv(slb_taxonid, "data/slb_taxonid.tsv.bz2")



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
