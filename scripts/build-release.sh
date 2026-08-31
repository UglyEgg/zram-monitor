#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
project_parent=$(dirname -- "$project_root")
project_name=$(basename -- "$project_root")
dist_dir=${DIST_DIR:-"$project_root/dist"}
temporary_dir=$(mktemp -d)
trap 'rm -rf -- "$temporary_dir"' EXIT HUP INT TERM

version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["KPlugin"]["Version"])' "$project_root/metadata.json")
plugin_id=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["KPlugin"]["Id"])' "$project_root/metadata.json")

case "$plugin_id" in
    ''|*[!0-9A-Za-z._-]*)
        printf 'Invalid plugin ID in metadata.json: %s\n' "$plugin_id" >&2
        exit 1
        ;;
esac

case "$version" in
    ''|*[!0-9A-Za-z.-]*)
        printf 'Invalid version in metadata.json: %s\n' "$version" >&2
        exit 1
        ;;
esac

plasmoid_name="$plugin_id-$version.plasmoid"
source_name="$project_name-$version-source.tar.gz"

(
    cd -- "$project_root"
    zip -qr "$temporary_dir/$plasmoid_name" contents LICENSES metadata.json
)

tar \
    --exclude="$project_name/.git" \
    --exclude="$project_name/dist" \
    --exclude='*.jsc' \
    --exclude='*.qmlc' \
    -C "$project_parent" \
    -czf "$temporary_dir/$source_name" \
    "$project_name"

unzip -t "$temporary_dir/$plasmoid_name" >/dev/null
mkdir -p -- "$dist_dir"
mv -- "$temporary_dir/$plasmoid_name" "$dist_dir/$plasmoid_name"
mv -- "$temporary_dir/$source_name" "$dist_dir/$source_name"
(
    cd -- "$dist_dir"
    sha256sum "$plasmoid_name" "$source_name" > SHA256SUMS
)

printf 'Created %s\n' "$dist_dir/$plasmoid_name"
printf 'Created %s\n' "$dist_dir/$source_name"
printf 'Created %s\n' "$dist_dir/SHA256SUMS"
