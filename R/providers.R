## Who the providers are, where their data comes from, and under what terms.
##
## This is the single place that knows a provider's identity, so the
## published metadata, the README on the data repository and the package
## documentation cannot drift apart.

PROVIDER_META <- list(
  itis = list(
    title = "Integrated Taxonomic Information System",
    url = "https://www.itis.gov",
    source = "https://www.itis.gov/downloads/itisSqlite.zip",
    license = "public domain",
    license_url = "https://www.itis.gov/what_itis.html",
    synthesis = FALSE,
    citation = paste("Retrieved from the Integrated Taxonomic Information",
                     "System on-line database, https://www.itis.gov")),
  ncbi = list(
    title = "NCBI Taxonomy",
    url = "https://www.ncbi.nlm.nih.gov/taxonomy",
    source = "https://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz",
    license = "public domain",
    license_url = "https://www.ncbi.nlm.nih.gov/home/about/policies/",
    synthesis = FALSE,
    citation = paste("Schoch CL, et al. NCBI Taxonomy: a comprehensive",
                     "update on curation, resources and tools.",
                     "Database (2020). doi:10.1093/database/baaa062")),
  col = list(
    title = "Catalogue of Life",
    url = "https://www.catalogueoflife.org",
    source = "https://download.checklistbank.org/col/latest_dwca.zip",
    license = "CC BY 4.0",
    license_url = "https://creativecommons.org/licenses/by/4.0/",
    synthesis = TRUE,
    citation = paste("B\u00e1nki O, et al. Catalogue of Life.",
                     "https://doi.org/10.48580/dfz8")),
  gbif = list(
    title = "GBIF Backbone Taxonomy",
    url = "https://www.gbif.org",
    source = paste0("https://hosted-datasets.gbif.org/datasets/backbone/",
                    "current/backbone.zip"),
    license = "CC BY 4.0",
    license_url = "https://creativecommons.org/licenses/by/4.0/",
    synthesis = TRUE,
    citation = paste("GBIF Secretariat. GBIF Backbone Taxonomy.",
                     "https://doi.org/10.15468/39omei")),
  ott = list(
    title = "Open Tree Taxonomy",
    url = "https://tree.opentreeoflife.org",
    source = "https://files.opentreeoflife.org/ott/",
    license = "CC0 1.0",
    license_url = "https://creativecommons.org/publicdomain/zero/1.0/",
    synthesis = TRUE,
    citation = paste("Rees JA, Cranston K. Automated assembly of a reference",
                     "taxonomy for phylogenetic data synthesis.",
                     "Biodiversity Data Journal (2017).",
                     "doi:10.3897/BDJ.5.e12581")),
  fb = list(
    title = "FishBase",
    url = "https://fishbase.org",
    source = "s3://cboettig/fishbase/fb/",
    license = "CC BY-NC 4.0",
    license_url = "https://creativecommons.org/licenses/by-nc/4.0/",
    synthesis = FALSE,
    citation = paste("Froese R, Pauly D (eds). FishBase.",
                     "https://www.fishbase.org")),
  slb = list(
    title = "SeaLifeBase",
    url = "https://www.sealifebase.org",
    source = "s3://cboettig/fishbase/slb/",
    license = "CC BY-NC 4.0",
    license_url = "https://creativecommons.org/licenses/by-nc/4.0/",
    synthesis = FALSE,
    citation = paste("Palomares MLD, Pauly D (eds). SeaLifeBase.",
                     "https://www.sealifebase.org"))
)

#' Describe the taxonomic name providers
#'
#' @param provider one or more provider abbreviations; all by default
#' @return a data.frame with one row per provider giving its `title`, `url`,
#'  the `source` its data is taken from, its `license` and a `citation`.
#' @details Providers are not interchangeable.  `col`, `gbif` and `ott` are
#' synthesis projects that integrate other checklists, while `itis`, `ncbi`,
#' `fb` and `slb` are primary authorities; the `synthesis` column records
#' which is which.  More importantly, providers disagree: the same name can
#' be accepted by one and a synonym of something else in another, so a name
#' resolved against one provider should not be mixed with names resolved
#' against another.  See `vignette("data-sources")`.
#'
#' Redistribution terms differ too.  `fb` and `slb` are CC BY-NC, so those
#' two tables may not be used commercially.
#' @export
#' @examples
#' taxadb_provider_info()
#' taxadb_provider_info("col")$citation
taxadb_provider_info <- function(provider = taxadb_providers()){

  unknown <- setdiff(provider, names(PROVIDER_META))
  if(length(unknown))
    stop("unknown provider(s): ", paste(unknown, collapse = ", "),
         call. = FALSE)

  rows <- lapply(provider, function(p){
    m <- PROVIDER_META[[p]]
    data.frame(provider = p, title = m$title, url = m$url,
               source = m$source, license = m$license,
               license_url = m$license_url, synthesis = m$synthesis,
               citation = m$citation, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

## Record which upstream release a build actually consumed.
##
## The provider abbreviation and the taxadb version alone do not say what
## went in: "gbif 2026" is built from a backbone GBIF released in August
## 2023, and "col 2026" from whatever `latest_dwca.zip` was on the build
## date.  Builders call this so the published manifest can say.
record_source <- function(db, provider, upstream_version = NA_character_,
                          source = NULL){
  if(is.null(source)) source <- PROVIDER_META[[provider]]$source
  DBI::dbExecute(db,
    "CREATE TABLE IF NOT EXISTS taxadb_provenance (
       provider VARCHAR, upstream_version VARCHAR, source VARCHAR)")
  DBI::dbExecute(db, "DELETE FROM taxadb_provenance WHERE provider = ?",
                 list(provider))
  DBI::dbExecute(db,
    "INSERT INTO taxadb_provenance VALUES (?, ?, ?)",
    list(provider, as.character(upstream_version), source))
  invisible(TRUE)
}

provenance_for <- function(db, provider){
  if(!"taxadb_provenance" %in% DBI::dbListTables(db))
    return(data.frame(provider = provider, upstream_version = NA_character_,
                      source = PROVIDER_META[[provider]]$source,
                      stringsAsFactors = FALSE))
  out <- DBI::dbGetQuery(db,
    "SELECT * FROM taxadb_provenance WHERE provider = ?", list(provider))
  if(nrow(out) == 0)
    return(data.frame(provider = provider, upstream_version = NA_character_,
                      source = PROVIDER_META[[provider]]$source,
                      stringsAsFactors = FALSE))
  out
}
