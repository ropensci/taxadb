
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

  ## Requires a column called sort that has 1 id for each input.

  sort <- "sort"
  multi_match <- df %>%
    dplyr::count(sort, sort = TRUE) %>%
    dplyr::filter(n > 1) %>%
    dplyr::select("sort")

  input_id <- df %>% select("sort") %>% distinct()

  ##alternately, resolve multi-match with top_n?

  ## Drop multi-match
  anti_join(df, multi_match, by = "sort") %>%
  ## And replace as NA
    right_join(input_id, by = "sort") %>%
    arrange(sort)


}
