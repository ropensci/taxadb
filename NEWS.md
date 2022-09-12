
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
