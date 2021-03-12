
<!-- README.md is generated from README.Rmd. Please edit that file -->

# taxadb <img src="man/figures/logo.svg" align="right" alt="" width="120" />

<!-- badges: start -->

[![R build
status](https://github.com/ropensci/taxadb/workflows/R-CMD-check/badge.svg)](https://github.com/ropensci/taxadb/actions)
[![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![Coverage
status](https://codecov.io/gh/ropensci/taxadb/branch/master/graph/badge.svg)](https://codecov.io/github/ropensci/taxadb?branch=master)
[![CRAN
status](https://www.r-pkg.org/badges/version/taxadb)](https://cran.r-project.org/package=taxadb)
[![DOI](https://zenodo.org/badge/130153207.svg)](https://zenodo.org/badge/latestdoi/130153207)

<!-- [![peer-review](https://badges.ropensci.org/344_status.svg)](https://github.com/ropensci/software-review/issues/344) -->

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
install.pacakges("taxadb")
```

or install the development version directly from GitHub:

``` r
devtools::install_github("ropensci/taxadb")
```

``` r
library(taxadb)
library(dplyr) # Used to illustrate how a typical workflow combines nicely with `dplyr`
```

Create a local copy of the Catalogue of Life (2018) database:

``` r
td_create("col", overwrite=FALSE)
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

head(birds, 10)
#>                          species          id
#> 1         Dendrocygna autumnalis COL:3177882
#> 2            Dendrocygna bicolor COL:3177881
#> 3                Anser canagicus COL:3178026
#> 4             Anser caerulescens COL:3178024
#> 5  Chen caerulescens (blue form)        <NA>
#> 6                   Anser rossii COL:3178025
#> 7                Anser albifrons COL:3178017
#> 8                Branta bernicla COL:3178037
#> 9      Branta bernicla nigricans COL:3185200
#> 10             Branta hutchinsii COL:3178039
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
#>                         species          id          accepted_name
#> 1        Dendrocygna autumnalis COL:3177882 Dendrocygna autumnalis
#> 2           Dendrocygna bicolor COL:3177881    Dendrocygna bicolor
#> 3               Anser canagicus COL:3178026          Chen canagica
#> 4            Anser caerulescens COL:3178024      Chen caerulescens
#> 5 Chen caerulescens (blue form)        <NA>                   <NA>
#> 6                  Anser rossii COL:3178025            Chen rossii
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

For instance, *Trochalopteron henrici gucenense* does not resolve to an
identifier in ITIS:

``` r
get_ids("Trochalopteron henrici gucenense") 
#> Warning:   Found 2 possible identifiers for Trochalopteron henrici gucenense.
#>   Returning NA. Try filter_id('Trochalopteron henrici gucenense', 'itis') to resolve manually.
#> [1] NA
```

Using `filter_name()`, we find this is because the name resolves not to
zero matches, but to more than one match:

``` r
filter_name("Trochalopteron henrici gucenense") 
#> # A tibble: 2 x 17
#>    sort taxonID   scientificName      taxonRank acceptedNameUsa… taxonomicStatus
#>   <int> <chr>     <chr>               <chr>     <chr>            <chr>          
#> 1     1 ITIS:924… Trochalopteron hen… subspeci… ITIS:916116      synonym        
#> 2     1 ITIS:924… Trochalopteron hen… subspeci… ITIS:916117      synonym        
#> # … with 11 more variables: update_date <chr>, kingdom <chr>, phylum <chr>,
#> #   class <chr>, order <chr>, family <chr>, genus <chr>, specificEpithet <chr>,
#> #   infraspecificEpithet <chr>, vernacularName <chr>, input <chr>
```

``` r
filter_name("Trochalopteron henrici gucenense")  %>%
  mutate(acceptedNameUsage = get_names(acceptedNameUsageID)) %>% 
  select(scientificName, taxonomicStatus, acceptedNameUsage, acceptedNameUsageID)
#> # A tibble: 2 x 4
#>   scientificName          taxonomicStatus acceptedNameUsage    acceptedNameUsag…
#>   <chr>                   <chr>           <chr>                <chr>            
#> 1 Trochalopteron henrici… synonym         Trochalopteron elli… ITIS:916116      
#> 2 Trochalopteron henrici… synonym         Trochalopteron henr… ITIS:916117
```

Similar functions `filter_id`, `filter_rank`, and `filter_common` take
IDs, scientific ranks, or common names, respectively. Here, we can get
taxonomic data on all bird names in the Catalogue of Life:

``` r
filter_rank(name = "Aves", rank = "class", provider = "col")
#> # A tibble: 36,336 x 21
#>     sort taxonID   scientificName    acceptedNameUsag… taxonomicStatus taxonRank
#>    <int> <chr>     <chr>             <chr>             <chr>           <chr>    
#>  1     1 COL:3148… Nisaetus nanus    COL:3148416       accepted        species  
#>  2     1 COL:3148… Circaetus beaudo… COL:3148666       accepted        species  
#>  3     1 COL:3148… Cariama cristata  COL:3148731       accepted        species  
#>  4     1 COL:3148… Chunga burmeiste… COL:3148732       accepted        species  
#>  5     1 COL:3148… Eurypyga helias   COL:3148733       accepted        species  
#>  6     1 COL:3148… Rhynochetos juba… COL:3148734       accepted        species  
#>  7     1 COL:3148… Leptosomus disco… COL:3148735       accepted        species  
#>  8     1 COL:3148… Neotis heuglinii  COL:3148736       accepted        species  
#>  9     1 COL:3148… Neotis ludwigii   COL:3148737       accepted        species  
#> 10     1 COL:3148… Neotis denhami    COL:3148738       accepted        species  
#> # … with 36,326 more rows, and 15 more variables: kingdom <chr>, phylum <chr>,
#> #   class <chr>, order <chr>, family <chr>, genus <chr>, specificEpithet <chr>,
#> #   infraspecificEpithet <chr>, taxonConceptID <chr>, isExtinct <chr>,
#> #   nameAccordingTo <chr>, namePublishedIn <chr>,
#> #   scientificNameAuthorship <chr>, vernacularName <chr>, input <chr>
```

Combining these with `dplyr` functions can make it easy to explore this
data: for instance, which families have the most species?

``` r
filter_rank(name = "Aves", rank = "class", provider = "col") %>%
  filter(taxonomicStatus == "accepted", taxonRank=="species") %>% 
  group_by(family) %>%
  count(sort = TRUE) %>% 
  head()
#> # A tibble: 6 x 2
#> # Groups:   family [6]
#>   family           n
#>   <chr>        <int>
#> 1 Tyrannidae     401
#> 2 Thraupidae     374
#> 3 Psittacidae    370
#> 4 Columbidae     344
#> 5 Trochilidae    338
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
#> # Source:   table<2020_dwc_col> [?? x 19]
#> # Database: duckdb_connection
#>    taxonID  scientificName    acceptedNameUsa… taxonomicStatus taxonRank kingdom
#>    <chr>    <chr>             <chr>            <chr>           <chr>     <chr>  
#>  1 COL:3738 Lobesia triacant… COL:3738         accepted        species   Animal…
#>  2 COL:4116 Syncollesis tril… COL:4116         accepted        species   Animal…
#>  3 COL:4118 Anisodes anablem… COL:4118         accepted        species   Animal…
#>  4 COL:4122 Cyclophora carol… COL:4122         accepted        species   Animal…
#>  5 COL:4127 Morchella magnis… COL:4127         accepted        species   Fungi  
#>  6 COL:4128 Streptothrix eff… COL:4128         accepted        species   Fungi  
#>  7 COL:4344 Aplosporella fau… COL:4344         accepted        species   Fungi  
#>  8 COL:9466 Synalus angustus  COL:9466         accepted        species   Animal…
#>  9 COL:9467 Synalus terrosus  COL:9467         accepted        species   Animal…
#> 10 COL:9468 Synema spinosum   COL:9468         accepted        species   Animal…
#> # … with more rows, and 13 more variables: phylum <chr>, class <chr>,
#> #   order <chr>, family <chr>, genus <chr>, specificEpithet <chr>,
#> #   infraspecificEpithet <chr>, taxonConceptID <chr>, isExtinct <chr>,
#> #   nameAccordingTo <chr>, namePublishedIn <chr>,
#> #   scientificNameAuthorship <chr>, vernacularName <chr>
```

We can still use most familiar `dplyr` verbs to perform common tasks.
For instance: which species has the most known synonyms?

``` r
taxa_tbl("col") %>% 
  count(acceptedNameUsageID, sort=TRUE)
#> # Source:     lazy query [?? x 2]
#> # Database:   duckdb_connection
#> # Ordered by: desc(n)
#>    acceptedNameUsageID     n
#>    <chr>               <dbl>
#>  1 COL:274062            456
#>  2 COL:353741            373
#>  3 COL:3778950           329
#>  4 COL:2535424           328
#>  5 COL:2921616           322
#>  6 COL:2532677           307
#>  7 COL:3779182           302
#>  8 COL:353740            296
#>  9 COL:2531203           253
#> 10 COL:1585420           252
#> # … with more rows
```

However, unlike the `filter_*` functions which return convenient
in-memory tables, this is still a remote connection. This means that
direct access using the `taxa_tbl()` function (or directly accessing the
database connection using `td_connect()`) is more low-level and requires
greater care. For instance, we cannot just add a `%>%
mutate(acceptedNameUsage = get_names(acceptedNameUsageID))` to the
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

-----

Please note that this project is released with a [Contributor Code of
Conduct](https://ropensci.org/code-of-conduct/). By participating in
this project you agree to abide by its terms.

[![ropensci\_footer](https://ropensci.org/public_images/ropensci_footer.png)](https://ropensci.org)
