
suppress_msg <- function(expr, pattern = "reserved SQL"){
withCallingHandlers(expr,
                    message = function(e){
                      if(grepl(pattern, e$message))
                        invokeRestart("muffleMessage")
                    })
}

#' @importFrom dplyr count filter select right_join anti_join
#' @importFrom stats na.omit
duplicate_as_unresolved <- function(df){
  # avoid warnings due to NSE
  scientificName <- "scientificName"
  n <- "n"


  ## FIXME duplicate scientificName not necessarily a problem!
  ## Problem is only when we have a given sciname resolving to
  ## more than one acceptedNameUsageID...
  ## and here we go:
  dups <- df %>%
    dplyr::count(scientificName) %>%
    dplyr::filter(n > 1) %>%
    dplyr::select(scientificName) %>%
    stats::na.omit() # NAs are not duplicates

  no_dups <- df %>%
    dplyr::anti_join(dups, by="scientificName")

  dplyr::select(df, scientificName) %>%
    distinct() %>%
    dplyr::left_join(no_dups, by="scientificName")
}
