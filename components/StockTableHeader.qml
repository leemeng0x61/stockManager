import qs.DCommon.Widgets as DmsCommon
import QtQuick
import qs.Widgets
import qs.Common
import "."
import "../services"
import "../services/StockUtils.js" as Utils

/*
 * StockTableHeader.qml - Table header component for stock list
 * Clickable column headers for sorting
 */

Rectangle {
    id: root

    // Properties
    property var translationFunc: function (key) {
        return key;
    }
    property var onSort: function (key) {
    }
    property string currentSortKey: ""
    property bool isAscending: true

    // Size
    width: parent ? parent.width : 440
    height: Utils.UI.HEADER_HEIGHT
    radius: 4
    color: Theme.surfaceVariant

    // Header column definition
    Row {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 12
        spacing: 5

        // Name column
        HeaderCell {
            width: Utils.COLUMN_WIDTH.NAME
            height: parent.height
            text: root.translationFunc("Name")
            horizontalAlignment: Text.AlignLeft
            sortKey: "name"
            active: root.currentSortKey === "name"
            isAscending: root.isAscending
            onClicked: root.onSort(sortKey)
        }

        // Code column
        HeaderCell {
            width: Utils.COLUMN_WIDTH.CODE
            height: parent.height
            text: root.translationFunc("Code")
            horizontalAlignment: Text.AlignRight
            sortKey: "code"
            active: root.currentSortKey === "code"
            isAscending: root.isAscending
            onClicked: root.onSort(sortKey)
        }

        // Price column
        HeaderCell {
            width: Utils.COLUMN_WIDTH.PRICE
            height: parent.height
            text: root.translationFunc("Price")
            horizontalAlignment: Text.AlignRight
            sortKey: "price"
            active: root.currentSortKey === "price"
            isAscending: root.isAscending
            onClicked: root.onSort(sortKey)
        }

        // Change column
        HeaderCell {
            width: Utils.COLUMN_WIDTH.CHANGE
            height: parent.height
            text: root.translationFunc("Change")
            horizontalAlignment: Text.AlignRight
            sortKey: "change"
            active: root.currentSortKey === "change"
            isAscending: root.isAscending
            onClicked: root.onSort(sortKey)
        }

        // Percent column
        HeaderCell {
            width: Utils.COLUMN_WIDTH.PERCENT
            height: parent.height
            text: root.translationFunc("Percent")
            horizontalAlignment: Text.AlignRight
            sortKey: "percent"
            active: root.currentSortKey === "percent"
            isAscending: root.isAscending
            onClicked: root.onSort(sortKey)
        }
    }

    // Header cell component
    component HeaderCell: Rectangle {
        id: headerCell
        property string text: ""
        property int horizontalAlignment: Text.AlignLeft
        property string sortKey: ""
        property bool active: false
        property bool isAscending: true

        signal clicked()

        color: mouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : "transparent"
        radius: 4

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            spacing: 2
            layoutDirection: headerCell.horizontalAlignment === Text.AlignRight ? Qt.RightToLeft : Qt.LeftToRight

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: headerCell.horizontalAlignment
                text: headerCell.text
                font.pixelSize: Theme.fontSizeMedium
                font.bold: headerCell.active
                color: headerCell.active ? Theme.primary : Theme.primary
                opacity: headerCell.active || mouseArea.containsMouse ? 1.0 : 0.7
                width: parent.width - (headerCell.active ? 18 : 0)
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
            }

            DmsCommon.DIcon {
                visible: headerCell.active
                name: headerCell.isAscending ? "keyboard_arrow_up" : "keyboard_arrow_down"
                size: 16
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
