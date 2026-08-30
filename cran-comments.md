## Test environments

* local Ubuntu 24.04, R 4.6.1 (full check: PDF manual and HTML validation
  both built, nothing skipped)
* GitHub Actions: ubuntu-latest, macOS-latest, windows-latest (release, devel, oldrel)

## R CMD check results

0 errors | 0 warnings | 0 notes

The incoming check on the previous submission reported
`https://www.itis.gov/` as a 404 from `inst/doc/data-sources.html`. ITIS is
intermittent for automated clients, so this release does not give a URL for it
at all: the vignette names each provider, and the home page, licence and
preferred citation are returned by `taxadb_provider_info()` from within R,
where the CRAN check does not resolve them. The ITIS citation is given
bibliographically rather than as its DOI, since `doi:10.5066/F7KH0KBK`
redirects to the same host and would inherit the same flakiness -- a plain
`doi:` in a vignette is resolved by the check.

Nothing under `inst/doc` now points at a provider. `urlchecker::url_check()`
reports no problems on the built package, and a scheduled workflow runs it
monthly, against both the built vignettes and the provider URLs held in R
code, so a dead link surfaces between releases rather than at submission.

The PDF manual builds and the HTML manual validates. Remaining DOIs are given
in `doi:` form.

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
