

# See ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump_archive/

#' @export
preprocess_ncbi <- function(url = "ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdmp.zip",
                            output_paths =
                              c(dwc = "2020/dwc_ncbi.tsv.gz",
                                common = "2020/common_ncbi.tsv.gz")){


  dir <- file.path(tempdir(), "ncbi")
  archive <- file.path(dir, "taxdmp.zip")
  dir.create(dir, FALSE, FALSE)
  download.file("ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdmp.zip", archive)
  message(paste(file_hash(archive)))


  unzip(archive, exdir=dir)

  node_cols <- c(
  "tax_id",
  "parent_tax_id",
  "rank",
  "embl_code",
  "division_id",
  "inherited_div_flag",
  "genetic_code_id",
  "inherited_GC_flag",
  "mitochondrial_genetic_code_id",
  "inherited_MGC_flag",
  "GenBank_hidden_flag",
  "hidden_subtree_root",
  "comments"
  )
node_types <- c("iiclilililllc")

  nodes <- vroom::vroom(file.path(dir, "nodes.dmp"), quote = "", delim = "\t|\t",
                             col_names = node_cols, col_types = node_types)

  name_cols <- c("tax_id", "name_txt", "unique_name", "name_class", "blank")
  name_type <- c("icccc")
  names <-  vroom::vroom(file.path(dir, "names.dmp"),
                         delim = "\t|",
                         col_names = name_cols,
                         col_types = name_type, quote ="")
  ncbi_taxa <-
    inner_join(nodes,names) %>%
    select(tax_id, parent_tax_id, rank, name_txt, unique_name, name_class)


  ncbi_ids <- ncbi_taxa %>%
    select(tsn = tax_id, parent_tsn = parent_tax_id) %>%
    distinct() %>%
    mutate(tsn = paste0("NCBI:", tsn),
           parent_tsn = paste0("NCBI:", parent_tsn))

  ## note: NCBI doesn't have rank ids
  ncbi <- ncbi_taxa %>%
    select(id = tax_id, name = name_txt, rank, name_type = name_class) %>%
    mutate(id = paste0("NCBI:", id))

  rm(list= c ("ncbi_taxa", "nodes", "names"))

  ## Recursively JOIN on id = parent
  ## FIXME do properly with recursive function and dplyr programming calls
  recursive_ncbi_ids <- ncbi_ids %>%
    left_join(rename(ncbi_ids, p2 = parent_tsn), by = c("parent_tsn" = "tsn")) %>%
    left_join(rename(ncbi_ids, p3 = parent_tsn), by = c("p2" = "tsn")) %>%
    left_join(rename(ncbi_ids, p4 = parent_tsn), by = c("p3" = "tsn")) %>%
    left_join(rename(ncbi_ids, p5 = parent_tsn), by = c("p4" = "tsn")) %>%
    left_join(rename(ncbi_ids, p6 = parent_tsn), by = c("p5" = "tsn")) %>%
    left_join(rename(ncbi_ids, p7 = parent_tsn), by = c("p6" = "tsn")) %>%
    left_join(rename(ncbi_ids, p8 = parent_tsn), by = c("p7" = "tsn")) %>%
    left_join(rename(ncbi_ids, p9 = parent_tsn), by = c("p8" = "tsn")) %>%
    left_join(rename(ncbi_ids, p10 = parent_tsn), by = c("p9" = "tsn")) %>%
    left_join(rename(ncbi_ids, p11 = parent_tsn), by = c("p10" = "tsn")) %>%
    left_join(rename(ncbi_ids, p12 = parent_tsn), by = c("p11" = "tsn")) %>%
    left_join(rename(ncbi_ids, p13 = parent_tsn), by = c("p12" = "tsn")) %>%
    left_join(rename(ncbi_ids, p14 = parent_tsn), by = c("p13" = "tsn")) %>%
    left_join(rename(ncbi_ids, p15 = parent_tsn), by = c("p14" = "tsn")) %>%
    left_join(rename(ncbi_ids, p16 = parent_tsn), by = c("p15" = "tsn")) %>%
    left_join(rename(ncbi_ids, p17 = parent_tsn), by = c("p16" = "tsn")) %>%
    left_join(rename(ncbi_ids, p18 = parent_tsn), by = c("p17" = "tsn")) %>%
    left_join(rename(ncbi_ids, p19 = parent_tsn), by = c("p18" = "tsn")) %>%
    left_join(rename(ncbi_ids, p20 = parent_tsn), by = c("p19" = "tsn")) %>%
    left_join(rename(ncbi_ids, p21 = parent_tsn), by = c("p20" = "tsn")) %>%
    left_join(rename(ncbi_ids, p22 = parent_tsn), by = c("p21" = "tsn")) %>%
    left_join(rename(ncbi_ids, p23 = parent_tsn), by = c("p22" = "tsn")) %>%
    left_join(rename(ncbi_ids, p24 = parent_tsn), by = c("p23" = "tsn")) %>%
    left_join(rename(ncbi_ids, p25 = parent_tsn), by = c("p24" = "tsn")) %>%
    left_join(rename(ncbi_ids, p26 = parent_tsn), by = c("p25" = "tsn")) %>%
    left_join(rename(ncbi_ids, p27 = parent_tsn), by = c("p26" = "tsn")) %>%
    left_join(rename(ncbi_ids, p28 = parent_tsn), by = c("p27" = "tsn")) %>%
    left_join(rename(ncbi_ids, p29 = parent_tsn), by = c("p28" = "tsn")) %>%
    left_join(rename(ncbi_ids, p30 = parent_tsn), by = c("p29" = "tsn")) %>%
    left_join(rename(ncbi_ids, p31 = parent_tsn), by = c("p30" = "tsn")) %>%
    left_join(rename(ncbi_ids, p32 = parent_tsn), by = c("p31" = "tsn")) %>%
    left_join(rename(ncbi_ids, p33 = parent_tsn), by = c("p32" = "tsn")) %>%
    left_join(rename(ncbi_ids, p34 = parent_tsn), by = c("p33" = "tsn")) %>%
    left_join(rename(ncbi_ids, p35 = parent_tsn), by = c("p34" = "tsn")) %>%
    left_join(rename(ncbi_ids, p36 = parent_tsn), by = c("p35" = "tsn")) %>%
    left_join(rename(ncbi_ids, p37 = parent_tsn), by = c("p36" = "tsn")) %>%
    left_join(rename(ncbi_ids, p38 = parent_tsn), by = c("p37" = "tsn"))

  rm(ncbi_ids)
  ## expect_true: confirm we have resolved all ids
  all(recursive_ncbi_ids[[length(recursive_ncbi_ids)]] == "NCBI:1")

  ## many more ids than path_ids
  long_hierarchy <-
    recursive_ncbi_ids %>%
    tidyr::gather(dummy, path_id, -tsn) %>%
    select(id = tsn, path_id) %>%
    distinct() %>%
    arrange(id)

  rm(recursive_ncbi_ids)

  expand <- ncbi %>%
    select(path_id = id, path = name, path_rank = rank, path_type = name_type)

  ncbi_long <- ncbi %>%
    filter(name_type == "scientific name") %>%
    select(-name_type) %>%
    inner_join(long_hierarchy) %>%
    inner_join(expand)

  ## Example query: how many species of fishes do we know?
  #fishes <- ncbi_long %>%
  #  filter(path == "fishes", rank == "species") %>%
  #  select(id, name, rank) %>% distinct()
  # 33,082 known species

  ## de-duplication of duplicate ranks
  tmp1 <- ncbi_long %>%
  #filter(path_type == "scientific name", rank == "species") %>%
    select(id, species = name, path, path_rank) %>%
    distinct() %>%
    # ncbii has a few duplicate "superfamily" with both as "scientific name"
    # This is probably a bug in there data as one of these should be "synonym"(?)
    filter(path_rank != "no rank") %>% ## Wide format includes named ranks only
    filter(path_rank != "superfamily")

  tmp2 <- tmp1 %>% group_by(id, path_rank) %>% top_n(1, wt = path)
  rank <- ncbi %>% select(id, name, rank, name_type) %>% distinct()

  ncbi_wide <- tmp2 %>% spread(path_rank, path) %>% distinct() %>% left_join(rank)


  ## Get common names for each entry
  ncbi_common <- ncbi %>%
    filter(name_type == "common name") %>%
    n_in_group(group_var = "id", n = 1, wt = name) %>%
    select(id, name)


  ##### Rename things to Darwin Core
  dwc <- ncbi_wide %>%
    rename(taxonID = id,
           scientificName = name,
           taxonRank = rank,
           taxonomicStatus = name_type) %>%
    mutate(acceptedNameUsageID = taxonID) %>%
    select(taxonID, scientificName, taxonRank,
           taxonomicStatus, acceptedNameUsageID,
           kingdom, phylum, class, order, family, genus,
           specificEpithet = species) %>% ungroup()

  dwc$taxonID[dwc$taxonomicStatus  != "scientific name"] <- NA_character_
  dwc$taxonomicStatus[dwc$taxonomicStatus  == "scientific name"] <- "accepted"


  #Common name table
  comm_table <- dwc %>%
    filter(taxonomicStatus == "common name") %>%
    select(acceptedNameUsageID, vernacularName = scientificName) %>%
    right_join(dwc) %>%
    #for this provider every acceptedNameUsageID has one accepted scientific name,
    ##  so just filter for those
    filter(taxonomicStatus == "accepted") %>%
    select(vernacularName, scientificName, taxonRank, taxonID, acceptedNameUsageID, taxonomicStatus)

  write_tsv(dwc, output_paths["dwc"])
  write_tsv(comm_table, output_paths["common"])

  file_hash(output_paths)

}

#reprocess_ncbi()

#library(piggyback)
#setwd("2019")
#piggyback::pb_upload("dwc_ncbi.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "2019")
#piggyback::pb_upload("common_ncbi.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "2019")

