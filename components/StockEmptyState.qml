import qs.DCommon.Widgets as DmsCommon
import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import "../services/StockUtils.js" as Utils

Item {
    id: root

    // Properties
    property var translationFunc: function (key) {
        return key;
    }
    property var onAddClicked: function () {
    }

    width: parent.width
    height: 300

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacingM
        width: Math.min(parent.width - 40, 300)

        DmsCommon.DIcon {
            name: "show_chart"
            size: 48
            color: Theme.surfaceVariantText
            Layout.alignment: Qt.AlignHCenter
            opacity: 0.5
        }

        StyledText {
            text: root.translationFunc("No stocks tracked")
            font.pixelSize: Theme.fontSizeLarge
            font.weight: Font.Bold
            color: Theme.surfaceText
            Layout.alignment: Qt.AlignHCenter
            opacity: 0.8
        }

        StyledText {
            text: root.translationFunc("Add stocks to monitor real-time prices and trends.")
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceVariantText
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        Item {
            height: Theme.spacingS; width: 1
        } // Spacer

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: buttonRow.width + 32
            height: 36
            radius: 18
            color: Theme.primaryContainer

            Row {
                id: buttonRow
                anchors.centerIn: parent
                spacing: 8

                DmsCommon.DIcon {
                    name: "add"
                    size: 18
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: root.translationFunc("Add Stock")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.onAddClicked()
            }
        }
    }
}