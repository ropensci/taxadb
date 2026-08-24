#!/usr/bin/env bash
#
# Publish a built taxadb snapshot to the data repository.
#
# Run td_build() and td_write_metadata() first; this only uploads what is
# already in the build output directory, and checks the metadata is there
# before it starts.
#
# Credentials come from the environment, so they are never written to disk
# or into a command line:
#
#   export SOURCECOOP_KEY=...
#   export SOURCECOOP_SECRET=...
#   inst/scripts/publish-snapshot.sh 2026
#
# Optional:
#   TAXADB_BUILD_DIR   build directory (default: the R user cache dir)
#   TAXADB_REPO        target repository (default: cboettig/taxadb)
#   DRY_RUN=1          list what would be uploaded and exit

set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "usage: $0 <version>   e.g. $0 2026" >&2
  exit 2
fi

REPO="${TAXADB_REPO:-cboettig/taxadb}"
BUILD_DIR="${TAXADB_BUILD_DIR:-$(Rscript -e 'cat(tools::R_user_dir("taxadb","cache"))')/build}"
SRC="$BUILD_DIR/out/$VERSION"
ENDPOINT="https://data.source.coop"

[ -d "$SRC" ] || { echo "no build output at $SRC" >&2; exit 1; }

# Publishing without the metadata would leave the data undocumented, which
# is part of what this is meant to fix.
for required in README.md manifest.csv; do
  [ -f "$SRC/$required" ] || {
    echo "$required missing from $SRC -- run td_write_metadata(\"$VERSION\") first" >&2
    exit 1; }
done

# Every table must be a single part, because the published URLs name part_0
# directly: a reader given .../dwc_col_part_0.parquet must get all of COL
# from it. If a table ever grows enough to need splitting, the advertised
# URLs have to change at the same time -- so refuse rather than silently
# truncate what those readers get.
split=$(find "$SRC" -name '*_part_1.parquet' -printf '%f\n' 2>/dev/null \
        | sed 's/_part_1\.parquet//' || true)
if [ -n "$split" ]; then
  echo "refusing to publish: these tables are split across parts, so a" >&2
  echo "reader of part_0 alone would get an incomplete table:" >&2
  echo "$split" | sed 's/^/  /' >&2
  exit 1
fi

echo "publishing $VERSION -> s3://$REPO/$VERSION"
find "$SRC" -maxdepth 1 -type f \
  \( -name '*.parquet' -o -name '*.md' -o -name '*.csv' \) \
  -printf '  %-34f %10s bytes\n' | sort

if [ "${DRY_RUN:-0}" = "1" ]; then echo "(dry run, nothing uploaded)"; exit 0; fi

: "${SOURCECOOP_KEY:?set SOURCECOOP_KEY}"
: "${SOURCECOOP_SECRET:?set SOURCECOOP_SECRET}"

# Destination guard. The source.coop credential is account-wide write across
# every repository under the account, and source.coop deletions have no
# archive to restore from -- so the only thing keeping a typo in TAXADB_REPO
# from writing into an unrelated repository is this check. Same guard the
# geo-agent-ops source-sync CronJob carries, for the same reason.
case "$REPO" in
  */*/*|*" "*|""|/*|*/) echo "refusing: TAXADB_REPO must be <account>/<repo>, got '$REPO'" >&2; exit 1 ;;
esac
case "$VERSION" in
  */*|*" "*|.*|"") echo "refusing: version must be a plain name, got '$VERSION'" >&2; exit 1 ;;
esac

# copy, never sync: sync would delete anything at the destination that is not
# in the build output, and this uploads one version directory into a
# repository that holds others.

# --s3-no-check-bucket: the bucket exists, and the key may not be permitted
# to probe it. --checksum: skip files whose content is already identical.
rclone copy "$SRC" ":s3:$REPO/$VERSION" \
  --s3-provider Other \
  --s3-endpoint "$ENDPOINT" \
  --s3-access-key-id "$SOURCECOOP_KEY" \
  --s3-secret-access-key "$SOURCECOOP_SECRET" \
  --s3-force-path-style \
  --s3-no-check-bucket \
  --checksum \
  --include '*.parquet' --include '*.md' --include '*.csv' \
  --progress

echo
echo "published. verify with:"
echo "  Rscript -e 'print(taxadb::td_validate(\"itis\", version=\"$VERSION\"))'"
