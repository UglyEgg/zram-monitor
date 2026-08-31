.pragma library

// SPDX-License-Identifier: GPL-3.0-or-later

function finiteNumber(value, fallback) {
    var number = Number(value)
    return isFinite(number) ? number : (fallback === undefined ? 0 : fallback)
}

function parseSnapshot(output) {
    var text = String(output || "").trim()
    if (text.length === 0) {
        return { ok: false, error: "The zram helper returned no data." }
    }

    try {
        var parsed = JSON.parse(text)
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
            return { ok: false, error: "The zram helper returned an invalid snapshot." }
        }
        if (typeof parsed.ok !== "boolean") {
            return { ok: false, error: "The zram helper returned an invalid snapshot." }
        }
        if (!parsed.ok) {
            return {
                ok: false,
                error: typeof parsed.error === "string" && parsed.error.length > 0
                    ? parsed.error : "zram data is unavailable."
            }
        }
        if (typeof parsed.devices !== "string" || typeof parsed.algorithm !== "string") {
            return { ok: false, error: "The zram helper returned an invalid snapshot." }
        }

        var numericFields = [
            "diskSizeBytes", "logicalBytes", "physicalBytes",
            "readSectors", "writeSectors", "memTotalBytes",
            "memAvailableBytes", "psiSomeAvg10"
        ]
        for (var index = 0; index < numericFields.length; ++index) {
            var value = parsed[numericFields[index]]
            if (typeof value !== "number" || !isFinite(value) || value < 0) {
                return { ok: false, error: "The zram helper returned an invalid snapshot." }
            }
        }
        if (parsed.logicalBytes > parsed.diskSizeBytes
                || parsed.memAvailableBytes > parsed.memTotalBytes
                || parsed.psiSomeAvg10 > 100) {
            return { ok: false, error: "The zram helper returned an inconsistent snapshot." }
        }
        return parsed
    } catch (error) {
        return { ok: false, error: "The zram helper returned malformed data." }
    }
}

function formatBytes(value) {
    var bytes = Math.max(0, finiteNumber(value))
    var units = ["B", "KiB", "MiB", "GiB", "TiB"]
    var unit = 0
    while (bytes >= 1024 && unit < units.length - 1) {
        bytes /= 1024
        unit += 1
    }
    var digits = unit >= 3 ? 1 : 0
    return bytes.toFixed(digits) + " " + units[unit]
}

function formatRate(value) {
    return formatBytes(value) + "/s"
}

function formatRatio(value) {
    var ratio = finiteNumber(value)
    return ratio > 0 ? ratio.toFixed(1) + "×" : "—"
}

function appendHistory(values, value, maximumLength) {
    var next = (values || []).concat([finiteNumber(value)])
    var overflow = next.length - Math.max(2, maximumLength)
    return overflow > 0 ? next.slice(overflow) : next
}

function maxHistory(values, floorValue) {
    var maximum = Math.max(0, finiteNumber(floorValue))
    var samples = values || []
    for (var index = 0; index < samples.length; ++index) {
        maximum = Math.max(maximum, finiteNumber(samples[index]))
    }
    return maximum
}
