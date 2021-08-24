/********************************************************************
 This file is part of the KDE project.

Copyright (C) 2014 Aleix Pol Gonzalez <aleixpol@blue-systems.com>

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

import QtQuick 2.6
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore

import org.kde.plasma.private.sessions 2.0
import "../components"

Item {
    id: wallpaperFader
    property Item clock
    property Item clockcenter
    property Item mainStack
    property Item footer
    property Item battery
    property Item ferenOSLogo
    property Item mediaControls
    property Item mediaAlbumArt
    //property alias source: wallpaperBlur.source
    //state: lockScreenRoot.uiVisible ? "on" : "off"
    property real factor: 0
    //readonly property bool lightBackground: Math.max(PlasmaCore.ColorScope.backgroundColor.r, PlasmaCore.ColorScope.backgroundColor.g, PlasmaCore.ColorScope.backgroundColor.b) > 0.5

    Behavior on factor {
        NumberAnimation {
            target: wallpaperFader
            property: "factor"
            duration: PlasmaCore.Units.veryLongDuration * 2
            easing.type: Easing.InOutQuad
        }
    }
//     FastBlur {
//         id: wallpaperBlur
//         anchors.fill: parent
//         radius: 50 * wallpaperFader.factor
//     }
    Rectangle {
        id: wallpaperShader
        anchors.fill: parent
        color: PlasmaCore.ColorScope.backgroundColor
    }

    states: [
        State {
            name: "on"
            PropertyChanges {
                target: mainStack
                opacity: 1
            }
            PropertyChanges {
                target: footer
                opacity: 1
            }
            PropertyChanges {
                target: wallpaperFader
                opacity: 0
            }
            //PropertyChanges {
                //target: clock.shadow
                //opacity: 0
            //}
            PropertyChanges {
                target: clock
                opacity: 1
            }
            PropertyChanges {
                target: clockcenter
                opacity: 0
            }
            PropertyChanges {
                target: battery
                opacity: 0
            }
            PropertyChanges {
                target: ferenOSLogo
                opacity: 1
            }
            PropertyChanges {
                target: mediaControls
                opacity: 1
            }
            PropertyChanges {
                target: mediaAlbumArt
                x: mediaControls.x + mediaControls.width + PlasmaCore.Units.smallSpacing * 4
            }
        },
        State {
            name: "off"
            PropertyChanges {
                target: mainStack
                opacity: 0
            }
            PropertyChanges {
                target: footer
                opacity: 0
            }
            PropertyChanges {
                target: wallpaperFader
                opacity: 0.6
            }
            //PropertyChanges {
                //target: clock.shadow
                //opacity: wallpaperFader.alwaysShowClock ? 1 : 0
            //}
            PropertyChanges {
                target: clock
                opacity: 0
            }
            PropertyChanges {
                target: clockcenter
                opacity: 1
            }
            PropertyChanges {
                target: battery
                opacity: 1
            }
            PropertyChanges {
                target: ferenOSLogo
                opacity: 0
            }
            PropertyChanges {
                target: mediaControls
                opacity: 0
            }
            PropertyChanges {
                target: mediaAlbumArt
                x: mediaControls.x
            }
        }
    ]
    transitions: [
        Transition {
            from: "off"
            to: "on"
            //Note: can't use animators as they don't play well with parallelanimations
            NumberAnimation {
                targets: [mainStack, footer, clock, clockcenter, wallpaperFader, battery, ferenOSLogo, mediaControls]
                property: "opacity"
                duration: PlasmaCore.Units.veryLongDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: mediaAlbumArt
                property: "x"
                duration: PlasmaCore.Units.veryLongDuration
                easing.type: Easing.InOutQuad
            }
        },
        Transition {
            from: "on"
            to: "off"
            NumberAnimation {
                targets: [mainStack, footer, clock, clockcenter, wallpaperFader, battery, ferenOSLogo, mediaControls]
                property: "opacity"
                duration: PlasmaCore.Units.veryLongDuration
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: mediaAlbumArt
                property: "x"
                duration: PlasmaCore.Units.veryLongDuration
                easing.type: Easing.InOutQuad
            }
        }
    ]
}
