
<!-- README.md is generated from README.Rmd. Please edit that file -->

# taxadb <img src="man/figures/logo.svg" align="right" alt="" width="120" />

[![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
[![Travis build
status](https://travis-ci.org/cboettig/taxadb.svg?branch=master)](https://travis-ci.org/cboettig/taxadb)
[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/cboettig/taxadb?branch=master&svg=true)](https://ci.appveyor.com/project/cboettig/taxadb)
[![Coverage
status](https://codecov.io/gh/cboettig/taxadb/branch/master/graph/badge.svg)](https://codecov.io/github/cboettig/taxadb?branch=master)
[![CRAN
status](https://www.r-pkg.org/badges/version/taxadb)](https://cran.r-project.org/package=taxadb)

The goal of `taxadb` is to provide *fast*, *consistent* access to
taxonomic data, supporting commont tasks such as resolving taxonomic
names to identifiers, looking up higher classification ranks of given
species, or returning a list of all species below a given rank. These
tasks are particularly common when synthesizing data across large
species assemblies, such as combining occurrence records with trait
records.

Existing approaches to these problems typically rely on web APIs, which
can make them impractical for work with large numbers of species or in
more complex pipelines. Queries and returned formats also differ across
the different taxonomic authorities, making tasks that query multiple
authorities particularly complex. `taxadb` creates a *local* database of
most readily available taxonomic authorities, each of which is
transformed into consistent, standard, and researcher-friendly tabular
formats.

## Install and initial setup

To get started, install the development version directly from GitHub:

``` r
devtools::install_github("cboettig/taxadb")
```

``` r
library(taxadb)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(readr)
```

Create a local copy of the Catalogue of Life (2018) database:

``` r
td_create("col")
#> not overwriting col
```

Read in the species list used by the Breeding Bird Survey:

``` r
bbs_species_list <- system.file("extdata/bbs.tsv", package="taxadb")
bbs <- read_tsv(bbs_species_list)
```

## Getting names and ids

Two core functions are `get_ids()` and `get_names()`. These functions
take a vector of names or ids (respectively), and return a vector of ids
or names (respectively). For instance, we can use this to attempt to
resolve all the bird names in the Breeding Bird Survey against the
Catalogue of Life:

``` r
birds <- bbs %>% 
  select(species) %>% 
  mutate(id = get_ids(species, "col"))

head(birds, 10)
#> # A tibble: 10 x 2
#>    species                       id          
#>    <chr>                         <chr>       
#>  1 Dendrocygna autumnalis        <NA>        
#>  2 Dendrocygna bicolor           COL:35517332
#>  3 Anser canagicus               COL:35517329
#>  4 Anser caerulescens            COL:35517325
#>  5 Chen caerulescens (blue form) <NA>        
#>  6 Anser rossii                  COL:35517328
#>  7 Anser albifrons               <NA>        
#>  8 Branta bernicla               COL:35517301
#>  9 Branta bernicla nigricans     COL:35537100
#> 10 Branta hutchinsii             COL:35536445
```

Note that some names cannot be resolved to an identifier. This can occur
because of mis-spellings, non-standard formatting, or the use of a
synonym not recognized by the naming provider. Names that cannot be
uniquely resolved because they are known synonyms of multiple different
species will also return `NA`. The `by_name` filtering functions can
help us resolve this last case (see below).

`get_ids()` returns the IDs of accepted names, that is
`dwc:AcceptedNameUsageID`s. We can resolve the IDs into accepted names:

``` r
birds %>% 
  mutate(accepted_name = get_names(id, "col"))
#> # A tibble: 750 x 3
#>    species                       id           accepted_name            
#>    <chr>                         <chr>        <chr>                    
#>  1 Dendrocygna autumnalis        <NA>         <NA>                     
#>  2 Dendrocygna bicolor           COL:35517332 Dendrocygna bicolor      
#>  3 Anser canagicus               COL:35517329 Chen canagica            
#>  4 Anser caerulescens            COL:35517325 Chen caerulescens        
#>  5 Chen caerulescens (blue form) <NA>         <NA>                     
#>  6 Anser rossii                  COL:35517328 Chen rossii              
#>  7 Anser albifrons               <NA>         <NA>                     
#>  8 Branta bernicla               COL:35517301 Branta bernicla          
#>  9 Branta bernicla nigricans     COL:35537100 Branta bernicla nigricans
#> 10 Branta hutchinsii             COL:35536445 Branta hutchinsii        
#> # … with 740 more rows
```

This illustrates that some of our names, e.g. *Dendrocygna bicolor* are
accepted in the Catalogue of Life, while others, *Anser canagicus* are
**known synonyms** of a different accepted name: **Chen canagica**.
Resolving synonyms and accepted names to identifiers helps us avoid the
possible miss-matches we could have when the same species is known by
two different names.

## Taxonomic Data Tables

Local access to taxonomic data tables lets us do much more than look up
names and ids. A family of `by_*` functions in `taxadb` help us work
directly with subsets of the taxonomic data. As we noted above, this can
be useful in resolving certain ambiguous names.

For instance, *Trochalopteron henrici gucenense* does not resolve to an
identifier in ITIS:

``` r
get_ids("Trochalopteron henrici gucenense") 
#> [1] NA
```

Using `by_name()`, we find this is because the name resolves not to zero
matches, but to more than one match:

``` r
by_name("Trochalopteron henrici gucenense") 
#> # A tibble: 2 x 17
#>   taxonID acceptedNameUsa… update_date scientificName taxonRank
#>   <chr>   <chr>            <chr>       <chr>          <chr>    
#> 1 ITIS:9… ITIS:916116      2013-11-04  Trochaloptero… subspeci…
#> 2 ITIS:9… ITIS:916117      2013-11-04  Trochaloptero… subspeci…
#> # … with 12 more variables: taxonomicStatus <chr>, kingdom <chr>,
#> #   phylum <chr>, class <chr>, order <chr>, family <chr>, genus <chr>,
#> #   specificEpithet <chr>, vernacularName <chr>,
#> #   infraspecificEpithet <chr>, input <chr>, sort <int>
```

``` r
by_name("Trochalopteron henrici gucenense")  %>%
  mutate(acceptedNameUsage = get_names(acceptedNameUsageID)) %>% 
  select(scientificName, taxonomicStatus, acceptedNameUsage, acceptedNameUsageID)
#> # A tibble: 2 x 4
#>   scientificName       taxonomicStatus acceptedNameUsage   acceptedNameUsa…
#>   <chr>                <chr>           <chr>               <chr>           
#> 1 Trochalopteron henr… synonym         Trochalopteron ell… ITIS:916116     
#> 2 Trochalopteron henr… synonym         Trochalopteron hen… ITIS:916117
```

Similar functions `by_id`, `by_rank`, and `by_common` take IDs,
scientific ranks, or common names, respectively. Here, we can get
taxonomic data on all bird names in the Catalogue of Life:

``` r
by_rank(name = "Aves", rank = "class", provider = "col")
#> # A tibble: 32,327 x 21
#>    taxonID scientificName acceptedNameUsa… taxonomicStatus taxonRank
#>    <chr>   <chr>          <chr>            <chr>           <chr>    
#>  1 COL:35… Struthio came… COL:35516814     accepted        species  
#>  2 COL:35… Rhea americana COL:35516815     accepted        species  
#>  3 COL:35… Dromaius nova… COL:35516817     accepted        species  
#>  4 COL:35… Casuarius ben… COL:35516818     accepted        species  
#>  5 COL:35… Casuarius una… COL:35516819     accepted        species  
#>  6 COL:35… Apteryx austr… COL:35516820     accepted        species  
#>  7 COL:35… Tinamus gutta… COL:35516823     accepted        species  
#>  8 COL:35… Tinamus major  COL:35516824     accepted        species  
#>  9 COL:35… Tinamus osgoo… COL:35516825     accepted        species  
#> 10 COL:35… Tinamus solit… COL:35516826     accepted        species  
#> # … with 32,317 more rows, and 16 more variables: kingdom <chr>,
#> #   phylum <chr>, class <chr>, order <chr>, family <chr>, genus <chr>,
#> #   specificEpithet <chr>, infraspecificEpithet <chr>,
#> #   taxonConceptID <chr>, isExtinct <chr>, nameAccordingTo <chr>,
#> #   namePublishedIn <chr>, scientificNameAuthorship <chr>,
#> #   vernacularName <chr>, input <chr>, sort <int>
```

Combining these with `dplyr` functions can make it easy to explore this
data: for instance, which families have the most species?

``` r
by_rank(name = "Aves", rank = "class", provider = "col") %>%
  filter(taxonomicStatus == "accepted", taxonRank=="species") %>% 
  group_by(family) %>%
  count(sort = TRUE) %>% 
  head()
#> # A tibble: 6 x 2
#> # Groups:   family [6]
#>   family           n
#>   <chr>        <int>
#> 1 Tyrannidae     402
#> 2 Psittacidae    377
#> 3 Thraupidae     374
#> 4 Trochilidae    339
#> 5 Columbidae     323
#> 6 Muscicapidae   317
```

## Using the database connection directly

`by_*` functions by default return in-memory data frames. Because they
are filtering functions, they return a subset of the full data which
matches a given query (names, ids, ranks, etc), so the returned
data.frames are smaller than the full record of a naming provider.
Working directly with the SQL connection to the MonetDBLite database
gives us access to all the data. The `taxa_tbl()` function provides this
connection:

``` r
taxa_tbl("col")
#> # Source:   table<col> [?? x 19]
#> # Database: MonetDBEmbeddedConnection
#>    taxonID scientificName acceptedNameUsa… taxonomicStatus taxonRank
#>    <chr>   <chr>          <chr>            <chr>           <chr>    
#>  1 COL:31… Limacoccus br… COL:316423       accepted        species  
#>  2 COL:31… Coccus bromel… COL:316424       accepted        species  
#>  3 COL:31… Apiomorpha po… COL:316425       accepted        species  
#>  4 COL:31… Eriococcus ch… COL:316441       accepted        species  
#>  5 COL:31… Eriococcus ch… COL:316442       accepted        species  
#>  6 COL:31… Eriococcus ch… COL:316443       accepted        species  
#>  7 COL:31… Eriococcus ci… COL:316444       accepted        species  
#>  8 COL:31… Eriococcus ci… COL:316445       accepted        species  
#>  9 COL:31… Eriococcus bu… COL:316447       accepted        species  
#> 10 COL:31… Eriococcus au… COL:316450       accepted        species  
#> # … with more rows, and 14 more variables: kingdom <chr>, phylum <chr>,
#> #   class <chr>, order <chr>, family <chr>, genus <chr>,
#> #   specificEpithet <chr>, infraspecificEpithet <chr>,
#> #   taxonConceptID <chr>, isExtinct <chr>, nameAccordingTo <chr>,
#> #   namePublishedIn <chr>, scientificNameAuthorship <chr>,
#> #   vernacularName <chr>
```

We can still use most familiar `dplyr` verbs to perform common tasks.
For instance: which species has the most known synonyms?

``` r
most_synonyms <- taxa_tbl("col") %>% 
  group_by(acceptedNameUsageID) %>% 
  count(sort=TRUE)
most_synonyms
#> # Source:     lazy query [?? x 2]
#> # Database:   MonetDBEmbeddedConnection
#> # Groups:     acceptedNameUsageID
#> # Ordered by: desc(n)
#>    acceptedNameUsageID     n
#>    <chr>               <dbl>
#>  1 COL:43082445          456
#>  2 COL:43081989          373
#>  3 COL:43124375          329
#>  4 COL:43353659          328
#>  5 COL:43223150          322
#>  6 COL:43337824          307
#>  7 COL:43124158          302
#>  8 COL:43081973          296
#>  9 COL:43333057          253
#> 10 COL:23162697          252
#> # … with more rows
```

However, unlike the `by_*` functions which return convienent in-memory
tables, this is still a remote connection. This means that direct access
using the `taxa_tbl()` function (or directly accessing the database
connection using `td_connect()`) is more low-level and requires greater
care. For instance, we cannot just add a `%>% mutate(acceptedNameUsage =
get_names(acceptedNameUsageID))` to the above, becuase `get_names` does
not work on a remote collection. Instead, we would first need to use a
`collect()` to pull the summary table into memory. Users familiar with
remote databases in `dplyr` will find using `taxa_tbl()` directly to be
convenient and fast, while other users may find the `by_*` approach to
be more intuitive.

So which species had those 456 names?

``` r
most_synonyms %>% 
  head(1) %>% 
  pull(acceptedNameUsageID) %>% 
  by_id("col") %>%
  select(scientificName)
#> # A tibble: 1 x 1
#>   scientificName                     
#>   <chr>                              
#> 1 Mentha longifolia subsp. longifolia
```

## Learn more

See richer examples, including name cleaning and background on the
schema in the
    vignettes:

  - [Tutorial](https://cboettig.github.io/taxadb/articles/intro.html)
  - [Schema](https://cboettig.github.io/taxadb/articles/articles/schema.html)
