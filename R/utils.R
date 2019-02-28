
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
  sort <- "sort"

  ## A name can create a duplicate entry when:
  ## - it is a synonym that resolves to two different accepted names (IUCN, "Melanitta fusca")
  ## - it is both a synonym and and accepted name (IUCN, "Megaceryle torquata")

  ## and here we go:
  dups <- df %>%
    select(-sort) %>%
    distinct() %>%
    dplyr::count(scientificName) %>%
    dplyr::filter(n > 1) %>%
    dplyr::select(scientificName) %>%
    stats::na.omit()
  no_dups <- df %>%
    dplyr::anti_join(dups, by="scientificName")

  dplyr::select(df, scientificName) %>%
    distinct() %>%
    dplyr::left_join(no_dups, by="scientificName") %>%
    arrange(sort)
}
