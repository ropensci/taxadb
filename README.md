
<!-- README.md is generated from README.Rmd. Please edit that file -->

# taxald

## Package API

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

-----

  - Resolve a list of names across multiple authorities to attain higher
    coverage,
  - provide merged tables

See [schema.md](schema.md) for a sketch of the underlying database
architecture imposed on the data source from each authority.

Note that all inputs and outputs should be vectorized.
