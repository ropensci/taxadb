#' @importFrom tidyr drop_na gather

###### sealifebase #######################
#' @export
preprocess_slb <- function(output_paths = c(dwc = "2019/dwc_slb.tsv.bz2",
                                            common = "2019/common_slb.tsv.bz2")){

  slb <- as_tibble(rfishbase::load_taxa(server = "sealifebase"))
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
    mutate(id = stri_paste("SLB:", id))

  slb_accepted <- slb_wide %>% select(id, species) %>% gather(rank, name, -id)



  species <- rfishbase:::fb_species(server = "sealifebase")
  syn <- rfishbase::synonyms(NULL, server = "sealifebase")

  slb_synonyms <- syn %>%
    left_join(species) %>%
    rename(id = SpecCode)  %>%
    mutate(id = stri_paste("SLB:", id),
           SynCode = stri_paste("SLB:", SynCode),
           TaxonLevel = tolower(TaxonLevel)) %>%
    select(id,
           accepted_name = Species,
           name = synonym,
           type = Status,
           synonym_id = SynCode,
           rank = TaxonLevel)

  slb_taxonid <- slb_synonyms %>%
    rename(accepted_id = id, id = synonym_id) %>%
    select(id, name, rank, accepted_id, name_type = type) %>%
    bind_rows(mutate(slb_accepted, accepted_id = id, name_type = "accepted")) %>%
    distinct() %>% de_duplicate()

  ## Get common names
  slb_common <- rfishbase::common_names(server = "sealifebase") %>%
    drop_na(ComName)

  #first english names
  comm_eng <- slb_common %>%
    filter(Language == "English") %>%
    n_in_group(group_var = "SpecCode", n = 1, wt = ComName)

  #get the rest
  comm_names <- slb_common %>%
    filter(!SpecCode %in% comm_eng$SpecCode) %>%
    n_in_group(group_var = "SpecCode", n = 1, wt = ComName) %>%
    bind_rows(comm_eng) %>%
    mutate(taxonID = stri_paste("SLB:", SpecCode)) %>%
    ungroup(SpecCode)

  ## Rename things to Darwin Core
  dwc_slb <- slb_taxonid %>%
    rename(taxonID = id,
           scientificName = name,
           taxonRank = rank,
           taxonomicStatus = name_type,
           acceptedNameUsageID = accepted_id) %>%
    left_join(slb_wide %>%
                select(taxonID = id,
                       kingdom, phylum, class, order, family, genus,
                       specificEpithet = species
                       #infraspecificEpithet
                ),
              by = "taxonID") %>%
    left_join(comm_names %>% select(taxonID , vernacularName = ComName))

  species <- stringi::stri_extract_all_words(dwc_slb$specificEpithet, simplify = TRUE)
  dwc_slb$specificEpithet <- species[,2]
  dwc_slb$infraspecificEpithet <- species[,3]

  dwc_slb <- dwc_slb %>%
    mutate(taxonomicStatus = forcats::fct_recode(taxonomicStatus, "accepted" = "accepted name"))


  ############# Common name table ######
  #join common names with all sci name data
  common <- slb_common %>%
    mutate(taxonID = stri_paste("SLB:", SpecCode)) %>%
    select(taxonID, vernacularName = ComName, language = Language) %>%
    inner_join(dwc_slb %>% select(-vernacularName), by = "taxonID") %>%
    distinct()

  #just want one sci name per accepted name ID, first get accepted names,
  # then pick a synonym for ID's that don't have an accepted name
  accepted_comm <- common %>% filter(taxonomicStatus %in% c("accepted", "accepted name"))

  #there are many ID's without an accepted name
  rest_comm <- common %>%
    filter(!acceptedNameUsageID %in% accepted_comm$acceptedNameUsageID)

  #there are only two accepted ID's (shown in table below) that have duplicate entries for common names,
  # indicating that they mapped to multiple scientific names, I think it's ok to keep them
  common %>%
    filter(!acceptedNameUsageID %in% accepted_comm$acceptedNameUsageID) %>%
    group_by(acceptedNameUsageID) %>%
    filter(n_distinct(scientificName)>1, n_distinct(vernacularName) != n())



  write_tsv(dwc_slb, output_paths["dwc"])
  write_tsv(common, output_paths["common"])

  file_hash(output_paths)
}

#preprocess_slb()
#piggyback::pb_upload("dwc/dwc_slb.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")
#piggyback::pb_upload("dwc/common_slb.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")

