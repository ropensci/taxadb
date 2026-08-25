# taxadb 0.3.0

## Data

All provider snapshots are rebuilt (#123). Six defects in the previously
published tables are fixed:

* `ncbi`: accepted names had no `taxonID` -- 2,210,230 of them -- which broke
  `filter_id()`, `get_names()` and the `get_ids()` round trip for the
  provider. The table also held only 3.8M of NCBI's 5.1M names, missing most
  names above species rank, and put the whole binomial in `specificEpithet`
  where every other provider puts the epithet alone.
* `col`: 402,570 names were empty, nearly all at genus rank and above, so
  higher taxa could not be found by name.
* `gbif`: 1,272,809 names were empty -- BOLD BINs, UNITE species hypotheses,
  metagenome-assembled genomes and hybrid formulas, which GBIF cannot
  canonicalize but which are still the names. 40,895 synonyms of `doubtful`
  names could not be resolved.
* `ott`: 2,226,375 synonyms had no `taxonomicStatus`, because OTT stopped
  populating the column this was read from.
* `itis`: 208,544 names gained a `family` and 212,029 a `class`; rank
  information had been missing for plants and fungi.
* `fb`, `slb`: accepted names and synonyms were numbered in separate
  sequences but given the same prefix, so 28,989 identifiers in `slb` named
  more than one taxon.

`scientificName` now preserves the authority's own name string. Previously
`clean_names()` was applied when building the tables, which stripped
punctuation out of the reference data itself: the phylum `Deinococcus-Thermus`
was published as `Deinococcus Thermus`, and `Acalypha gracilens var.
monococca` as `var  monococca`. `clean_names()` is for normalizing your own
input at query time; it is unchanged and still exported.

`fb` (FishBase) and `slb` (SeaLifeBase) are published again.

`iucn`, `tpl` and `wd` are dropped. The IUCN Red List cannot be redistributed
under its terms and its API now requires a personal token -- use
[rredlist](https://docs.ropensci.org/rredlist/), noting that the Red List is a
conservation-status source rather than a taxonomy. The Plant List was retired
by its maintainers in 2013; use `col`, or World Flora Online. Wikidata was
never published.

Note that the `gbif` table is built from the most recent backbone GBIF has
published, which is dated 2023-08-28.

## Versions

Older releases are republished on the same object store as the current ones,
so an analysis that pinned a version keeps resolving. Archival snapshots are
byte-identical to the original release and are deliberately **not** corrected:
a silently repaired snapshot would return different results to a script
written against the real one. They therefore predate the schema rules and
generally violate some, which each release records per table in the
`rules_violated` column of its `manifest.csv`.

`22.12` -- the version `taxadb` 0.2.x resolved by default, and the one pinned
by `bdc` and `BeeBDC` -- is published, covering the nine datasets that release
declared. Its IUCN table is excluded: the Red List terms prohibit
redistribution of the data and its derivatives.

## Reading the data

* Tables are read directly from versioned Parquet on
  [source.coop](https://source.coop/cboettig/taxadb) by `duckdb`. There is no
  import step: `filter_name("Homo sapiens", "itis")` works on a fresh install.
* `td_download()` installs a local copy for offline use or repeated queries.
  `td_create()` is retained as an alias for it.
* `available_versions()`, `available_providers()` and `list_snapshots()`
  report what is published, discovered from the data repository, so a new
  release needs no package update to become visible.
* `taxadb_uri()` gives the location backing any table, and
  `options(taxadb_repo=)` redirects reads to a mirror or to your own builds.
* `taxadb_provider_info()` gives each provider's authority, licence and
  preferred citation. **`fb` and `slb` are CC BY-NC** and may not be used
  commercially; the other providers permit commercial use with attribution.

## Building and checking the data

* `td_build()` rebuilds a provider from its own distribution, and
  `build_itis()`, `build_ncbi()`, `build_col()`, `build_gbif()`, `build_ott()`
  and `build_fishbase()` are exported individually. This supersedes the
  separate `taxadb-cache` repository, so a fresher snapshot than the published
  one no longer requires anyone else's involvement. Builds run in `duckdb`,
  out of core.
* `td_validate()` checks a table against the taxadb schema rules, stated as
  structural invariants rather than a column whitelist. It is what gates the
  published snapshots.
* `td_manifest()` and `td_write_metadata()` describe a built snapshot: row
  counts, column lists, per-file SHA-256, and the upstream release each table
  was derived from.

## Breaking changes

* `duckdb` is the only backend. The `RSQLite`, `MonetDBLite` and in-memory
  options are gone, along with the `backends` vignette and the `TAXADB_DRIVER`
  environment variable. `dbdir`, `driver` and `read_only` arguments to
  `td_connect()` are ignored.
* The content-hash and provenance layer is removed: `tl_import()`, the
  bundled `schema.json`, and the `contentid` and `memoise` dependencies. The
  data are addressed by version and provider instead.
* `iucn`, `tpl` and `wd` are no longer recognized providers.
* `ncbi`'s `specificEpithet` holds the epithet, not the binomial. `fb` and
  `slb` synonyms have a `NULL` `taxonID`, with the FishBase `SynCode` in a
  new `synonymID` column.

## Documentation

* README gains a section on names that match more than one taxon, which
  affects 207,438 of GBIF's 7.2 million names (2.9%). It separates the three
  causes -- homonyms across nomenclatural codes, ambiguous synonyms, and
  duplicate name usages -- and recommends `filter_name()` over `get_ids()`
  for bulk matching, since keeping only accepted rows resolves 51% of cases
  and the classification columns resolve most of the rest.

## Bug fixes

* `filter_name()` and the other `filter_*` functions no longer let `duckdb`
  scale memory with core count. `duckdb` defaults to one scanning thread per
  core and a buffer pool of most of system RAM; each scanning thread holds a
  decompressed Parquet row group, so on a 128-core machine looking up a single
  name in the GBIF table peaked at 1.3 GB while getting no faster.
  `td_connect()` now caps threads at 8, which measured *faster* than the
  default (0.7s against 1.0s) at a quarter of the memory. Raise it with
  `options(taxadb_threads=)`; `td_build()` lifts it automatically, since a
  bulk build is the opposite workload (#95).
* `latest_version()` ordered versions as strings, so `"22.12"` sorted above
  `"2026"` and publishing an archival release would have made 2022 data the
  default for every query. Versions are now compared as version numbers.
* `itis` and `ncbi` gain `scientificNameAuthorship`, which every other
  provider already carried (#100). ITIS supplies it for 97% of names; NCBI
  records authorship as a separate `authority` name, which is now also lifted
  onto the taxon's other rows, covering 52%. Authorship is what distinguishes
  same-name-different-author synonyms, which is the case the requester raised.
* The paper describing the package is cited in the README and the
  `data-sources` vignette, not only in `inst/CITATION` (#92).
* The warning `get_ids()` emits for an ambiguous name suggested
  `filter_name('X', '')` with an empty provider, because it was built from
  the deprecated `db` argument rather than `provider`. The suggested command
  now works.
* `get_names()` returns `NA` for an unmatched identifier, as documented,
  rather than erroring.
* `get_names()` works for every identifier format. The `uri` format never
  round-tripped for any provider, because the URI prefix was applied as a
  regular expression and ITIS's contains `?` and `&`; and all formats but
  `prefix` errored for the `itis_test` provider.
* The bundled `itis_test` fixture is regenerated from a real build, and the
  examples that had been querying names absent from it now work.

# taxadb 0.2.2

* `clean_names` now also removes the "spp." epithet

# taxadb 0.2.1

* substantial speed improvements to all `filter_*` and `get_*` functions
* streamline legacy code in filter_* and get_* functions to better leverage duckdb speed increase
* `get_names` and `get_ids` now use the same argument name, `provider`, to specify the naming provider,
  rather than `db` (which was used in `taxize::get_ids`)

# taxadb 0.2.0

* taxadb is now backed by partitioned parquet files, cached locally by contentid
* taxadb is now fully-duckdb based. This deprecates the previous 'pluggable' backend
  with options to use RSQLite or no database backend. Parquet-backed option means that
  even initial import is much faster, leaving no need to use any of the inferior 
  backend options.
* mutate_db is deprecated, `dplyr::mutate()` will work as anticipated.
* metadata/prov archive is now based on schema.org rather than DCAT2
* includes 22.12 release for name providers `col`, `itis`, `ncbi`, `ott`, and `gbif`.
  Other database name providers are currently deprecated (though at least `iucn` should be restored soon).

# taxadb 0.1.6

* bugfix for recent duckdb release. 
(imported table names are now prefixed with "v" to avoid names that start with numbers)


# taxadb 0.1.5

* bugfix for upcoming dbplyr release

# taxadb 0.1.4

* bugfix in `get_ids()` when multiple English common names are accepted for the species.
* export `taxadb_dir()`, making it easier to purge the DB after `duckdb` upgrades
* All imports must be used
* Improve testing in `db=NULL` case.
* Require R.utils, to ensure compressed files can be expanded

# taxadb 0.1.3

* more robust testing

# taxadb 0.1.2

* avoid erroneous messages when installing providers that lack common names.

# taxadb 0.1.1

* introduce `tl_import` to import taxonomic databases [#79]
* make `duckdb` the default backend
* bugfix to possible ordering problem in `get_names` [#78]
* Added a `NEWS.md` file to track changes to the package.
