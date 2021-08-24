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

import QtQuick 2.8
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.workspace.components 2.0 as PW

import org.kde.plasma.private.sessions 2.0
import "../components"

PlasmaCore.ColorScope {

    id: lockScreenUi
    // If we're using software rendering, draw outlines instead of shadows
    // See https://bugs.kde.org/show_bug.cgi?id=398317
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    readonly property bool lightBackground: Math.max(PlasmaCore.ColorScope.backgroundColor.r, PlasmaCore.ColorScope.backgroundColor.g, PlasmaCore.ColorScope.backgroundColor.b) > 0.5
    property bool showClock: typeof config === "undefined" || typeof config.showClock === "undefined" || config.showClock === true

    colorGroup: PlasmaCore.Theme.ComplementaryColorGroup

    Connections {
        target: authenticator
        function onFailed() {
            root.notification = i18nd("plasma_lookandfeel_org.kde.lookandfeel","Unlocking failed");
        }
        function onGraceLockedChanged() {
            if (!authenticator.graceLocked) {
                root.notification = "";
                root.clearPassword();
            }
        }
        function onMessage(msg) {
            root.notification = msg;
        }
        function onError(err) {
            root.notification = err;
        }
    }

    SessionManagement {
        id: sessionManagement
    }

    Connections {
        target: sessionManagement
        function onAboutToSuspend() {
            root.clearPassword();
        }
    }

    SessionsModel {
        id: sessionsModel
        showNewSessionEntry: false
    }

    PlasmaCore.DataSource {
        id: keystateSource
        engine: "keystate"
        connectedSources: "Caps Lock"
    }

    Loader {
        id: changeSessionComponent
        active: false
        source: "ChangeSession.qml"
        visible: false
    }


    MouseArea {
        id: lockScreenRoot

        property bool uiVisible: true
        property bool blockUI: mainStack.depth > 1 || mainBlock.mainPasswordBox.text.length > 0 || inputPanel.keyboardActive

        x: parent.x
        y: parent.y
        width: parent.width
        height: parent.height
        hoverEnabled: true
        drag.filterChildren: true
        onPressed: uiVisible = true;
        onPositionChanged: uiVisible = true;
        onUiVisibleChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }
        Keys.onEscapePressed: {
            if (showClock) {
                uiVisible = !uiVisible;
            } else {
                uiVisible = true;
            }
            if (inputPanel.keyboardActive) {
                inputPanel.showHide();
            }
            if (!uiVisible) {
                root.clearPassword();
            }
        }
        Keys.onPressed: {
            uiVisible = true;
            event.accepted = false;
        }
        Timer {
            id: fadeoutTimer
            interval: 10000
            onTriggered: {
                if (!lockScreenRoot.blockUI && showClock) {
                    lockScreenRoot.uiVisible = false;
                }
            }
        }

        Component.onCompleted: fadeoutTimer.restart()

        states: [
            State {
                name: "onOtherSession"
                // for slide out animation
                PropertyChanges { target: lockScreenRoot; y: lockScreenRoot.height }
                // we also change the opacity just to be sure it's not visible even on unexpected screen dimension changes with possible race conditions
                PropertyChanges { target: lockScreenRoot; opacity: 0 }
            }
        ]

        transitions:
            Transition {
            // we only animate switchting to another session, because kscreenlocker doesn't get notified when
            // coming from another session back and so we wouldn't know when to trigger the animation exactly
            from: ""
            to: "onOtherSession"

            PropertyAnimation { id: stateChangeAnimation; properties: "y"; duration: PlasmaCore.Units.longDuration; easing.type: Easing.InQuad}
            PropertyAnimation { properties: "opacity"; duration: PlasmaCore.Units.longDuration}

            onRunningChanged: {
                // after the animation has finished switch session: since we only animate the transition TO state "onOtherSession"
                // and not the other way around, we don't have to check the state we transitioned into
                if (/* lockScreenRoot.state == "onOtherSession" && */ !running) {
                    mainStack.currentItem.switchSession()
                }
            }
        }

        WallpaperFader {
            anchors.fill: parent
            state: lockScreenRoot.uiVisible ? "on" : "off"
//             source: wallpaper
            mainStack: mainStack
            footer: footer
            clock: clock
            clockcenter: clockcenter
            battery: battery
            ferenOSLogo: ferenOSLogo
            mediaControls: mediaControls
            mediaAlbumArt: mediaAlbumArt
        }

        Clock {
            id: clock
            y: height / 2.5
            anchors {
                left: parent.left
                top: parent.top
            }
            anchors.leftMargin:  PlasmaCore.Units.smallSpacing * 6
            anchors.topMargin:  PlasmaCore.Units.smallSpacing * 6
            visible: y > 0
            Layout.alignment: Qt.AlignBaseline
        }

        Loader {
            id: clockcenter
            y: height / 2.5
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            visible: y > 0
            Layout.alignment: Qt.AlignBaseline
            source: "ClockCenter.qml"
            active: showClock
        }

        ListModel {
            id: users

            Component.onCompleted: {
                users.append({name: kscreenlocker_userName,
                                realName: kscreenlocker_userName,
                                icon: kscreenlocker_userImage,

                })
            }
        }

        StackView {
            id: mainStack
            anchors {
                left: parent.left
                right: parent.right
            }
            height: lockScreenRoot.height
            focus: true //StackView is an implicit focus scope, so we need to give this focus so the item inside will have it

            // this isn't implicit, otherwise items still get processed for the scenegraph
            visible: opacity > 0

            initialItem: MainBlock {
                id: mainBlock
                lockScreenUiVisible: lockScreenRoot.uiVisible

                Stack.onStatusChanged: {
                    // prepare for presenting again to the user
                    if (Stack.status == Stack.Activating) {
                        mainPasswordBox.remove(0, mainPasswordBox.length)
                        mainPasswordBox.focus = true
                    }
                }


                notificationMessage: {
                    var text = ""
                    if (keystateSource.data["Caps Lock"]["Locked"]) {
                        text += i18nd("plasma_lookandfeel_org.kde.lookandfeel","Caps Lock is on")
                        if (root.notification) {
                            text += " • "
                        }
                    }
                    text += root.notification
                    return text
                }

                onLoginRequest: {
                    root.notification = ""
                    authenticator.tryUnlock(password)
                }

                onSwitchUserRequest: {
                    root.notification = ""
                    mainStack.pop({immediate:true})
                    sessionsModel.startNewSession(true /* lock the screen too */)
                    lockScreenRoot.state = ''
                }
            }

            Component.onCompleted: {
                if (defaultToSwitchUser) { //context property
                    mainStack.pop({immediate:true})
                    sessionsModel.startNewSession(true /* lock the screen too */)
                    lockScreenRoot.state = ''
                }
            }
        }

        Loader {
            id: inputPanel
            state: "hidden"
            readonly property bool keyboardActive: item ? item.active : false
            anchors {
                left: parent.left
                right: parent.right
            }
            function showHide() {
                state = state == "hidden" ? "visible" : "hidden";
            }
            Component.onCompleted: {
                inputPanel.source = Qt.platform.pluginName.includes("wayland") ? "../components/VirtualKeyboard_wayland.qml" : "../components/VirtualKeyboard.qml"
            }

            onKeyboardActiveChanged: {
                if (keyboardActive) {
                    state = "visible";
                } else {
                    state = "hidden";
                }
            }

            states: [
                State {
                    name: "visible"
                    PropertyChanges {
                        target: mainStack
                        y: Math.min(0, lockScreenRoot.height - inputPanel.height - mainBlock.height/2)
                    }
                    PropertyChanges {
                        target: inputPanel
                        y: lockScreenRoot.height - inputPanel.height
                    }
                },
                State {
                    name: "hidden"
                    PropertyChanges {
                        target: mainStack
                        y: 0
                    }
                    PropertyChanges {
                        target: inputPanel
                        y: lockScreenRoot.height - lockScreenRoot.height/4
                    }
                }
            ]
            transitions: [
                Transition {
                    from: "hidden"
                    to: "visible"
                    SequentialAnimation {
                        ScriptAction {
                            script: {
                                inputPanel.item.activated = true;
                                Qt.inputMethod.show();
                            }
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: mainStack
                                property: "y"
                                duration: PlasmaCore.Units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: inputPanel
                                property: "y"
                                duration: PlasmaCore.Units.longDuration
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                },
                Transition {
                    from: "visible"
                    to: "hidden"
                    SequentialAnimation {
                        ParallelAnimation {
                            NumberAnimation {
                                target: mainStack
                                property: "y"
                                duration: PlasmaCore.Units.longDuration
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                target: inputPanel
                                property: "y"
                                duration: PlasmaCore.Units.longDuration
                                easing.type: Easing.InQuad
                            }
                            OpacityAnimator {
                                target: inputPanel
                                duration: PlasmaCore.Units.longDuration
                                easing.type: Easing.InQuad
                            }
                        }
                        ScriptAction {
                            script: {
                                Qt.inputMethod.hide();
                            }
                        }
                    }
                }
            ]
        }

        Loader {
            active: root.viewVisible
            source: "LockOsd.qml"
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: PlasmaCore.Units.largeSpacing
            }
        }

        Image {
            id: ferenOSLogo
            height: Math.min(PlasmaCore.Units.gridUnit * 1.8)
            fillMode: Image.PreserveAspectFit
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin:  PlasmaCore.Units.smallSpacing * 8
            }
            source: "../components/artwork/watermark.png"
            mipmap: true
        }

        Loader {
            id: mediaControls
            anchors {
                bottom: parent.bottom
                left: parent.left
                margins:  PlasmaCore.Units.smallSpacing * 6
            }
            Layout.preferredHeight: mediaAlbumArt.preferredHeight
            active: config.showMediaControls
            source: "MediaControls.qml"
        }

        Loader {
            id: mediaAlbumArt
            anchors {
                bottom: parent.bottom
                bottomMargin:  PlasmaCore.Units.smallSpacing * 6
            }

            x: mediaControls.x + mediaControls.width + PlasmaCore.Units.smallSpacing * 4
            width: ferenOSLogo.x - PlasmaCore.Units.smallSpacing * 8 - mediaControls.x
            Layout.fillWidth: true
            Layout.preferredHeight: item ? item.implicitHeight : 0
            active: config.showMediaControls
            source: "MediaAlbumArt.qml"
        }

        Loader {
            id: battery
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins:  PlasmaCore.Units.smallSpacing * 6
            }
            source: "../components/Battery.qml"
            active: showClock
        }

        RowLayout {
            id: footer
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins:  PlasmaCore.Units.smallSpacing * 6
            }

            PlasmaComponents3.ToolButton {
                text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Button to show/hide virtual keyboard", "Virtual Keyboard")
                icon.name: inputPanel.keyboardActive ? "input-keyboard-virtual-on" : "input-keyboard-virtual-off"
                onClicked: {
                    // Otherwise the password field loses focus and virtual keyboard
                    // keystrokes get eaten
                    mainBlock.mainPasswordBox.forceActiveFocus();
                    inputPanel.showHide()
                }

                visible: inputPanel.status == Loader.Ready
            }

            PlasmaComponents3.ToolButton {
                Accessible.description: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "Button to change keyboard layout", "Switch layout")
                icon.name: "input-keyboard"

                PW.KeyboardLayoutSwitcher {
                    id: keyboardLayoutSwitcher

                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                }

                text: keyboardLayoutSwitcher.layoutNames.longName
                onClicked: keyboardLayoutSwitcher.keyboardLayout.switchToNextLayout()

                visible: keyboardLayoutSwitcher.hasMultipleKeyboardLayouts
            }
        }
    }

    Component.onCompleted: {
        // version support checks
        if (root.interfaceVersion < 1) {
            // ksmserver of 5.4, with greeter of 5.5
            root.viewVisible = true;
        }
    }
}
