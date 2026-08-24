#' Rebuild the FishBase or SeaLifeBase snapshot
#'
#' @inheritParams build_itis
#' @param provider `"fb"` for FishBase or `"slb"` for SeaLifeBase
#' @param fb_version which FishBase snapshot to build from, e.g. `"v26.07"`.
#'  Defaults to the most recent published.
#' @return the paths written, invisibly
#' @details FishBase and SeaLifeBase share a schema, and both are already
#' published as Parquet alongside the taxadb snapshots, so this build reads
#' them over the network and downloads nothing.
#'
#' FishBase numbers accepted species (`SpecCode`) and synonyms (`SynCode`)
#' in two independent sequences, so the same integer means different things
#' in each: `SpecCode` 1 is *Scyris indica* while `SynCode` 1 is *Alausa
#' coerulea*.  Prefixing both as `FB:1` would make one identifier name two
#' taxa, which it did in the previously published table -- 20,295 FishBase
#' identifiers and 61,125 SeaLifeBase ones were ambiguous.
#'
#' Only `SpecCode` is therefore used as the `taxonID`, and synonyms carry a
#' `NULL` one exactly as they do for NCBI and OTT.  Nothing is lost: the
#' `SynCode` is published in its own `synonymID` column.  A consequence is
#' that a synonym whose `SpecCode` is 0 -- not linked to any species record,
#' 1,043 names in FishBase and 7,512 in SeaLifeBase -- has nothing to
#' resolve to and is dropped.
#'
#' Classification comes from the `families` table.  FishBase covers only
#' fishes, so its phylum and kingdom are constant.  SeaLifeBase spans some
#' sixty phyla across several kingdoms and asserts no kingdom itself, so
#' `kingdom` is left empty there rather than inferred.
#'
#' FishBase data is CC-BY-NC; see <https://fishbase.org>.
#' @family build
#' @export
#' @examples \dontrun{
#' build_fishbase("2026", provider = "fb")
#' }
build_fishbase <- function(version = format(Sys.Date(), "%Y"),
                           provider = c("fb", "slb"),
                           fb_version = NULL,
                           dir = build_dir(),
                           db = td_connect()){

  provider <- match.arg(provider)
  if(is.null(fb_version)) fb_version <- latest_fishbase_version(provider, db)

  message("building ", provider, " ", version, " from FishBase ", fb_version)
  base <- paste0("s3://cboettig/fishbase/", provider, "/", fb_version,
                 "/parquet/")
  tbl <- function(name) paste0("read_parquet('", base, name, ".parquet')")

  prefix <- toupper(provider)

  ## The families table carries family, order and class, and for
  ## SeaLifeBase phylum too.  It contains a header artefact row
  ## (Class = 'Class') which we drop.
  has_phylum <- "Phylum" %in%
    DBI::dbGetQuery(db, paste0("DESCRIBE SELECT * FROM ", tbl("families"))
                    )$column_name
  ## FishBase covers only fishes, so its phylum is constant; SeaLifeBase
  ## spans some sixty phyla and gives its own.  Neither asserts a kingdom,
  ## but every fish is an animal, where SeaLifeBase spans several kingdoms
  ## and so is left empty rather than guessed at.
  phylum  <- if(has_phylum) "nullif(trim(Phylum), '')" else "'Chordata'"
  kingdom <- if(provider == "fb") "'Animalia'" else "CAST(NULL AS VARCHAR)"

  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE fb_class AS
     SELECT CAST(FamCode AS VARCHAR)   AS FamCode,
            nullif(trim(Family), '')   AS family,
            nullif(trim(\"Order\"), '') AS \"order\",
            nullif(trim(Class), '')    AS class,
            ", phylum, " AS phylum,
            ", kingdom, " AS kingdom
     FROM ", tbl("families"), "
     WHERE nullif(trim(Class), '') IS DISTINCT FROM 'Class'"))

  ## Accepted species come from the species table, which is authoritative.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE fb_accepted AS
     SELECT CAST(s.SpecCode AS VARCHAR) AS id,
            trim(concat_ws(' ', nullif(trim(s.Genus), ''),
                                nullif(trim(s.Species), ''))) AS scientificName,
            nullif(trim(s.Genus), '')   AS genus,
            nullif(trim(s.Species), '') AS specificEpithet,
            nullif(trim(s.Author), '')  AS scientificNameAuthorship,
            c.family, c.\"order\", c.class, c.phylum, c.kingdom
     FROM ", tbl("species"), " s
     LEFT JOIN fb_class c ON CAST(s.FamCode AS VARCHAR) = c.FamCode
     WHERE nullif(trim(s.Genus), '') IS NOT NULL"))

  ## Every other name lives in the synonyms table, each with its own SynCode.
  ## TaxonLevel is inconsistently capitalized and sometimes absent; FishBase
  ## synonyms are binomials, so an absent level is a species.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE fb_syn AS
     SELECT CAST(sy.SynCode AS VARCHAR) AS id,
            CASE WHEN sy.SpecCode = 0 THEN NULL
                 ELSE CAST(sy.SpecCode AS VARCHAR) END AS accepted_id,
            trim(concat_ws(' ', nullif(trim(sy.SynGenus), ''),
                                nullif(trim(sy.SynSpecies), '')))
              AS scientificName,
            coalesce(lower(nullif(trim(sy.TaxonLevel), '')), 'species')
              AS taxonRank,
            lower(nullif(trim(sy.Status), '')) AS status,
            nullif(trim(sy.Author), '') AS scientificNameAuthorship
     FROM ", tbl("synonyms"), " sy
     WHERE nullif(trim(sy.SynGenus), '') IS NOT NULL
       AND sy.SynCode IS NOT NULL"))

  ## A synonyms row saying 'accepted name' for a name the species table
  ## already gives is the same name-usage recorded twice; keep the species
  ## table's row.  One that names something different is a further name
  ## FishBase accepts for that species, and is kept as such.
  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE fb_dwc AS
     SELECT ", prefix_id("a.id", prefix), " AS taxonID,
            a.scientificName,
            'species' AS taxonRank,
            ", prefix_id("a.id", prefix), " AS acceptedNameUsageID,
            'accepted' AS taxonomicStatus,
            a.kingdom, a.phylum, a.class, a.\"order\", a.family, a.genus,
            a.specificEpithet,
            CAST(NULL AS VARCHAR) AS infraspecificEpithet,
            a.scientificNameAuthorship,
            CAST(NULL AS VARCHAR) AS synonymID
     FROM fb_accepted a
   UNION ALL
     SELECT CAST(NULL AS VARCHAR) AS taxonID,
            s.scientificName,
            s.taxonRank,
            ", prefix_id("s.accepted_id", prefix), " AS acceptedNameUsageID,
            s.status AS taxonomicStatus,
            c.kingdom, c.phylum, c.class, c.\"order\", c.family,
            split_part(s.scientificName, ' ', 1) AS genus,
            nullif(split_part(s.scientificName, ' ', 2), '') AS specificEpithet,
            nullif(split_part(s.scientificName, ' ', 3), '')
              AS infraspecificEpithet,
            s.scientificNameAuthorship,
            s.id AS synonymID
     FROM fb_syn s
     JOIN fb_accepted c ON s.accepted_id = c.id
     WHERE NOT (s.status = 'accepted name'
                AND s.scientificName = c.scientificName)"))

  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE fb_vern AS
     SELECT CAST(SpecCode AS VARCHAR) AS id,
            nullif(trim(ComName), '')  AS vernacularName,
            lower(nullif(trim(Language), '')) AS language,
            PreferredName
     FROM ", tbl("comnames"), "
     WHERE nullif(trim(ComName), '') IS NOT NULL"))
  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE fb_vern_one AS
     SELECT id, first(vernacularName ORDER BY coalesce(PreferredName,0) = 0,
                                              coalesce(language,'zz') <> 'english',
                                              lower(vernacularName))
              AS vernacularName
     FROM fb_vern GROUP BY id")

  DBI::dbExecute(db, paste0(
    "CREATE OR REPLACE TABLE fb_final AS
     SELECT d.*, v.vernacularName
     FROM fb_dwc d
     LEFT JOIN fb_vern_one v
       ON d.acceptedNameUsageID = ", prefix_id("v.id", prefix)))

  DBI::dbExecute(db,
    "CREATE OR REPLACE TABLE fb_clean AS
     SELECT d.* FROM fb_final d
     WHERE d.scientificName IS NOT NULL AND d.taxonRank IS NOT NULL
       AND d.taxonomicStatus IS NOT NULL
       AND d.acceptedNameUsageID IN
         (SELECT taxonID FROM fb_final WHERE taxonID = acceptedNameUsageID)")

  record_source(db, provider, upstream_version = fb_version,
                source = paste0("s3://cboettig/fishbase/", provider, "/",
                                fb_version, "/parquet/"))

  dwc <- paste("SELECT",
               dwc_select(c("scientificNameAuthorship", "synonymID")),
               "FROM fb_clean")
  common <- paste0(
    "SELECT d.taxonID, v.vernacularName, v.language,
            d.acceptedNameUsageID, d.scientificName, d.taxonRank,
            d.taxonomicStatus,
            d.kingdom, d.phylum, d.class, d.\"order\", d.family, d.genus,
            d.specificEpithet, d.infraspecificEpithet
     FROM fb_clean d
     JOIN fb_vern v ON d.taxonID = ", prefix_id("v.id", prefix))

  out <- c(write_snapshot(db, dwc, provider, "dwc", version,
                          file.path(dir, "out")),
           write_snapshot(db, common, provider, "common", version,
                          file.path(dir, "out")))
  invisible(out)
}

## Most recent FishBase / SeaLifeBase snapshot published on source.coop.
latest_fishbase_version <- function(provider = "fb", db = td_connect()){
  glob <- paste0("s3://cboettig/fishbase/", provider, "/*/parquet/species.parquet")
  files <- DBI::dbGetQuery(db,
    paste0("SELECT file FROM glob('", glob, "')"))$file
  if(length(files) == 0)
    stop("could not list FishBase snapshots for ", provider, call. = FALSE)
  max(basename(dirname(dirname(files))))
}
