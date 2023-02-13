


prov_cache <- function() {
  url <- paste0("https://raw.githubusercontent.com/",
         "boettiger-lab/taxadb-cache/master/schema.json")

  ## Meh, already imported by httr
  read_json <- getExportedValue("jsonlite", "read_json")
  toJSON <- getExportedValue("jsonlite", "toJSON")
  fromJSON <- getExportedValue("jsonlite", "fromJSON")

  cache <- system.file("extdata", "schema.json", package = "taxadb")

  prov <- tryCatch(read_json(url),
                   error = function(e) read_json(cache),
                   finally = read_json(cache)
  )
  prov
}

parse_schema <- function(provider = "col", version = "latest", schema = "dwc",
                         prov = prov_cache()
                         ){


  elements <- prov[["@graph"]]
  datasets <- purrr::map_chr(elements, "type", .default=NA) == "Dataset"
  elements <- elements[datasets]

  versions <- purrr::map_chr(elements, "version", .default=NA)
  if(version == "latest") version <- max(versions)
  elements <- elements[versions == version]


  # filters
  name <- purrr::map_chr(elements, "name", .default=NA)
  elements <- elements[grepl(pattern = provider, name)]

  name <- purrr::map_chr(elements, "name", .default=NA)
  elements <- elements[grepl(pattern = schema, name)]

  name <- purrr::map_chr(elements, "name", .default=NA)
  if(length(elements) > 1) stop(paste("multiple matches found:", name))

  files <- purrr::map(elements, "distribution") |>
    purrr::map(purrr::map_chr, "contentUrl") |> getElement(1)
  ids <- purrr::map(elements, "distribution") |>
    purrr::map(purrr::map_chr, "id") |> getElement(1)

  id <- ids[grepl(".parquet", files)]
  url <- files[grepl(".parquet", files)]
  data.frame(id=id, url=url, version= version)
}


# ['file1.parquet', 'file2.parquet', 'file3.parquet']
duckdb_view <- function(urls,
                        tablename,
                        conn = DBI::dbConnect(duckdb::duckdb())
                        ){

  #DBI::dbExecute(conn, "INSTALL 'httpfs';") # import from HTTP
  #DBI::dbExecute(conn, "LOAD 'httpfs';")

  current_tbls <- DBI::dbListTables(conn)
  if(all(tablename %in% current_tbls)) return(invisible(conn))
  str_quo <- function(x) paste0("'", x, "'")
  files <- paste0("[", paste0(str_quo(urls), collapse=", "), "]")
  view_query <- paste("CREATE VIEW", str_quo(tablename),
                      "AS SELECT * FROM parquet_scan(",
                      files,
                      ");")

  DBI::dbSendQuery(conn, view_query)
  invisible(conn)
}

# downloads URLs to local content store unless they already are present.
cache_urls <- function(urls, ids = names(urls)) {

  if(is.null(ids)) {
    ids <- contentid::store(urls)
  }
  tsv <- contentid_registry(ids, urls)
  paths <- vapply(ids,
                  contentid::resolve, store = TRUE,
                  registries = c(tsv, contentid::content_dir()),
                  character(1L))
  paths
}


# takes id : source pairs and returns a contentid registry we can resolve against
contentid_registry <- function(ids, sources) {
  tmp <- tempfile(fileext = ".tsv")

  if(is.null(ids)) ids <- NA
  df <- data.frame(identifier = ids, source = sources, date = NA, size=NA,
                   status =200, md5 = NA, sha1=NA, sha256=NA, sha384 = NA,
                   sha512 = NA)
  write.table(df,   tmp, row.names = FALSE, sep="\t", quote=FALSE)
  return(tmp)
}

