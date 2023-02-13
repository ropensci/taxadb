#' Show the taxadb directory
#'
#' @details NOTE: after upgrading `duckdb`, a user may need to delete any
#' existing databases created with the previous version. An efficient
#' way to do so is `unlink(taxadb::taxadb_dir(), TRUE)`.
#' @export
#' @examples
#' ## show the directory
#' taxadb_dir()
#' ## Purge the local db
#' unlink(taxadb::taxadb_dir(), TRUE)
#'
taxadb_dir <- function(){
  Sys.getenv("TAXADB_HOME",  tools::R_user_dir("taxadb"))
}
