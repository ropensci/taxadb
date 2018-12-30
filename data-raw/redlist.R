library(tidyverse)
library(httr)
links <- paste0("http://apiv3.iucnredlist.org/api/v3/species/page/",
                0:10,
                "?token=9bb4facb6d23f48efbf424bb05c0c1ef1cf6f468393bc745d42179ac4aca5fee")
system.time({

  full <- links %>%
    map_df(function(link){
      GET(link) %>%
        content() %>%
        getElement("result") %>%
        map_df(function(x){
          x %>% purrr::flatten() %>% as.tibble()
        })
    })
})


sentence_case <- function(x) {
  Hmisc::capitalize(str_to_lower(x))
  #gsub("(. )([A-Z])(.+)", "\\1\\U\\2\\L\\3", x)
}
hierarchy <- full %>% select(id = taxonid, kingdom = kingdom_name, phylum = phylum_name,
                class = class_name, order = order_name, family = family_name,
                genus = genus_name, species = scientific_name) %>%
  mutate_if(is.character, sentence_case) %>%
  mutate(id = paste0("IUCN:", id))

dir.create("data", FALSE)
write_tsv(hierarchy, "data/iucn_hierarchy.tsv.bz2")

#, category   infra_rank    infra_name      population   )

## Or just read in result to save time
full2 <- read_csv("https://espm-157.github.io/extinction-module/all_species.csv")

#install.packages('rredlist')
library(rredlist)
key <- "9bb4facb6d23f48efbf424bb05c0c1ef1cf6f468393bc745d42179ac4aca5fee"
#c("Geranoaetus albicaudatus", "Hopea auriculata") %>%
synonyms <- full$scientific_name %>%
  map_dfr(function(name){
      return <- rredlist::rl_synonyms(name, key = key)
      return$result
    })



common <- full$scientific_name %>%
  map_dfr(function(name){
    return <- rredlist::rl_common_names(name, key = key)
    return$result
  })
