
providers_download_url <- function(files, version = latest_version()){
  paste0("https://github.com/boettiger-lab/taxadb-cache/",
         "releases/download/", version, "/", files)
}


taxadb_cache <- new.env()

#' List available releases
#'
#' taxadb uses pre-computed cache files that are released on an annual
#' version schedule.
#'
#' @export
#' @examples
#' available_versions()
available_versions <- function(){

  ## check for cached version first
  avail_releases <- mget("avail_releases",
                         envir = taxadb_cache,
                         ifnotfound = NA)[[1]]
  if(!all(is.na(avail_releases)))
    return(avail_releases)

  ## FIXME consider using direct access of a metadata record file instead
  ## of relying on GitHub release tags to provide information about
  ## available versions

  ## Okay, check GH for a release
  req <- curl::curl_fetch_memory(paste0(
    "https://api.github.com/repos/",
    "boettiger-lab/taxadb-cache/releases"))
  json <- jsonlite::fromJSON(rawToChar(req$content))
  avail_releases <- json[["tag_name"]]

  ## Cache this so we don't hit GH every single time!
  assign("avail_releases", avail_releases, envir = taxadb_cache)

  avail_releases
}

latest_version <- function() {
  available_versions()[[1]]
}
