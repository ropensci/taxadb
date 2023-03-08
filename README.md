
<!-- README.md is generated from README.Rmd. Please edit that file -->

# taxadb <img src="man/figures/logo.svg" align="right" alt="" width="120" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/ropensci/taxadb/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ropensci/taxadb/actions/workflows/R-CMD-check.yaml)
[![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![Coverage
status](https://codecov.io/gh/ropensci/taxadb/branch/master/graph/badge.svg)](https://codecov.io/github/ropensci/taxadb?branch=master)
[![CRAN
status](https://www.r-pkg.org/badges/version/taxadb)](https://cran.r-project.org/package=taxadb)
[![DOI](https://zenodo.org/badge/130153207.svg)](https://zenodo.org/badge/latestdoi/130153207)
<!-- badges: end -->

The goal of `taxadb` is to provide *fast*, *consistent* access to
taxonomic data, supporting common tasks such as resolving taxonomic
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

To get started, install from CRAN

``` r
install.packages("taxadb")
```

or install the development version directly from GitHub:

``` r
devtools::install_github("ropensci/taxadb")
```

``` r
library(taxadb)
library(dplyr) # Used to illustrate how a typical workflow combines nicely with `dplyr`
```

Create a local copy of the (current) Catalogue of Life database:

``` r
td_create("col")
```

Read in the species list used by the Breeding Bird Survey:

``` r
bbs_species_list <- system.file("extdata/bbs.tsv", package="taxadb")
bbs <- read.delim(bbs_species_list)
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
#> Joining with `by = join_by(scientificName)`

head(birds, 10)
#>                          species        id
#> 1         Dendrocygna autumnalis COL:34Q2Z
#> 2            Dendrocygna bicolor COL:34Q32
#> 3                Anser canagicus      <NA>
#> 4             Anser caerulescens      <NA>
#> 5  Chen caerulescens (blue form)      <NA>
#> 6                   Anser rossii      <NA>
#> 7                Anser albifrons COL:679WV
#> 8                Branta bernicla  COL:N749
#> 9      Branta bernicla nigricans      <NA>
#> 10             Branta hutchinsii  COL:N74B
```

Note that some names cannot be resolved to an identifier. This can occur
because of miss-spellings, non-standard formatting, or the use of a
synonym not recognized by the naming provider. Names that cannot be
uniquely resolved because they are known synonyms of multiple different
species will also return `NA`. The `filter_name` filtering functions can
help us resolve this last case (see below).

`get_ids()` returns the IDs of accepted names, that is
`dwc:AcceptedNameUsageID`s. We can resolve the IDs into accepted names:

``` r
birds %>% 
  mutate(accepted_name = get_names(id, "col")) %>% 
  head()
#>                         species        id          accepted_name
#> 1        Dendrocygna autumnalis COL:34Q2Z Dendrocygna autumnalis
#> 2           Dendrocygna bicolor COL:34Q32    Dendrocygna bicolor
#> 3               Anser canagicus      <NA>                   <NA>
#> 4            Anser caerulescens      <NA>                   <NA>
#> 5 Chen caerulescens (blue form)      <NA>                   <NA>
#> 6                  Anser rossii      <NA>                   <NA>
```

This illustrates that some of our names, e.g. *Dendrocygna bicolor* are
accepted in the Catalogue of Life, while others, *Anser canagicus* are
**known synonyms** of a different accepted name: **Chen canagica**.
Resolving synonyms and accepted names to identifiers helps us avoid the
possible miss-matches we could have when the same species is known by
two different names.

## Taxonomic Data Tables

Local access to taxonomic data tables lets us do much more than look up
names and ids. A family of `filter_*` functions in `taxadb` help us work
directly with subsets of the taxonomic data. As we noted above, this can
be useful in resolving certain ambiguous names.

For instance, *Agrostis caespitosa* does not resolve to an identifier in
ITIS:

``` r
get_ids("Agrostis caespitosa", "itis") 
#> Joining with `by = join_by(scientificName)`
#> Warning:   Found 5 possible identifiers for Agrostis caespitosa.
#>   Returning NA. Try filter_name('Agrostis caespitosa', '') to resolve manually.
#> [1] NA
```

Using `filter_name()`, we find this is because the name resolves not to
zero matches, but is a known synonym to more than one accepted name (as
indicated by the accepted name usage id)

``` r
filter_name('Agrostis caespitosa', 'itis')
#> # A tibble: 6 × 15
#>   taxonID     scien…¹ taxon…² accep…³ taxon…⁴ updat…⁵ kingdom phylum class order
#>   <chr>       <chr>   <chr>   <chr>   <chr>   <chr>   <chr>   <chr>  <chr> <chr>
#> 1 ITIS:785430 Agrost… species ITIS:5… synonym 2010-1… Plantae <NA>   Magn… Poal…
#> 2 ITIS:785431 Agrost… species ITIS:4… synonym 2010-1… Plantae <NA>   Magn… Poal…
#> 3 ITIS:785432 Agrost… species ITIS:4… synonym 2010-1… Plantae <NA>   Magn… Poal…
#> 4 ITIS:785433 Agrost… species ITIS:7… synonym 2010-1… Plantae <NA>   Magn… Poal…
#> 5 ITIS:785434 Agrost… species ITIS:5… synonym 2010-1… Plantae <NA>   Magn… Poal…
#> 6 ITIS:785435 Agrost… species ITIS:7… synonym 2010-1… Plantae <NA>   Magn… Poal…
#> # … with 5 more variables: family <chr>, genus <chr>, specificEpithet <chr>,
#> #   infraspecificEpithet <chr>, vernacularName <chr>, and abbreviated variable
#> #   names ¹​scientificName, ²​taxonRank, ³​acceptedNameUsageID, ⁴​taxonomicStatus,
#> #   ⁵​update_date
```

We can resolve the scientific name to the acceptedNameUsage using
`get_names()` on the *accepted* IDs: (These also correspond to the genus
and specificEpithet column, as the classification is always given only
based on acceptedNameUsageID).

``` r
filter_name("Agrostis caespitosa")  %>%
  mutate(acceptedNameUsage = get_names(acceptedNameUsageID)) %>% 
  select(scientificName, taxonomicStatus, acceptedNameUsage, acceptedNameUsageID)
#> # A tibble: 6 × 4
#>   scientificName      taxonomicStatus acceptedNameUsage          acceptedNameU…¹
#>   <chr>               <chr>           <chr>                      <chr>          
#> 1 Agrostis caespitosa synonym         Deschampsia cespitosa      ITIS:502001    
#> 2 Agrostis caespitosa synonym         Agrostis stolonifera       ITIS:40400     
#> 3 Agrostis caespitosa synonym         Agrostis stolonifera       ITIS:40400     
#> 4 Agrostis caespitosa synonym         Calamagrostis preslii      ITIS:782718    
#> 5 Agrostis caespitosa synonym         Muhlenbergia torreyi       ITIS:503886    
#> 6 Agrostis caespitosa synonym         Muhlenbergia quadridentata ITIS:783883    
#> # … with abbreviated variable name ¹​acceptedNameUsageID
```

Similar functions `filter_id`, `filter_rank`, and `filter_common` take
IDs, scientific ranks, or common names, respectively. Here, we can get
taxonomic data on all bird names in the Catalogue of Life:

``` r
filter_rank(name = "Aves", rank = "class", provider = "col")
#> # A tibble: 10,598 × 25
#>    taxonID   accepte…¹ scien…² taxon…³ taxon…⁴ kingdom phylum class order family
#>    <chr>     <chr>     <chr>   <chr>   <chr>   <chr>   <chr>  <chr> <chr> <chr> 
#>  1 COL:59ZVZ COL:59ZVZ Tyto l… accept… species Animal… Chord… Aves  Stri… Tyton…
#>  2 COL:64X3G COL:64X3G Aegoli… accept… species Animal… Chord… Aves  Stri… Strig…
#>  3 COL:5XGW7 COL:5XGW7 Celeus… accept… species Animal… Chord… Aves  Pici… Picid…
#>  4 COL:4NGTM COL:4NGTM Psepho… accept… species Animal… Chord… Aves  Psit… Psitt…
#>  5 COL:3C9TF COL:3C9TF Eulamp… accept… species Animal… Chord… Aves  Apod… Troch…
#>  6 COL:6CZN3 COL:6CZN3 Discos… accept… species Animal… Chord… Aves  Apod… Troch…
#>  7 COL:4S4FP COL:4S4FP Rhaphi… accept… species Animal… Chord… Aves  Apod… Apodi…
#>  8 COL:7TCSL COL:7TCSL Dryoba… accept… species Animal… Chord… Aves  Pici… Picid…
#>  9 COL:3HT3X COL:3HT3X Gymnop… accept… species Animal… Chord… Aves  Colu… Colum…
#> 10 COL:3Z72J COL:3Z72J Melane… accept… species Animal… Chord… Aves  Pici… Picid…
#> # … with 10,588 more rows, 15 more variables: genus <chr>,
#> #   specificEpithet <chr>, infraspecificEpithet <chr>, cultivarEpithet <chr>,
#> #   datasetID <chr>, namePublishedIn <chr>, nameAccordingTo <chr>,
#> #   taxonRemarks <chr>, nomenclaturalStatus <chr>, nomenclaturalCode <chr>,
#> #   parentNameUsageID <chr>, originalNameUsageID <chr>,
#> #   `dcterms:references` <chr>, language <chr>, vernacularName <chr>, and
#> #   abbreviated variable names ¹​acceptedNameUsageID, ²​scientificName, …
```

Combining these with `dplyr` functions can make it easy to explore this
data: for instance, which families have the most species?

``` r
filter_rank(name = "Aves", rank = "class", provider = "col") %>%
  filter(taxonomicStatus == "accepted", taxonRank=="species") %>% 
  group_by(family) %>%
  count(sort = TRUE) %>% 
  head()
#> # A tibble: 6 × 2
#> # Groups:   family [6]
#>   family           n
#>   <chr>        <int>
#> 1 Tyrannidae     401
#> 2 Thraupidae     374
#> 3 Psittacidae    370
#> 4 Trochilidae    361
#> 5 Columbidae     344
#> 6 Muscicapidae   314
```

## Using the database connection directly

`filter_*` functions by default return in-memory data frames. Because
they are filtering functions, they return a subset of the full data
which matches a given query (names, ids, ranks, etc), so the returned
data.frames are smaller than the full record of a naming provider.
Working directly with the SQL connection to the MonetDBLite database
gives us access to all the data. The `taxa_tbl()` function provides this
connection:

``` r
taxa_tbl("col")
#> # Source:   table<v22.12_dwc_col> [?? x 25]
#> # Database: DuckDB 0.7.0 [unknown@Linux 5.17.15-76051715-generic:R 4.2.2/:memory:]
#>    taxonID   accepte…¹ scien…² taxon…³ taxon…⁴ kingdom phylum class order family
#>    <chr>     <chr>     <chr>   <chr>   <chr>   <chr>   <chr>  <chr> <chr> <chr> 
#>  1 COL:3L3RS COL:3L3RS Hersil… accept… species Animal… Arthr… <NA>  Aran… Hersi…
#>  2 COL:6MTNS COL:6MTNS Idiotr… accept… species Animal… Arthr… Inse… Hemi… Helot…
#>  3 COL:39VC7 COL:39VC7 Enitha… accept… species Animal… Arthr… Inse… Hemi… Noton…
#>  4 COL:6LHWM COL:6LHWM Heleoc… accept… species Animal… Arthr… Inse… Hemi… Nauco…
#>  5 COL:38PQV COL:38PQV Ectemn… accept… species Animal… Arthr… Inse… Hemi… Corix…
#>  6 COL:73VN6 COL:73VN6 Neomac… accept… species Animal… Arthr… Inse… Hemi… Nauco…
#>  7 COL:6MKPW COL:6MKPW Hydrot… accept… species Animal… Arthr… Inse… Hemi… Helot…
#>  8 COL:5FMGW COL:5FMGW rotumai accept… subspe… <NA>    <NA>   <NA>  <NA>  <NA>  
#>  9 COL:3L5C7 COL:3L5C7 Hesper… accept… species Animal… Arthr… Inse… Hemi… Corix…
#> 10 COL:SVTT  COL:SVTT  Cercot… accept… species Animal… Arthr… Inse… Hemi… Nepid…
#> # … with more rows, 15 more variables: genus <chr>, specificEpithet <chr>,
#> #   infraspecificEpithet <chr>, cultivarEpithet <chr>, datasetID <chr>,
#> #   namePublishedIn <chr>, nameAccordingTo <chr>, taxonRemarks <chr>,
#> #   nomenclaturalStatus <chr>, nomenclaturalCode <chr>,
#> #   parentNameUsageID <chr>, originalNameUsageID <chr>,
#> #   `dcterms:references` <chr>, language <chr>, vernacularName <chr>, and
#> #   abbreviated variable names ¹​acceptedNameUsageID, ²​scientificName, …
```

We can still use most familiar `dplyr` verbs to perform common tasks.
For instance: which species has the most known synonyms?

``` r
taxa_tbl("itis") %>% 
  count(acceptedNameUsageID, sort=TRUE)
#> # Source:     SQL [?? x 2]
#> # Database:   DuckDB 0.7.0 [unknown@Linux 5.17.15-76051715-generic:R 4.2.2/:memory:]
#> # Ordered by: desc(n)
#>    acceptedNameUsageID     n
#>    <chr>               <dbl>
#>  1 ITIS:50               462
#>  2 ITIS:983681           303
#>  3 ITIS:983691           286
#>  4 ITIS:983714           237
#>  5 ITIS:983710           231
#>  6 ITIS:798259           145
#>  7 ITIS:24921            144
#>  8 ITIS:527684           134
#>  9 ITIS:505191           126
#> 10 ITIS:504874           123
#> # … with more rows
```

However, unlike the `filter_*` functions which return convenient
in-memory tables, this is still a remote connection. This means that
direct access using the `taxa_tbl()` function (or directly accessing the
database connection using `td_connect()`) is more low-level and requires
greater care. For instance, we cannot just add a
`%>% mutate(acceptedNameUsage = get_names(acceptedNameUsageID))` to the
above, because `get_names` does not work on a remote collection.
Instead, we would first need to use a `collect()` to pull the summary
table into memory. Users familiar with remote databases in `dplyr` will
find using `taxa_tbl()` directly to be convenient and fast, while other
users may find the `filter_*` approach to be more intuitive.

## Learn more

- See richer examples the package
  [Tutorial](https://docs.ropensci.org/taxadb/articles/articles/intro.html).

- Learn about the underlying data sources and formats in [Data
  Sources](https://docs.ropensci.org/taxadb/articles/data-sources.html)

- Get better performance by selecting an alternative [database
  backend](https://docs.ropensci.org/taxadb/articles/backends.html)
  engines.

------------------------------------------------------------------------

Please note that this project is released with a [Contributor Code of
Conduct](https://ropensci.org/code-of-conduct/). By participating in
this project you agree to abide by its terms.

[![ropensci_footer](https://ropensci.org/public_images/ropensci_footer.png)](https://ropensci.org)
