## Shared by the two steps of .github/workflows/url-check.yaml.
##
## `urlchecker::url_check()` does the checking -- this only decides which of
## its findings should fail the job, because not every finding is a dead link:
##
##   403  a web application firewall refusing an automated client. Several
##        providers (GBIF, FishBase, SeaLifeBase) always do this. Nothing to fix.
##   0/Error  the host was unreachable from this runner just now.
##
## Everything else in the 4xx/5xx range is the page really being gone. Those
## are retried once first: a single hiccup from a provider is exactly what we
## are trying to avoid being surprised by at submission time, so it should not
## be what fails this job either.

TOLERATED <- function(status) {
  s <- suppressWarnings(as.integer(status))
  is.na(s) | s == 0L | s == 403L
}

## `From` comes back as a list column -- one URL can have several parents --
## and a url db needs Parent to be a plain character vector.
recheck <- function(problems) {
  parent <- vapply(problems$From, function(x) paste(x, collapse = ", "),
                   character(1))
  urlchecker::url_check(db = data.frame(URL = as.character(problems$URL),
                                        Parent = parent))
}

report <- function(problems, what) {
  problems <- as.data.frame(problems)
  if (!nrow(problems)) {
    cat("no problems in the ", what, " URLs\n", sep = "")
    return(invisible())
  }

  print(problems[c("URL", "From", "Status", "Message")])

  hard <- problems[!TOLERATED(problems$Status), , drop = FALSE]
  if (!nrow(hard)) {
    cat("all tolerated (firewall refusal or host unreachable)\n")
    return(invisible())
  }

  cat("rechecking", nrow(hard), "before failing\n")
  still <- as.data.frame(recheck(hard))
  still <- still[!TOLERATED(still$Status), , drop = FALSE]
  if (!nrow(still)) {
    cat("all cleared on recheck\n")
    return(invisible())
  }

  print(still[c("URL", "From", "Status", "Message")])
  stop(nrow(still), " dead ", what, " URL(s)", call. = FALSE)
}
