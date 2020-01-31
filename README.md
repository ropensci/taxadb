
<!-- README.md is generated from README.Rmd. Please edit that file -->

# taxadb <img src="man/figures/logo.svg" align="right" alt="" width="120" />

[![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
[![Travis build
status](https://travis-ci.org/ropensci/taxadb.svg?branch=master)](https://travis-ci.org/ropensci/taxadb)
[![AppVeyor build
status](https://ci.appveyor.com/api/projects/status/github/ropensci/taxadb?branch=master&svg=true)](https://ci.appveyor.com/project/cboettig/taxadb)
[![Coverage
status](https://codecov.io/gh/ropensci/taxadb/branch/master/graph/badge.svg)](https://codecov.io/github/ropensci/taxadb?branch=master)
[![CRAN
status](https://www.r-pkg.org/badges/version/taxadb)](https://cran.r-project.org/package=taxadb)

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

To get started, install the development version directly from GitHub:

``` r
devtools::install_github("ropensci/taxadb")
```

``` r
library(taxadb)
library(dplyr) # Used to illustrate how a typical workflow combines nicely with `dplyr`
```

Create a local copy of the Catalogue of Life (2018) database:

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

head(birds, 10)
#>                          species           id
#> 1         Dendrocygna autumnalis COL:35517330
#> 2            Dendrocygna bicolor COL:35517332
#> 3                Anser canagicus COL:35517329
#> 4             Anser caerulescens COL:35517325
#> 5  Chen caerulescens (blue form)         <NA>
#> 6                   Anser rossii COL:35517328
#> 7                Anser albifrons COL:35517308
#> 8                Branta bernicla COL:35517301
#> 9      Branta bernicla nigricans COL:35537100
#> 10             Branta hutchinsii COL:35536445
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
#>                         species           id        accepted_name
#> 1        Dendrocygna autumnalis COL:35517330      Tringa flavipes
#> 2           Dendrocygna bicolor COL:35517332    Picoides dorsalis
#> 3               Anser canagicus COL:35517329   Setophaga castanea
#> 4            Anser caerulescens COL:35517325  Bombycilla cedrorum
#> 5 Chen caerulescens (blue form)         <NA>       Icteria virens
#> 6                  Anser rossii COL:35517328 Somateria mollissima
```

This illustrates that some of our names, e.g. *Dendrocygna bicolor* are
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
#> Importing 2019_dwc_itis.tsv.bz2 in 100000 line chunks:
#>  ...Done! (in 13.33816 secs)
#> [1] NA
```

Using `filter_name()`, we find this is because the name resolves not to
zero matches, but to more than one match:

``` r
filter_name("Trochalopteron henrici gucenense") 
#> # A tibble: 2 x 17
#>    sort taxonID scientificName taxonRank acceptedNameUsa… taxonomicStatus
#>   <int> <chr>   <chr>          <chr>     <chr>            <chr>          
#> 1     1 ITIS:9… Trochaloptero… subspeci… ITIS:916117      synonym        
#> 2     1 ITIS:9… Trochaloptero… subspeci… ITIS:916116      synonym        
#> # … with 11 more variables: update_date <chr>, kingdom <chr>, phylum <chr>,
#> #   class <chr>, order <chr>, family <chr>, genus <chr>, specificEpithet <chr>,
#> #   vernacularName <chr>, infraspecificEpithet <chr>, input <chr>
```

``` r
filter_name("Trochalopteron henrici gucenense")  %>%
  mutate(acceptedNameUsage = get_names(acceptedNameUsageID)) %>% 
  select(scientificName, taxonomicStatus, acceptedNameUsage, acceptedNameUsageID)
#> # A tibble: 2 x 4
#>   scientificName          taxonomicStatus acceptedNameUsage    acceptedNameUsag…
#>   <chr>                   <chr>           <chr>                <chr>            
#> 1 Trochalopteron henrici… synonym         Trochalopteron henr… ITIS:916117      
#> 2 Trochalopteron henrici… synonym         Trochalopteron elli… ITIS:916116
```

Similar functions `filter_id`, `filter_rank`, and `filter_common` take
IDs, scientific ranks, or common names, respectively. Here, we can get
taxonomic data on all bird names in the Catalogue of Life:

``` r
filter_rank(name = "Aves", rank = "class", provider = "col")
#> # A tibble: 35,398 x 21
#>     sort taxonID scientificName acceptedNameUsa… taxonomicStatus taxonRank
#>    <int> <chr>   <chr>          <chr>            <chr>           <chr>    
#>  1     1 COL:35… Sturnella mag… COL:35520416     accepted        species  
#>  2     1 COL:35… Tauraco porph… COL:35530219     accepted        infraspe…
#>  3     1 COL:35… Pyroderus scu… COL:35534370     accepted        infraspe…
#>  4     1 COL:35… Dromaius minor COL:35552206     synonym         infraspe…
#>  5     1 COL:35… Lepidocolapte… COL:35525495     accepted        species  
#>  6     1 COL:35… Casuarius pap… COL:35552204     synonym         infraspe…
#>  7     1 COL:35… Forpus modest… COL:35536431     accepted        species  
#>  8     1 COL:35… Pterocnemia p… COL:35552203     synonym         infraspe…
#>  9     1 COL:35… Ceyx lepidus … COL:35532279     accepted        infraspe…
#> 10     1 COL:35… Rhea tarapace… COL:35552202     synonym         infraspe…
#> # … with 35,388 more rows, and 15 more variables: kingdom <chr>, phylum <chr>,
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
#> 4 Trochilidae    338
#> 5 Muscicapidae   314
#> 6 Columbidae     312
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
#> # Source:   table<2019_dwc_col> [?? x 19]
#> # Database: duckdb_connection
#>    taxonID scientificName acceptedNameUsa… taxonomicStatus taxonRank kingdom
#>    <chr>   <chr>          <chr>            <chr>           <chr>     <chr>  
#>  1 COL:31… Limacoccus br… COL:316423       accepted        species   Animal…
#>  2 COL:31… Coccus bromel… COL:316424       accepted        species   Animal…
#>  3 COL:31… Apiomorpha po… COL:316425       accepted        species   Animal…
#>  4 COL:31… Eriococcus ch… COL:316441       accepted        species   Animal…
#>  5 COL:31… Eriococcus ch… COL:316442       accepted        species   Animal…
#>  6 COL:31… Eriococcus ch… COL:316443       accepted        species   Animal…
#>  7 COL:31… Eriococcus ci… COL:316444       accepted        species   Animal…
#>  8 COL:31… Eriococcus ci… COL:316445       accepted        species   Animal…
#>  9 COL:31… Eriococcus bu… COL:316447       accepted        species   Animal…
#> 10 COL:31… Eriococcus au… COL:316450       accepted        species   Animal…
#> # … with more rows, and 13 more variables: phylum <chr>, class <chr>,
#> #   order <chr>, family <chr>, genus <chr>, specificEpithet <chr>,
#> #   infraspecificEpithet <chr>, taxonConceptID <chr>, isExtinct <chr>,
#> #   nameAccordingTo <chr>, namePublishedIn <chr>,
#> #   scientificNameAuthorship <chr>, vernacularName <chr>
```

We can still use most familiar `dplyr` verbs to perform common tasks.
For instance: which species has the most known synonyms?

``` r
most_synonyms <- 
  taxa_tbl("col") %>% 
  count(acceptedNameUsageID, sort=TRUE)
most_synonyms
#> # Source:     lazy query [?? x 2]
#> # Database:   duckdb_connection
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

So which species had those 456 names?

``` r
#most_synonyms %>% 
#  head(1) %>% 
#  pull(acceptedNameUsageID) %>% 
#  filter_id("col") %>%
#  select(scientificName)


filter_id("COL:43082445", "col")
#> # A tibble: 1 x 21
#>   input  sort taxonID scientificName acceptedNameUsa… taxonomicStatus taxonRank
#>   <chr> <int> <chr>   <chr>          <chr>            <chr>           <chr>    
#> 1 COL:…     1 COL:43… Mentha longif… COL:43082445     accepted        infraspe…
#> # … with 14 more variables: kingdom <chr>, phylum <chr>, class <chr>,
#> #   order <chr>, family <chr>, genus <chr>, specificEpithet <chr>,
#> #   infraspecificEpithet <chr>, taxonConceptID <chr>, isExtinct <chr>,
#> #   nameAccordingTo <chr>, namePublishedIn <chr>,
#> #   scientificNameAuthorship <chr>, vernacularName <chr>
```

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
this project you agree to abide by its
terms.

[![ropensci\_footer](https://ropensci.org/public_images/ropensci_footer.png)](https://ropensci.org)
