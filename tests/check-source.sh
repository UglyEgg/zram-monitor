#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$project_root/metadata.json" <<'PY'
import json
import re
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    metadata = json.load(handle)

plugin = metadata["KPlugin"]
assert metadata["KPackageStructure"] == "Plasma/Applet"
assert metadata["X-Plasma-API-Minimum-Version"] == "6.0"
assert "X-Plasma-MainScript" not in metadata
assert plugin["Id"] == "quest.entropy.zrammonitor"
assert plugin["License"] == "GPL-3.0-or-later"
assert re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:[-+][0-9A-Za-z.-]+)?", plugin["Version"])
assert plugin["Website"] == "https://github.com/uglyegg/zram-monitor"
assert plugin["BugReportUrl"] == "https://github.com/uglyegg/zram-monitor/issues"
PY

if grep -R -n --exclude-dir=.git --exclude=CHANGELOG.md 'io\.github\.uglyegg\.zrammonitor' "$project_root"; then
    printf '%s\n' 'Legacy plugin ID remains in the repository.' >&2
    exit 1
fi

for required_path in \
    contents/config/config.qml \
    contents/config/main.xml \
    contents/tools/zram-monitor-snapshot \
    contents/ui/CompactRepresentation.qml \
    contents/ui/FullRepresentation.qml \
    contents/ui/main.qml \
    LICENSES/GPL-3.0-or-later.txt \
    metadata.json; do
    test -f "$project_root/$required_path"
done

test -x "$project_root/contents/tools/zram-monitor-snapshot"
test -x "$project_root/scripts/build-release.sh"

find "$project_root/contents/tools" "$project_root/scripts" "$project_root/tests" \
    -type f -name '*.sh' -exec sh -n {} \;

printf '%s\n' 'Source structure and metadata are valid.'
