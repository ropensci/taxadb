library(tidyverse)
library(httr)
links <- paste0("http://apiv3.iucnredlist.org/api/v3/species/page/",
                0:9,
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

## Or just read in result to save time
full <- read_csv("https://espm-157.github.io/extinction-module/all_species.csv")

#install.packages('rredlist')
library(rredlist)
key <- "9bb4facb6d23f48efbf424bb05c0c1ef1cf6f468393bc745d42179ac4aca5fee"
#c("Geranoaetus albicaudatus", "Hopea auriculata") %>%
synonyms <- full$scientific_name %>%
  map_dfr(function(name){
      return <- rredlist::rl_synonyms(name, key = key)
      return$result
    })

