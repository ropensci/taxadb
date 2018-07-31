
tmp <- tempdir()
Sys.setenv(TAXALD_HOME=tmp)
library(taxald)
system.time(
create_taxadb()
)

system.time({
  
df <- taxa_tbl(authority = "itis", schema = "hierarchy")
library(dplyr)
chameleons <- df %>% filter(family == "Chamaeleonidae") %>% collect()

})
