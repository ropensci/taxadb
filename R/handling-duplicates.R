
#' @importFrom dplyr count filter select right_join anti_join arrange
#' @importFrom stats na.omit
duplicate_as_unresolved <- function(df){

  ## Requires a column called sort that has 1 id for each input.
  # NSE
  sort <- "sort"
  n <- "n"

  multi_match <- df %>%
    dplyr::count(sort, sort = TRUE) %>%
    dplyr::filter(n > 1) %>%
    dplyr::select("sort")

  input_id <- df %>% dplyr::select("sort") %>% dplyr::distinct()

  ##alternately, resolve multi-match with top_n?

  ## Drop multi-match
  dplyr::anti_join(df, multi_match, by = "sort") %>%
    ## And replace as NA
    dplyr::right_join(input_id, by = "sort") %>%
    dplyr::arrange(sort)

}


#' @importFrom dplyr count filter select right_join anti_join arrange
#' @importFrom stats na.omit
duplicate_as_first <- function(df){

  # avoid complaints about NSE terms
  scientificName <- "scientificName"
  sort <- "sort"

  df %>%
    dplyr::group_by(sort) %>%
    dplyr::top_n(1, scientificName) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(sort)

}
