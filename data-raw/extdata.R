## Script to prepare the data files included in extdata from original sources


url <- "ftp://ftpext.usgs.gov/pub/er/md/laurel/BBS/DataFiles/SpeciesList.txt"
col_names <- c("Seq", "AOU", "English_Common_Name", "French_Common_Name",
               "Spanish_Common_Name", "order", "family", "genus", "species")
bbs <- readr::read_table(url,
                         skip = 9,
                         col_names = col_names,
                         col_types = "ccccccccc")
bbs <- bbs %>% mutate(species = paste(genus, species))
readr::write_tsv(bbs,  "../inst/extdata/bbs.tsv")
