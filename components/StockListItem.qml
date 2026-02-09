import QtQuick
import qs.Widgets
import qs.Common
import "."
import "../services"
import "../services/StockUtils.js" as Utils

/*
 * StockListItem.qml - Individual stock row component
 * Supports swipe-to-delete functionality
 */

Item {
    id: root

    // Required properties
    property var stockData: null
    property int itemIndex: 0
    property bool isAlternate: false
    property bool isEditMode: false
    property bool isPinned: false
    property bool showSparklines: true

    // Callbacks
    property var onDelete: function (code) {
    }
    property var onPin: function (code) {
    }
    property var onSwipeOpen: function (index) {
    }
    property var onSwipeClose: function () {
    }
    // Signal for showing details with geometry
    signal showDetail(var stock, real x, real y, real w, real h)

    // Internal state
    property bool isOpen: false

    // Size
    width: parent ? parent.width : 440
    height: Utils.UI.ROW_HEIGHT
    clip: true

    // Delete button background (visible when swiped left)
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        width: Utils.UI.DELETE_BUTTON_WIDTH
        color: Utils.COLORS.DELETE
        radius: 8
        visible: itemContent.x < -5 && !isEditMode
        opacity: Math.min(1.0, Math.abs(itemContent.x) / 70)

        DankIcon {
            name: "delete"
            size: 20
            color: "white"
            anchors.centerIn: parent
            scale: Math.min(1.0, Math.abs(itemContent.x) / 60)
        }
    }

    // Pin button background (visible when swiped right)
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        width: Utils.UI.DELETE_BUTTON_WIDTH
        color: Theme.primary
        radius: 8
        visible: itemContent.x > 5 && !isEditMode
        opacity: Math.min(1.0, Math.abs(itemContent.x) / 70)

        DankIcon {
            name: "push_pin"
            size: 20
            color: "white"
            anchors.centerIn: parent
            scale: Math.min(1.0, Math.abs(itemContent.x) / 60)
        }
    }

    // Main content container (draggable)
    Rectangle {
        id: itemContent
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width
        x: 0
        radius: 4
        color: root.ListView.isCurrentItem ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1) : (root.isAlternate ? Theme.surfaceVariant : "transparent")
        border.color: root.ListView.isCurrentItem ? Theme.primary : "transparent"
        border.width: root.ListView.isCurrentItem ? 1 : 0
        opacity: 0.9

        Behavior on x {
            NumberAnimation {
                duration: 200; easing.type: Easing.OutQuad
            }
        }

        // Selection MouseArea
        MouseArea {
            anchors.fill: parent
            onClicked: root.ListView.view.currentIndex = root.itemIndex
        }

        // Swipe gesture handler (Background Layer)
        MouseArea {
            id: swipeArea
            anchors.fill: parent
            // Disable swipe when in edit mode
            visible: !root.isEditMode
            property real startX: 0
            property bool isDragging: false

            onPressed: function (mouse) {
                startX = mouse.x;
                isDragging = true;
                // Notify parent to close other items
                if (!root.isOpen) {
                    root.onSwipeOpen(root.itemIndex);
                }
            }

            onPositionChanged: function (mouse) {
                if (!isDragging) return;

                var deltaX = mouse.x - startX;

                // Allow dragging in both directions
                // Left (-): Delete (limit to -MAX)
                // Right (+): Pin (limit to +MAX)

                if (deltaX < 0) {
                    // Swiping left - Delete
                    if (itemContent.x > 0) itemContent.x = 0; // Reset if coming from right
                    itemContent.x = Math.max(deltaX, Utils.UI.DELETE_MAX_DRAG);
                } else if (deltaX > 0) {
                    // Swiping right - Pin
                    if (itemContent.x < 0) itemContent.x = 0; // Reset if coming from left
                    itemContent.x = Math.min(deltaX, -Utils.UI.DELETE_MAX_DRAG); // Use same max drag distance (positive)
                }
            }

            onReleased: {
                isDragging = false;
                finalizeSwipe();
            }

            onCanceled: {
                isDragging = false;
                finalizeSwipe();
            }

            function finalizeSwipe() {
                // Swipe Left -> Delete
                if (itemContent.x < Utils.UI.DELETE_THRESHOLD) {
                    itemContent.x = Utils.UI.DELETE_MAX_DRAG;
                    root.isOpen = true;
                }
                // Swipe Right -> Pin
                else if (itemContent.x > -Utils.UI.DELETE_THRESHOLD) { // Threshold is negative, so check against positive 35
                    itemContent.x = -Utils.UI.DELETE_MAX_DRAG; // Snap to positive 70
                    root.isOpen = true;
                }
                // Close
                else {
                    itemContent.x = 0;
                    root.isOpen = false;
                    root.onSwipeClose();
                }
            }
        }

        // Data row (Foreground Layer)
        Row {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 12
            spacing: 5
            z: 10 // Ensure interactive elements are above swipe area

            // Edit Mode: Pin Button (Left)
            Rectangle {
                width: root.isEditMode ? 28 : 0
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                visible: root.isEditMode
                clip: true
                color: root.isPinned ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : (pinMouse.containsMouse ? Theme.surfaceVariant : "transparent")
                radius: 14

                Behavior on width {
                    NumberAnimation {
                        duration: 250; easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                DankIcon {
                    name: "push_pin"
                    filled: root.isPinned
                    size: 16
                    color: root.isPinned ? Theme.primary : Theme.surfaceVariantText
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: pinMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.stockData) root.onPin(root.stockData.code)
                }
            }

            // Name with country emoji
            Row {
                // Adjust width based on BOTH edit buttons
                width: Utils.COLUMN_WIDTH.NAME - (root.isEditMode ? 24 + 24 : 0) // Pin + Delete
                height: parent.height
                spacing: 3

                Behavior on width {
                    NumberAnimation {
                        duration: 200; easing.type: Easing.OutQuad
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Utils.getCountryEmoji(root.stockData ? root.stockData.code : "")
                    font.pixelSize: Theme.fontSizeMedium
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 20
                    text: root.stockData ? root.stockData.name : ""
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.primary
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }
            }

            // Stock code
            Row {
                width: Utils.COLUMN_WIDTH.CODE
                height: parent.height
                spacing: 4
                layoutDirection: Qt.RightToLeft

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.stockData ? Utils.getPureCode(root.stockData.code) : "--"
                    font.pixelSize: Theme.fontSizeMedium
                    font.family: "monospace"
                    color: Theme.secondary
                }

                StockSparkline {
                    id: sparkline
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.showSparklines
                    history: root.stockData ? root.stockData.history : []
                    lineColor: root.stockData ? StockService.getChangeColor(root.stockData.changeAmount) : Theme.primary
                    
                    MouseArea {
                        anchors.fill: parent
                        // Make sure we have a decent hit target
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.stockData) {
                                // Map coordinates to the ListView (common ancestor available via attached property)
                                var p = sparkline.mapToItem(root.ListView.view, 0, 0);
                                root.showDetail(root.stockData, p.x, p.y, sparkline.width, sparkline.height);
                            }
                        }
                    }
                }
            }

            // Current price
            StyledText {
                width: Utils.COLUMN_WIDTH.PRICE
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: root.stockData ? Utils.formatNumber(root.stockData.currentPrice) : "--"
                font.pixelSize: Theme.fontSizeMedium
                font.family: "monospace"
                color: Theme.primary
            }

            // Change amount
            StyledText {
                width: Utils.COLUMN_WIDTH.CHANGE
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: root.stockData ? Utils.formatChange(root.stockData.changeAmount) : "--"
                font.pixelSize: Theme.fontSizeMedium
                font.family: "monospace"
                color: root.stockData ? StockService.getChangeColor(root.stockData.changeAmount) : Utils.COLORS.NEUTRAL
            }

            // Change percent
            StyledText {
                width: Utils.COLUMN_WIDTH.PERCENT
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                text: root.stockData ? Utils.formatPercent(root.stockData.changePercent) : "--"
                font.pixelSize: Theme.fontSizeMedium
                font.family: "monospace"
                font.bold: true
                color: root.stockData ? StockService.getChangeColor(root.stockData.changeAmount) : Utils.COLORS.NEUTRAL
            }

            // Edit Mode: Delete Button (Right)
            Rectangle {
                width: root.isEditMode ? 28 : 0
                height: 28
                anchors.verticalCenter: parent.verticalCenter
                visible: root.isEditMode
                clip: true
                color: deleteMouse.containsMouse ? Qt.rgba(Utils.COLORS.DELETE.r, Utils.COLORS.DELETE.g, Utils.COLORS.DELETE.b, 0.15) : "transparent"
                radius: 14

                Behavior on width {
                    NumberAnimation {
                        duration: 250; easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                DankIcon {
                    name: "delete"
                    size: 16
                    color: Utils.COLORS.DELETE
                    anchors.centerIn: parent
                }

                MouseArea {
                    id: deleteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.stockData) root.onDelete(root.stockData.code)
                }
            }
        }
    }

    // Swipe Action Area: Delete (Left Swipe -> Right Button)
    MouseArea {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Utils.UI.DELETE_BUTTON_WIDTH
        // Enable if swiped left (negative X)
        enabled: itemContent.x <= Utils.UI.DELETE_THRESHOLD && !root.isEditMode
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.stockData) {
                root.onDelete(root.stockData.code);
            }
        }
    }

    // Swipe Action Area: Pin (Right Swipe -> Left Button)
    MouseArea {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Utils.UI.DELETE_BUTTON_WIDTH
        // Enable if swiped right (positive X)
        enabled: itemContent.x >= -Utils.UI.DELETE_THRESHOLD && !root.isEditMode
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.stockData) {
                // Toggle pin
                root.onPin(root.stockData.code);
                // Close swipe
                root.closeSwipe();
            }
        }
    }

    // Public method to close swipe
    function closeSwipe() {
        itemContent.x = 0;
        isOpen = false;
    }
}