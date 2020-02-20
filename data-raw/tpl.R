#' @export
preprocess_tpl <- function(output_files = c(dwc = "2019/dwc_tpl.tsv.bz2")){
  archive <- file.path(tempdir(), "plantlist.tsv.bz2")
  download.file("https://github.com/cboettig/taxadb/releases/download/data/taxizedb.2ftpl.2fplantlist.tsv.bz2",
                archive)

  read_tsv <- function(...) readr::read_tsv(..., quote = "", col_types = readr::cols(.default = "c"))
  tpl_taxa <- read_tsv(archive)

  ## note: only has accepted names
  # tpl_taxa %>% count(taxonomic_status_in_tpl)
  tpl_dwc <- tpl_taxa %>%
    mutate(id = stri_paste("TPL:", id),
           scientificName = stri_paste(genus, species),
           taxonRank = "species",
           taxonomicStatus = "accepted",
           acceptedNameUsageID = id,
           kingdom = "plantae", phylum = NA, class = NA, order = NA)  %>%
    select(taxonID = id,
           scientificName,
           taxonRank,
           acceptedNameUsageID,
           kingdom, phylum, class, order, family, genus,
           specificEpithet = species,
           infraspecificEpithet = infraspecific_epithet,
           scientificNameAuthorship = authorship,
           namePublishedInYear = date,
           nomenclaturalStatus = nomenclatural_status_from_original_data_source)

  write_tsv(tpl_dwc, output_files["dwc"])
  file_hash(output_files)
}




