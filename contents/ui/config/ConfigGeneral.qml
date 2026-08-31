// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: page

    property alias cfg_refreshInterval: refreshInterval.value
    property alias cfg_showPanelRatio: showPanelRatio.checked
    property alias cfg_notificationsEnabled: notificationsEnabled.checked
    property alias cfg_pressureThreshold: pressureThreshold.value
    property alias cfg_sustainSeconds: sustainSeconds.value

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: refreshInterval
            Kirigami.FormData.label: i18n("Refresh interval:")
            from: 1
            to: 30
            editable: true
            textFromValue: function (value) {
                return i18np("%1 second", "%1 seconds", value);
            }
            valueFromText: function (text) {
                var parsed = parseInt(text, 10);
                return isNaN(parsed) ? 15 : parsed;
            }
        }

        QQC2.CheckBox {
            id: showPanelRatio
            Kirigami.FormData.label: i18n("Panel:")
            text: i18n("Show compression ratio in the panel")
        }

        QQC2.CheckBox {
            id: notificationsEnabled
            Kirigami.FormData.label: i18n("Alerts:")
            text: i18n("Notify on sustained pressure")
        }

        QQC2.SpinBox {
            id: pressureThreshold
            Kirigami.FormData.label: i18n("Memory pressure threshold:")
            from: 1
            to: 100
            editable: true
            textFromValue: function (value) {
                return value + "%";
            }
            valueFromText: function (text) {
                var parsed = parseInt(text, 10);
                return isNaN(parsed) ? 20 : parsed;
            }
        }

        QQC2.SpinBox {
            id: sustainSeconds
            Kirigami.FormData.label: i18n("Sustained for:")
            from: 5
            to: 300
            stepSize: 5
            editable: true
            textFromValue: function (value) {
                return i18np("%1 second", "%1 seconds", value);
            }
            valueFromText: function (text) {
                var parsed = parseInt(text, 10);
                return isNaN(parsed) ? 30 : parsed;
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
            text: i18n("The system RAM-used total already includes zram's physical cost. “Swapped pages” is the uncompressed amount held inside zram; do not add it to RAM used.")
            wrapMode: Text.WordWrap
            opacity: 0.75
        }

        QQC2.Label {
            Layout.fillWidth: true
            Kirigami.FormData.isSection: true
            text: i18n("A pressure alert requires both elevated memory PSI and active zram traffic. Capacity alone never triggers an alert.")
            wrapMode: Text.WordWrap
            opacity: 0.75
        }
    }
}
