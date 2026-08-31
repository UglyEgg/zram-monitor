// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import org.kde.plasma.plasma5support as Plasma5Support

QtObject {
    id: job

    property string command: ""
    readonly property bool busy: command.length > 0

    signal finished(var data)

    function start(nextCommand) {
        var requested = String(nextCommand || "");
        if (requested.length === 0 || busy) {
            return false;
        }
        command = requested;
        process.disconnectSource(requested);
        process.connectSource(requested);
        return true;
    }

    function cancel() {
        var previous = command;
        command = "";
        if (previous.length > 0) {
            process.disconnectSource(previous);
        }
    }

    property Plasma5Support.DataSource process: Plasma5Support.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: function (sourceName, data) {
            disconnectSource(sourceName);
            if (sourceName !== job.command) {
                return;
            }
            job.command = "";
            job.finished(data);
        }
    }

    Component.onDestruction: cancel()
}
