
#' td_home
#' 
#' Set taxald home directory where database will be stored
#' @param dbdir a location on your computer where the database should be installed.
#' By default, will look for a location given by `Sys.getenv("TAXALD_HOME")` if not specified.
#' @param create should the location be created if no directory exits? 
#' @return dbdir path that will be used.
#' @export
td_home <- function(dbdir = Sys.getenv("TAXALD_HOME"), create = TRUE){
  if(dbdir == ""){
    stop(paste0(
      'Please set a location for the taxald database by running:\n\n\t',
      'td_home("~/.taxald")', '\n\n',
      'or setting the env variable TAXALD_HOME to the appropriate ',
      'location'), call. = FALSE)
  }
  if(!dir.exists(dbdir) && create){
    dir.create(dbdir, showWarnings = FALSE, recursive = TRUE)
  }

  ## Persist setting throughout session
  Sys.setenv(TAXALD_HOME=dbdir)
  
  ## FIXME Should we also set this more persistently, e.g. to an Renviron file?
  
  dbdir
}