
<!-- README.md is generated from README.Rmd. Please edit that file -->

# taxadb <img src="man/figures/logo.svg" align="right" alt="" width="120" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/ropensci/taxadb/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ropensci/taxadb/actions/workflows/R-CMD-check.yaml)
[![lifecycle](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html)
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
authorities particularly complex. `taxadb` provides each of the readily
available taxonomic authorities in one consistent, standard,
researcher-friendly tabular format, and queries it with ordinary `dplyr`
verbs.

The data are published as versioned
[Parquet](https://parquet.apache.org/) snapshots on
[source.coop](https://source.coop/cboettig/taxadb) and read directly
from there by `duckdb`, so there is no import step and no server to set
up. Queries only read the columns and row groups they need, so filtering
a seven-million-row table over the network is quick. If you would rather
work offline or are making many queries against one table,
`td_download()` installs a local copy and everything else is unchanged.

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

No setup step is needed: tables are read on demand. To see what is
published,

``` r
available_versions()
#> [1] "2026"
available_providers()
#>    provider schema
#> 1       col common
#> 7       col    dwc
#> 2        fb common
#> 8        fb    dwc
#> 3      gbif common
#> 9      gbif    dwc
#> 4      itis common
#> 10     itis    dwc
#> 5      ncbi common
#> 11     ncbi    dwc
#> 12      ott    dwc
#> 6       slb common
#> 13      slb    dwc
```

Optionally, install a local copy of a provider you plan to query
heavily:

``` r
td_download("col")
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
#> [1m[22mJoining with `by = join_by(scientificName)`

head(birds, 10)
#>                          species        id
#> 1         Dendrocygna autumnalis COL:34Q2Z
#> 2            Dendrocygna bicolor COL:34Q32
#> 3                Anser canagicus COL:66XX4
#> 4             Anser caerulescens COL:66XWS
#> 5  Chen caerulescens (blue form)      <NA>
#> 6                   Anser rossii COL:66XWT
#> 7                Anser albifrons COL:679WV
#> 8                Branta bernicla  COL:N749
#> 9      Branta bernicla nigricans COL:7JGH7
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
#> 3               Anser canagicus COL:66XX4        Anser canagicus
#> 4            Anser caerulescens COL:66XWS     Anser caerulescens
#> 5 Chen caerulescens (blue form)      <NA>                   <NA>
#> 6                  Anser rossii COL:66XWT           Anser rossii
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
#> [1m[22mJoining with `by = join_by(scientificName)`
#> Warning:   Found [1m[34m5[39m[22m possible identifiers for [3m[1m[31mAgrostis caespitosa[39m[22m[23m.
#>   Returning [1m[34mNA[39m[22m. Try [1m[34mfilter_name('Agrostis caespitosa', 'itis')[39m[22m to resolve manually.
#> [1] NA
```

Using `filter_name()`, we find this is because the name resolves not to
zero matches, but is a known synonym to more than one accepted name (as
indicated by the accepted name usage id)

``` r
filter_name('Agrostis caespitosa', 'itis')
#> [90m# A tibble: 6 × 15[39m
#>   taxonID   scientificName taxonRank acceptedNameUsageID taxonomicStatus kingdom
#>   [3m[90m<chr>[39m[23m     [3m[90m<chr>[39m[23m          [3m[90m<chr>[39m[23m     [3m[90m<chr>[39m[23m               [3m[90m<chr>[39m[23m           [3m[90m<chr>[39m[23m  
#> [90m1[39m ITIS:785… Agrostis caes… species   ITIS:502001         synonym         Plantae
#> [90m2[39m ITIS:785… Agrostis caes… species   ITIS:40400          synonym         Plantae
#> [90m3[39m ITIS:785… Agrostis caes… species   ITIS:40400          synonym         Plantae
#> [90m4[39m ITIS:785… Agrostis caes… species   ITIS:782718         synonym         Plantae
#> [90m5[39m ITIS:785… Agrostis caes… species   ITIS:503886         synonym         Plantae
#> [90m6[39m ITIS:785… Agrostis caes… species   ITIS:783883         synonym         Plantae
#> [90m# ℹ 9 more variables: phylum <chr>, class <chr>, order <chr>, family <chr>,[39m
#> [90m#   genus <chr>, specificEpithet <chr>, infraspecificEpithet <chr>,[39m
#> [90m#   vernacularName <chr>, update_date <chr>[39m
```

We can resolve the scientific name to the acceptedNameUsage using
`get_names()` on the *accepted* IDs: (These also correspond to the genus
and specificEpithet column, as the classification is always given only
based on acceptedNameUsageID).

``` r
filter_name("Agrostis caespitosa")  %>%
  mutate(acceptedNameUsage = get_names(acceptedNameUsageID)) %>% 
  select(scientificName, taxonomicStatus, acceptedNameUsage, acceptedNameUsageID)
#> [90m# A tibble: 6 × 4[39m
#>   scientificName      taxonomicStatus acceptedNameUsage      acceptedNameUsageID
#>   [3m[90m<chr>[39m[23m               [3m[90m<chr>[39m[23m           [3m[90m<chr>[39m[23m                  [3m[90m<chr>[39m[23m              
#> [90m1[39m Agrostis caespitosa synonym         Deschampsia cespitosa  ITIS:502001        
#> [90m2[39m Agrostis caespitosa synonym         Agrostis stolonifera   ITIS:40400         
#> [90m3[39m Agrostis caespitosa synonym         Agrostis stolonifera   ITIS:40400         
#> [90m4[39m Agrostis caespitosa synonym         Calamagrostis preslii  ITIS:782718        
#> [90m5[39m Agrostis caespitosa synonym         Muhlenbergia torreyi   ITIS:503886        
#> [90m6[39m Agrostis caespitosa synonym         Muhlenbergia quadride… ITIS:783883
```

Similar functions `filter_id`, `filter_rank`, and `filter_common` take
IDs, scientific ranks, or common names, respectively. Here, we can get
taxonomic data on all bird names in the Catalogue of Life:

``` r
filter_rank(name = "Aves", rank = "class", provider = "col")
#> [90m# A tibble: 56,739 × 25[39m
#>    taxonID  scientificName taxonRank acceptedNameUsageID taxonomicStatus kingdom
#>    [3m[90m<chr>[39m[23m    [3m[90m<chr>[39m[23m          [3m[90m<chr>[39m[23m     [3m[90m<chr>[39m[23m               [3m[90m<chr>[39m[23m           [3m[90m<chr>[39m[23m  
#> [90m 1[39m COL:ZMF  Arachnothera   genus     COL:ZMF             accepted        Animal…
#> [90m 2[39m COL:ZQC  Aramides       genus     COL:ZQC             accepted        Animal…
#> [90m 3[39m COL:ZQH  Aramus         genus     COL:ZQH             accepted        Animal…
#> [90m 4[39m COL:ZRKV Crotophaga ani species   COL:ZRKV            accepted        Animal…
#> [90m 5[39m COL:ZRKW Crotophaga ma… species   COL:ZRKW            accepted        Animal…
#> [90m 6[39m COL:ZRKX Crotophaga su… species   COL:ZRKX            accepted        Animal…
#> [90m 7[39m COL:ZRV  Aratinga       genus     COL:ZRV             accepted        Animal…
#> [90m 8[39m COL:ZQD  Aramidopsis    genus     COL:ZQD             accepted        Animal…
#> [90m 9[39m COL:ZT9X Crypsirina cu… species   COL:ZT9X            accepted        Animal…
#> [90m10[39m COL:ZT9Y Crypsirina te… species   COL:ZT9Y            accepted        Animal…
#> [90m# ℹ 56,729 more rows[39m
#> [90m# ℹ 19 more variables: phylum <chr>, class <chr>, order <chr>, family <chr>,[39m
#> [90m#   genus <chr>, specificEpithet <chr>, infraspecificEpithet <chr>,[39m
#> [90m#   vernacularName <chr>, scientificNameAuthorship <chr>,[39m
#> [90m#   cultivarEpithet <chr>, nomenclaturalCode <chr>, nomenclaturalStatus <chr>,[39m
#> [90m#   namePublishedIn <chr>, nameAccordingTo <chr>, taxonRemarks <chr>,[39m
#> [90m#   parentNameUsageID <chr>, originalNameUsageID <chr>, datasetID <chr>, …[39m
```

Combining these with `dplyr` functions can make it easy to explore this
data: for instance, which families have the most species?

``` r
filter_rank(name = "Aves", rank = "class", provider = "col") %>%
  filter(taxonomicStatus == "accepted", taxonRank=="species") %>% 
  group_by(family) %>%
  count(sort = TRUE) %>% 
  head()
#> [90m# A tibble: 6 × 2[39m
#> [90m# Groups:   family [6][39m
#>   family           n
#>   [3m[90m<chr>[39m[23m        [3m[90m<int>[39m[23m
#> [90m1[39m Tyrannidae     446
#> [90m2[39m Thraupidae     387
#> [90m3[39m Trochilidae    361
#> [90m4[39m Columbidae     352
#> [90m5[39m Furnariidae    321
#> [90m6[39m Muscicapidae   318
```

## When a name matches more than one taxon

`get_ids()` returns one identifier per input name, so it has to return
`NA` when a name resolves more than one way, with a warning telling you
which name was ambiguous:

``` r
get_ids(c("Morus", "Homo sapiens"), "gbif")
#> [1m[22mJoining with `by = join_by(scientificName)`
#> Warning:   Found [1m[34m2[39m[22m possible identifiers for [3m[1m[31mMorus[39m[22m[23m.
#>   Returning [1m[34mNA[39m[22m. Try [1m[34mfilter_name('Morus', 'gbif')[39m[22m to resolve manually.
#> [1] NA             "GBIF:2436436"
```

This is not a data defect, and it is common: **207,438 of GBIF’s 7.2
million names (2.9%) resolve to more than one accepted identifier.**
Three different things cause it, and they call for different responses.

**Homonyms.** The same name published independently under different
codes of nomenclature, most often once for an animal and once for a
plant. `Morus` is both the gannets and the mulberries:

``` r
filter_name("Morus", "gbif") |>
  filter(taxonomicStatus == "accepted") |>
  select(taxonID, scientificName, kingdom, family)
#> [90m# A tibble: 2 × 4[39m
#>   taxonID      scientificName kingdom  family  
#>   [3m[90m<chr>[39m[23m        [3m[90m<chr>[39m[23m          [3m[90m<chr>[39m[23m    [3m[90m<chr>[39m[23m   
#> [90m1[39m GBIF:2480962 Morus          Animalia Sulidae 
#> [90m2[39m GBIF:2984545 Morus          Plantae  Moraceae
```

`Erica` (a jumping spider and the heaths), `Oenanthe` (the wheatears and
the water-dropworts) and `Prunella` (the accentors and selfheal) are the
same story. No lookup can resolve these from the name alone, because the
name genuinely denotes two taxa.

**Ambiguous synonyms.** A name that has been applied to two different
accepted taxa, and so is a synonym of both. These have no accepted row
of their own:

``` r
filter_name("Sphex coronatus", "gbif") |>
  select(taxonID, taxonomicStatus, acceptedNameUsageID, family)
#> [90m# A tibble: 2 × 4[39m
#>   taxonID       taxonomicStatus     acceptedNameUsageID family     
#>   [3m[90m<chr>[39m[23m         [3m[90m<chr>[39m[23m               [3m[90m<chr>[39m[23m               [3m[90m<chr>[39m[23m      
#> [90m1[39m GBIF:7752074  heterotypic synonym GBIF:7438612        Crabronidae
#> [90m2[39m GBIF:10994029 heterotypic synonym GBIF:5041068        Sphecidae
```

**Duplicate name usages**, where the same name appears at several ranks
or in several rank-level combinations.

### What to do

Most of it resolves on its own. Of the 207,438 ambiguous GBIF names:

|                                                   | names   | share |
|---------------------------------------------------|---------|-------|
| resolve to one once you keep only accepted names  | 106,700 | 51%   |
| are ambiguous synonyms, with no accepted row      | 90,321  | 44%   |
| are true homonyms, ambiguous among accepted names | 10,417  | 5%    |

So the first move is to use `filter_name()` rather than `get_ids()` and
keep the accepted rows, which recovers half the cases and shows you the
rest instead of collapsing them to `NA`:

``` r
matched <- filter_name(c("Morus", "Oenanthe", "Homo sapiens"), "gbif") |>
  filter(taxonomicStatus == "accepted")
count(matched, scientificName)
#> [90m# A tibble: 3 × 2[39m
#>   scientificName     n
#>   [3m[90m<chr>[39m[23m          [3m[90m<int>[39m[23m
#> [90m1[39m Homo sapiens       1
#> [90m2[39m Morus              2
#> [90m3[39m Oenanthe           2
```

For the 10,417 genuine homonyms, add whatever you already know about the
group. `kingdom` separates 3,160 of them and `family` another 88:

``` r
filter_name("Morus", "gbif") |>
  filter(taxonomicStatus == "accepted", kingdom == "Plantae") |>
  select(taxonID, scientificName, family)
#> [90m# A tibble: 1 × 3[39m
#>   taxonID      scientificName family  
#>   [3m[90m<chr>[39m[23m        [3m[90m<chr>[39m[23m          [3m[90m<chr>[39m[23m   
#> [90m1[39m GBIF:2984545 Morus          Moraceae
```

The remaining 7,169 are homonyms within a single family. Nothing in the
data distinguishes them, so they need a decision from you rather than a
better query – which is the honest answer, and the reason `get_ids()`
returns `NA` rather than guessing.

Because providers disagree about which names are ambiguous, a name that
is ambiguous in GBIF may be unambiguous in ITIS or COL. Resolving
against a second provider is a reasonable tiebreak, but do not mix the
resulting identifiers: see `vignette("data-sources")` on why providers
are not interchangeable.

## Using the database connection directly

`filter_*` functions by default return in-memory data frames. Because
they are filtering functions, they return a subset of the full data
which matches a given query (names, ids, ranks, etc), so the returned
data.frames are smaller than the full record of a naming provider.
Working directly with the database connection gives us access to all the
data. The `taxa_tbl()` function provides this connection:

``` r
taxa_tbl("col")
#> [90m# A query:  ?? x 25[39m
#> [90m# Database: DuckDB 1.5.4 [unknown@Linux 6.17.9-76061709-generic:R 4.6.1/:memory:][39m
#>    taxonID  scientificName taxonRank acceptedNameUsageID taxonomicStatus kingdom
#>    [3m[90m<chr>[39m[23m    [3m[90m<chr>[39m[23m          [3m[90m<chr>[39m[23m     [3m[90m<chr>[39m[23m               [3m[90m<chr>[39m[23m           [3m[90m<chr>[39m[23m  
#> [90m 1[39m COL:ZLWR Crossocerus a… species   COL:ZLWR            accepted        Animal…
#> [90m 2[39m COL:ZLWS Crossocerus a… species   COL:ZLWS            accepted        Animal…
#> [90m 3[39m COL:ZLWT Crossocerus a… species   COL:ZLWT            accepted        Animal…
#> [90m 4[39m COL:ZLWV Crossocerus a… species   COL:ZLWV            accepted        Animal…
#> [90m 5[39m COL:ZLWW Crossocerus a… species   COL:ZM5T            synonym         Animal…
#> [90m 6[39m COL:ZLWX Crossocerus a… species   COL:ZLWX            accepted        Animal…
#> [90m 7[39m COL:ZLW… Marefusivirus… species   COL:ZLWXDDuEcdAV0x… accepted        [31mNA[39m     
#> [90m 8[39m COL:ZLWY Crossocerus a… species   COL:ZLWY            accepted        Animal…
#> [90m 9[39m COL:ZLWZ Crossocerus a… species   COL:ZLWZ            accepted        Animal…
#> [90m10[39m COL:ZLX  Arachnophyllum genus     COL:ZLX             accepted        Plantae
#> [90m# ℹ more rows[39m
#> [90m# ℹ 19 more variables: phylum <chr>, class <chr>, order <chr>, family <chr>,[39m
#> [90m#   genus <chr>, specificEpithet <chr>, infraspecificEpithet <chr>,[39m
#> [90m#   vernacularName <chr>, scientificNameAuthorship <chr>,[39m
#> [90m#   cultivarEpithet <chr>, nomenclaturalCode <chr>, nomenclaturalStatus <chr>,[39m
#> [90m#   namePublishedIn <chr>, nameAccordingTo <chr>, taxonRemarks <chr>,[39m
#> [90m#   parentNameUsageID <chr>, originalNameUsageID <chr>, datasetID <chr>, …[39m
```

We can still use most familiar `dplyr` verbs to perform common tasks.
For instance: which species has the most known synonyms?

``` r
taxa_tbl("itis") %>% 
  count(acceptedNameUsageID, sort=TRUE)
#> [90m# A query:    ?? x 2[39m
#> [90m# Database:   DuckDB 1.5.4 [unknown@Linux 6.17.9-76061709-generic:R 4.6.1/:memory:][39m
#> [90m# Ordered by: desc(n)[39m
#>    acceptedNameUsageID     n
#>    [3m[90m<chr>[39m[23m               [3m[90m<dbl>[39m[23m
#> [90m 1[39m ITIS:50               463
#> [90m 2[39m ITIS:983681           324
#> [90m 3[39m ITIS:983691           278
#> [90m 4[39m ITIS:983714           197
#> [90m 5[39m ITIS:798259           145
#> [90m 6[39m ITIS:24921            144
#> [90m 7[39m ITIS:983710           141
#> [90m 8[39m ITIS:527684           134
#> [90m 9[39m ITIS:505191           127
#> [90m10[39m ITIS:504874           123
#> [90m# ℹ more rows[39m
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

- `taxadb_provider_info()` gives each provider’s authority, licence and
  preferred citation. Note that `fb` and `slb` are CC BY-NC.

## Building the data yourself

The published snapshots are built by this package, using exported
functions rather than a separate pipeline, so you can rebuild any
provider yourself – to get a fresher snapshot than the published one, or
to check how a table was derived:

``` r
td_build("itis")          # fetch, normalize and write the snapshot
td_validate("itis")       # check it against the schema rules
```

`td_validate()` checks the rules the tables are supposed to satisfy:
`scientificName` non-empty at every rank, `acceptedNameUsageID`
populated on accepted names as well as synonyms, every
`acceptedNameUsageID` resolving to an accepted name, identifiers
carrying the provider prefix and never naming two different names. It is
worth running on your own builds, and it is what gates the published
ones.

Builds run entirely in `duckdb` and out of core, so they are bounded by
disk rather than memory. See `?td_build`.

------------------------------------------------------------------------

Please note that this project is released with a [Contributor Code of
Conduct](https://ropensci.org/code-of-conduct/). By participating in
this project you agree to abide by its terms.

[![ropensci_footer](https://ropensci.org/public_images/ropensci_footer.png)](https://ropensci.org)
