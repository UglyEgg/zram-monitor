#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
plugin_id=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["KPlugin"]["Id"])' "$project_root/metadata.json")
test_data_home=$(mktemp -d)
trap 'rm -rf -- "$test_data_home"' EXIT HUP INT TERM

XDG_DATA_HOME="$test_data_home" kpackagetool6 --type Plasma/Applet --install "$project_root" >/dev/null
installed="$test_data_home/plasma/plasmoids/$plugin_id"

test -f "$installed/metadata.json"
test -f "$installed/contents/ui/main.qml"
test -f "$installed/contents/tools/zram-monitor-snapshot"

XDG_DATA_HOME="$test_data_home" kpackagetool6 --type Plasma/Applet --show "$plugin_id"
