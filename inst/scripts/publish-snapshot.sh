#!/usr/bin/env bash
#
# Publish a built taxadb snapshot to the data repository.
#
# Run td_build() and td_write_metadata() first: this uploads what is already
# in the build output directory and checks the metadata is there before it
# starts.
#
#   RCLONE_CONFIG=/path/to/rclone.conf inst/scripts/publish-snapshot.sh 2026
#
# Credentials come from a named rclone remote, never from this script, an
# argument or an environment variable of their own. Nothing here reads or
# echoes a key. The cluster keeps a suitable config in the `rclone-config` /
# `rclone-backup` secret under the key `rclone.conf`.
#
# Optional:
#   TAXADB_BUILD_DIR   build directory (default: the R user cache dir)
#   TAXADB_REPO        target repository (default: cboettig/taxadb)
#   RCLONE_REMOTE      remote name for source.coop (default: source)
#   DRY_RUN=1          run every check, then list and exit without uploading

set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "usage: $0 <version>   e.g. $0 2026" >&2
  exit 2
fi

REPO="${TAXADB_REPO:-cboettig/taxadb}"
REMOTE="${RCLONE_REMOTE:-source}"

# source.coop's write path is not its read path. Reads present each account
# as its own bucket, but writes go to one shared bucket with the account as
# the first key segment:
#
#   read   https://data.source.coop/cboettig/taxadb/2026/...
#   write  <remote>:us-west-2.opendata.source.coop/cboettig/taxadb/2026/...
DEST_BUCKET="us-west-2.opendata.source.coop"

BUILD_DIR="${TAXADB_BUILD_DIR:-$(Rscript -e 'cat(tools::R_user_dir("taxadb","cache"))')/build}"
SRC="$BUILD_DIR/out/$VERSION"
DEST="$REMOTE:$DEST_BUCKET/$REPO/$VERSION"

# ---------------------------------------------------------------------------
# Checks. All of these run under DRY_RUN too -- a dry run that skipped them
# would report success for a configuration that cannot actually publish.
# ---------------------------------------------------------------------------

[ -d "$SRC" ] || { echo "no build output at $SRC" >&2; exit 1; }

# Publishing without the metadata would leave the data undocumented, which is
# part of what this is meant to fix.
for required in README.md manifest.csv; do
  [ -f "$SRC/$required" ] || {
    echo "$required missing from $SRC -- run td_write_metadata(\"$VERSION\") first" >&2
    exit 1; }
done

# Every table must be a single part, because the published URLs name part_0
# directly: a reader given .../dwc_col_part_0.parquet must get all of COL from
# it. If a table ever grows enough to need splitting, the advertised URLs have
# to change at the same time -- so refuse rather than silently truncate what
# those readers get.
split=$(find "$SRC" -name '*_part_1.parquet' -printf '%f\n' 2>/dev/null \
        | sed 's/_part_1\.parquet//' || true)
if [ -n "$split" ]; then
  echo "refusing: these tables are split across parts, so a reader of" >&2
  echo "part_0 alone would get an incomplete table:" >&2
  echo "$split" | sed 's/^/  /' >&2
  exit 1
fi

# Names, before they are used to build a path. The credential is account-wide
# write and source.coop deletions have no archive to restore from, so a typo
# in TAXADB_REPO is the failure worth spending a few lines on.
case "$REPO" in
  */*/*|*" "*|""|/*|*/)
    echo "refusing: TAXADB_REPO must be <account>/<repo>, got '$REPO'" >&2; exit 1 ;;
esac
case "$VERSION" in
  */*|*" "*|.*|"")
    echo "refusing: version must be a plain name, got '$VERSION'" >&2; exit 1 ;;
esac
case "$DEST" in
  "$REMOTE:$DEST_BUCKET/$REPO/"?*) : ;;
  *) echo "refusing: '$DEST' is not a $REPO sub-path" >&2; exit 1 ;;
esac
case "$DEST_BUCKET" in
  *source.coop) : ;;
  *) echo "refusing: '$DEST_BUCKET' is not a source.coop bucket" >&2; exit 1 ;;
esac

rclone listremotes 2>/dev/null | grep -qx "$REMOTE:" || {
  echo "no rclone remote named '$REMOTE'. Remotes available:" >&2
  rclone listremotes >&2
  echo "Set RCLONE_CONFIG to a config defining a source.coop remote, or" >&2
  echo "RCLONE_REMOTE to the right name." >&2
  exit 1; }

# Three S3 systems are reachable from here: source.coop, MinIO at
# minio.carlboettiger.info and NRP at s3-west.nrp-nautilus.io. Publishing into
# the wrong one is the mistake this catches.
#
# An absent endpoint is correct rather than suspicious: source.coop is hosted
# on AWS S3 directly, so its remote is a plain `provider = AWS` with no
# endpoint override, and us-west-2.opendata.source.coop is a real AWS bucket.
# Only an endpoint pointing somewhere that is NOT source.coop disqualifies.
remote_endpoint=$(rclone config show "$REMOTE" 2>/dev/null | sed -n 's/^endpoint *= *//p')
case "$remote_endpoint" in
  ""|*source.coop*) : ;;
  *) echo "refusing: remote '$REMOTE' points at '$remote_endpoint', not source.coop" >&2
     echo "  (the MinIO and NRP remotes are not publication targets)" >&2
     exit 1 ;;
esac

# Prove we reach the right account and repository before transferring
# anything. This catches a wrong remote, a wrong account and a mistyped repo
# at once, without relying on name matching.
rclone lsd "$REMOTE:$DEST_BUCKET/$REPO" >/dev/null 2>&1 || {
  echo "refusing: cannot list $REMOTE:$DEST_BUCKET/$REPO" >&2
  echo "  the repository must exist and the credential must reach it" >&2
  exit 1; }

# ---------------------------------------------------------------------------

echo "publishing $VERSION -> $DEST"
find "$SRC" -maxdepth 1 -type f \
  \( -name '*.parquet' -o -name '*.md' -o -name '*.csv' \) \
  -printf '  %-34f %10s bytes\n' | sort

if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "(dry run: all checks passed, nothing uploaded)"
  exit 0
fi

# copy, never sync: sync deletes whatever at the destination is not present
# locally, and this uploads one version directory into a repository holding
# others. --checksum skips files whose content is already identical.
rclone copy "$SRC" "$DEST" \
  --checksum \
  --include '*.parquet' --include '*.md' --include '*.csv' \
  --transfers 2 --checkers 4 --tpslimit 5 --retries 5 \
  --stats 30s \
  --progress

echo
echo "published. verify with:"
echo "  Rscript -e 'print(taxadb::td_validate(\"itis\", version=\"$VERSION\"))'"
