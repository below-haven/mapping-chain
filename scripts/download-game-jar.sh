#!/usr/bin/env bash

set -euo pipefail

readonly MANIFEST_URL="http://gamemedia2.spiralknights.com/spiral/latest/getdown.txt"
readonly GAME_BASE_URL="http://gamemedia2.spiralknights.com/spiral"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(dirname -- "$SCRIPT_DIR")"
readonly OUTPUT_DIR="$REPO_ROOT/temp"

usage() {
  echo "Usage: $(basename -- "$0") [version]"
}

if (( $# > 1 )); then
  usage >&2
  exit 2
fi

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

version=${1:-}

if [[ -z $version ]]; then
  echo "Fetching latest game version..."
  manifest=$(curl --fail --silent --show-error --location "$MANIFEST_URL")
  version=$(
    awk -F '=' '
      /^[[:space:]]*version[[:space:]]*=/ {
        value = $2
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        print value
        exit
      }
    ' <<< "$manifest"
  )

  if [[ -z $version ]]; then
    echo "Error: could not find a version in $MANIFEST_URL" >&2
    exit 1
  fi
fi

if [[ ! $version =~ ^[0-9]+$ ]]; then
  echo "Error: version must contain digits only (received: $version)" >&2
  exit 2
fi

readonly version
readonly jar_url="$GAME_BASE_URL/$version/code/projectx-pcode.jar"
readonly output_file="$OUTPUT_DIR/$version.jar"
readonly partial_file="$output_file.part"

mkdir -p "$OUTPUT_DIR"
trap 'rm -f -- "$partial_file"' EXIT

echo "Downloading game version $version..."
curl --fail --show-error --location --output "$partial_file" "$jar_url"
mv -- "$partial_file" "$output_file"

echo "Downloaded to $output_file"
