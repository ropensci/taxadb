
#' @import arkdb RSQLite DBI readr dpylr

preprocess_itis <- function(url = "https://www.itis.gov/downloads/itisSqlite.zip",
                            output_paths =
                              c(dwc = "2019/dwc_itis.tsv.bz2",
                                common = "2019/common_itis.tsv.bz2")
){

  archive <- file.path(tempdir(), "itis",  "itisSqlite.zip")
  dir <- dirname(archive)
  dir.create(dir, FALSE, FALSE)
  download.file(url, archive)
  message(paste(file_hash(archive)))

  unzip(archive, exdir=dir)
  dbname <- list.files(list.dirs(dir, recursive=FALSE), pattern="[.]sqlite", full.names = TRUE)
  db <- DBI::dbConnect(RSQLite::SQLite(), dbname = dbname)
  arkdb::ark(db, dir, arkdb::streamable_readr_tsv(), lines = 1e6L)

  ## defaulting to logicals is so annoying!
  read_tsv <- function(...) readr::read_tsv(..., quote = "", col_types = readr::cols(.default = "c"))


  ## not that rank_id isn't a unique id by itself!
  rank_tbl <-
    read_tsv(file.path(dir, "taxon_unit_types.tsv.bz2")) %>%
    select(kingdom_id, rank_id, rank_name) %>%
    collect() %>%
    unite(rank_id, -rank_name, sep = "-") %>%
    mutate(rank_name =
             stringr::str_remove_all(
              stringr::str_to_lower(rank_name),"\\s"))

  hierarch <-
    read_tsv(file.path(dir, "taxonomic_units.tsv.bz2")) %>%
    mutate(rank_id = paste(kingdom_id, rank_id, sep="-")) %>%
    select(tsn, parent_tsn, rank_id, complete_name) %>% distinct()

  itis <-
    left_join(
      inner_join(hierarch, rank_tbl, copy = TRUE),
      read_tsv(file.path(dir, "hierarchy.tsv.bz2")) %>%
        select(tsn = TSN, parent_tsn = Parent_TSN, hierarchy_string)
    ) %>%
    arrange(tsn) %>%
    select(tsn, complete_name, rank_name,
           rank_id, parent_tsn, hierarchy_string) %>%
    left_join(
              select(read_tsv(file.path(dir, "vernaculars.tsv.bz2")),
                     tsn, vernacular_name, language))  %>%
   left_join(
              select(read_tsv(file.path(dir, "taxonomic_units.tsv.bz2")),
                    tsn, update_date, name_usage)
    ) %>%
    rename(id = tsn,
           parent_id = parent_tsn,
           common_name = vernacular_name,
           name = complete_name,
           rank = rank_name)  %>%
    mutate(id = stri_paste("ITIS:", id),
           rank_id = stri_paste("ITIS:", rank_id),
           parent_id = stri_paste("ITIS:", parent_id))


  ## transforms we do in R
  itis$hierarchy_string <- gsub("(\\d+)", "ITIS:\\1",
                                     gsub("-", " | ",
                                          itis$hierarchy_string))
  itis <- itis %>% rename(hierarchy = hierarchy_string)


  ## Go into long form:
  longform <- function(row, pattern = "\\s*\\|\\s*"){
    row_as_df <-
      tibble(id = row$id,
                 name = row$name,
                 rank = row$rank,
                 path_id = str_split(row$hierarchy, pattern)[[1]],
                 common_name = row$common_name,
                 language = row$language,
                 update_date = row$update_date,
                 name_usage = row$name_usage)

  }

  hier_expand <- itis %>%
    select(id, path = name, path_rank = rank, path_rank_id = rank_id)

  as_date <- function(x){
    class(x) <- "Date"
    x
  }

  itis_long <- itis %>%
    purrr::transpose() %>%
    map_dfr(longform) %>%
    left_join(hier_expand, by = c("path_id" = "id")) %>%
    distinct() %>%
    select(id, name, rank, common_name, language, path,
           path_rank, path_id, path_rank_id, name_usage, update_date) %>%
    mutate(update_date = as_date(update_date))



  ## Wide-format classification table (scientific names only)
  itis_hierarchy <-
    itis_long %>%
    filter(rank == "species", name_usage == "valid") %>%
    select(id, species = name, path, path_rank) %>%
    distinct() %>%
    spread(path_rank, path)


  ####
  ## accepted == valid
  ### https://www.itis.gov/submit_guidlines.html#usage

  taxonid <- itis_long %>%
    select(id, name, rank, name_usage, update_date) %>%
    distinct() %>%
    mutate(update_date = as.character(update_date)) # date type not robust on joins

  synonyms <- taxonid %>%
    filter(name_usage %in% c("not accepted", "invalid")) %>%
    mutate(name_usage = "synonym")

  accepted <- taxonid %>%
    filter(name_usage %in% c("accepted", "valid")) %>%
     mutate(accepted_id = id,
            name_usage = "accepted")

  ## A single name column which contains both synonyms and accepted names
  ## Useful for matching since we usually don't know what we have.
  itis_taxonid <-
    read_tsv(file.path(dir, "synonym_links.tsv.bz2")) %>%
    rename(id = tsn, accepted_id = tsn_accepted) %>%
    mutate(id = stri_paste("ITIS:", id),
           accepted_id = stri_paste("ITIS:", accepted_id)) %>%
    select(-update_date) %>%
    right_join(synonyms, by = "id") %>%
    bind_rows(accepted) %>%
    select(id, name, rank, accepted_id, name_type = name_usage, update_date) %>%
    de_duplicate()


  dwc_core <- itis_taxonid %>%
    rename(taxonID = id,
           scientificName = name,
           taxonRank = rank,
           taxonomicStatus = name_type,
           acceptedNameUsageID = accepted_id) %>%
    left_join(itis_hierarchy %>%
                select(taxonID = id,
                       kingdom, phylum, class, order, family, genus,
                       specificEpithet = species
                       #infraspecificEpithet
                ),
              by = c("acceptedNameUsageID" =  "taxonID")) 
  

  species <- stringi::stri_extract_all_words(dwc_core$specificEpithet, simplify = TRUE)
  dwc_core$specificEpithet <- species[,2]
  dwc_core$infraspecificEpithet <- species[,3]



  # get common names #
  vern <- read_tsv(file.path(dir, "vernaculars.tsv.bz2")) %>%
    mutate(acceptedNameUsageID = stri_paste("ITIS:", tsn)) %>%
    select(-tsn)

  #first the ones with accepted common names
  acc_common <- vern %>%
    filter(approved_ind == "Y")

  #of those left grab the english name if there is one
  acc_common <- vern %>%
    filter(!acceptedNameUsageID %in% acc_common$acceptedNameUsageID, language == "English") %>%
    n_in_group(group_var = "acceptedNameUsageID", n = 1, wt = vernacular_name) %>%
    bind_rows(acc_common)

  #then the rest just grab the first alphabetically
  com_names <-  vern %>%
    filter(!acceptedNameUsageID %in% acc_common$acceptedNameUsageID) %>%
    group_by(acceptedNameUsageID) %>%
    top_n(n = 1, wt = vernacular_name) %>%
    bind_rows(acc_common) %>%
    distinct(acceptedNameUsageID, .keep_all = TRUE)


  ## add vernacular name
  dwc <- dwc_core %>%
    left_join(com_names %>%
                select(vernacularName = vernacular_name, acceptedNameUsageID),
              by = "acceptedNameUsageID") %>%
    distinct()
  
  
  ## Common name table
  common <-  vern %>%
    select(-approved_ind, -vern_id) %>%
    inner_join(dwc %>% select(-vernacularName, -update_date)) %>%
    rename(vernacularName = vernacular_name)


  dir.create(dirname(output_paths["dwc"]), FALSE)
  write_tsv(dwc, output_paths["dwc"])
  write_tsv(common, output_paths["common"])

  file_hash(output_paths)

}
#piggyback::pb_upload("dwc/dwc_itis.tsv.bz2", repo = "boettiger-lab/taxadb-cache")
#piggyback::pb_upload("dwc/common_itis.tsv.bz2", repo = "boettiger-lab/taxadb-cache")


