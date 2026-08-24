#' Rebuild the GBIF backbone snapshot
#'
#' @inheritParams build_itis
#' @param archive path to the GBIF backbone archive; downloaded if missing
#' @return the paths written, invisibly
#' @details GBIF supplies `canonicalName` -- the name without authorship --
#' alongside the full `scientificName`, so no name parsing is needed.  It
#' leaves `canonicalName` empty for names its parser cannot analyse, which
#' includes the sequence-derived identifiers GBIF carries in quantity (BOLD
#' BINs, UNITE species hypotheses, metagenome-assembled genomes) and hybrid
#' formulas; for those the `scientificName` is the name, and is used.
#'
#' GBIF leaves `acceptedNameUsageID` empty on `accepted` and on `doubtful`
#' names alike, since it redirects neither.  Both therefore become their own
#' accepted name here, which is also what keeps GBIF's 40,895 synonyms of
#' doubtful names resolvable.
#' @family build
#' @export
#' @examples \dontrun{
#' build_gbif("2026")
#' }
build_gbif <- function(version = format(Sys.Date(), "%Y"),
                       archive = NULL,
                       dir = build_dir(),
                       db = td_connect()){

  if(is.null(archive))
    archive <- fetch_archive(paste0("https://hosted-datasets.gbif.org/",
                                    "datasets/backbone/current/backbone.zip"),
                             "gbif_backbone.zip", dir)
  extracted <- extract_archive(archive, dir, "gbif")

  message("building gbif ", version)

  read_gbif <- function(file)
    paste0("read_csv('", archive_file(extracted, paste0("^", file, "$")),
           "', delim='\t', header=true, quote='', all_varchar=true, ",
           "normalize_names=false)")

  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE gbif_names AS
     SELECT taxonID,
            nullif(parentNameUsageID, '')   AS parentNameUsageID,
            nullif(acceptedNameUsageID, '') AS acceptedNameUsageID,
            nullif(originalNameUsageID, '') AS originalNameUsageID,
            nullif(taxonomicStatus, '')     AS taxonomicStatus,
            nullif(taxonRank, '')           AS taxonRank,
            coalesce(nullif(canonicalName, ''),
                     ", canonical_name_sql("scientificName",
                                            "scientificNameAuthorship"), ")
              AS scientificName,
            nullif(scientificNameAuthorship, '') AS scientificNameAuthorship,
            nullif(specificEpithet, '')          AS specificEpithet,
            nullif(infraspecificEpithet, '')     AS infraspecificEpithet,
            nullif(genericName, '')              AS genericName,
            nullif(nameAccordingTo, '')          AS nameAccordingTo,
            nullif(namePublishedIn, '')          AS namePublishedIn,
            nullif(nomenclaturalStatus, '')      AS nomenclaturalStatus,
            nullif(taxonRemarks, '')             AS taxonRemarks
     FROM ", read_gbif("Taxon.tsv"), "
     WHERE nullif(taxonID, '') IS NOT NULL"))

  ## A name GBIF does not redirect is its own accepted name.
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE edges AS
     SELECT taxonID, parentNameUsageID FROM gbif_names
     WHERE acceptedNameUsageID IS NULL")
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE nodes AS
     SELECT taxonID, taxonRank, scientificName FROM gbif_names
     WHERE acceptedNameUsageID IS NULL")
  build_classification(db)

  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE gbif_vern AS
     SELECT taxonID,
            nullif(vernacularName, '') AS vernacularName,
            lower(nullif(language, '')) AS language
     FROM ", read_gbif("VernacularName.tsv")))
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE gbif_vern_one AS
     SELECT taxonID,
            first(vernacularName ORDER BY coalesce(language,'zz') <> 'en',
                                          lower(vernacularName))
              AS vernacularName
     FROM gbif_vern WHERE vernacularName IS NOT NULL GROUP BY taxonID")

  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE gbif_dwc AS
     SELECT
       ", prefix_id("n.taxonID", "GBIF"), " AS taxonID,
       n.scientificName,
       n.taxonRank,
       ", prefix_id("coalesce(n.acceptedNameUsageID, n.taxonID)", "GBIF"), "
         AS acceptedNameUsageID,
       n.taxonomicStatus,
       c.kingdom, c.phylum, c.class, c.order, c.family,
       coalesce(c.genus, n.genericName) AS genus,
       n.specificEpithet, n.infraspecificEpithet,
       v.vernacularName,
       n.scientificNameAuthorship, n.nomenclaturalStatus,
       n.namePublishedIn, n.nameAccordingTo, n.taxonRemarks,
       ", prefix_id("n.parentNameUsageID", "GBIF"), " AS parentNameUsageID,
       ", prefix_id("n.originalNameUsageID", "GBIF"), " AS originalNameUsageID
     FROM gbif_names n
     LEFT JOIN classification c
       ON coalesce(n.acceptedNameUsageID, n.taxonID) = c.taxonID
     LEFT JOIN gbif_vern_one v ON n.taxonID = v.taxonID"))

  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE gbif_dwc_clean AS
     SELECT d.* FROM gbif_dwc d
     WHERE d.scientificName IS NOT NULL
       AND d.taxonRank IS NOT NULL
       AND d.taxonomicStatus IS NOT NULL
       AND d.acceptedNameUsageID IN
         (SELECT taxonID FROM gbif_dwc WHERE taxonID = acceptedNameUsageID)")

  extra <- c("scientificNameAuthorship", "nomenclaturalStatus",
             "namePublishedIn", "nameAccordingTo", "taxonRemarks",
             "parentNameUsageID", "originalNameUsageID")
  dwc <- paste("SELECT", dwc_select(extra), "FROM gbif_dwc_clean")

  common <- paste0(
    "SELECT d.taxonID, v.vernacularName, v.language,
            d.acceptedNameUsageID, d.scientificName, d.taxonRank,
            d.taxonomicStatus,
            d.kingdom, d.phylum, d.class, d.order, d.family, d.genus,
            d.specificEpithet, d.infraspecificEpithet
     FROM gbif_dwc_clean d
     JOIN (SELECT ", prefix_id("taxonID", "GBIF"), " AS taxonID,
                  vernacularName, language
           FROM gbif_vern WHERE vernacularName IS NOT NULL) v
       ON d.taxonID = v.taxonID")

  out <- c(write_snapshot(db, dwc, "gbif", "dwc", version,
                          file.path(dir, "out")),
           write_snapshot(db, common, "gbif", "common", version,
                          file.path(dir, "out")))
  invisible(out)
}
