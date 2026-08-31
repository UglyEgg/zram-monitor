// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import "js/Metrics.js" as Metrics

Item {
    id: compact

    required property var monitor

    Kirigami.Theme.inherit: true

    readonly property bool showRatio: Plasmoid.configuration.showPanelRatio
    readonly property color localStatusColor: {
        switch (monitor.healthState) {
        case "critical":
            return Kirigami.Theme.negativeTextColor;
        case "warning":
            return Kirigami.Theme.neutralTextColor;
        case "active":
            return Kirigami.Theme.highlightColor;
        case "healthy":
            return Kirigami.Theme.positiveTextColor;
        default:
            return Kirigami.Theme.disabledTextColor;
        }
    }
    readonly property color symbolicColor: monitor.healthState === "critical" || monitor.healthState === "warning" ? localStatusColor : Kirigami.Theme.textColor

    Layout.minimumWidth: Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? height : Kirigami.Units.gridUnit * 2
    Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? width : Kirigami.Units.gridUnit * 2
    Layout.preferredWidth: Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? (showRatio ? Kirigami.Units.gridUnit * 3.8 : height) : Kirigami.Units.gridUnit * 2
    Layout.preferredHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? (showRatio ? Kirigami.Units.gridUnit * 3.8 : width) : Kirigami.Units.gridUnit * 2

    Canvas {
        id: compressionIcon

        width: Math.max(18, Math.min(24, Math.min(compact.width, compact.height) * 0.78))
        height: width
        x: compact.showRatio ? Math.max(0, (Math.min(compact.width, compact.height) - width) / 2) : (compact.width - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        antialiasing: true

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

        onPaint: {
            var context = getContext("2d");
            context.clearRect(0, 0, width, height);
            context.save();
            context.scale(width / 24, height / 24);
            context.strokeStyle = compact.symbolicColor;
            context.lineWidth = 1.7;
            context.lineCap = "round";
            context.lineJoin = "round";

            roundRect(context, 3.5, 4.5, 17, 4, 2);
            context.stroke();

            context.beginPath();
            context.moveTo(12, 9.5);
            context.lineTo(12, 13.7);
            context.moveTo(9.8, 11.5);
            context.lineTo(12, 13.7);
            context.lineTo(14.2, 11.5);
            context.stroke();

            roundRect(context, 7.5, 15.5, 9, 4, 2);
            context.stroke();
            context.restore();
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Column {
        visible: compact.showRatio && width > 0
        anchors.left: compressionIcon.right
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: -2

        Text {
            width: parent.width
            text: Metrics.formatRatio(monitor.effectiveRatio)
            color: compact.symbolicColor
            font.bold: true
            font.pixelSize: Math.max(10, Math.min(14, compact.height * 0.35))
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: monitor.statusText
            color: Kirigami.Theme.textColor
            opacity: 0.72
            font.pixelSize: Math.max(8, Math.min(10, compact.height * 0.24))
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: i18n("Open zRAM Monitor")
        onClicked: monitor.expanded = !monitor.expanded
    }

    onSymbolicColorChanged: compressionIcon.requestPaint()
}
