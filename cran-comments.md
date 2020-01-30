We are pleased to submit the intial release of taxadb.  

The IUCN website URL does not include a HEAD, which causes CRAN's header-only check request (`curl -I -L`) to fail,
even though a full check (`curl -L` would resolve https://iucnredlist.org).  To avoid this spurious error, I have
listed this link as plain text.

CRAN's checks also appeared to stall out on one system on the previous submission.  While I cannot replicate this (locally checks run under 2 minutes), I agree it may be due to a possible web request, so this revision caches a minimal copy of the data used in regular checks so that tests can be run more efficiently.


## Test environments

* local OS X install, R 3.6.2
* ubuntu 16.04 (on travis-ci), R 3.6.2
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.
