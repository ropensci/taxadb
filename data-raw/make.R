library(conflicted)


library(drake)

library(tidyr)
library(dplyr)
library(readr)
library(forcats)
library(stringi)
library(rfishbase) # 3.0
library(fs)
library(here)
library(RSQLite)

conflict_prefer("gather", "tidyr")
conflict_prefer("expand", "tidyr")
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")
conflict_scout()

source(here("data-raw/helper-routines.R"))


source(here("data-raw/itis.R"))
source(here("data-raw/gbif.R"))


#plan <- drake_plan(


gbif = preprocess_gbif(url = file_in("http://rs.gbif.org/datasets/backbone/backbone-current.zip"),
                       output_paths = c(dwc = file_out("2019/dwc_gbif.tsv.bz2"),
                                        common = file_out("2019/common_gbif.tsv.bz2")))

itis = preprocess_itis(url = file_in("https://www.itis.gov/downloads/itisSqlite.zip"),
                       output_paths = c(dwc = file_out("2019/dwc_itis.tsv.bz2"),
                                        common = file_out("2019/common_itis.tsv.bz2")))

ncbi = preprocess_ncbi(url = file_in("ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdmp.zip"),
                      output_paths = c(dwc = file_out("2019/dwc_ncbi.tsv.bz2"),
                                       common = file_out("2019/common_ncbi.tsv.bz2")))

col = preprocess_col(url = file_in("http://www.catalogueoflife.org/DCA_Export/zip-fixed/2019-annual.zip"),
                     output_paths = c(dwc = file_out("2019/dwc_col.tsv.bz2"),
                                      common = file_out("2019/common_col.tsv.bz2")))


fb = preprocess_fb(output_paths = c(dwc = file_out("2019/dwc_fb.tsv.bz2"),
                                    common = file_out("2019/common_fb.tsv.bz2")))

slb = preprocess_slb(output_paths = c(dwc = file_out("2019/dwc_slb.tsv.bz2"),
                                    common = file_out("2019/common_slb.tsv.bz2")))

ott = preprocess_ott(url = file_in("http://files.opentreeoflife.org/ott/ott3.2/ott3.2.tgz"),
                     output_paths = c(dwc = file_out("2019/dwc_ott.tsv.bz2"),
                                      common = file_out("2019/common_ott.tsv.bz2")))


#)


#config <- drake_config(plan)
#vis_drake_graph(config)
#drake::make(plan)


# piggyback::pb_upload( "dwc/fb.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")
# piggyback::pb_upload("dwc/common_fb.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")




#piggyback::pb_upload("dwc/dwc_slb.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")
#piggyback::pb_upload("dwc/common_slb.tsv.bz2", repo="boettiger-lab/taxadb-cache", tag = "dwc")
