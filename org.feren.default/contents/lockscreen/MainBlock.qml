/*
 *   Copyright 2016 David Edmundson <davidedmundson@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.2

import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents3

import "../components"

Item {
    id: root

    /*
     * Any message to be displayed to the user, visible above the text fields
     */
    property alias notificationMessage: notificationsLabel.text

    /*
     * Self explanatory
     */
    property int fontSize: PlasmaCore.Theme.defaultFont.pointSize + 2

    property Item mainPasswordBox: passwordBox
    property bool lockScreenUiVisible: false

    //the y position that should be ensured visible when the on screen keyboard is visible
    property int visibleBoundary: mapFromItem(loginButton, 0, 0).y
    onHeightChanged: visibleBoundary = mapFromItem(loginButton, 0, 0).y + loginButton.height + PlasmaCore.Units.smallSpacing
    /*
     * Login has been requested with the following username and password
     * If username field is visible, it will be taken from that, otherwise from the "name" property of the currentIndex
     */
    signal loginRequest(string password)
    signal switchUserRequest()

    function startLogin() {
        var password = passwordBox.text

        //this is partly because it looks nicer
        //but more importantly it works round a Qt bug that can trigger if the app is closed with a TextField focused
        //See https://bugreports.qt.io/browse/QTBUG-55460
        loginButton.forceActiveFocus();
        loginRequest(password);
    }

    function switchUser() {
        switchuserButton.forceActiveFocus();
        switchUserRequest();
    }

    PlasmaComponents3.Label {
        id: ferenuserName
        anchors {
            left: parent.left
            right: ferenuserPicture.left
            verticalCenter: parent.verticalCenter
            rightMargin: PlasmaCore.Units.largeSpacing
        }
        font.pointSize: Math.max(1.6 * theme.defaultFont.pointSize)
        height: implicitHeight // work around stupid bug in Plasma Components that sets the height
        text: kscreenlocker_userName
        style: softwareRendering ? Text.Outline : Text.Normal
        styleColor: softwareRendering ? PlasmaCore.ColorScope.backgroundColor : "transparent" //no outline, doesn't matter
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignRight
    }

    UserPicture {
        id: ferenuserPicture
        anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }
        width: PlasmaCore.Units.gridUnit * 8
        avatarPath: kscreenlocker_userImage || ""
        iconSource: "user-identity"
        visible: true

    }

    RowLayout {
        id: passwordControls
        Layout.fillWidth: true
        anchors {
            left: ferenuserPicture.right
            leftMargin: PlasmaCore.Units.largeSpacing
            verticalCenter: parent.verticalCenter
        }

        PlasmaComponents3.TextField {
            id: passwordBox
            font.pointSize: PlasmaCore.Theme.defaultFont.pointSize + 1
            Layout.fillWidth: true

            placeholderText: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Password")
            focus: true
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
            enabled: !authenticator.graceLocked
            revealPasswordButtonShown: true
            height: implicitHeight

            // In Qt this is implicitly active based on focus rather than visibility
            // in any other application having a focussed invisible object would be weird
            // but here we are using to wake out of screensaver mode
            // We need to explicitly disable cursor flashing to avoid unnecessary renders
            cursorVisible: visible

            onAccepted: {
                if (lockScreenUiVisible) {
                    startLogin();
                }
            }

            Connections {
                target: root
                function onClearPassword() {
                    passwordBox.forceActiveFocus()
                    passwordBox.text = "";
                }
            }
        }

        PlasmaComponents3.Button {
            id: loginButton
            Accessible.name: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Unlock")
            Layout.preferredHeight: passwordBox.implicitHeight
            Layout.preferredWidth: loginButton.Layout.preferredHeight

            icon.name: "go-next"

            onClicked: startLogin()
        }
    }

    ColumnLayout {
        anchors {
            top: passwordControls.bottom
            topMargin: PlasmaCore.Units.smallSpacing
            left: passwordControls.left
        }

        PlasmaComponents3.Label {
            id: notificationsLabel
            font.pointSize: root.fontSize
            Layout.maximumWidth: PlasmaCore.Units.gridUnit * 16
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.italic: true
            visible: text != "" ? true : false
        }

        PlasmaComponents3.ToolButton {
            id: switchuserButton
            Accessible.name: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Switch User")
            text: i18nd("plasma_lookandfeel_org.kde.lookandfeel", "Switch User")
            Layout.preferredHeight: passwordBox.implicitHeight
            onClicked: switchUser()
        }
    }
}
