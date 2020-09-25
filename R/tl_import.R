
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
#' `tl_import` parses a DCAT2/PROV-O record to determine the correct version
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

  series <- unlist(lapply(schema, paste, provider, sep="_"))
  keys <- paste(version, series, sep="_")

  ## For unit tests / examples only
  if(provider == "itis_test"){
    testfile <- c(
        system.file("extdata", "dwc_itis_test.tsv.bz2",
                    package = "taxadb"),
        system.file("extdata", "common_itis_test.tsv.bz2",
                    package = "taxadb"))
    names(testfile) <- paste0(version, c("_common_itis_test", "_dwc_itis_test"))

    return(testfile[keys])
  }

  prov <- parse_prov(prov)
  dict <- prov$id
  names(dict) <- prov$key

  if(any(is.na(dict[keys]))){
    message(paste("could not find",
                  paste(keys[is.na(dict[keys])], collapse= ", "),
                  "\n  checking for older versions."))

    tmp <- prov[prov$series %in% series, ]
    keys <- tmp$key
    message(paste("  using", paste(keys, collapse= ", ")))
    dict <- tmp$id
    names(dict) <- tmp$key

  }

  ids <- as.character(na_omit(dict[keys]))
  tablenames <- names(na_omit(dict[keys]))

  ## This will resolve the content-based identifier for the data to an appropriate source,
  ## validate that the data matches the checksum given in the identifier,
  ## and cache a local copy.  If the a local copy already matches the checksum,
  ## this will avoid downloading at all
  paths <- vapply(ids, contentid::resolve, "", store=TRUE)
  names(paths) <- tablenames
  paths
}



na_omit <- function(x) x[!is.na(x)]


## data-raw me?
## export me?

## Allow soft dependency
## @importFrom jsonlite read_json toJSON fromJSON

parse_prov <- function(url =
                         paste0("https://raw.githubusercontent.com/",
                                "boettiger-lab/taxadb-cache/master/prov.json")){

  ## Meh, already imported by httr
  read_json <- getExportedValue("jsonlite", "read_json")
  toJSON <- getExportedValue("jsonlite", "toJSON")
  fromJSON <- getExportedValue("jsonlite", "fromJSON")

  cache <- system.file("extdata", "prov.json", package = "taxadb")

  prov <- tryCatch(read_json(url),
                   error = function(e) read_json(cache),
                   finally = read_json(cache)
  )
  graph <- toJSON(prov$`@graph`, auto_unbox = TRUE)
  df <- fromJSON(graph, simplifyVector = TRUE)

  outputs <- df[df$description == "output data",
                c("id", "title", "wasGeneratedAtTime", "compressFormat")]

  tmp <- vapply(outputs$wasGeneratedAtTime, `[[`, "", 1)
  outputs$wasGeneratedAtTime <- as.Date(tmp)
  outputs$version <- format(outputs$wasGeneratedAtTime, "%Y")
  outputs$series <- gsub("\\.tsv\\.gz", "", outputs$title)
  outputs$series <- gsub("\\.tsv\\.bz2", "", outputs$series)
  outputs$key <- paste(outputs$version, outputs$series, sep="_")
  outputs
}


latest_version <-
  function(url = paste0("https://raw.githubusercontent.com/",
                        "boettiger-lab/taxadb-cache/master/prov.json")){
  prov <- parse_prov(url)
  max(prov$version)

}


