import QtQuick
import qs.Common
import qs.Widgets
import "."
import "../services"
import "../services/StockUtils.js" as Utils

Rectangle {
    id: root
    width: parent.width
    height: 32
    color: "transparent"

    property var displayStocks: []
    property var lastUpdateDate: null
    property bool isLoading: false
    property bool hasError: false
    property bool isEditMode: false
    property var t: function (k) {
        return k
    }

    signal addClicked(real x, real y, real w, real h)

    signal settingsClicked()

    signal refreshClicked()

    Item {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        // Left: Stock Count & Error Indicator
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            DankIcon {
                visible: root.hasError
                name: "error"
                size: 16
                color: Theme.error
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.isLoading ? root.t("Loading...") : `${root.displayStocks.length}${root.t("Stocks")}`
                font.pixelSize: Theme.fontSizeSmall
                color: root.hasError ? Theme.error : Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Center: Last Update Time & Market Status (Clickable)
        Rectangle {
            anchors.centerIn: parent
            width: updateRow.width + 16
            height: 28
            radius: 6
            color: updateMouseArea.containsMouse ? Theme.surfaceVariant : "transparent"

            Row {
                id: updateRow
                anchors.centerIn: parent
                spacing: 6
                opacity: 0.8

                Rectangle {
                    width: 8; height: 8; radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: Utils.isTradingTime() ? "#52c41a" : Theme.surfaceVariantText

                    SequentialAnimation on opacity {
                        running: Utils.isTradingTime()
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 1.0;
                            to: 0.3; duration: 1500; easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            from: 0.3;
                            to: 1.0; duration: 1500; easing.type: Easing.InOutQuad
                        }
                    }
                }

                StyledText {
                    text: root.t("Updated: ") + (root.lastUpdateDate ? Utils.formatSmartTime(new Date(root.lastUpdateDate)) : root.t("Never"))
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: updateMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.refreshClicked()
            }
        }

        // Right: Action Buttons
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            // Add Button
            IconButton {
                id: addBtn
                iconName: "add"
                onClicked: {
                    var pos = addBtn.mapToItem(null, 0, 0);
                    root.addClicked(pos.x, pos.y, addBtn.width, addBtn.height);
                }
            }
        }
    }

    // Unified Icon Button Component
    component IconButton: Rectangle {
        property string iconName: ""
        property color iconColor: Theme.surfaceVariantText
        property bool isRotating: false

        signal clicked()

        width: 32; height: 32; radius: 6
        color: mouseArea.containsMouse ? Theme.surfaceVariant : "transparent"

        DankIcon {
            anchors.centerIn: parent
            name: iconName
            size: 18
            color: iconColor

            RotationAnimator on rotation {
                running: isRotating
                from: 0;
                to: 360; loops: Animation.Infinite; duration: 1000
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
