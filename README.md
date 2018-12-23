
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

The goal of `taxadb` is to provide fast access to taxonomic data and
manipulations, such as resolving taxonomic names to ids, looking up
higher classification ranks of given species, or returning a list of all
species below a given rank. These tasks are particularly common when
synthesizing data across large species assemblies, such as combining
occurrence records with trait records.

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

Before we can use most `taxadb` functions, we need to do a one-time
installation of the database `taxadb` uses for almost all commands. This
can take a while to run, but needs only be done once. The database is
installed on your local hard-disk and will persist between R sessions.
By default, the database will be installed in your user’s application
data directory, as detected by the `rappdirs` package. (Set a custom
location instead using `dbdir` argument.)

``` r
library(taxadb)
td_create()
#> not overwriting itis_hierarchy
#> not overwriting itis_taxonid
#> not overwriting itis_synonyms
```

The default behavior installs only the ITIS database. You can also
specify a list of authorities to install, or install every authority
using `td_create("all")`.

## Test drive

Once the databases have been set up, we’re ready to explore.  
Here’s a list of all the birds species known to ITIS:

``` r
descendants(name = "Aves", rank = "class")
#> # A tibble: 10,401 x 26
#>    id    class family genus infraclass infrakingdom infraorder infraphylum
#>    <chr> <chr> <chr>  <chr> <chr>      <chr>        <chr>      <chr>      
#>  1 ITIS… Aves  Strut… Stru… <NA>       Deuterostom… <NA>       Gnathostom…
#>  2 ITIS… Aves  Rheid… Rhea  <NA>       Deuterostom… <NA>       Gnathostom…
#>  3 ITIS… Aves  Droma… Drom… <NA>       Deuterostom… <NA>       Gnathostom…
#>  4 ITIS… Aves  Casua… Casu… <NA>       Deuterostom… <NA>       Gnathostom…
#>  5 ITIS… Aves  Casua… Casu… <NA>       Deuterostom… <NA>       Gnathostom…
#>  6 ITIS… Aves  Apter… Apte… <NA>       Deuterostom… <NA>       Gnathostom…
#>  7 ITIS… Aves  Tinam… Tina… <NA>       Deuterostom… <NA>       Gnathostom…
#>  8 ITIS… Aves  Tinam… Tina… <NA>       Deuterostom… <NA>       Gnathostom…
#>  9 ITIS… Aves  Tinam… Tina… <NA>       Deuterostom… <NA>       Gnathostom…
#> 10 ITIS… Aves  Tinam… Tina… <NA>       Deuterostom… <NA>       Gnathostom…
#> # ... with 10,391 more rows, and 18 more variables: kingdom <chr>,
#> #   order <chr>, phylum <chr>, section <chr>, species <chr>,
#> #   subclass <chr>, subfamily <chr>, subgenus <chr>, subkingdom <chr>,
#> #   suborder <chr>, subphylum <chr>, subsection <chr>, subtribe <chr>,
#> #   superclass <chr>, superfamily <chr>, superorder <chr>,
#> #   superphylum <chr>, tribe <chr>
```

## Learn More

### [An introduction to taxadb](https://cboettig.github.io/taxadb/articles/articles/taxadb.html)

The [taxadb
introduction](https://cboettig.github.io/taxadb/articles/articles/taxadb.html)
provides an overview showing how `taxadb` functions can help us
synthesize data across a given list of species by resolving synonyms and
identifiers.

### [taxadb schemas](https://cboettig.github.io/taxadb/articles/articles/schema.html)

See the
[schemas](https://cboettig.github.io/taxadb/articles/articles/schema.html)
vignette for an overview of the underlying tables used by `taxadb`
functions, and more about the different authorities accessed by taxadb.
