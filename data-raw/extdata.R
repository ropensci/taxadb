library(readr)
library(dplyr)
library(purrr)

## Script to prepare the data files included in extdata from original sources


## Breeding Bird Survey
url <- "ftp://ftpext.usgs.gov/pub/er/md/laurel/BBS/DataFiles/SpeciesList.txt"
col_names <- c("Seq", "AOU", "English_Common_Name", "French_Common_Name",
               "Spanish_Common_Name", "order", "family", "genus", "species")
bbs <- readr::read_table(url,
                         skip = 9,
                         col_names = col_names,
                         col_types = "ccccccccc")
bbs <- bbs %>% mutate(species = paste(genus, species))
readr::write_tsv(bbs,  "../inst/extdata/bbs.tsv")


## Elton bird trait data
elton <-
  read_tsv("https://ndownloader.figshare.com/files/5631081", guess_max = 10000) %>%
  select(Scientific, mass = `BodyMass-Value`, common = English)%>%
  mutate(itis = get_ids(Scientific, "itis"))

## Subset of data where names are synonyms by ITIS
traits_ <-
  elton$Scientific %>%
  by_name("itis") %>%
  filter(taxonomicStatus != "accepted") %>%
  select(Scientific = scientificName) %>%
  inner_join(elton) %>%
  head(10) %>%
  select(elton_name = Scientific, mass) %>%
  mutate(name_A = get_names(get_ids(elton_name)))


key <- "9bb4facb6d23f48efbf424bb05c0c1ef1cf6f468393bc745d42179ac4aca5fee"
status_data <-
  traits_$elton_name  %>%
  get_ids("iucn") %>% #could use IUCN id directly
  get_names("iucn") %>%
  map(rredlist::rl_search, key = key) %>%
  map_df("result") %>%
  select(name_B = scientific_name, category) %>%
  as_tibble()

trait_data <-
  traits_ %>%
  mutate(name_A = coalesce(name_A, elton_name)) %>% # replace NA with fallback name
  select(name_A, mass)


readr::write_tsv(trait_data,  "inst/extdata/trait_data.tsv")
readr::write_tsv(status_data,  "inst/extdata/status_data.tsv")



## bad -- only a single species resulves both mass and
#full_join( trait_data, status_data, by = c("name_A"= "name_B" ),
#           na_matches = "never")

## good
#full_join(
#  trait_data %>% mutate(id = get_ids(name_A, "col")),
#  status_data %>% mutate(id = get_ids(name_B, "col")),
#  na_matches = "never") %>%
#  select(id,name_A, mass, category, name_B)


