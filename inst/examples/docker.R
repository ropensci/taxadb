
create_monetdb <- function(datadir = rappdirs::user_data_dir("taxadb")) {
  if (!requireNamespace("stevedore", quietly = TRUE)) {
    stop("Package stevedore must be installed to use this function")
  }
  if (!requireNamespace("MonetDB.R", quietly = TRUE)) {
    stop("Package stevedore must be installed to use this function")
  }

  dir.create(datadir, FALSE)
  stopifnot(stevedore::docker_available())
  docker <- stevedore::docker_client()
  docker$container$run("monetdb/monetdb",
    detach = TRUE,
    volumes = paste0(normalizePath(datadir), ":/var/monetdb5/dbfarm/taxadb"),
#    env = c("DBA_PASSWORD" = "dba"),
    ports = "50000:50000"
#    ports = "127.0.0.1:50000:50000"
  )
}


#conn <- dbConnect(MonetDB.R(), host="localhost", dbname="taxadb", user="monetdb", password="monetdb")
