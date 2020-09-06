#' @importFrom utils globalVariables
globalVariables(c("taxonID", "scientificName", "kingdom", "phylum", "class", "order", "family", "genus", "species",
                  "taxonConceptID", "isExtinct", "specificEpithet", "infraspecificEpithet", "nameAccordingTo",
                  "namePublishedIn", "scientificNameAuthorship", "namePublishedIn", "vernacularName", "language",
                  "Species", "SpecCode", "Class", "SuperClass", "Family", "Order", "Genus", "Species", "type", "TaxonLevel",
                  "synonym", "name", "Language", "commonNames", "accepted_id", "synonym_id", "SynCode", "taxon",
                  "taxonomicStatus", "acceptedNameUsageID"))

#' preprocess_col
#'
#' @param url Source of Catalogue of Life
#' @param output_paths paths where output will be written: must be two paths, one named dwc, one named common
#' @param dir working directory for downloads, will be tempdir() by default
#'
#' @export
#' @import stringi forcats readr dplyr
#' @importFrom methods className
#' @importFrom stats family setNames
#' @importFrom utils download.file untar unzip
#' @details NOTE: A list of  all snapshots available from: http://www.catalogueoflife.org/DCA_Export/archive.php
preprocess_col <- function(url = paste0("http://www.catalogueoflife.org/DCA_Export/zip-fixed/",
                                        2019,
                                        "-annual.zip"),
                           output_paths = c(dwc = "2019/dwc_col.tsv.bz2",
                                            common = "2019/common_col.tsv.bz2"),
                           dir = file.path(tempdir(), "col")){


  dir.create(dir, FALSE, FALSE)
  curl::curl_download(url,
                file.path(dir, "col-annual.zip"))
  unzip(file.path(dir, "col-annual.zip"), exdir=dir)

  ## a better read_tsv
  read_tsv <- function(...) readr::read_tsv(..., quote = "",
                                            col_types = readr::cols(.default = "c"))


  taxon <- read_tsv(file.path(dir, "taxa.txt"))
  reference <- read_tsv(file.path(dir, "reference.txt"))

  ## scientificNameAuthorship tagged on to scientificName, and in inconsistent format. trim it off.
  taxa_tmp <- taxon %>%
    mutate(taxonomicStatus = forcats::fct_recode(taxonomicStatus, "accepted" = "accepted name")) %>%
    select(taxonID, scientificName, acceptedNameUsageID, taxonomicStatus, taxonRank,
           kingdom, phylum, class, order, family, genus, specificEpithet, infraspecificEpithet,
           taxonConceptID, isExtinct, nameAccordingTo, namePublishedIn, scientificNameAuthorship)
  taxa <- bind_rows(
    taxa_tmp %>%
      filter(!is.na(scientificNameAuthorship)) %>%
      mutate(scientificName =
             stri_trim(stri_replace_first_fixed(scientificName, scientificNameAuthorship, ""))),
    taxa_tmp %>%
      filter(is.na(scientificNameAuthorship))
  )

  ## For accepted names, set acceptedNameUsageID to match taxonID, rather NA
  accepted <-
    filter(taxa, taxonomicStatus %in% c("accepted", "provisionally accepted name")) %>%
    mutate(acceptedNameUsageID = taxonID)

  accepted_heirarchy <- select(accepted, -acceptedNameUsageID, -scientificName, -taxonomicStatus)
  rest <-
    filter(taxa, taxonomicStatus != "accepted") %>%
    filter(!is.na(acceptedNameUsageID)) %>%
    select(taxonID, scientificName, acceptedNameUsageID, taxonomicStatus) %>%
    left_join(accepted_heirarchy, by = c("acceptedNameUsageID" = "taxonID"))


  # We drop un-mapped synonyms, as they are not helpful

  vernacular <- read_tsv(file.path(dir, "vernacular.txt"))
  #First we create the separate common names table
  comm_table <- vernacular %>%
    select(taxonID, vernacularName, language) %>%
    inner_join(bind_rows(accepted), by = "taxonID") %>%
    mutate(taxonID = stringi::stri_paste("COL:", taxonID),
           acceptedNameUsageID = stringi::stri_paste("COL:", acceptedNameUsageID)
           )

  # Also add a common name to the master dwc table
  # first english names,
  # #why doesn't this return a unique list of taxonID without distinct()??
  comm_eng <- vernacular %>%
    filter(language == "English") %>%
    n_in_group(group_var = "taxonID", n = 1, wt = vernacularName)

  #get the rest
  comm_names <- vernacular %>%
    filter(!taxonID %in% comm_eng$taxonID) %>%
    n_in_group(group_var = "taxonID", n = 1, wt = vernacularName) %>%
    bind_rows(comm_eng)  %>%
    select(taxonID, vernacularName)

  ## stri_paste respects NAs, avoids "<prefix>:NA"
  dwc_col <-
    bind_rows(accepted, rest) %>%
    left_join(comm_names, by = "taxonID") %>%
    mutate(taxonID = stringi::stri_paste("COL:", taxonID),
           acceptedNameUsageID = stringi::stri_paste("COL:", acceptedNameUsageID))


  message("writing COL Output...\n")

 write_tsv(dwc_col, output_paths[["dwc"]])
 write_tsv(comm_table, output_paths[["common"]])

}





in_url <- paste0("http://www.catalogueoflife.org/DCA_Export/zip-fixed/", 2020, "-annual.zip")
in_file <- "/minio/shared-data/taxadb/ott/col-2020-annual.zip"
dir.create(dirname(in_file))
curl::curl_download(in_url, in_file)
code <- c("data-raw/col.R","data-raw/helper-routines.R")
output_paths <- c(dwc = "2019/dwc_col.tsv.bz2",
                 common = "2019/common_col.tsv.bz2")

source("data-raw/helper-routines.R")

## HERE WE GO!
preprocess_col(url = in_url, output_paths = output_paths)

## And publish provenance
prov:::minio_store(c(in_file, code, output_paths), "https://minio.thelio.carlboettiger.info", dir = "/minio/")
prov::write_prov(data_in = in_file, code = code, data_out =  unname(output_paths), prov="data-raw/prov.json", append=TRUE)


