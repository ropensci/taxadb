#' Rebuild the Open Tree Taxonomy snapshot
#'
#' @inheritParams build_itis
#' @param archive path to the OTT release archive; downloaded if missing
#' @param ott_version the OTT release to build from, e.g. `"3.7.3"`
#' @return the paths written, invisibly
#' @details OTT ships `taxonomy.tsv` and `synonyms.tsv`, both delimited with
#' `\\t|\\t`.  `synonyms.tsv` keys each synonym to the `uid` of the name it is
#' a synonym *of*: OTT mints no identifier for the synonym itself, so those
#' rows carry a `NULL` `taxonID`, which the taxadb rules allow.
#'
#' OTT no longer populates the `type` column of `synonyms.tsv` -- it is empty
#' for all 2.2 million rows in release 3.7.3 -- so a synonym is recorded as
#' `synonym` unless a type is given.
#'
#' OTT publishes no vernacular names, so there is no `common` table for this
#' provider; [filter_common()] warns accordingly.
#' @family build
#' @export
#' @examples \dontrun{
#' build_ott("2026")
#' }
build_ott <- function(version = format(Sys.Date(), "%Y"),
                      archive = NULL,
                      ott_version = "3.7.3",
                      dir = build_dir(),
                      db = td_connect()){

  if(is.null(archive))
    archive <- fetch_archive(
      paste0("https://files.opentreeoflife.org/ott/ott", ott_version,
             "/ott", ott_version, ".tgz"),
      paste0("ott", ott_version, ".tgz"), dir)
  extracted <- extract_archive(archive, dir, "ott")

  message("building ott ", version)

  ## Fields are separated by '\t|\t' and the line ends '\t|'.  No field in
  ## either file contains a bare '|', so splitting on '|' and trimming the
  ## tabs recovers the fields exactly.
  ott_read <- function(file, names)
    paste0("read_csv('", archive_file(extracted, paste0("^", file, "$")),
           "', delim='|', header=true, quote='', all_varchar=true, ",
           "names=[", paste0("'", names, "'", collapse = ", "), "])")

  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE ott_taxonomy AS
     SELECT trim(uid, chr(9))        AS uid,
            nullif(trim(parent_uid, chr(9)), '') AS parent_uid,
            trim(name, chr(9))       AS scientificName,
            nullif(trim(rank, chr(9)), '')       AS taxonRank,
            nullif(trim(sourceinfo, chr(9)), '') AS sourceinfo,
            nullif(trim(flags, chr(9)), '')      AS flags
     FROM ", ott_read("taxonomy.tsv",
       c("uid", "parent_uid", "name", "rank", "sourceinfo", "uniqname",
         "flags", "trailing"))))

  ## `type` is empty throughout release 3.7.3; keep the coalesce so that a
  ## release which starts populating it again is picked up.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE ott_synonyms AS
     SELECT trim(uid, chr(9))  AS uid,
            trim(name, chr(9)) AS scientificName,
            coalesce(nullif(trim(type, chr(9)), ''), 'synonym')
              AS taxonomicStatus,
            nullif(trim(sourceinfo, chr(9)), '') AS sourceinfo
     FROM ", ott_read("synonyms.tsv",
       c("name", "uid", "type", "uniqname", "sourceinfo", "trailing"))))

  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE edges AS
     SELECT uid AS taxonID, parent_uid AS parentNameUsageID FROM ott_taxonomy")
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE nodes AS
     SELECT uid AS taxonID, taxonRank, scientificName FROM ott_taxonomy")
  build_classification(db)

  ## Accepted names, then synonyms of them.  A synonym takes the rank and
  ## classification of the name it points at, which is all OTT tells us
  ## about it.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE ott_dwc AS
     SELECT ", prefix_id("t.uid", "OTT"), " AS taxonID,
            t.scientificName,
            t.taxonRank,
            ", prefix_id("t.uid", "OTT"), " AS acceptedNameUsageID,
            'accepted' AS taxonomicStatus,
            c.kingdom, c.phylum, c.class, c.order, c.family, c.genus,
            ", epithet_sql("t.scientificName", "c.genus", 1),
              " AS specificEpithet,
            ", epithet_sql("t.scientificName", "c.genus", 2),
              " AS infraspecificEpithet,
            CAST(NULL AS VARCHAR) AS vernacularName,
            t.sourceinfo, t.flags
     FROM ott_taxonomy t
     LEFT JOIN classification c ON t.uid = c.taxonID
   UNION ALL
     SELECT CAST(NULL AS VARCHAR) AS taxonID,
            s.scientificName,
            t.taxonRank,
            ", prefix_id("s.uid", "OTT"), " AS acceptedNameUsageID,
            s.taxonomicStatus,
            c.kingdom, c.phylum, c.class, c.order, c.family, c.genus,
            ", epithet_sql("s.scientificName", "c.genus", 1),
              " AS specificEpithet,
            ", epithet_sql("s.scientificName", "c.genus", 2),
              " AS infraspecificEpithet,
            CAST(NULL AS VARCHAR) AS vernacularName,
            s.sourceinfo, CAST(NULL AS VARCHAR) AS flags
     FROM ott_synonyms s
     JOIN ott_taxonomy t ON s.uid = t.uid
     LEFT JOIN classification c ON s.uid = c.taxonID"))

  dwc <- paste("SELECT", dwc_select(c("sourceinfo", "flags")),
               "FROM ott_dwc",
               "WHERE scientificName IS NOT NULL AND taxonRank IS NOT NULL")

  out <- write_snapshot(db, dwc, "ott", "dwc", version, file.path(dir, "out"))
  invisible(out)
}
