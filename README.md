
[![lifecycle](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![Travis build
status](https://travis-ci.org/cboettig/taxald.svg?branch=master)](https://travis-ci.org/cboettig/taxald)
[![Coverage
status](https://codecov.io/gh/cboettig/taxald/branch/master/graph/badge.svg)](https://codecov.io/github/cboettig/taxald?branch=master)
[![CRAN
status](https://www.r-pkg.org/badges/version/taxald)](https://cran.r-project.org/package=taxald)

<!-- README.md is generated from README.Rmd. Please edit that file -->

# taxald

**This package is purley exploratory at this stage\!**

Central to `taxald` design is to create a *local* database of all
avialable taxonomic authority data that we can query quickly, even when
working with tens of thousands of species. The second key feature of
`taxald` design is to return queries from each authority using a
*consistent* and convenient table structure, facilitating queries that
compare, combine, or work across names from multiple authorities.

## Install and initial setup

`taxald` should now be installable. To get started, try:

``` r
devtools::install_github("cboettig/taxald")
```

Before we can use most `taxald` functions, we need to do a one-time
installation of the database `taxald` uses for almost all commands. This
can take a while to run, but needs only be done once. The database is
installed on your local harddisk and will persist between R sessions.
Download and install the database like so:

``` r
library(taxald)
```

``` r
create_taxadb()
```

By default, this will install the database into a hidden `.taxald`
folder in your home directory (`~/.taxald`). You can control this by
passing the path to `create_taxadb()` or setting the environmental
variable `TAXALD_HOME` to a different location.

This function downloads each of the individual tables and loads them
into a [MonetDBLite](https://www.monetdb.org) database. (MonetDBLite is
much like SQLite, requiring no external server setup. However, for our
purposes, MonetDB’s columnar design provides significantly faster
performance than SQLite, Postgres, or even some in-memory operations in
`dplyr`.)

Currently tables are pulled from the development cache on GitHub. Many
of these tables are still being cleaned up and standardized, see
[schema.md](schema.md). Multiple tablesare provided for each authority,
though some of these contain redundant information, different
orientations may prove more convenient or computationally efficient.

## Package API

``` r
library(tictoc) # let's display timing of queries for reference
```

Once the database is installed, we can start to make some queries.

First, let’s get a nice big species list, say, all the birds (known to
the Catalogue of Life):

``` r
tic()
df <- descendents(name = "Aves", rank = "class", authority="col")
#> Joining, by = "path_rank"
#> Warning: Translator is missing window variants of the following aggregate functions:
#> * median

#> Warning: Translator is missing window variants of the following aggregate functions:
#> * median
toc()
#> 8.961 sec elapsed
```

How many species did we get?

``` r
length(df$name)
#> [1] 1758354
```

In general, this species list could have come from anywhere (i.e. some
particular research project) and not from a single authority.

We can get the full hierachical classification for this list of species:

``` r
tic()
hierarchy(df$name)
#> Joining, by = "species"
#> # A tibble: 1,758,654 x 26
#>    id    class family genus infraclass infrakingdom infraorder infraphylum
#>    <chr> <chr> <chr>  <chr> <chr>      <chr>        <chr>      <chr>      
#>  1 ITIS… Gast… Punct… Para… <NA>       Protostomia  <NA>       <NA>       
#>  2 ITIS… Inse… Diasp… Pseu… Neoptera   Protostomia  <NA>       <NA>       
#>  3 ITIS… Inse… Diasp… Pseu… Neoptera   Protostomia  <NA>       <NA>       
#>  4 ITIS… Inse… Diasp… Pseu… Neoptera   Protostomia  <NA>       <NA>       
#>  5 ITIS… Inse… Diasp… Pseu… Neoptera   Protostomia  <NA>       <NA>       
#>  6 ITIS… Inse… Dacty… Pseu… Neoptera   Protostomia  <NA>       <NA>       
#>  7 ITIS… Inse… Diasp… Radi… Neoptera   Protostomia  <NA>       <NA>       
#>  8 ITIS… Inse… Diasp… Thys… Neoptera   Protostomia  <NA>       <NA>       
#>  9 ITIS… Inse… Diasp… Thys… Neoptera   Protostomia  <NA>       <NA>       
#> 10 ITIS… Inse… Erioc… Erio… Neoptera   Protostomia  <NA>       <NA>       
#> # ... with 1,758,644 more rows, and 18 more variables: kingdom <chr>,
#> #   order <chr>, phylum <chr>, section <chr>, species <chr>,
#> #   subclass <chr>, subfamily <chr>, subgenus <chr>, subkingdom <chr>,
#> #   suborder <chr>, subphylum <chr>, subsection <chr>, subtribe <chr>,
#> #   superclass <chr>, superfamily <chr>, superorder <chr>,
#> #   superphylum <chr>, tribe <chr>
toc()
#> 15.567 sec elapsed
```

Design sketch/spec for package API:

  - Given vector of taxonomic names, return taxonomic identifiers
  - Given taxonomic identifiers, return heirarchical classification.

(Note that for some authorities, e.g. GBIF and TPL, taxonomic
identifiers are only assigned to species names. So given the name of a
higher-level rank, no id could be returned)

  - Given any higher-order rank name (e.g. `infraorder`) return
    identifiers of all member species.

  - Given common names, resolve to accepted scientific name

  - Resolve any known miss-spelling, recognized synonymous name, generic
    name or name-part to corresponding taxonomic name.

  - Map between identifiers

  - Normalize rank names

  - Resolve a list of names across multiple authorities to attain higher
    coverage,

  - provide merged tables

See [schema.md](schema.md) for a sketch of the underlying database
architecture imposed on the data source from each authority.

Note that all inputs and outputs should be vectorized.
