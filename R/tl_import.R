
## make contentid & jsonlite optional and otherwise cache a copy of the current prov table?
## Would need to fall back on download.file() then


#' Import taxonomic database tables
#'
#' Downloads the requested taxonomic data tables and return a local path
#' to the data in `tsv.gz` format.  Downloads are cached and identified by
#' content hash so that `tl_import` will not attempt to download the
#' same file multiple times.
#' @inheritParams taxa_tbl
#' @param prov Address (URL) to provenance record
#'
#' @details
#' `tl_import` parses a schema.org record to determine the correct version
#'  to download. If offline, `tl_import` will attempt to resolve against
#'  it's own provenance cache. Users can also examine / parse the prov
#'  JSON-LD file directly to determine the provenance of the data products
#'  used.
#'
#'
#' @return path(s) to the downloaded files in the cache
#' @export
#' @importFrom contentid resolve
tl_import <- function(provider = getOption("tl_default_provider", "itis"),
                      schema = c("dwc", "common"),
                      version = latest_version(),
                      prov = paste0("https://raw.githubusercontent.com/",
                                    "boettiger-lab/taxadb-cache/master/prov.json")
                      ){

  meta <- parse_schema(provider, version, shema, prov)
  paths <- cache_urls(meta$url, meta$id)
  paths
}


available_versions <- function(){
    prov = prov_cache()
    elements <- prov[["@graph"]]
    datasets <- purrr::map_chr(elements, "type", .default=NA) == "Dataset"
    elements <- elements[datasets]
    versions <- purrr::map_chr(elements, "version", .default=NA)

}
#' @importFrom memoise memoise
latest_version <- function() {
  avail_versions <- memoise::memoise(available_versions)
  max(avail_versions())
}
