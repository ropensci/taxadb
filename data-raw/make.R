
library(conflicted)
library(tidyverse)
library(rfishbase) # 3.0
library(fs)
library(here)
library(RSQLite)
library(drake)
conflict_prefer("gather", "tidyr")
conflict_prefer("expand", "tidyr")
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")
conflict_scout()

message(fs::path_wd())

devtools::load_all()
#plan <- drake_plan(

tag <- "2020"

## 2020 annual not released yet
## col_source <- paste0("http://www.catalogueoflife.org/DCA_Export/zip-fixed/", tag, "-annual.zip")
col_source <- "http://www.catalogueoflife.org/DCA_Export/zip-fixed/2020-01-10-archive-complete.zip"
ott_source <- "http://files.opentreeoflife.org/ott/ott3.2/ott3.2.tgz"
gbif_source <- "http://rs.gbif.org/datasets/backbone/backbone-current.zip"
itis_source <- "https://www.itis.gov/downloads/itisSqlite.zip"
ncbi_source <- "ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdmp.zip"
# 
# contenturi::register_remote(col_source)
# contenturi::register_remote(ott_source)
# contenturi::register_remote(gbif_source)
# contenturi::register_remote(itis_source)



fb = preprocess_fb(output_paths = c(dwc = file.path(tag, "dwc_fb.tsv.bz2"),
                                    common = file.path(tag, "common_fb.tsv.bz2")))

slb = preprocess_slb(output_paths = c(dwc = file.path(tag, "dwc_slb.tsv.bz2"),
                                    common = file.path(tag, "common_slb.tsv.bz2")))

ott = preprocess_ott(url = ott_source,
                     output_paths = c(dwc = file.path(tag, "dwc_ott.tsv.bz2"),
                                      common = file.path(tag, "common_ott.tsv.bz2")))


gbif = preprocess_gbif(url = gbif_source,
                       output_paths = c(dwc = file.path(tag, "dwc_gbif.tsv.bz2"),
                                        common = file.path(tag, "common_gbif.tsv.bz2")))

itis = preprocess_itis(url = itis_source,
                       output_paths = c(dwc = file.path(tag, "dwc_itis.tsv.bz2"),
                                        common = file.path(tag, "common_itis.tsv.bz2")))

ncbi = preprocess_ncbi(url = ncbi_source,
                       output_paths = c(dwc = file.path(tag, "dwc_ncbi.tsv.bz2"),
                                        common = file.path(tag, "common_ncbi.tsv.bz2")))

col = preprocess_col(url = col_source,
                     output_paths = c(dwc = file.path(tag, "dwc_col.tsv.bz2"),
                                      common = file.path(tag, "common_col.tsv.bz2")),
                     dir = "col")


#)

# library(piggyback)
# setwd("2020"); fs::dir_ls("*.bz2") %>% pb_upload(repo = "boettiger-lab/taxadb-cache", tag = tag)

library(pins)
board_register_github(repo = "cboettig/pins-test", name = "github_pins_test")
pin("2020/dwc_gbif.tsv.bz2", board = "github_pins_test")


#config <- drake_config(plan)
#vis_drake_graph(config)
#drake::make(plan)
