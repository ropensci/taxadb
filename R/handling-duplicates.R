
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
    safe_right_join(input_id, by = "sort") %>%
    dplyr::arrange(sort)

}


#' @importFrom dplyr count mutate select arrange
#' @importFrom dplyr pull top_n group_by ungroup
#' @importFrom stats na.omit
#' @importFrom utils head
take_first_duplicate <- function(df){


  # avoid complaints about NSE terms
  scientificName <- "scientificName"
  sort <- "sort"
  row_num = "row_num"
  n <- "n"

  ## Skip this if sort index is never duplicated
  max_repeated <- df %>%
    dplyr::count(sort, sort=T) %>%
    utils::head(1) %>%
    dplyr::pull(n)
  if(max_repeated == 1) return(df)

## adding row_number avoids top_n()
## collapsing repeated scentificNames
## when sort is already unique.
  df %>%
    dplyr::arrange(scientificName) %>%
    dplyr::mutate(row_num = dplyr::row_number()) %>%
    dplyr::group_by(sort) %>%
    dplyr::top_n(1, row_num) %>%
    dplyr::ungroup() %>%
    dplyr::arrange(sort)

}
