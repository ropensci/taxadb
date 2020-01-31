

test_ott <- function(dwc){
  ## testing
  dwc %>%
    filter(!is.na(infraspecificEpithet),
           taxonRank == "species", !is.na(genus)) %>%
    select(scientificName, taxonRank,
           taxonomicStatus, genus,
           specificEpithet, infraspecificEpithet)


  #unlink("ott3.0.tgz")
  #unlink("ott", recursive = TRUE)

  ###################


  ## Debug info: use this to view the duplicated ranks.
  has_duplicate_rank <- pre_spread %>%
    group_by(id, path_rank) %>%
    summarise(l = length(path)) %>%
    filter(l>1)
  dups <- pre_spread %>%
    semi_join(select(has_duplicate_rank, id, path_rank))

  x = tidy_names(c("class", "class"))

  dedup_ex <- dups  %>%
    mutate(orig_rank = path_rank) %>%
    group_by(id, orig_rank) %>%
    mutate(path_rank = tidy_names(orig_rank, quiet = TRUE)) %>%
    select(-orig_rank)
  dedup_ex


  rm(has_duplicate_rank, dups)

  ## Worse method, takes first among the duplicates
  #pre_spread <- pre_spread %>% mutate(row = 1:n())
  #tmp <- pre_spread %>% select(id, path_rank, row)
  # %>% group_by(path_rank) %>% top_n(1)
  #uniques <- left_join(tmp, pre_spread,
  # by = c("row", "id",  "path_rank")) %>% ungroup()
}
