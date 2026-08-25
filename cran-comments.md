## Test environments

* local Ubuntu 24.04, R 4.6.1 (full check: PDF manual and HTML validation
  both built, nothing skipped)
* GitHub Actions: ubuntu-latest, macOS-latest, windows-latest (release, devel, oldrel)

## R CMD check results

0 errors | 0 warnings | 0 notes

`urlchecker::url_check()` reports no problems. The PDF manual builds and the
HTML manual validates. DOIs are given in `doi:` form
and provider homepages are named rather than linked, since several sit behind
web application firewalls that return 403 to automated clients and one serves
an incomplete TLS certificate chain.

Examples do not access the network. Every runnable example uses a small
subset of ITIS bundled in `inst/extdata`; examples that would download data
or query the remote store are wrapped in `\dontrun{}`.

## Reverse dependencies

Checked all five: bdc, BeeBDC, EML, prepR4pcm, R2camtrapdp.

This release changes where the underlying data is read from. `bdc` and
`BeeBDC` pin the data version `"22.12"`; that version is published at the new
location, so both continue to work unchanged, verified by running their
pinned calls against this release. Both maintainers have been notified.

`iucn`, `tpl` and `wd` are no longer offered as providers. No reverse
dependency loses working functionality: `bdc` and `prepR4pcm` already refuse
those codes in their own source, having independently determined that they
did not work.
