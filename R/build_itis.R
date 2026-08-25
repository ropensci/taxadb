#' Rebuild the ITIS snapshot
#'
#' @param version snapshot version to write, e.g. `"2026"`
#' @param archive path to the ITIS SQLite archive; downloaded if missing
#' @param dir directory for build inputs and outputs
#' @param db a duckdb connection
#' @return the paths written, invisibly
#' @details ITIS distributes a SQLite database, which duckdb reads directly.
#' `n_usage` carries the accepted/synonym distinction under two vocabularies,
#' zoological (`valid`/`invalid`) and botanical (`accepted`/`not accepted`);
#' both map onto `accepted` and `synonym`.
#'
#' ITIS assigns a TSN to synonyms as well as accepted names, so every row
#' here carries its own `taxonID` -- which makes ITIS the reference for the
#' taxadb rules checked by [td_validate()].
#'
#' `scientificNameAuthorship` is taken from ITIS's own author table, keyed on
#' the author id together with the kingdom, since the id is only unique within
#' one.
#' @family build
#' @export
#' @examples \dontrun{
#' build_itis("2026")
#' }
build_itis <- function(version = format(Sys.Date(), "%Y"),
                       archive = NULL,
                       dir = build_dir(),
                       db = td_connect()){

  if(is.null(archive))
    archive <- fetch_archive("https://www.itis.gov/downloads/itisSqlite.zip",
                             "itisSqlite.zip", dir)
  extracted <- extract_archive(archive, dir, "itis")
  sqlite <- archive_file(extracted, "\\.sqlite$")

  DBI::dbExecute(db, "INSTALL sqlite;")
  DBI::dbExecute(db, "LOAD sqlite;")
  scan <- function(table) paste0("sqlite_scan('", sqlite, "', '", table, "')")

  message("building itis ", version)

  ## rank_id is only unique within a kingdom, so the rank lookup is keyed on
  ## both.  Rank names are lowercased per the taxadb conventions.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE itis_ranks AS
     SELECT kingdom_id, rank_id, lower(rank_name) AS taxonRank
     FROM ", scan("taxon_unit_types")))

  ## Authorship, requested in ropensci/taxadb#100. Like rank_id, the author
  ## id is only unique within a kingdom, so the join is keyed on both. 97% of
  ## ITIS names carry one.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE itis_authors AS
     SELECT taxon_author_id, kingdom_id,
            nullif(trim(taxon_author), '') AS scientificNameAuthorship
     FROM ", scan("taxon_authors_lkp")))

  ## `nodes` is every name ITIS knows, accepted or not.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE itis_nodes AS
     SELECT
       CAST(u.tsn AS VARCHAR)        AS tsn,
       CAST(u.parent_tsn AS VARCHAR) AS parent_tsn,
       u.complete_name               AS scientificName,
       r.taxonRank                   AS taxonRank,
       u.unit_name2                  AS specificEpithet,
       nullif(trim(concat_ws(' ', u.unit_name3, u.unit_name4)), '')
                                     AS infraspecificEpithet,
       CAST(u.update_date AS VARCHAR) AS update_date,
       a.scientificNameAuthorship,
       CASE WHEN u.n_usage IN ('valid', 'accepted') THEN 'accepted'
            ELSE 'synonym' END       AS taxonomicStatus
     FROM ", scan("taxonomic_units"), " u
     LEFT JOIN itis_ranks r
       ON u.rank_id = r.rank_id AND u.kingdom_id = r.kingdom_id
     LEFT JOIN itis_authors a
       ON u.taxon_author_id = a.taxon_author_id
      AND u.kingdom_id = a.kingdom_id"))

  ## The hierarchy is defined over accepted names only; a synonym inherits
  ## the classification of the name it points to.  parent_tsn is 0, not
  ## NULL, at the root.
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE edges AS
     SELECT tsn AS taxonID, nullif(parent_tsn, '0') AS parentNameUsageID
     FROM itis_nodes WHERE taxonomicStatus = 'accepted'")
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE nodes AS
     SELECT tsn AS taxonID, taxonRank, scientificName
     FROM itis_nodes WHERE taxonomicStatus = 'accepted'")
  build_classification(db)

  ## One vernacular name per taxon, English preferred, chosen by name so
  ## the pick is stable across rebuilds.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE itis_vern AS
     SELECT CAST(tsn AS VARCHAR) AS tsn,
            first(vernacular_name ORDER BY language <> 'English',
                                           lower(vernacular_name))
              AS vernacularName
     FROM ", scan("vernaculars"), " GROUP BY tsn"))

  ## acceptedNameUsageID: a synonym points at its accepted name, an
  ## accepted name at itself.  taxadb requires it on every row.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE itis_dwc AS
     SELECT
       ", prefix_id("n.tsn", "ITIS"), " AS taxonID,
       n.scientificName,
       n.taxonRank,
       ", prefix_id("coalesce(s.tsn_accepted_chr, n.tsn)", "ITIS"), "
         AS acceptedNameUsageID,
       n.taxonomicStatus,
       n.update_date,
       c.kingdom, c.phylum, c.class, c.order, c.family, c.genus,
       n.specificEpithet,
       n.infraspecificEpithet,
       v.vernacularName,
       n.scientificNameAuthorship
     FROM itis_nodes n
     LEFT JOIN (SELECT CAST(tsn AS VARCHAR) AS tsn,
                       CAST(tsn_accepted AS VARCHAR) AS tsn_accepted_chr
                FROM ", scan("synonym_links"), ") s ON n.tsn = s.tsn
     LEFT JOIN classification c
       ON coalesce(s.tsn_accepted_chr, n.tsn) = c.taxonID
     LEFT JOIN itis_vern v ON n.tsn = v.tsn"))

  ## A synonym whose accepted TSN is absent from taxonomic_units would be a
  ## dangling reference; ITIS has none, but drop any rather than publish them.
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE itis_dwc_clean AS
     SELECT d.* FROM itis_dwc d
     WHERE d.acceptedNameUsageID IN
       (SELECT taxonID FROM itis_dwc WHERE taxonomicStatus = 'accepted')
       AND d.scientificName IS NOT NULL
       AND d.taxonRank IS NOT NULL")

  ## The ITIS archive names its own directory itisSqlite<MMDDYY>.
  stamp <- regmatches(basename(dirname(sqlite)),
                      regexpr("[0-9]{6}$", basename(dirname(sqlite))))
  record_source(db, "itis", upstream_version = if(length(stamp) == 1)
    format(as.Date(stamp, "%m%d%y"), "%Y-%m-%d") else NA_character_)

  dwc <- paste("SELECT",
               dwc_select(c("scientificNameAuthorship", "update_date")),
               "FROM itis_dwc_clean")

  ## The common table keeps every vernacular name, one row each, with the
  ## language it is given in -- where `dwc` carries only the single
  ## preferred name per taxon.
  common <- paste0(
    "SELECT d.taxonID, v.vernacular_name AS vernacularName,
            lower(v.language) AS language,
            d.acceptedNameUsageID, d.scientificName, d.taxonRank,
            d.taxonomicStatus,
            d.kingdom, d.phylum, d.class, d.order, d.family, d.genus,
            d.specificEpithet, d.infraspecificEpithet
     FROM itis_dwc_clean d
     JOIN (SELECT ", prefix_id("CAST(tsn AS VARCHAR)", "ITIS"), " AS taxonID,
                  vernacular_name, language
           FROM ", scan("vernaculars"), ") v ON d.taxonID = v.taxonID")

  out <- c(write_snapshot(db, dwc, "itis", "dwc", version,
                          file.path(dir, "out")),
           write_snapshot(db, common, "itis", "common", version,
                          file.path(dir, "out")))
  invisible(out)
}
