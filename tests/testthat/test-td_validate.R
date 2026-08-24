## The bundled fixture is a subset of a real ITIS build, so it must satisfy
## the same rules a published snapshot does.  If these fail, either the
## fixture or the rules have drifted.

test_that("the bundled fixture conforms to the taxadb rules", {
  for(schema in c("dwc", "common")){
    out <- td_validate("itis_test", schema)
    expect_s3_class(out, "data.frame")
    expect_true(nrow(out) > 5)
    expect_true(all(out$pass),
                info = paste("violated:",
                             paste(out$rule[!out$pass], out$note[!out$pass],
                                   collapse = "; ")))
  }
})

test_that("td_validate reports rather than errors on a broken table", {
  db <- td_connect()
  ## A taxonID that is NULL on an accepted name is the NCBI defect; an
  ## acceptedNameUsageID pointing nowhere is a dangling reference.
  DBI::dbExecute(db, "CREATE OR REPLACE VIEW dwc_broken_1 AS
    SELECT * FROM (VALUES
      (NULL,   'BAD:1', 'Aaa aaa', 'species', 'accepted'),
      ('BAD:2','BAD:9', 'Bbb bbb', 'species', 'synonym')
    ) t(taxonID, acceptedNameUsageID, scientificName, taxonRank,
        taxonomicStatus)")
  out <- taxadb:::td_validate_table("dwc_broken_1", "dwc", "bad", db = db)
  expect_false(out$pass[out$rule == "accepted_has_id"])
  expect_false(out$pass[out$rule == "accepted_resolves"])
})

test_that("a mistyped id column is reported, not fatal", {
  db <- td_connect()
  ## An all-NA taxonID is often written as INTEGER, which used to make the
  ## identifier comparisons error out instead of reporting.
  DBI::dbExecute(db, "CREATE OR REPLACE VIEW dwc_broken_2 AS
    SELECT * FROM (VALUES
      (CAST(NULL AS INTEGER), 'BAD:1', 'Aaa aaa', 'species', 'accepted')
    ) t(taxonID, acceptedNameUsageID, scientificName, taxonRank,
        taxonomicStatus)")
  out <- taxadb:::td_validate_table("dwc_broken_2", "dwc", "bad", db = db)
  expect_false(out$pass[out$rule == "types"])
  ## the other rules still ran
  expect_true(all(c("scientificName", "accepted_resolves") %in% out$rule))
})

test_that("a taxonID naming two different names is caught", {
  db <- td_connect()
  ## FishBase numbered accepted names and synonyms in separate sequences,
  ## so one prefixed id named two taxa.
  DBI::dbExecute(db, "CREATE OR REPLACE VIEW dwc_broken_3 AS
    SELECT * FROM (VALUES
      ('BAD:1','BAD:1', 'Aaa aaa', 'species', 'accepted'),
      ('BAD:1','BAD:1', 'Zzz zzz', 'species', 'accepted')
    ) t(taxonID, acceptedNameUsageID, scientificName, taxonRank,
        taxonomicStatus)")
  out <- taxadb:::td_validate_table("dwc_broken_3", "dwc", "bad", db = db)
  expect_false(out$pass[out$rule == "taxonID_one_name"])
})

test_that("an ambiguous synonym on two accepted names is allowed", {
  db <- td_connect()
  ## ITIS records 255 of these; one row per reading is the honest
  ## representation, and the identifier still means one name.
  DBI::dbExecute(db, "CREATE OR REPLACE VIEW dwc_ok_1 AS
    SELECT * FROM (VALUES
      ('BAD:1','BAD:1', 'Aaa aaa', 'species', 'accepted'),
      ('BAD:2','BAD:2', 'Bbb bbb', 'species', 'accepted'),
      ('BAD:3','BAD:1', 'Ccc ccc', 'species', 'synonym'),
      ('BAD:3','BAD:2', 'Ccc ccc', 'species', 'synonym')
    ) t(taxonID, acceptedNameUsageID, scientificName, taxonRank,
        taxonomicStatus)")
  out <- taxadb:::td_validate_table("dwc_ok_1", "dwc", "bad", db = db)
  expect_true(all(out$pass),
              info = paste(out$rule[!out$pass], collapse = "; "))
})

test_that("statuses other than accepted and synonym may self-reference", {
  db <- td_connect()
  ## GBIF's `doubtful` and COL's `provisionally accepted` are redirected
  ## nowhere, so they are their own accepted name.
  DBI::dbExecute(db, "CREATE OR REPLACE VIEW dwc_ok_2 AS
    SELECT * FROM (VALUES
      ('BAD:1','BAD:1', 'Aaa aaa', 'species', 'doubtful'),
      ('BAD:2','BAD:2', 'Bbb bbb', 'species', 'provisionally accepted'),
      ('BAD:3','BAD:1', 'Ccc ccc', 'species', 'synonym')
    ) t(taxonID, acceptedNameUsageID, scientificName, taxonRank,
        taxonomicStatus)")
  out <- taxadb:::td_validate_table("dwc_ok_2", "dwc", "bad", db = db)
  expect_true(all(out$pass),
              info = paste(out$rule[!out$pass], collapse = "; "))
})
