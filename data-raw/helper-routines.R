de_duplicate <- function(species){

  ## Note for further testing: commented code below
  ## adds a column indicating how many times species name appears,
  ## & sorts with duplicates at top for inspection.
  # duplicates <- species %>% count(name) %>%
  #   inner_join(species, by ="name") %>% arrange(desc(n))

  ## Note: based on old convention:
  ## - name : scientificName
  ## - name_type : taxonomicStatus

  if("name_type" %in% colnames(species)){
    ## A common reason for duplicates is that the same name matches
    name_type <- quo(name_type)
    name <- quo(name)
    levels <- unique(species$name_type)
    levels <- c(levels[!(levels %in% "accepted")], "accepted") # make accepted the "highest"
    species <- species %>%
      ## Uses explicit factor to enforce order -- no! drops all non-matched types
      mutate(!!name_type := factor(!!name_type,  levels)) %>%
      group_by(!!name) %>% top_n(1, !!name_type)

  }
  species
}

n_in_group <- function(data, group_var, ...){
  data %>%
    group_by_(group_var) %>%
    top_n(...) %>%
    distinct_(group_var, .keep_all = TRUE)
}
