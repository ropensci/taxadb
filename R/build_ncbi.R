#' Rebuild the NCBI Taxonomy snapshot
#'
#' @inheritParams build_itis
#' @param archive path to the NCBI `taxdump.tar.gz`; downloaded if missing
#' @return the paths written, invisibly
#' @details NCBI distributes `nodes.dmp` (the hierarchy) and `names.dmp`
#' (every name), in a format that claims to be tab-separated but delimits
#' fields with `\\t|\\t`.
#'
#' Every row of `names.dmp` carries the *accepted* taxon's `tax_id`, whatever
#' the name's class: NCBI mints no separate identifier for a synonym.  So the
#' `scientific name` rows become the accepted names, carrying a `taxonID` and
#' pointing `acceptedNameUsageID` at themselves, and every other name class
#' becomes a row for the same taxon with a `NULL` `taxonID` -- which the
#' taxadb rules permit, since there is no identifier to give.
#' @family build
#' @export
#' @examples \dontrun{
#' build_ncbi("2026")
#' }
build_ncbi <- function(version = format(Sys.Date(), "%Y"),
                       archive = NULL,
                       dir = build_dir(),
                       db = td_connect()){

  if(is.null(archive))
    archive <- fetch_archive(
      "https://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz",
      "taxdump.tar.gz", dir)
  extracted <- extract_archive(archive, dir, "ncbi")

  message("building ncbi ", version)

  ## The .dmp files use '\t|\t' between fields and '\t|' at end of line.
  ## Read on '|' and trim the tabs; supply column names explicitly, since
  ## duckdb's generated names depend on the column count.
  dmp <- function(file, names){
    paste0("read_csv('", archive_file(extracted, paste0("^", file, "$")),
           "', delim='|', header=false, quote='', all_varchar=true, ",
           "names=[", paste0("'", names, "'", collapse = ", "), "])")
  }

  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE ncbi_nodes AS
     SELECT trim(tax_id, chr(9))        AS tax_id,
            trim(parent_tax_id, chr(9)) AS parent_tax_id,
            trim(rank, chr(9))          AS taxonRank
     FROM ", dmp("nodes.dmp", c("tax_id", "parent_tax_id", "rank",
       "embl_code", "division_id", "inherited_div", "gencode_id",
       "inherited_gc", "mito_gencode_id", "inherited_mgc",
       "genbank_hidden", "hidden_subtree", "comments", "trailing"))))

  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE ncbi_names AS
     SELECT trim(tax_id, chr(9))     AS tax_id,
            trim(name_txt, chr(9))   AS name_txt,
            trim(name_class, chr(9)) AS name_class
     FROM ", dmp("names.dmp",
                 c("tax_id", "name_txt", "unique_name", "name_class",
                   "trailing"))))

  ## The accepted name of each taxon.  A tax_id has exactly one
  ## 'scientific name' in names.dmp.
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE ncbi_accepted AS
     SELECT tax_id, name_txt AS scientificName
     FROM ncbi_names WHERE name_class = 'scientific name'")

  ## The root (tax_id 1) is its own parent; leave it without one.
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE edges AS
     SELECT tax_id AS taxonID,
            CASE WHEN parent_tax_id = tax_id THEN NULL ELSE parent_tax_id END
              AS parentNameUsageID
     FROM ncbi_nodes")
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE nodes AS
     SELECT n.tax_id AS taxonID, n.taxonRank, a.scientificName
     FROM ncbi_nodes n JOIN ncbi_accepted a USING (tax_id)")
  build_classification(db)

  ## NCBI gives no language for its vernacular names.  Prefer the GenBank
  ## common name, which is the curated one, then any common name.
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE ncbi_vern AS
     SELECT tax_id,
            first(name_txt ORDER BY name_class <> 'genbank common name',
                                    lower(name_txt)) AS vernacularName
     FROM ncbi_names
     WHERE name_class IN ('genbank common name', 'common name')
     GROUP BY tax_id")

  ## Every name class other than 'scientific name' is a name for the same
  ## taxon that NCBI does not treat as the accepted one.  Keeping the class
  ## verbatim in taxonomicStatus preserves distinctions worth having:
  ## 'authority' and 'type material' are not synonyms in the usual sense.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE ncbi_dwc AS
     SELECT
       CASE WHEN nm.name_class = 'scientific name'
            THEN ", prefix_id("nm.tax_id", "NCBI"), " END AS taxonID,
       nm.name_txt AS scientificName,
       nd.taxonRank,
       ", prefix_id("nm.tax_id", "NCBI"), " AS acceptedNameUsageID,
       CASE WHEN nm.name_class = 'scientific name' THEN 'accepted'
            ELSE nm.name_class END AS taxonomicStatus,
       c.kingdom, c.phylum, c.class, c.order, c.family, c.genus,
       ", epithet_sql("nm.name_txt", "c.genus", 1), " AS specificEpithet,
       ", epithet_sql("nm.name_txt", "c.genus", 2), " AS infraspecificEpithet,
       v.vernacularName
     FROM ncbi_names nm
     JOIN ncbi_nodes nd USING (tax_id)
     LEFT JOIN classification c ON nm.tax_id = c.taxonID
     LEFT JOIN ncbi_vern v ON nm.tax_id = v.tax_id"))

  ## taxdump is regenerated daily and carries no version string, so the
  ## date of the dump we read is the only version there is.
  record_source(db, "ncbi", upstream_version = format(
    as.Date(file.mtime(archive_file(extracted, "^nodes\\.dmp$"))), "%Y-%m-%d"))

  dwc <- paste("SELECT", dwc_select(), "FROM ncbi_dwc",
               "WHERE scientificName IS NOT NULL AND taxonRank IS NOT NULL")

  common <- paste0(
    "SELECT d.taxonID, nm.name_txt AS vernacularName,
            d.acceptedNameUsageID, d.scientificName, d.taxonRank,
            d.taxonomicStatus,
            d.kingdom, d.phylum, d.class, d.order, d.family, d.genus,
            d.specificEpithet, d.infraspecificEpithet
     FROM ncbi_dwc d
     JOIN ncbi_names nm
       ON d.acceptedNameUsageID = ", prefix_id("nm.tax_id", "NCBI"), "
     WHERE d.taxonomicStatus = 'accepted'
       AND nm.name_class IN ('genbank common name', 'common name',
                             'blast name')")

  out <- c(write_snapshot(db, dwc, "ncbi", "dwc", version,
                          file.path(dir, "out")),
           write_snapshot(db, common, "ncbi", "common", version,
                          file.path(dir, "out")))
  invisible(out)
}
