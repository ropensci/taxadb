## Regenerate the itis_test fixture bundled in inst/extdata.
##
## The fixture backs every example and most tests, so it must work offline
## and stay small, while still containing the names those examples look up.
## It is a subset of a real ITIS build -- accepted names, synonyms, ranks and
## vernaculars all behave as they do in the full table -- so td_validate()
## holds on it, and it is regenerated from a build rather than edited by hand.
##
## Run after building ITIS:
##   td_build("itis", version = "2026")
##   source("data-raw/itis_test_fixture.R")

library(taxadb)
library(DBI)

version <- "2026"
build_out <- file.path(build_dir(), "out")

db <- td_connect()
dwc <- taxadb_uri("itis", "dwc", version, local = TRUE)
common <- taxadb_uri("itis", "common", version, local = TRUE)

## Families containing the taxa the examples use: great apes and monkeys
## (Homo sapiens, Sapajus apella, Midas bicolor), laughingthrushes
## (Trochalopteron, which gives a species/subspecies synonym pair), and
## corvids (which carry the vernacular names the fuzzy examples match).
FAMILIES <- c("Hominidae", "Callitrichidae", "Cebidae",
              "Leiothrichidae", "Corvidae")

## Plus a few named taxa outside those families, and the higher ranks the
## filter_rank() examples ask for.
NAMES <- c("Poa annua", "Aves", "Mammalia", "Primates", "Passeriformes",
           "Animalia", "Chordata", "Plantae", "Magnoliopsida", "Poaceae",
           "Poa")

quoted <- function(x) paste0("'", gsub("'", "''", x), "'", collapse = ", ")

subset_sql <- function(src)
  paste0("SELECT * FROM read_parquet('", src, "') WHERE family IN (",
         quoted(FAMILIES), ") OR scientificName IN (", quoted(NAMES), ")")

dbExecute(db, paste0("COPY (", subset_sql(dwc),
                     ") TO 'inst/extdata/dwc_itis_test.parquet'",
                     " (FORMAT parquet, COMPRESSION zstd);"))
dbExecute(db, paste0("COPY (", subset_sql(common),
                     ") TO 'inst/extdata/common_itis_test.parquet'",
                     " (FORMAT parquet, COMPRESSION zstd);"))

for(f in c("inst/extdata/dwc_itis_test.parquet",
           "inst/extdata/common_itis_test.parquet"))
  message(basename(f), ": ",
          format(dbGetQuery(db, paste0("SELECT count(*) n FROM read_parquet('",
                                       f, "')"))$n, big.mark = ","),
          " rows, ", round(file.size(f) / 1024), " KB")

## The fixture must satisfy the same rules as a published table.
print(td_validate("itis_test", "dwc"))
print(td_validate("itis_test", "common"))
