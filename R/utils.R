
suppress_msg <- function(expr, pattern = "reserved SQL"){
withCallingHandlers(expr,
                    message = function(e){
                      if(grepl(pattern, e$message))
                        invokeRestart("muffleMessage")
                    })
}

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
