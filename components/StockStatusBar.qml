import QtQuick
import qs.Common
import qs.Widgets
import "."
import "../services"
import "../services/StockUtils.js" as Utils

Item {
    id: root

    // Properties
    property int orientation: Qt.Horizontal
    property var pinnedStocks: []
    property var shIndex: ({})
    property real barThickness: 48
    property var barConfig: null
    property int maxCount: 3
    property bool scrollable: false

    // Carousel state
    property int carouselIndex: 0
    property int itemsPerPage: maxCount > 0 ? maxCount : 3
    readonly property var visiblePinnedStocks: {
        if (!pinnedStocks || pinnedStocks.length === 0) return [];

        // If scrolling is disabled, just show the first N items up to max count
        if (!scrollable) {
            return pinnedStocks.slice(0, Math.min(pinnedStocks.length, itemsPerPage));
        }

        // If scrolling is enabled
        if (pinnedStocks.length <= itemsPerPage) return pinnedStocks;
        return pinnedStocks.slice(carouselIndex, carouselIndex + itemsPerPage);
    }

    Timer {
        id: carouselTimer
        interval: 5000
        running: scrollable && pinnedStocks && pinnedStocks.length > itemsPerPage
        repeat: true
        onTriggered: {
            let next = root.carouselIndex + itemsPerPage;
            if (next >= root.pinnedStocks.length) root.carouselIndex = 0;
            else root.carouselIndex = next;
        }
    }

    readonly property bool isVertical: orientation === Qt.Vertical

    implicitWidth: layoutLoader.item ? layoutLoader.item.implicitWidth : 0
    implicitHeight: layoutLoader.item ? layoutLoader.item.implicitHeight : 0

    Loader {
        id: layoutLoader
        anchors.centerIn: parent
        sourceComponent: isVertical ? columnLayout : rowLayout
    }

    Component {
        id: rowLayout
        Row {
            spacing: 8
            Repeater {
                model: root.visiblePinnedStocks
                delegate: Row {
                    spacing: 4
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Utils.formatBarText(modelData, StockService.displayMode, StockService.nameDisplayMode)
                        font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                        color: Qt.tint(StockService.getChangeColor(modelData.changeAmount), Theme.withAlpha(Theme.barForeground, 0.48))
                    }
                    Rectangle {
                        visible: index < root.visiblePinnedStocks.length - 1 || (root.pinnedStocks.length === 0)
                        width: 1; height: 12; color: Theme.surfaceVariant; anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            StyledText {
                visible: !root.pinnedStocks || root.pinnedStocks.length === 0
                text: root.shIndex && root.shIndex.code ? Utils.formatBarText(root.shIndex, StockService.displayMode, StockService.nameDisplayMode) : "..."
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: root.shIndex ? Qt.tint(StockService.getChangeColor(root.shIndex.changeAmount), Theme.withAlpha(Theme.barForeground, 0.48)) : Utils.COLORS.NEUTRAL
            }
        }
    }

    Component {
        id: columnLayout
        Column {
            spacing: 4
            Repeater {
                model: root.visiblePinnedStocks
                delegate: StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Utils.formatBarText(modelData, StockService.displayMode, StockService.nameDisplayMode)
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    color: Qt.tint(StockService.getChangeColor(modelData.changeAmount), Theme.withAlpha(Theme.barForeground, 0.48))
                }
            }

            StyledText {
                visible: !root.pinnedStocks || root.pinnedStocks.length === 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.shIndex && root.shIndex.code ? Utils.formatBarText(root.shIndex, StockService.displayMode, StockService.nameDisplayMode) : "..."
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: root.shIndex ? Qt.tint(StockService.getChangeColor(root.shIndex.changeAmount), Theme.withAlpha(Theme.barForeground, 0.48)) : Utils.COLORS.NEUTRAL
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (root.scrollable && root.pinnedStocks && root.pinnedStocks.length > root.itemsPerPage) {
                    let next = root.carouselIndex + root.itemsPerPage;
                    if (next >= root.pinnedStocks.length) root.carouselIndex = 0;
                    else root.carouselIndex = next;
                    carouselTimer.restart();
                }
            }
        }
    }
}
