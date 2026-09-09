#!/usr/bin/env bash
#
# Update the vendored claude-code release manifest to the latest (or a given)
# version. The cairn overlay (pkgs/default.nix) imports this manifest to pin
# claude-code ahead of nixpkgs.
#
# nixpkgs' claude-code recipe fetches the release binary and `unzstd`s it in the
# install phase, so the src it expects is the ZSTD-COMPRESSED artifact, not the
# raw ELF. Our override reuses that recipe, so the manifest we vendor must point
# at `claude.zst` (checksum + size describing the .zst). Upstream's manifest.json
# only advertises the raw binary, so we fetch each `<binary>.zst` ourselves and
# record its own sha256/size. Handing the recipe the raw binary makes `unzstd`
# die with "unsupported format" — which is exactly how this last broke.
#
# Usage:
#   ./scripts/update-claude-code.sh           # latest stable release
#   ./scripts/update-claude-code.sh 2.1.170   # a specific version
#
# Run by .github/workflows/update-claude-code.yml on a schedule, but safe to
# run locally too. Prints the resulting version on stdout.
set -euo pipefail

BASE_URL="https://downloads.claude.ai/claude-code-releases"
DEST="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/pkgs/claude-code-manifest.json"

VERSION="${1:-$(curl -fsSL "$BASE_URL/latest")}"

# Download to a temp file first so a failed/partial fetch never clobbers the
# committed manifest.
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
curl -fsSL "$BASE_URL/$VERSION/manifest.json" --output "$TMP"

# Sanity check: the fetched manifest must report the version we asked for.
GOT="$(grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' "$TMP" | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
if [ "$GOT" != "$VERSION" ]; then
  echo "error: manifest version ($GOT) does not match requested version ($VERSION)" >&2
  exit 1
fi

# Rewrite every platform to describe its `<binary>.zst`: swap the binary name,
# and replace checksum/size with the compressed artifact's own values. All other
# fields (version, commit, sdkCompat, ...) are preserved verbatim. Written to a
# temp path first so a failed download never leaves a half-rewritten manifest.
OUT="$(mktemp)"
trap 'rm -f "$TMP" "$OUT"' EXIT
python3 - "$VERSION" "$BASE_URL" "$TMP" "$OUT" <<'PY'
import hashlib, json, sys, urllib.request

version, base_url, src, out = sys.argv[1:5]
manifest = json.load(open(src))

for plat, entry in manifest["platforms"].items():
    zst = entry["binary"] + ".zst"
    url = f"{base_url}/{version}/{plat}/{zst}"
    print(f"fetching {url}", file=sys.stderr)
    data = urllib.request.urlopen(url).read()
    entry["binary"] = zst
    entry["checksum"] = hashlib.sha256(data).hexdigest()
    entry["size"] = len(data)

with open(out, "w") as fh:
    json.dump(manifest, fh, indent=2)
    fh.write("\n")
PY

mv "$OUT" "$DEST"
trap - EXIT
echo "$VERSION"
