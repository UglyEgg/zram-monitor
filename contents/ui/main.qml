// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import org.kde.notification
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "js/Metrics.js" as Metrics

PlasmoidItem {
    id: root

    property bool ready: false
    property string errorMessage: ""

    property string devices: ""
    property string algorithm: ""
    property double diskSizeBytes: 0
    property double logicalBytes: 0
    property double physicalBytes: 0
    property double memTotalBytes: 0
    property double memAvailableBytes: 0
    property double psiSomeAvg10: 0
    property double swapInBytesPerSecond: 0
    property double swapOutBytesPerSecond: 0

    property double lastTimestampMs: 0
    property double lastReadSectors: 0
    property double lastWriteSectors: 0
    property double pressureDurationMs: 0
    property string previousHealthState: "unavailable"

    property var swapInHistory: []
    property var swapOutHistory: []
    property var pressureHistory: []

    readonly property int dashboardWidth: 430
    readonly property int dashboardHeight: 350
    readonly property int historyWindowMinutes: 15
    readonly property double savedBytes: Math.max(0, logicalBytes - physicalBytes)
    readonly property double systemRamUsedBytes: Math.max(0, memTotalBytes - memAvailableBytes)
    readonly property double effectiveRatio: physicalBytes > 0 ? logicalBytes / physicalBytes : 0
    readonly property double totalSwapRate: swapInBytesPerSecond + swapOutBytesPerSecond
    readonly property int refreshIntervalSeconds: Math.max(1, Math.min(30, Plasmoid.configuration.refreshInterval))
    readonly property int pressureThresholdPercent: Math.max(1, Math.min(100, Plasmoid.configuration.pressureThreshold))
    readonly property int sustainDurationSeconds: Math.max(5, Math.min(300, Plasmoid.configuration.sustainSeconds))
    readonly property bool pressureElevated: psiSomeAvg10 >= pressureThresholdPercent
    readonly property bool trafficActive: totalSwapRate >= 1024 * 1024
    readonly property bool sustainedPressure: pressureDurationMs >= sustainDurationSeconds * 1000
    readonly property string healthState: {
        if (!ready)
            return "unavailable";
        if (sustainedPressure)
            return "critical";
        if (pressureElevated && trafficActive)
            return "warning";
        if (trafficActive)
            return "active";
        return "healthy";
    }
    readonly property string statusText: {
        switch (healthState) {
        case "critical":
            return i18n("Thrashing");
        case "warning":
            return i18n("Pressure rising");
        case "active":
            return i18n("Active");
        case "healthy":
            return i18n("Healthy");
        default:
            return i18n("Unavailable");
        }
    }
    readonly property string interpretation: {
        if (!ready)
            return errorMessage || i18n("zram data is unavailable.");
        if (healthState === "critical")
            return i18n("Sustained swap traffic and memory pressure indicate thrashing.");
        if (healthState === "warning")
            return i18n("Pressure is elevated while zram is moving pages.");
        if (healthState === "active")
            return i18n("zram is moving pages, but memory pressure remains low.");
        return i18n("zram is avoiding %1 of physical RAM without sustained pressure.", Metrics.formatBytes(savedBytes));
    }
    readonly property string summaryMessage: {
        switch (healthState) {
        case "critical":
            return i18n("Sustained pressure and swap traffic");
        case "warning":
            return i18n("Pressure is rising while zram is active");
        case "active":
            return i18n("Compressing pages; memory pressure is low");
        case "healthy":
            return i18n("Ready; no sustained memory pressure");
        default:
            return errorMessage || i18n("zram data is unavailable");
        }
    }

    readonly property string snapshotPath: {
        var value = Qt.resolvedUrl("../tools/zram-monitor-snapshot").toString();
        return decodeURIComponent(value.replace(/^file:\/\//, ""));
    }
    readonly property string snapshotCommand: "/bin/sh " + shellQuote(snapshotPath)

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.title: i18n("zRAM Monitor")
    Plasmoid.icon: "memory"
    Plasmoid.status: healthState === "critical" || healthState === "warning" ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.ActiveStatus
    Plasmoid.configurationRequired: false
    Plasmoid.hasConfigurationInterface: true

    toolTipMainText: i18n("zRAM Monitor — %1", statusText)
    toolTipSubText: ready ? i18n("%1 RAM avoided · %2 effective", Metrics.formatBytes(savedBytes), Metrics.formatRatio(effectiveRatio)) : interpretation
    toolTipTextFormat: Text.PlainText

    switchWidth: dashboardWidth
    switchHeight: dashboardHeight
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : null

    compactRepresentation: CompactRepresentation {
        monitor: root
    }
    fullRepresentation: FullRepresentation {
        monitor: root
        designWidth: root.dashboardWidth
        designHeight: root.dashboardHeight
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function historyLimit() {
        return Math.max(30, Math.round(historyWindowMinutes * 60 / refreshIntervalSeconds));
    }

    function refresh() {
        snapshotJob.start(snapshotCommand);
    }

    function openConfiguration() {
        var configureAction = Plasmoid.internalAction("configure");
        if (configureAction) {
            configureAction.trigger();
        }
    }

    function acceptSnapshot(snapshot) {
        if (!snapshot.ok) {
            ready = false;
            errorMessage = String(snapshot.error || i18n("zram data is unavailable."));
            return;
        }

        var timestamp = Date.now();
        var readSectors = Metrics.finiteNumber(snapshot.readSectors);
        var writeSectors = Metrics.finiteNumber(snapshot.writeSectors);
        var elapsedSeconds = lastTimestampMs > 0 ? (timestamp - lastTimestampMs) / 1000 : 0;

        if (elapsedSeconds > 0 && elapsedSeconds < 120) {
            swapInBytesPerSecond = Math.max(0, readSectors - lastReadSectors) * 512 / elapsedSeconds;
            swapOutBytesPerSecond = Math.max(0, writeSectors - lastWriteSectors) * 512 / elapsedSeconds;
        } else {
            swapInBytesPerSecond = 0;
            swapOutBytesPerSecond = 0;
        }

        lastTimestampMs = timestamp;
        lastReadSectors = readSectors;
        lastWriteSectors = writeSectors;

        devices = String(snapshot.devices || "");
        algorithm = String(snapshot.algorithm || "—");
        diskSizeBytes = Metrics.finiteNumber(snapshot.diskSizeBytes);
        logicalBytes = Metrics.finiteNumber(snapshot.logicalBytes);
        physicalBytes = Metrics.finiteNumber(snapshot.physicalBytes);
        memTotalBytes = Metrics.finiteNumber(snapshot.memTotalBytes);
        memAvailableBytes = Metrics.finiteNumber(snapshot.memAvailableBytes);
        psiSomeAvg10 = Metrics.finiteNumber(snapshot.psiSomeAvg10);
        ready = true;
        errorMessage = "";

        var intervalMs = refreshIntervalSeconds * 1000;
        if (pressureElevated && trafficActive) {
            pressureDurationMs = Math.min(sustainDurationSeconds * 1000, pressureDurationMs + (elapsedSeconds > 0 ? elapsedSeconds * 1000 : intervalMs));
        } else {
            pressureDurationMs = 0;
        }

        var limit = historyLimit();
        swapInHistory = Metrics.appendHistory(swapInHistory, swapInBytesPerSecond, limit);
        swapOutHistory = Metrics.appendHistory(swapOutHistory, swapOutBytesPerSecond, limit);
        pressureHistory = Metrics.appendHistory(pressureHistory, psiSomeAvg10, limit);

        if (healthState === "critical" && previousHealthState !== "critical" && Plasmoid.configuration.notificationsEnabled) {
            pressureNotification.title = i18n("zram pressure is sustained");
            pressureNotification.text = interpretation;
            pressureNotification.sendEvent();
        }
        previousHealthState = healthState;
    }

    onExpandedChanged: {
        if (expanded)
            refresh();
    }

    Timer {
        interval: root.refreshIntervalSeconds * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    ExecutableJob {
        id: snapshotJob
        onFinished: function (data) {
            var exitCode = Number(data && data["exit code"]);
            if (!isFinite(exitCode) || exitCode !== 0) {
                root.ready = false;
                root.errorMessage = i18n("The zram snapshot helper failed.");
                return;
            }
            root.acceptSnapshot(Metrics.parseSnapshot(data["stdout"]));
        }
    }

    Notification {
        id: pressureNotification
        componentName: "plasma_workspace"
        eventId: "notification"
        iconName: "data-warning"
        flags: Notification.Persistent | Notification.SkipGrouping | Notification.DefaultEvent
        urgency: Notification.HighUrgency
    }
}
