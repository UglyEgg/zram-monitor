#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
snapshot=$(/bin/sh "$project_root/contents/tools/zram-monitor-snapshot")

printf '%s\n' "$snapshot" | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
assert isinstance(payload.get("ok"), bool)
if payload["ok"]:
    required = {
        "devices", "algorithm",
        "diskSizeBytes", "logicalBytes", "physicalBytes",
        "readSectors", "writeSectors", "memTotalBytes", "memAvailableBytes",
        "psiSomeAvg10",
    }
    missing = sorted(required.difference(payload))
    assert not missing, f"missing fields: {missing}"
    for key in required.difference({"devices", "algorithm"}):
        assert float(payload[key]) >= 0, f"negative field: {key}"
    assert payload["diskSizeBytes"] >= payload["logicalBytes"]
print(json.dumps(payload, indent=2, sort_keys=True))
'
