/********************************************************************
 This file is part of the KDE project.

Copyright (C) 2016 Kai Uwe Broulik <kde@privat.broulik.de>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************/

import QtQuick 2.5
import QtQuick.Layouts 1.1

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    visible: mpris2Source.hasPlayer
    implicitHeight: PlasmaCore.Units.gridUnit * 3
    implicitWidth: PlasmaCore.Units.gridUnit*7 // 2 + 2 + 3

    RowLayout {
        id: controlsRow
        anchors.fill: parent
        spacing: 0

        enabled: mpris2Source.canControl

        PlasmaCore.DataSource {
            id: mpris2Source

            readonly property string source: "@multiplex"
            readonly property var playerData: data[source]

            readonly property bool hasPlayer: sources.length > 1 && !!playerData
            readonly property string identity: hasPlayer ? playerData.Identity : ""
            readonly property bool playing: hasPlayer && playerData.PlaybackStatus === "Playing"
            readonly property bool canControl: hasPlayer && playerData.CanControl
            readonly property bool canGoBack: hasPlayer && playerData.CanGoPrevious
            readonly property bool canGoNext: hasPlayer && playerData.CanGoNext

            engine: "mpris2"
            connectedSources: [source]

            function startOperation(op) {
                var service = serviceForSource(source)
                var operation = service.operationDescription(op)
                return service.startOperationCall(operation)
            }

            function goPrevious() {
                startOperation("Previous");
            }
            function goNext() {
                startOperation("Next");
            }
            function playPause(source) {
                startOperation("PlayPause");
            }
        }

        PlasmaComponents3.ToolButton {
            focusPolicy: Qt.TabFocus
            enabled: mpris2Source.canGoBack
            Layout.preferredHeight: PlasmaCore.Units.gridUnit*2
            Layout.preferredWidth: Layout.preferredHeight
            icon.name: LayoutMirroring.enabled ? "media-skip-forward" : "media-skip-backward"
            onClicked: {
                fadeoutTimer.running = false
                mpris2Source.goPrevious()
            }
            visible: mpris2Source.canGoBack || mpris2Source.canGoNext
            Accessible.name: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Previous track")
        }

        PlasmaComponents3.ToolButton {
            focusPolicy: Qt.TabFocus
            Layout.fillHeight: true
            Layout.preferredWidth: height // make this button bigger
            icon.name: mpris2Source.playing ? "media-playback-pause" : "media-playback-start"
            onClicked: {
                fadeoutTimer.running = false
                mpris2Source.playPause()
            }
            Accessible.name: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Play or Pause media")
        }

        PlasmaComponents3.ToolButton {
            focusPolicy: Qt.TabFocus
            enabled: mpris2Source.canGoNext
            Layout.preferredHeight: PlasmaCore.Units.gridUnit*2
            Layout.preferredWidth: Layout.preferredHeight
            icon.name: LayoutMirroring.enabled ? "media-skip-backward" : "media-skip-forward"
            onClicked: {
                fadeoutTimer.running = false
                mpris2Source.goNext()
            }
            visible: mpris2Source.canGoBack || mpris2Source.canGoNext
            Accessible.name: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Next track")
        }
    }
}
