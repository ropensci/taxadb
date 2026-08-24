## The taxadb conformance rules.
##
## taxadb publishes a strict subset of Darwin Core: stricter than the
## standard requires, so that a name lookup is always a single join and
## never a special case.  The rules below define that subset, and
## `td_validate()` checks a table against them.
##
## The load-bearing rule is the treatment of `acceptedNameUsageID`.  Darwin
## Core leaves it optional on accepted names -- providers commonly omit it
## there, since an accepted name is its own accepted name.  taxadb instead
## requires it on *every* row, repeating the `taxonID` on accepted names.
## That way resolving any name, accepted or synonym, to its accepted
## identifier is one column read with no NULL handling.

DWC_REQUIRED <- c("taxonID", "scientificName", "taxonRank",
                  "acceptedNameUsageID", "taxonomicStatus")

DWC_HIERARCHY <- c("kingdom", "phylum", "class", "order", "family", "genus",
                   "specificEpithet", "infraspecificEpithet")

COMMON_REQUIRED <- c("taxonID", "vernacularName", "acceptedNameUsageID",
                     "scientificName", "taxonRank", "taxonomicStatus")

## `common` additionally records the language each vernacular name is in.
COMMON_OPTIONAL <- "language"

#' Check a taxadb table against the taxadb Darwin Core rules
#'
#' @inheritParams filter_by
#' @return a data.frame with one row per rule, giving whether the table
#'  `pass`es, how many rows `violations` were found, and a `note`.
#' @details The rules checked are:
#'
#' * **columns** -- the required Darwin Core terms are present, spelled in
#'   Darwin Core camelCase.
#' * **types** -- identifier and name columns are character.  A column that
#'   is entirely `NA` will often be typed as integer or logical by mistake,
#'   which this catches.
#' * **scientificName** -- never `NA`.  Every row names something, at every
#'   rank: `Animalia` is a scientificName just as `Homo sapiens` is.
#' * **taxonRank**, **taxonomicStatus** -- never `NA`.
#' * **acceptedNameUsageID** -- never `NA`, on synonyms *and* on accepted
#'   names.  This is where taxadb is stricter than Darwin Core.
#' * **accepted_has_id** -- a row that is its own accepted name has a
#'   `taxonID`.  (`taxonID` may be `NA` on a synonym, where the provider
#'   mints no identifier for it -- OTT and NCBI, for instance, do not.)
#' * **accepted_resolves** -- every `acceptedNameUsageID` matches the
#'   `taxonID` of a self-referencing row.  No dangling references.
#' * **self_is_accepted** -- a row whose `taxonID` equals its
#'   `acceptedNameUsageID` is labelled `accepted` in `taxonomicStatus`.
#' * **accepted_unique** -- no duplicate `taxonID` among accepted names.
#' * **id_prefix** -- identifiers are the provider's identifier prefixed by
#'   the provider abbreviation in capitals, e.g. `ITIS:180092`.
#'
#' `taxonomicStatus` is deliberately *not* checked against a controlled
#' vocabulary beyond requiring that accepted names say `accepted`: providers
#' draw real distinctions (`homotypic synonym`, `provisionally accepted`,
#' `misapplied`) that are worth preserving.
#' @export
#' @examples \donttest{
#' td_validate("itis_test")
#' }
td_validate <- function(provider = getOption("taxadb_default_provider", "itis"),
                        schema = c("dwc", "common"),
                        version = latest_version(),
                        db = td_connect()){

  schema <- match.arg(schema)
  tbl <- taxa_tbl(provider, schema, version, db)
  name <- dbplyr::remote_name(tbl)

  cols <- DBI::dbGetQuery(db, paste0("DESCRIBE SELECT * FROM ", name))
  required <- switch(schema, dwc = DWC_REQUIRED, common = COMMON_REQUIRED)

  rules <- list(rule_columns(cols, required, schema))

  ## The remaining rules read the required columns; running them against a
  ## table that is missing one would error rather than report.  A column of
  ## the wrong type is reported by rule_types and then cast, so that one
  ## mistyped column does not mask every other finding.
  if(all(required %in% cols$column_name)){
    src <- normalized_src(name, required)
    rules <- c(rules, list(
      rule_types(cols, required),
      rule_not_null(db, src, "scientificName"),
      rule_not_null(db, src, "taxonRank"),
      rule_not_null(db, src, "taxonomicStatus"),
      rule_not_null(db, src, "acceptedNameUsageID"),
      rule_accepted_has_id(db, src),
      rule_self_is_accepted(db, src),
      rule_id_prefix(db, src, provider)))

    if(schema == "common")
      rules <- c(rules, list(rule_not_null(db, src, "vernacularName")))

    ## Two rules are meaningful only on `dwc`, which is the complete name
    ## list.  `common` holds one row per vernacular name, so a taxonID
    ## recurs by design, and it lists only taxa that have a vernacular
    ## name, so an acceptedNameUsageID need not appear in it as a row.
    if(schema == "dwc")
      rules <- c(rules, list(rule_accepted_resolves(db, src),
                             rule_accepted_unique(db, src)))
  }

  out <- do.call(rbind, rules)
  out$provider <- provider
  out$schema <- schema
  out$version <- version
  out[c("provider", "schema", "version", "rule", "pass", "violations", "note")]
}

check <- function(rule, violations, note = ""){
  data.frame(rule = rule, pass = violations == 0,
             violations = as.numeric(violations), note = note,
             stringsAsFactors = FALSE)
}

## The rules compare identifiers as strings.  A column that is entirely NULL
## is often typed INTEGER or BOOLEAN by the writer, which would make those
## comparisons error; casting lets every rule still report.
normalized_src <- function(name, required){
  cast <- paste0("CAST(\"", required, "\" AS VARCHAR) AS \"", required, "\"",
                 collapse = ", ")
  paste0("(SELECT ", cast, " FROM ", name, ")")
}

## A single scalar count from the database.
count_where <- function(db, src, where){
  DBI::dbGetQuery(db,
    paste0("SELECT count(*) AS n FROM ", src, " WHERE ", where))$n
}

rule_columns <- function(cols, required, schema){
  missing <- setdiff(required, cols$column_name)
  ## A miscapitalized term reads as missing; say so, since it is the
  ## likeliest cause and the easiest to fix.
  near <- required[tolower(required) %in%
                   setdiff(tolower(cols$column_name), cols$column_name)]
  note <- if(length(missing) == 0) paste(schema, "terms present")
          else paste("missing:", paste(missing, collapse = ", "),
                     if(length(near)) paste0(" (wrong case: ",
                       paste(near, collapse = ", "), ")") else "")
  check("columns", length(missing), note)
}

rule_types <- function(cols, required){
  types <- cols$column_type[match(required, cols$column_name)]
  bad <- required[types != "VARCHAR"]
  check("types", length(bad),
        if(length(bad) == 0) "identifier and name columns are VARCHAR"
        else paste("not VARCHAR:", paste0(bad, " <",
                   types[types != "VARCHAR"], ">", collapse = ", ")))
}

rule_not_null <- function(db, src, column){
  n <- count_where(db, src, paste0("\"", column, "\" IS NULL"))
  check(column, n, if(n == 0) paste(column, "never NULL")
                   else paste(format(n, big.mark = ","), "NULL", column))
}

## A row that is its own accepted name must carry an identifier.  We cannot
## key off taxonID = acceptedNameUsageID here (that is what we are testing),
## so we key off the status term.
rule_accepted_has_id <- function(db, src){
  n <- count_where(db, src,
    "taxonomicStatus LIKE '%accepted%' AND taxonID IS NULL")
  check("accepted_has_id", n,
        if(n == 0) "accepted names all carry a taxonID"
        else paste(format(n, big.mark = ","),
                   "accepted names with NULL taxonID"))
}

rule_accepted_resolves <- function(db, src){
  n <- DBI::dbGetQuery(db, paste0(
    "WITH acc AS (SELECT DISTINCT taxonID FROM ", src,
    " WHERE taxonID = acceptedNameUsageID) ",
    "SELECT count(*) AS n FROM ", src, " t ",
    "LEFT JOIN acc ON t.acceptedNameUsageID = acc.taxonID ",
    "WHERE acc.taxonID IS NULL"))$n
  check("accepted_resolves", n,
        if(n == 0) "every acceptedNameUsageID resolves to an accepted name"
        else paste(format(n, big.mark = ","), "dangling acceptedNameUsageID"))
}

rule_self_is_accepted <- function(db, src){
  n <- count_where(db, src,
    "taxonID = acceptedNameUsageID AND taxonomicStatus NOT LIKE '%accepted%'")
  check("self_is_accepted", n,
        if(n == 0) "self-referencing rows are labelled accepted"
        else paste(format(n, big.mark = ","),
                   "self-referencing rows not labelled accepted"))
}

rule_accepted_unique <- function(db, src){
  n <- DBI::dbGetQuery(db, paste0(
    "SELECT count(*) AS n FROM (SELECT taxonID FROM ", src,
    " WHERE taxonID = acceptedNameUsageID",
    " GROUP BY taxonID HAVING count(*) > 1)"))$n
  check("accepted_unique", n,
        if(n == 0) "one row per accepted taxonID"
        else paste(format(n, big.mark = ","), "duplicated accepted taxonID"))
}

rule_id_prefix <- function(db, src, provider){
  ## itis_test carries real ITIS identifiers
  prefix <- toupper(sub("_test$", "", provider))
  pattern <- paste0("^", prefix, ":")
  n <- count_where(db, src, paste0(
    "(taxonID IS NOT NULL AND NOT regexp_matches(taxonID, '", pattern, "')) ",
    "OR NOT regexp_matches(acceptedNameUsageID, '", pattern, "')"))
  check("id_prefix", n,
        if(n == 0) paste0("identifiers prefixed '", prefix, ":'")
        else paste(format(n, big.mark = ","), "identifiers not prefixed '",
                   prefix, ":'"))
}
