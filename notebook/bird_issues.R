gbif_birds <- bbs %>%
  pull(species) %>%
  ids("gbif") %>%
  filter(sort == 185)

gbif_birds %>% count(sort) %>% arrange(desc(n))
get_ids(bbs$species, "gbif") %>% length()
descendants(id = c("GBIF:4966628", "GBIF:2481745", "GBIF:9786750"), provider = "gbif")
