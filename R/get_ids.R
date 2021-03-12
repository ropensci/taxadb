
## FIXME get_ids objects to having duplicated names.
##  ( duplicate_as_unresolved() drops the duplicates?
## duplicated names should be okay!

#' get_ids
#'
#' A drop-in replacement for `[taxize::get_ids()]`
#' @param names a list of scientific names (which may
#'   include higher-order ranks in most authorities).
#' @param db abbreviation code for the provider.  See details.
#' @param format Format for the returned identifier, one of
#'   - `prefix` (e.g. `NCBI:9606`, the default), or
#'   - `bare` (e.g. `9606`, used in `taxize::get_ids()`),
#'   - `uri` (e.g.
#'   `http://ncbi.nlm.nih.gov/taxonomy/9606`).
#' @param version Which version of the taxadb provider database should we use?
#'  defaults to latest.  see `[avialable_releases()]` for details.
#' @param taxadb_db Connection to from `[td_connect()]`.
#' @param ignore_case should we ignore case (capitalization) in matching names?
#' default is `TRUE`.
#' @param warn should we display warnings on NAs resulting from multiply-resolved matches?
#' (Unlike unmatched names, these NAs can usually be resolved manually via [filter_id()])
#' @param ... additional arguments (currently ignored)
#' @return a vector of IDs, of the same length as the input names Any
#' unmatched names or multiply-matched names will return as [NA]s.
#' To resolve multi-matched names, use `[filter_name()]` instead to return
#' a table with a separate row for each separate match of the input name.
#' @seealso filter_name
#' @family get
#' @details Note that some taxize authorities: `nbn`, `tropicos`, and `eol`,
#' are not recognized by taxadb and will throw an error here. Meanwhile,
#' taxadb recognizes several authorities not known to `[taxize::get_ids()]`.
#' Both include `itis`, `ncbi`, `col`, and `gbif`.
#'
#' Like all taxadb functions, this function will run
#' fastest if a local copy of the provider is installed in advance
#' using `[td_create()]`.
#' @examples \donttest{
#'
#'   \dontshow{
#'    ## All examples use a temporary directory
#'    options("taxadb_default_provider"="itis_test")
#'    Sys.setenv(TAXADB_HOME=tempdir())
#'   }
#'
#' get_ids("Midas bicolor")
#' get_ids(c("Midas bicolor", "Aves"), format = "prefix")
#' get_ids("Midas bicolor", format = "uri")
#'
#' }
#'
#'
#' @export
#' @importFrom dplyr pull
#' @importFrom tibble column_to_rownames
get_ids <- function(names,
                    db = getOption("taxadb_default_provider", "itis"),
                    format = c("prefix", "bare", "uri"),
                    version = latest_version(),
                    taxadb_db = td_connect(),
                    ignore_case = TRUE,
                    warn = TRUE,
                    ...){
  format <- match.arg(format)
  n <- length(names)
  provider <- db


  # be compatible with common space delimiters
  names <- gsub("[_|-|\\.]", " ", names)

  taxa <- filter_name(name = names,
                provider = provider,
                version = version,
                collect = TRUE,
                ignore_case = ignore_case,
                db = taxadb_db) %>%
    arrange(sort)

  out <- vapply(names, function(x){
    df <- taxa[x == taxa$scientificName, ]
    df <- df[!is.na(df$scientificName),]

    if(nrow(df) < 1) return(NA_character_)

    # Unambiguous: one acceptedNameUsageID per name
    if(nrow(df)==1) return(df$acceptedNameUsageID[1])

    ## Drop infraspecies when not perfect match
    df <- df[is.na(df$infraspecificEpithet),]

    ## If we resolve to a unique accepted ID, return that
    ids <- unique(df$acceptedNameUsageID)
    if(length(ids)==1){
      return(ids)
    } else {
      if(warn){
      warning(paste0("  Found ", bb(length(ids)), " possible identifiers for ",
                     ibr(x),
                     ".\n  Returning ", bb('NA'), ". Try ",
                     bb(paste0("filter_id('", x, "', '", provider,"')")),
                     " to resolve manually.\n"),
              call. = FALSE)
      }
      return(NA_character_)
    }
  },
  character(1L), USE.NAMES = FALSE)


  ## Format ID as requested
  switch(format,
         "uri" = prefix_to_uri(out),
         "prefix" = out,
         strip_prefix(out))
}

strip_prefix <- function(x) gsub("^\\w+:", "", x)

i_or_na <- function(x, i){
  if(length(x) < i) return(as.character(NA))
  x[[i]]
}

replace_na <- function(x, replace=""){
  ifelse(is.na(x), replace, x)
}
replace_empty <- function(x){
  ifelse(x=="", NA, x)
}

prefix_to_uri <- function(x){
  # Use look-behind to keep the ":" and split after it.
  bits <- strsplit(x, "(?<=:)", perl = TRUE)
  input <- tibble(
    id_prefix = vapply(bits, `[[`, character(1L), 1),
    id = vapply(bits, i_or_na, character(1L), 2))
  resolved <- dplyr::left_join(input, prefixes, "id_prefix")

  ## append prefixes, respecting NAs
  out <- paste0(replace_na(resolved$url_prefix), replace_na(resolved$id))
  replace_empty(out)
}


ibr <- function(...){
  if(!requireNamespace("crayon", quietly = TRUE)) return(paste(...))
  crayon::italic(crayon::bold(crayon::red(...)))
}
bb <- function(...){
  if(!requireNamespace("crayon", quietly = TRUE)) return(paste(...))
  crayon::bold(crayon::blue(...))
}
