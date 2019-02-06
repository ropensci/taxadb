
suppress_msg <- function(expr, pattern = "reserved SQL"){
withCallingHandlers(expr,
                    message = function(e){
                      if(grepl(pattern, e$message))
                        invokeRestart("muffleMessage")
                    })
}

#' @importFrom dplyr count filter select right_join anti_join
duplicate_as_unresolved <- function(df){
  scientificName <- "scientificName" # avoid warnings due to NSE
  n <- "n"
  dups <- df %>%
    dplyr::count(scientificName) %>%
    dplyr::filter(n > 1) %>%
    dplyr::select(scientificName)
  no_dups <- df %>% dplyr::anti_join(dups, by="scientificName")
  dplyr::select(df, scientificName) %>% distinct() %>%
    dplyr::left_join(no_dups, by="scientificName")
}
