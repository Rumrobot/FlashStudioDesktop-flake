#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

api=https://api.github.com/repos/FlashForge/Orca-Flashforge/releases/latest
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

release=$tmp/release.json
entries=$tmp/entries.jsonl
out=$tmp/sources.json

if [ -n "${GITHUB_TOKEN:-}" ]; then
  curl -fsSL -H "Authorization: Bearer $GITHUB_TOKEN" "$api" > "$release"
else
  curl -fsSL "$api" > "$release"
fi
version=$(jq -r '.tag_name | ltrimstr("v")' "$release")
: > "$entries"

jq -c '.assets[] | {name, url: .browser_download_url}' "$release" |
while IFS= read -r asset; do
  name=$(printf '%s\n' "$asset" | jq -r .name)
  url=$(printf '%s\n' "$asset" | jq -r .url)

  case "$name" in
    *.AppImage) system=x86_64-linux ;;
    *) continue ;;
  esac

  prefetch_output=$(nix store prefetch-file --json "$url")
  sha256=$(printf '%s\n' "$prefetch_output" | jq -r .hash)

  jq -n \
    --arg system "$system" \
    --arg version "$version" \
    --arg url "$url" \
    --arg sha256 "$sha256" \
    '{($system): {version: $version, url: $url, sha256: $sha256}}' >> "$entries"
done

jq -s 'add' "$entries" > "$out"
jq -e 'length > 0' "$out" > /dev/null

mv "$out" sources.json
cat sources.json
