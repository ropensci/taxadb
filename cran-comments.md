We are pleased to submit the intial release of taxadb.  

The YEAR stated in the LICENSE is now updated.  

We are using \dontshow in examples to
hide commands which are related only to testing settings. Showing these would be confusing
to the user, because they only set an environmental variable related to testing.  
Please note that the discussion of `dontshow` in the Writing R Extensions manual, 
"Writing R Extensions",
https://cran.r-project.org/doc/manuals/r-release/R-exts.html#index-_005cdontshow, does 
not at this time discuss use of \dontshow, but this use is consistent with other 
examples of CRAN packages which use \dontshow to hide testing-related setting of options, etc
in examples.  We have spent considerable time selecting examples and having them peer-reviewed
(e.g. https://github.com/ropensci/software-review/issues/344).  This issue was not commented
on in previous submissions of this package, the automated checks, or the writing CRAN Extensions
Manual, and our use is consistent with other CRAN packages use.  If you feel these examples
would somehow be clearer without the use of `\dontshow` around parts meant for creating a testing
environment only, some further explanation would be appreciated.  



## Test environments

* local OS X install, R 3.6.2
* ubuntu 16.04 (on travis-ci), R 3.6.2
* win-builder (devel and release)

## R CMD check results

0 errors | 0 warnings | 0 notes

* This is a new release.
