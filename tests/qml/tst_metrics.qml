// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtTest
import "../../contents/ui/js/Metrics.js" as Metrics

TestCase {
    name: "Metrics"

    readonly property var validSnapshot: ({
        ok: true,
        devices: "zram0",
        algorithm: "zstd",
        diskSizeBytes: 8192,
        logicalBytes: 4096,
        physicalBytes: 1536,
        readSectors: 100,
        writeSectors: 200,
        memTotalBytes: 10240000,
        memAvailableBytes: 4096000,
        psiSomeAvg10: 0.25
    })

    function snapshotWith(changes) {
        var snapshot = Object.assign({}, validSnapshot)
        for (var key in changes)
            snapshot[key] = changes[key]
        return snapshot
    }

    function test_parseValidSnapshot() {
        var parsed = Metrics.parseSnapshot(JSON.stringify(validSnapshot))
        verify(parsed.ok)
        compare(parsed.logicalBytes, 4096)
    }

    function test_preserveUnavailableReason() {
        var parsed = Metrics.parseSnapshot('{"ok":false,"error":"No active zram swap device was found."}')
        verify(!parsed.ok)
        compare(parsed.error, "No active zram swap device was found.")
    }

    function test_rejectMissingMetric() {
        var snapshot = snapshotWith({})
        delete snapshot.physicalBytes
        verify(!Metrics.parseSnapshot(JSON.stringify(snapshot)).ok)
    }

    function test_rejectNegativeMetric() {
        var snapshot = snapshotWith({ physicalBytes: -1 })
        verify(!Metrics.parseSnapshot(JSON.stringify(snapshot)).ok)
    }

    function test_rejectInconsistentMetric() {
        var snapshot = snapshotWith({ memAvailableBytes: validSnapshot.memTotalBytes + 1 })
        verify(!Metrics.parseSnapshot(JSON.stringify(snapshot)).ok)
        snapshot = snapshotWith({ psiSomeAvg10: 100.01 })
        verify(!Metrics.parseSnapshot(JSON.stringify(snapshot)).ok)
    }

    function test_rejectInvalidEnvelope() {
        verify(!Metrics.parseSnapshot('{"ok":"yes"}').ok)
        verify(!Metrics.parseSnapshot('[]').ok)
        verify(!Metrics.parseSnapshot('not json').ok)
        verify(!Metrics.parseSnapshot('').ok)
    }
}
