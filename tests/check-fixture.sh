#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later

set -eu

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
fixture_root="$project_root/tests/fixtures/active-swap-only"

snapshot=$(
    ZRAM_MONITOR_SYS_BLOCK_ROOT="$fixture_root/sys/block" \
    ZRAM_MONITOR_PROC_ROOT="$fixture_root/proc" \
    /bin/sh "$project_root/contents/tools/zram-monitor-snapshot"
)

printf '%s\n' "$snapshot" | python3 -c '
import json
import sys

payload = json.load(sys.stdin)
assert payload["ok"] is True
assert payload["devices"] == "zram0"
assert payload["algorithm"] == "zstd"
assert payload["diskSizeBytes"] == 8192
assert payload["logicalBytes"] == 4096
assert payload["physicalBytes"] == 1536
assert payload["readSectors"] == 100
assert payload["writeSectors"] == 200
assert payload["memTotalBytes"] == 10240000
assert payload["memAvailableBytes"] == 4096000
assert payload["psiSomeAvg10"] == 0
'

printf '%s\n' 'Fixture snapshot is valid.'
