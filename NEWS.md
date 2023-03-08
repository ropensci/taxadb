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
