import QtQuick 2.0
import QtQuick.Window 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height

    property string selectedUser: userModel.lastUser || ""
    property string clockText: ""

    function updateClock() { clockText = Qt.formatDateTime(new Date(), "hh:mm") }
    function login() {
        if (username.text.length === 0 || password.text.length === 0) {
            message.text = "Введите имя пользователя и пароль"
            return
        }
        message.text = "Выполняется вход…"
        sddm.login(username.text, password.text, sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0)
    }

    color: "#171522"
    gradient: Gradient {
        GradientStop { position: 0.0; color: "#171522" }
        GradientStop { position: 0.55; color: "#201b35" }
        GradientStop { position: 1.0; color: "#101522" }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            message.text = "Не удалось войти. Проверьте пароль."
            password.text = ""
            password.forceActiveFocus()
        }
        function onLoginSucceeded() { message.text = "" }
    }

    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.updateClock() }
    Component.onCompleted: {
        root.updateClock()
        if (username.text.length > 0) password.forceActiveFocus()
        else username.forceActiveFocus()
    }

    Rectangle {
        width: 430; height: 580; radius: 28
        anchors.centerIn: parent
        color: "#dd211d32"
        border.width: 1; border.color: "#66594f84"

        Column {
            anchors.fill: parent
            anchors.margins: 38
            spacing: 12

            Text {
                text: "◈  PhantomOS"; color: "#eee9ff"
                font.family: "Noto Sans"; font.pixelSize: 27; font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: root.clockText; color: "#c4badf"
                font.family: "Noto Sans"; font.pixelSize: 46
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: Qt.formatDate(new Date(), "dddd, d MMMM")
                color: "#9288ad"; font.family: "Noto Sans"; font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Item { width: 1; height: 10 }
            Text { text: "Пользователь"; color: "#c4badf"; font.pixelSize: 13 }
            Rectangle {
                width: parent.width; height: 48; radius: 12; color: "#29243d"
                border.width: username.activeFocus ? 2 : 1
                border.color: username.activeFocus ? "#a78bfa" : "#51456f"
                TextInput {
                    id: username
                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#eee9ff"; selectionColor: "#a78bfa"
                    font.family: "Noto Sans"; font.pixelSize: 15
                    text: root.selectedUser
                    onAccepted: password.forceActiveFocus()
                }
            }
            Text { text: "Пароль"; color: "#c4badf"; font.pixelSize: 13 }
            Rectangle {
                width: parent.width; height: 48; radius: 12; color: "#29243d"
                border.width: password.activeFocus ? 2 : 1
                border.color: password.activeFocus ? "#a78bfa" : "#51456f"
                TextInput {
                    id: password
                    anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#eee9ff"; selectionColor: "#a78bfa"
                    font.family: "Noto Sans"; font.pixelSize: 15
                    echoMode: TextInput.Password
                    onAccepted: root.login()
                }
            }
            Rectangle {
                width: parent.width; height: 50; radius: 14
                color: loginArea.containsMouse ? "#b69cff" : "#a78bfa"
                Behavior on color { ColorAnimation { duration: 140 } }
                Text {
                    anchors.centerIn: parent; text: "Войти"
                    color: "#171522"; font.family: "Noto Sans"; font.pixelSize: 15; font.bold: true
                }
                MouseArea { id: loginArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.login() }
            }
            Text {
                id: message; width: parent.width; height: 28
                text: ""; color: "#ff9aa2"; font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap
            }
        }
    }

    Row {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 28; spacing: 10
        Repeater {
            model: [
                { label: "Перезагрузка", action: "reboot" },
                { label: "Выключение", action: "powerOff" }
            ]
            delegate: Rectangle {
                width: 142; height: 42; radius: 12
                color: powerArea.containsMouse ? "#3a3155" : "#29243d"
                border.width: 1; border.color: "#51456f"
                Text { anchors.centerIn: parent; text: modelData.label; color: "#c4badf"; font.pixelSize: 12 }
                MouseArea {
                    id: powerArea; anchors.fill: parent; hoverEnabled: true
                    onClicked: modelData.action === "reboot" ? sddm.reboot() : sddm.powerOff()
                }
            }
        }
    }
}
