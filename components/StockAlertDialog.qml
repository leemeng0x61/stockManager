import QtQuick
import QtQuick.Controls 2.15
import qs.Widgets
import qs.Common
import "."
import "../services"
import "../services/StockUtils.js" as Utils

Rectangle {
    id: root

    // Signals
    signal confirm(bool enabled, real threshold)
    signal cancel()

    // Properties
    property var translationFunc: function (key) {
        return key;
    }
    property var stockData: null
    property bool alertEnabled: false
    property real alertThreshold: 3.0

    // Geometry for animation
    property real startX: 0
    property real startY: 0
    property real startW: 32
    property real startH: 32

    anchors.fill: parent
    color: "transparent"
    visible: opacity > 0
    opacity: 0
    enabled: state === "expanded"

    Behavior on opacity {
        NumberAnimation {
            duration: 250
        }
    }

    Keys.enabled: state === "expanded"
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.close();
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.confirmSettings();
            event.accepted = true;
        }
    }

    // Dim Background
    Rectangle {
        id: dimBackground
        anchors.fill: parent
        color: "#000000"
        opacity: 0

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Main Dialog
    Rectangle {
        id: dialogWindow
        
        // Initial / Target state geometry
        x: startX
        y: startY
        width: startW
        height: startH
        radius: 16
        
        color: Theme.surface
        border.color: Theme.surfaceVariant
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        // Content Area (Separated from Container for better performance)
        Column {
            id: contentColumn
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: 312 // (360 - 48 padding)
            spacing: 12
            opacity: 0

            // Title
            Row {
                width: parent.width
                spacing: 8

                DankIcon {
                    name: "notifications"
                    size: 20
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - 32
                    spacing: 1

                    StyledText {
                        text: root.translationFunc("Stock Alert Settings")
                        font.pixelSize: Theme.fontSizeMedium
                        font.bold: true
                        color: Theme.primary
                    }

                    StyledText {
                        text: root.stockData ? (root.stockData.name + " (" + Utils.getPureCode(root.stockData.code) + ")") : ""
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondary
                        opacity: 0.7
                    }
                }
            }

            // Separator
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surfaceVariant
                opacity: 0.3
            }

            // Enable Switch
            Row {
                width: parent.width
                height: 36
                spacing: 10

                DankIcon {
                    name: alertSwitch.checked ? "notifications_active" : "notifications_off"
                    size: 18
                    color: alertSwitch.checked ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - 100
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    StyledText {
                        text: root.translationFunc("Enable Alert")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primary
                    }

                    StyledText {
                        text: root.translationFunc("Alert when change exceeds")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondary
                        opacity: 0.6
                    }
                }

                Item {
                    width: 60
                    height: parent.height

                    Switch {
                        id: alertSwitch
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        checked: root.alertEnabled
                    }
                }
            }

            // Threshold Input
            Column {
                width: parent.width
                spacing: 6
                opacity: alertSwitch.checked ? 1.0 : 0.4
                enabled: alertSwitch.checked

                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                StyledText {
                    text: root.translationFunc("Alert Threshold (%)")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primary
                }

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 10
                    color: Theme.surfaceVariant
                    border.color: thresholdInput.activeFocus ? Theme.primary : "transparent"
                    border.width: 2

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        DankIcon {
                            name: "trending_up"
                            size: 18
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: thresholdInput
                            width: parent.width - 50
                            height: parent.height
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            font.pixelSize: Theme.fontSizeMedium
                            font.family: "monospace"
                            font.bold: true
                            color: Theme.primary
                            selectByMouse: true
                            text: root.alertThreshold.toFixed(1)
                            validator: DoubleValidator {
                                bottom: 0.1
                                top: 100.0
                                decimals: 1
                            }

                            onActiveFocusChanged: {
                                if (activeFocus) {
                                    selectAll()
                                }
                            }
                        }

                        StyledText {
                            text: "%"
                            font.pixelSize: Theme.fontSizeMedium
                            font.bold: true
                            color: Theme.secondary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // Quick preset buttons
                Row {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: [1.0, 3.0, 5.0, 10.0]

                        Rectangle {
                            width: (parent.width - 18) / 4
                            height: 28
                            radius: 6
                            color: mouseArea.containsMouse ? Theme.primary : Theme.surfaceVariant
                            opacity: mouseArea.containsMouse ? 0.2 : 0.5

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.toFixed(1) + "%"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.primary
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: thresholdInput.text = modelData.toFixed(1)
                            }
                        }
                    }
                }
            }

            // Buttons
            Row {
                width: parent.width
                height: 36
                spacing: 10

                Rectangle {
                    width: (parent.width - 10) / 2
                    height: parent.height
                    radius: 10
                    color: cancelMouse.containsMouse ? Theme.surfaceVariant : "transparent"
                    border.color: Theme.surfaceVariant
                    border.width: 2

                    StyledText {
                        anchors.centerIn: parent
                        text: root.translationFunc("Cancel")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondary
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }

                Rectangle {
                    width: (parent.width - 10) / 2
                    height: parent.height
                    radius: 10
                    color: saveMouse.containsMouse ? Qt.darker(Theme.primary, 1.1) : Theme.primary

                    StyledText {
                        anchors.centerIn: parent
                        text: root.translationFunc("Save")
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        color: "white"
                    }

                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.confirmSettings()
                    }
                }
            }
        }
    }

    // States
    states: [
        State {
            name: "expanded"
            PropertyChanges {
                target: root
                opacity: 1
            }
            PropertyChanges {
                target: dimBackground
                opacity: 0.4
            }
            PropertyChanges {
                target: dialogWindow
                x: (root.width - 360) / 2
                y: Math.max(12, Math.min(root.height - contentColumn.height - 96, root.height - dialogWindow.height - 12))
                width: 360
                height: contentColumn.height + 32
            }
            PropertyChanges {
                target: contentColumn
                opacity: 1
            }
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "expanded"
            ParallelAnimation {
                NumberAnimation {
                    target: root
                    property: "opacity"
                    duration: 150
                }
                NumberAnimation {
                    target: dimBackground
                    property: "opacity"
                    duration: 300
                }
                NumberAnimation {
                    target: dialogWindow
                    properties: "x,y,width,height"
                    duration: 350
                    easing.type: Easing.OutCubic
                }
                SequentialAnimation {
                    PauseAnimation {
                        duration: 150
                    }
                    NumberAnimation {
                        target: contentColumn
                        property: "opacity"
                        duration: 200
                    }
                }
            }
        },
        Transition {
            from: "expanded"
            to: ""
            ParallelAnimation {
                NumberAnimation {
                    target: contentColumn
                    property: "opacity"
                    duration: 100
                }
                NumberAnimation {
                    target: dialogWindow
                    properties: "x,y,width,height"
                    duration: 250
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: dimBackground
                    property: "opacity"
                    duration: 250
                }
                NumberAnimation {
                    target: root
                    property: "opacity"
                    duration: 250
                }
            }
        }
    ]

    function open(stock, x, y, w, h) {
        if (!stock) return
        root.startX = x || 0
        root.startY = y || 0
        root.startW = w || 32
        root.startH = h || 32
        root.stockData = stock
        root.alertEnabled = stock.alertEnabled || false
        root.alertThreshold = stock.alertThreshold || 3.0
        alertSwitch.checked = root.alertEnabled
        thresholdInput.text = root.alertThreshold.toFixed(1)
        root.state = "expanded"
        Qt.callLater(() => thresholdInput.forceActiveFocus())
    }

    function close() {
        root.state = ""
        Qt.callLater(() => root.cancel())
    }

    function confirmSettings() {
        var threshold = parseFloat(thresholdInput.text)
        if (isNaN(threshold) || threshold < 0.1) {
            threshold = 3.0
        }
        root.confirm(alertSwitch.checked, threshold)
        close()
    }
}
