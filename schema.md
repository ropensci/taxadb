# Database schema for taxald

For each authority:

- `hierarchy` table, in which any valid rank is a column, and a taxon `id` is a unique key.

- `taxonid` table, in which a taxonomic `id` is a unique key to a scientific name, and every taxonomic identifier defined by the authority is present in exactly one row.  Additional columns include the `name` and `rank` associated with that information.  

- Optionally, a `hierarchy_long` table, with columns `id`, `path`, `path_id`, and `path_rank`, defining hierarchy connected to any given taxonomic `id`.  Unlike the "wide" format, this approach can associate un-ranked and duplicate rank names (such as multiple `superfamily` names found in NCBI).    

- Optionally, a `other_names` table, in which a column `other_names` includes any possible name except those names already given in the `taxonid` table (e.g. common names, synonyms, misspellings).   A column `name_type` indicates if name is a common name, A column `id` associates a name with a taxonomic identifer as a foreign key. An optional column `language` specifies the language of any common/vernacular name.

## Long format

`<prefix>_wide`

Single-table representation of all "core" data.  Format includes followings required columns:

id | name | rank  | path    |  path_rank  | path_id
---|------|-------|---------|-------------|---------

And the following optional columns:

 rank_id  | path_rank_id  | name_type   | date
----------|---------------|-------------|---------

Most databases do not define ids for ranks.



Disadvantages: `id` is repeated across rows in order to reflect full hierarchy. Thus
`id` is not a valid *primary key* and performance suffers (both due to higher row count and inability to join on `id` as a *primary key*).  


## Hierarchy table:

Working table name: `<prefix>_wide`

id | species name | kingdom | subkingdom  | ... 
---|--------------|---------|-------------|-----


This format fails to accomodate unnamed ranks or ranks that resolve non-uniquely.

`id` must be a valid primary key and cannot be repeated.

> Should `id` correspond to species level or include all known ids?

Some database sources (GBIF, TPL, and currently FB, SLB the way they are implemented) are "wide" to start and only define identifiers at the species level. 

COL is specified in "wide" format but does define ids for scientific names at all rank levels.  

## Conventions

- `species` is always given as the scientific name associated with the species; e.g. `Homo sapiens` not `sapiens`.  (ITIS convention)
- Identifiers use the integer identifier defined by the authority, prefixed by the authority abbreviation in all capital letters: `ITIS:`, `GBIF:`, etc.
- Rank names are always lower case without hyphens or spaces. Rank names should be mapped
  to a table of standard accepted rank names (i.e. those recognized by ITIS, NCBI, Wikidata),
  and rank names should have 
- Encoding is UTF-8