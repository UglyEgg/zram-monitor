// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "js/Metrics.js" as Metrics

Item {
    id: view

    required property var monitor
    required property int designWidth
    required property int designHeight

    Kirigami.Theme.inherit: true

    readonly property color themeText: Kirigami.Theme.textColor
    readonly property color themeHighlight: Kirigami.Theme.highlightColor
    readonly property color themePositive: Kirigami.Theme.positiveTextColor
    readonly property color themeNeutral: Kirigami.Theme.neutralTextColor
    readonly property color themeNegative: Kirigami.Theme.negativeTextColor
    readonly property color themeDisabled: Kirigami.Theme.disabledTextColor
    readonly property color statusColor: {
        switch (monitor.healthState) {
        case "critical":
            return themeNegative;
        case "warning":
            return themeNeutral;
        case "active":
            return themeHighlight;
        case "healthy":
            return themePositive;
        default:
            return themeDisabled;
        }
    }

    Layout.minimumWidth: designWidth - 40
    Layout.minimumHeight: designHeight - 20
    Layout.preferredWidth: designWidth
    Layout.preferredHeight: designHeight

    Accessible.name: i18n("zRAM memory map")
    Accessible.description: i18n("%1 of swapped pages occupy %2 of system RAM, avoiding %3.", Metrics.formatBytes(monitor.logicalBytes), Metrics.formatBytes(monitor.physicalBytes), Metrics.formatBytes(monitor.savedBytes))

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    function roundRect(context, x, y, width, height, radius) {
        var right = x + width;
        var bottom = y + height;
        context.beginPath();
        context.moveTo(x + radius, y);
        context.lineTo(right - radius, y);
        context.quadraticCurveTo(right, y, right, y + radius);
        context.lineTo(right, bottom - radius);
        context.quadraticCurveTo(right, bottom, right - radius, bottom);
        context.lineTo(x + radius, bottom);
        context.quadraticCurveTo(x, bottom, x, bottom - radius);
        context.lineTo(x, y + radius);
        context.quadraticCurveTo(x, y, x + radius, y);
        context.closePath();
    }

    function label(context, text, x, y, size, color, alignment, weight) {
        context.fillStyle = color;
        context.textAlign = alignment || "left";
        context.font = (weight || 400) + " " + size + "px '" + Kirigami.Theme.defaultFont.family + "'";
        context.fillText(text, x, y);
    }

    function drawSeries(context, values, maximum, x, y, width, height, color, lineWidth) {
        if (!values || values.length === 0 || maximum <= 0)
            return;
        if (values.length === 1) {
            var singleY = y + height - height * Math.min(1, Math.max(0, Number(values[0]) || 0) / maximum);
            context.fillStyle = color;
            context.beginPath();
            context.arc(x + width, singleY, Math.max(2, lineWidth), 0, Math.PI * 2);
            context.fill();
            return;
        }
        context.beginPath();
        for (var index = 0; index < values.length; ++index) {
            var pointX = x + width * index / (values.length - 1);
            var pointY = y + height - height * Math.min(1, Math.max(0, Number(values[index]) || 0) / maximum);
            if (index === 0)
                context.moveTo(pointX, pointY);
            else
                context.lineTo(pointX, pointY);
        }
        context.strokeStyle = color;
        context.lineWidth = lineWidth;
        context.lineJoin = "round";
        context.lineCap = "round";
        context.stroke();
    }

    function trafficHistory() {
        var incoming = monitor.swapInHistory || [];
        var outgoing = monitor.swapOutHistory || [];
        var count = Math.max(incoming.length, outgoing.length);
        var result = [];
        for (var index = 0; index < count; ++index)
            result.push((Number(incoming[index]) || 0) + (Number(outgoing[index]) || 0));
        return result;
    }

    Canvas {
        id: memoryMap
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var context = getContext("2d");
            var baseWidth = view.designWidth;
            var baseHeight = view.designHeight;
            var scaleX = width / baseWidth;
            var scaleY = height / baseHeight;
            var chartX = 12;
            var chartWidth = baseWidth - 24;
            var logical = Math.max(0, monitor.logicalBytes);
            var physical = Math.max(0, monitor.physicalBytes);
            var saved = Math.max(0, monitor.savedBytes);
            var totalRam = Math.max(0, monitor.memTotalBytes);
            var usedRam = Math.max(0, monitor.systemRamUsedBytes);
            var otherRam = Math.max(0, usedRam - physical);
            var availableRam = Math.max(0, totalRam - usedRam);
            var physicalFraction = logical > 0 ? Math.min(1, physical / logical) : 0;
            var otherFraction = totalRam > 0 ? Math.min(1, otherRam / totalRam) : 0;
            var zramFraction = totalRam > 0 ? Math.min(1 - otherFraction, physical / totalRam) : 0;
            var traffic = trafficHistory();
            var trafficMaximum = Math.max(1024 * 1024, Metrics.maxHistory(traffic, 0));

            context.save();
            context.clearRect(0, 0, width, height);
            context.scale(scaleX, scaleY);
            context.textBaseline = "alphabetic";

            label(context, i18n("zRAM Monitor"), 12, 27, 18, themeText, "left", 600);
            context.fillStyle = statusColor;
            context.beginPath();
            context.arc(143, 21, 4, 0, Math.PI * 2);
            context.fill();
            label(context, monitor.statusText, 153, 26, 13, statusColor, "left", 600);

            context.strokeStyle = withAlpha(themeText, 0.13);
            context.lineWidth = 1;
            context.beginPath();
            context.moveTo(12, 42.5);
            context.lineTo(418, 42.5);
            context.stroke();

            label(context, i18n("COMPRESSED MEMORY"), 12, 61, 10, withAlpha(themeText, 0.58), "left", 600);
            label(context, Metrics.formatBytes(logical), 12, 86, 22, themeText, "left", 600);
            label(context, i18n("swapped pages"), 92, 84, 12, withAlpha(themeText, 0.68), "left", 400);
            label(context, i18n("%1 effective", Metrics.formatRatio(monitor.effectiveRatio)), 418, 84, 13, statusColor, "right", 600);

            roundRect(context, chartX, 96, chartWidth, 23, 11.5);
            context.fillStyle = withAlpha(themePositive, 0.22);
            context.fill();
            roundRect(context, chartX, 96, Math.max(23, chartWidth * physicalFraction), 23, 11.5);
            context.fillStyle = withAlpha(themeHighlight, 0.88);
            context.fill();

            context.fillStyle = themeHighlight;
            context.beginPath();
            context.arc(16, 136, 4, 0, Math.PI * 2);
            context.fill();
            label(context, i18n("zram RAM"), 26, 140, 12, withAlpha(themeText, 0.68), "left", 400);
            label(context, Metrics.formatBytes(physical), 89, 140, 13, themeText, "left", 600);
            context.fillStyle = themePositive;
            context.beginPath();
            context.arc(315, 136, 4, 0, Math.PI * 2);
            context.fill();
            label(context, i18n("avoided"), 325, 140, 12, withAlpha(themeText, 0.68), "left", 400);
            label(context, Metrics.formatBytes(saved), 418, 140, 13, themeText, "right", 600);

            var sourceCenter = chartX + chartWidth * physicalFraction / 2;
            var targetCenter = chartX + chartWidth * (otherFraction + zramFraction / 2);
            context.strokeStyle = withAlpha(themeHighlight, 0.30);
            context.lineWidth = 2;
            context.beginPath();
            context.moveTo(sourceCenter, 120);
            context.bezierCurveTo(sourceCenter, 151, targetCenter, 151, targetCenter, 178);
            context.stroke();

            label(context, i18n("SYSTEM RAM"), 12, 169, 10, withAlpha(themeText, 0.58), "left", 600);
            label(context, i18n("%1 of %2 used", Metrics.formatBytes(usedRam), Metrics.formatBytes(totalRam)), 418, 169, 13, themeText, "right", 600);

            roundRect(context, chartX, 178, chartWidth, 23, 11.5);
            context.fillStyle = withAlpha(themeText, 0.09);
            context.fill();
            context.save();
            roundRect(context, chartX, 178, chartWidth, 23, 11.5);
            context.clip();
            context.fillStyle = withAlpha(themeText, 0.36);
            context.fillRect(chartX, 178, chartWidth * otherFraction, 23);
            context.fillStyle = withAlpha(themeHighlight, 0.88);
            context.fillRect(chartX + chartWidth * otherFraction, 178, chartWidth * zramFraction, 23);
            context.restore();

            context.fillStyle = withAlpha(themeText, 0.36);
            context.beginPath();
            context.arc(16, 218, 4, 0, Math.PI * 2);
            context.fill();
            label(context, i18n("other %1", Metrics.formatBytes(otherRam)), 26, 222, 12, withAlpha(themeText, 0.68), "left", 400);
            context.fillStyle = themeHighlight;
            context.beginPath();
            context.arc(169, 218, 4, 0, Math.PI * 2);
            context.fill();
            label(context, i18n("zram %1", Metrics.formatBytes(physical)), 179, 222, 12, withAlpha(themeText, 0.68), "left", 400);
            label(context, i18n("%1 available", Metrics.formatBytes(availableRam)), 418, 222, 12, withAlpha(themeText, 0.68), "right", 400);

            context.strokeStyle = withAlpha(themeText, 0.13);
            context.lineWidth = 1;
            context.beginPath();
            context.moveTo(12, 238.5);
            context.lineTo(418, 238.5);
            context.stroke();

            context.fillStyle = statusColor;
            context.beginPath();
            context.arc(16, 255, 4, 0, Math.PI * 2);
            context.fill();
            label(context, monitor.summaryMessage, 26, 259, 12, themeText, "left", 400);
            label(context, i18n("PSI %1%", monitor.psiSomeAvg10.toFixed(1)), 418, 259, 12, withAlpha(themeText, 0.65), "right", 400);

            label(context, i18np("%1 MINUTE", "%1 MINUTES", monitor.historyWindowMinutes), 12, 278, 10, withAlpha(themeText, 0.58), "left", 600);
            label(context, i18n("traffic %1  ·  pressure %2%", Metrics.formatRate(monitor.totalSwapRate), monitor.psiSomeAvg10.toFixed(1)), 418, 278, 11, withAlpha(themeText, 0.68), "right", 400);

            context.strokeStyle = withAlpha(themeText, 0.10);
            context.lineWidth = 1;
            for (var guide = 0; guide < 3; ++guide) {
                var guideY = 288.5 + guide * 15;
                context.beginPath();
                context.moveTo(12, guideY);
                context.lineTo(418, guideY);
                context.stroke();
            }
            drawSeries(context, traffic, trafficMaximum, 12, 288, 406, 30, themeHighlight, 2);
            drawSeries(context, monitor.pressureHistory || [], 100, 12, 288, 406, 30, statusColor, 1.5);

            label(context, monitor.ready ? i18n("%1 · %2 · %3", monitor.devices, monitor.algorithm, Metrics.formatBytes(monitor.diskSizeBytes)) : monitor.errorMessage, 12, 340, 11, withAlpha(themeText, 0.58), "left", 400);
            label(context, i18n("every %1 s", monitor.refreshIntervalSeconds), 418, 340, 11, withAlpha(themeText, 0.58), "right", 400);
            context.restore();
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Connections {
        target: monitor

        function onReadyChanged() {
            memoryMap.requestPaint();
        }
        function onErrorMessageChanged() {
            memoryMap.requestPaint();
        }
        function onDevicesChanged() {
            memoryMap.requestPaint();
        }
        function onAlgorithmChanged() {
            memoryMap.requestPaint();
        }
        function onDiskSizeBytesChanged() {
            memoryMap.requestPaint();
        }
        function onLogicalBytesChanged() {
            memoryMap.requestPaint();
        }
        function onPhysicalBytesChanged() {
            memoryMap.requestPaint();
        }
        function onMemTotalBytesChanged() {
            memoryMap.requestPaint();
        }
        function onMemAvailableBytesChanged() {
            memoryMap.requestPaint();
        }
        function onPsiSomeAvg10Changed() {
            memoryMap.requestPaint();
        }
        function onSwapInBytesPerSecondChanged() {
            memoryMap.requestPaint();
        }
        function onSwapOutBytesPerSecondChanged() {
            memoryMap.requestPaint();
        }
        function onSwapInHistoryChanged() {
            memoryMap.requestPaint();
        }
        function onSwapOutHistoryChanged() {
            memoryMap.requestPaint();
        }
        function onPressureHistoryChanged() {
            memoryMap.requestPaint();
        }
        function onHealthStateChanged() {
            memoryMap.requestPaint();
        }
    }

    Item {
        id: refreshAction
        width: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing
        height: width
        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.right: configureAction.left
        anchors.rightMargin: Kirigami.Units.smallSpacing
        z: 2

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.cornerRadius
            color: refreshMouse.containsMouse ? view.withAlpha(view.themeText, 0.10) : "transparent"
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.small
            height: width
            source: "view-refresh"
        }
        MouseArea {
            id: refreshMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: i18n("Refresh")
            onClicked: monitor.refresh()
        }
    }

    Item {
        id: configureAction
        width: Kirigami.Units.iconSizes.smallMedium + Kirigami.Units.smallSpacing
        height: width
        anchors.top: parent.top
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.right: parent.right
        anchors.rightMargin: Kirigami.Units.smallSpacing
        z: 2

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.cornerRadius
            color: configureMouse.containsMouse ? view.withAlpha(view.themeText, 0.10) : "transparent"
        }
        Kirigami.Icon {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.small
            height: width
            source: "configure"
        }
        MouseArea {
            id: configureMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: i18n("Configure")
            onClicked: monitor.openConfiguration()
        }
    }

    onThemeTextChanged: memoryMap.requestPaint()
    onThemeHighlightChanged: memoryMap.requestPaint()
    onThemePositiveChanged: memoryMap.requestPaint()
    onThemeNeutralChanged: memoryMap.requestPaint()
    onThemeNegativeChanged: memoryMap.requestPaint()
    onThemeDisabledChanged: memoryMap.requestPaint()
    onStatusColorChanged: memoryMap.requestPaint()
}
