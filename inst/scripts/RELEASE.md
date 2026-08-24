# Publishing a taxadb snapshot

The data are built by this package, so a release is a package task rather
than a separate pipeline. Everything below runs from a checkout.

## 1. Build

```r
library(taxadb)
td_build(taxadb_providers(), version = "2026")
```

Downloads roughly 1.8 GB of provider archives on a cold cache (kept in
`build_dir()` afterwards) and takes a few minutes. `td_build()` validates
each table as it finishes and warns if any rule is violated.

## 2. Check

```r
for (p in taxadb_providers())
  for (s in c("dwc", "common"))
    print(td_validate(p, s, version = "2026"))
```

Every rule must pass before publishing. `td_validate()` is the gate: a
violation here means a reader will hit the same problem.

Point `TAXADB_HOME` at `file.path(build_dir(), "out")` so this reads the
tables you just built rather than the published ones.

## 3. Write the metadata

```r
td_write_metadata("2026")
```

Writes `manifest.csv` and `README.md` next to the Parquet files. The
publish script refuses to upload without them.

## 4. Publish

```sh
export SOURCECOOP_KEY=...
export SOURCECOOP_SECRET=...
DRY_RUN=1 inst/scripts/publish-snapshot.sh 2026   # check the file list
inst/scripts/publish-snapshot.sh 2026
```

Publishing to an existing version overwrites it. People do read these URLs
directly -- the advice on ropensci/taxadb#123 pointed at
`.../2026/dwc_col_part_0.parquet` -- so overwriting changes data underneath
running code. Prefer a new version unless the point is to replace something
broken.

## 5. Re-render the README

`README.Rmd` queries the published data, so its output only reflects a new
release after that release is up:

```r
rmarkdown::render("README.Rmd")
```

Worth checking the diff: it is the quickest end-to-end confirmation that
what you published is what you meant to.

## Notes on individual providers

- **gbif** builds from the most recent backbone GBIF has published, dated
  2023-08-28. Both hosted-datasets.gbif.org and ChecklistBank offer the same
  release; there is no newer one. Occurrence-derived taxon tables are not a
  substitute, since they carry no identifiers, no synonyms and no
  `taxonomicStatus`.
- **col** builds from `latest_dwca.zip`, so its content depends on the build
  date. The release it used is recorded in the manifest.
- **ncbi**'s taxdump is regenerated daily and carries no version string; the
  date of the dump read is recorded as the version.
- **fb** and **slb** read FishBase's own published Parquet and download
  nothing. They are CC BY-NC, unlike the other providers.
- **ott** pins a release in `build_ott(ott_version=)`; bump it when Open Tree
  publishes a new one.
