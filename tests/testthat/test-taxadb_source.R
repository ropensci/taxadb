test_that("taxadb_uri resolves the bundled fixture without network", {
  p <- taxadb_uri("itis_test", "dwc")
  expect_true(file.exists(p))
  expect_true(grepl("dwc_itis_test\\.parquet$", p))
  expect_true(file.exists(taxadb_uri("itis_test", "common")))
})

test_that("taxadb_uri points at object storage when there is no local copy", {
  withr::local_envvar(TAXADB_HOME = tempfile())
  uri <- taxadb_uri("itis", "dwc", version = "2026")
  expect_match(uri, "^s3://")
  expect_match(uri, "2026/dwc_itis_part_\\*\\.parquet$")
})

test_that("taxadb_uri prefers a local copy when one is present", {
  home <- withr::local_tempdir()
  withr::local_envvar(TAXADB_HOME = home)
  dir.create(file.path(home, "2026"), recursive = TRUE)
  f <- file.path(home, "2026", "dwc_itis_part_0.parquet")
  file.copy(taxadb_uri("itis_test", "dwc"), f)
  uri <- taxadb_uri("itis", "dwc", version = "2026")
  expect_false(grepl("^s3://", uri))
  expect_identical(Sys.glob(uri), f)
})

test_that("asking for a missing local copy explains how to get one", {
  withr::local_envvar(TAXADB_HOME = tempfile())
  expect_error(taxadb_uri("itis", "dwc", version = "2026", local = TRUE),
               "td_download")
})

test_that("the repository can be redirected for a mirror", {
  withr::local_options(taxadb_repo = "someone/elsewhere")
  expect_identical(taxadb_repo(), "someone/elsewhere")
  withr::local_envvar(TAXADB_HOME = tempfile())
  expect_match(taxadb_uri("itis", "dwc", version = "2026"),
               "^s3://someone/elsewhere/")
})

test_that("taxadb_providers lists what we can rebuild", {
  expect_setequal(taxadb_providers(),
                  c("itis", "ncbi", "col", "gbif", "ott", "fb", "slb"))
})

test_that("td_build refuses an unknown provider by name", {
  expect_error(td_build("nosuchprovider"), "no builder for provider")
  ## iucn was dropped; the message should say so plainly rather than
  ## suggesting credentials that no longer help.
  expect_error(td_build("iucn"), "no builder for provider")
})

test_that("versions are ordered as versions, not as strings", {
  ## "22.12" sorts after "2026" as a string, so publishing the 2022 archival
  ## release once made it the default for every query.
  expect_identical(taxadb:::version_max(c("2026", "22.12")), "2026")
  expect_identical(taxadb:::version_max(c("22.12", "2026", "22.01")), "2026")
  expect_identical(taxadb:::version_max(c("2026", "2027")), "2027")
  expect_identical(taxadb:::version_max("22.12"), "22.12")
  ## an unparseable label must not win over a real version
  expect_identical(taxadb:::version_max(c("2026", "draft")), "2026")
  ## and with nothing to go on we still return something usable
  expect_identical(taxadb:::version_max(character(0)),
                   taxadb:::TAXADB_FALLBACK_VERSION)
})
