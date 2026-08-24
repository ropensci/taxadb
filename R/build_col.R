#' Rebuild the Catalogue of Life snapshot
#'
#' @inheritParams build_itis
#' @param archive path to the COL Darwin Core Archive; downloaded if missing
#' @return the paths written, invisibly
#' @details COL publishes a Darwin Core Archive whose `scientificName` carries
#' the authorship -- `Acanthocerataceae Crawford & Round`.  taxadb wants the
#' canonical name, since authorship abbreviations vary too much between
#' providers to match on.  COL also supplies `scientificNameAuthorship`
#' separately, so the canonical name is the one with that suffix removed.
#'
#' COL marks accepted names by leaving `acceptedNameUsageID` empty, and
#' distinguishes `accepted` from `provisionally accepted`; both are accepted
#' in the sense that matters here, that they are nobody else's synonym, so
#' both get `acceptedNameUsageID` set to their own `taxonID`.
#' @family build
#' @export
#' @examples \dontrun{
#' build_col("2026")
#' }
build_col <- function(version = format(Sys.Date(), "%Y"),
                      archive = NULL,
                      dir = build_dir(),
                      db = td_connect()){

  if(is.null(archive))
    archive <- fetch_archive(
      "https://download.checklistbank.org/col/latest_dwca.zip",
      "col_dwca.zip", dir)
  extracted <- extract_archive(archive, dir, "col")

  message("building col ", version)

  ## COL's column names carry their namespace prefix (`dwc:taxonID`), and
  ## the name fields contain unescaped quotes, so the CSV reader must not
  ## treat any character as a quote.
  read_col <- function(file){
    paste0("read_csv('", archive_file(extracted, paste0("^", file, "$")),
           "', delim='\t', header=true, quote='', all_varchar=true, ",
           "normalize_names=false, ignore_errors=false)")
  }
  ## Strip the namespace prefix so the columns are plain Darwin Core terms.
  bare <- function(tbl, cols)
    paste0("\"", tbl, ":", cols, "\" AS \"", cols, "\"", collapse = ", ")

  taxon_cols <- c("taxonID", "parentNameUsageID", "acceptedNameUsageID",
                  "originalNameUsageID", "datasetID", "taxonomicStatus",
                  "taxonRank", "scientificName", "scientificNameAuthorship",
                  "genericName", "specificEpithet", "infraspecificEpithet",
                  "cultivarEpithet", "nameAccordingTo", "namePublishedIn",
                  "nomenclaturalCode", "nomenclaturalStatus", "taxonRemarks")

  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE col_raw AS
     SELECT ", bare("dwc", taxon_cols), ",
            \"dcterms:references\" AS \"references\"
     FROM ", read_col("Taxon.tsv")))

  ## An accepted name is one COL does not redirect: acceptedNameUsageID is
  ## empty.  That covers both `accepted` and `provisionally accepted`.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE col_names AS
     SELECT taxonID,
            nullif(parentNameUsageID, '') AS parentNameUsageID,
            nullif(acceptedNameUsageID, '') AS acceptedNameUsageID,
            nullif(originalNameUsageID, '') AS originalNameUsageID,
            nullif(taxonomicStatus, '') AS taxonomicStatus,
            nullif(taxonRank, '') AS taxonRank,
            ", canonical_name_sql("scientificName",
                                  "scientificNameAuthorship"),
            " AS scientificName,
            nullif(scientificNameAuthorship, '') AS scientificNameAuthorship,
            coalesce(nullif(genericName, ''), NULL) AS genericName,
            nullif(specificEpithet, '') AS specificEpithet,
            nullif(infraspecificEpithet, '') AS infraspecificEpithet,
            nullif(cultivarEpithet, '') AS cultivarEpithet,
            nullif(nameAccordingTo, '') AS nameAccordingTo,
            nullif(namePublishedIn, '') AS namePublishedIn,
            nullif(nomenclaturalCode, '') AS nomenclaturalCode,
            nullif(nomenclaturalStatus, '') AS nomenclaturalStatus,
            nullif(taxonRemarks, '') AS taxonRemarks,
            nullif(datasetID, '') AS datasetID,
            nullif(\"references\", '') AS \"references\",
            nullif(acceptedNameUsageID, '') IS NULL AS is_accepted
     FROM col_raw
     WHERE nullif(taxonID, '') IS NOT NULL"))

  ## The hierarchy runs through accepted names only; a synonym inherits the
  ## classification of the name it redirects to.  COL does supply kingdom
  ## through genus itself, but only patchily above genus, so we derive all
  ## seven ranks the same way as for every other provider.
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE edges AS
     SELECT taxonID, parentNameUsageID FROM col_names WHERE is_accepted")
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE nodes AS
     SELECT taxonID, taxonRank, scientificName
     FROM col_names WHERE is_accepted")
  build_classification(db)

  ## One vernacular name per taxon for the dwc table, English preferred.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE col_vern AS
     SELECT \"dwc:taxonID\" AS taxonID,
            nullif(\"dwc:vernacularName\", '') AS vernacularName,
            lower(nullif(\"dcterms:language\", '')) AS language
     FROM ", read_col("VernacularName.tsv")))
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE col_vern_one AS
     SELECT taxonID,
            first(vernacularName ORDER BY coalesce(language,'zz') <> 'eng',
                                          lower(vernacularName))
              AS vernacularName
     FROM col_vern WHERE vernacularName IS NOT NULL GROUP BY taxonID")

  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE col_dwc AS
     SELECT
       ", prefix_id("n.taxonID", "COL"), " AS taxonID,
       n.scientificName,
       n.taxonRank,
       ", prefix_id("coalesce(n.acceptedNameUsageID, n.taxonID)", "COL"), "
         AS acceptedNameUsageID,
       n.taxonomicStatus,
       c.kingdom, c.phylum, c.class, c.order, c.family,
       coalesce(c.genus, n.genericName) AS genus,
       n.specificEpithet,
       n.infraspecificEpithet,
       v.vernacularName,
       n.scientificNameAuthorship, n.cultivarEpithet,
       n.nomenclaturalCode, n.nomenclaturalStatus,
       n.namePublishedIn, n.nameAccordingTo, n.taxonRemarks,
       ", prefix_id("n.parentNameUsageID", "COL"), " AS parentNameUsageID,
       ", prefix_id("n.originalNameUsageID", "COL"), " AS originalNameUsageID,
       n.datasetID, n.\"references\"
     FROM col_names n
     LEFT JOIN classification c
       ON coalesce(n.acceptedNameUsageID, n.taxonID) = c.taxonID
     LEFT JOIN col_vern_one v ON n.taxonID = v.taxonID"))

  ## A synonym pointing at a taxonID that is not itself an accepted name is
  ## a dangling reference; publish neither it nor an unnamed row.
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE col_dwc_clean AS
     SELECT d.* FROM col_dwc d
     WHERE d.scientificName IS NOT NULL
       AND d.taxonRank IS NOT NULL
       AND d.taxonomicStatus IS NOT NULL
       AND d.acceptedNameUsageID IN
         (SELECT taxonID FROM col_dwc WHERE taxonID = acceptedNameUsageID)")

  ## COL's eml.xml carries the release date of the checklist.
  eml <- tryCatch(readLines(archive_file(extracted, "^eml\\.xml$"),
                            warn = FALSE), error = function(e) character(0))
  pub <- regmatches(eml, regexpr("(?<=<pubDate>)[^<]+", eml, perl = TRUE))
  record_source(db, "col", upstream_version = if(length(pub))
    trimws(pub[[1]]) else NA_character_)

  extra <- c("scientificNameAuthorship", "cultivarEpithet",
             "nomenclaturalCode", "nomenclaturalStatus", "namePublishedIn",
             "nameAccordingTo", "taxonRemarks", "parentNameUsageID",
             "originalNameUsageID", "datasetID", "references")
  dwc <- paste("SELECT", dwc_select(extra), "FROM col_dwc_clean")

  common <- paste0(
    "SELECT d.taxonID, v.vernacularName, v.language,
            d.acceptedNameUsageID, d.scientificName, d.taxonRank,
            d.taxonomicStatus,
            d.kingdom, d.phylum, d.class, d.order, d.family, d.genus,
            d.specificEpithet, d.infraspecificEpithet, d.cultivarEpithet
     FROM col_dwc_clean d
     JOIN (SELECT ", prefix_id("taxonID", "COL"), " AS taxonID,
                  vernacularName, language
           FROM col_vern WHERE vernacularName IS NOT NULL) v
       ON d.taxonID = v.taxonID")

  out <- c(write_snapshot(db, dwc, "col", "dwc", version,
                          file.path(dir, "out")),
           write_snapshot(db, common, "col", "common", version,
                          file.path(dir, "out")))
  invisible(out)
}
