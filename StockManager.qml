import QtQuick
import QtQuick.Controls 2.15
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./services/StockUtils.js" as Utils
import "./services"
import "./components"
import "."

/*
 * StockManager.qml - Main plugin component
 * Refactored to use StockService singleton
 */

PluginComponent {
    id: pluginRoot

    pluginId: "stockManager"
    layerNamespacePlugin: "stockManager"

    Component.onCompleted: {
        // Explicitly trigger data load on startup
        StockService.loadStockData();
    }

    // UI State
    property bool popoutVisible: false
    property bool isEditMode: false
    property string lastKey: "" // For sequence keys like 'gg'
    property var selectedStock: null

    function t(key) {
        let val = Utils.t(key);
        return val !== null ? val : I18n.tr(key);
    }

    Timer {
        id: sequenceTimer
        interval: 500; repeat: false
        onTriggered: pluginRoot.lastKey = ""
    }

    Timer {
        interval: StockService.refreshInterval
        running: true; repeat: true
        onTriggered: if (Utils.isTradingTime()) StockService.fetchStockData()
    }

    popoutWidth: 460
    popoutHeight: StockService.getPopoutHeight()

    horizontalBarPill: StockStatusBar {
        orientation: Qt.Horizontal
        pinnedStocks: StockService.pinnedStocks
        shIndex: StockService.shIndex
        barThickness: pluginRoot.barThickness
        config: pluginRoot.barConfig
        maxCount: StockService.statusBarMaxCount
        scrollable: StockService.statusBarScrollable
    }

    verticalBarPill: StockStatusBar {
        orientation: Qt.Vertical
        pinnedStocks: StockService.pinnedStocks
        shIndex: StockService.shIndex
        barThickness: pluginRoot.barThickness
        config: pluginRoot.barConfig
        maxCount: StockService.statusBarMaxCount
        scrollable: StockService.statusBarScrollable
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutComp
            headerText: pluginRoot.t("Stock Manager")
            showCloseButton: true
            focus: true

            ListModel {
                id: stockListModel
            }

            function syncStockList() {
                var source = StockService.displayStocks || [];
                var count = source.length;

                // Structural check: Rebuild if length differs significantly or IDs mismatch completely
                var needRebuild = false;
                if (stockListModel.count !== count) {
                    needRebuild = true;
                } else {
                    for (var i = 0; i < count; i++) {
                        if (stockListModel.get(i).code !== source[i].code) {
                            needRebuild = true;
                            break;
                        }
                    }
                }

                if (needRebuild) {
                    // 1. Capture selection state
                    var oldIndex = stockList.currentIndex;
                    var oldSelectedCode = null;
                    if (oldIndex >= 0 && oldIndex < stockListModel.count) {
                        oldSelectedCode = stockListModel.get(oldIndex).code;
                    }

                    // 2. Rebuild model
                    stockListModel.clear();
                    for (var j = 0; j < count; j++) {
                        stockListModel.append(source[j]);
                    }

                    // 3. Restore selection
                    if (oldSelectedCode) {
                        var newIndex = -1;
                        // Try to find the moved stock
                        for (var k = 0; k < stockListModel.count; k++) {
                            if (stockListModel.get(k).code === oldSelectedCode) {
                                newIndex = k;
                                break;
                            }
                        }

                        if (newIndex >= 0) {
                            // Stock still exists (moved or same place)
                            stockList.currentIndex = newIndex;
                        } else {
                            // Stock was deleted, select closest index
                            var targetIndex = Math.min(oldIndex, stockListModel.count - 1);
                            stockList.currentIndex = targetIndex;
                        }
                    } else {
                        // Nothing was selected, or list is empty
                        stockList.currentIndex = -1;
                    }
                    return;
                }

                // Update values in place
                for (var m = 0; m < count; m++) {
                    stockListModel.set(m, source[m]);
                }
            }

            Connections {
                target: StockService

                function onDisplayStocksChanged() {
                    syncStockList();
                }
            }

            Component.onCompleted: {
                pluginRoot.popoutVisible = true;
                syncStockList(); // Initial sync
                popoutComp.forceActiveFocus();
            }

            function closeAllDeleteButtons() {
                if (stockList.currentOpenIndex !== -1) {
                    var item = stockList.itemAtIndex(stockList.currentOpenIndex);
                    if (item && item.closeSwipe) item.closeSwipe();
                    stockList.currentOpenIndex = -1;
                }
            }

            Component.onDestruction: {
                pluginRoot.popoutVisible = false;
                pluginRoot.isEditMode = false;
                closeAllDeleteButtons();
            }

            Keys.onPressed: (event) => {
                // If dialog is open, let it handle keys
                if (addDialog.state === "expanded") return;

                if (event.key === Qt.Key_F) {
                    var pos = bottomBar.mapToItem(popoutComp, 0, 0);
                    addDialog.open(pos.x + 8, pos.y, 32, 32);
                    event.accepted = true;
                } else if (event.key === Qt.Key_E) {
                    pluginRoot.isEditMode = !pluginRoot.isEditMode;
                    event.accepted = true;
                } else if (event.key === Qt.Key_R) {
                    StockService.fetchStockData();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (stockList.currentIndex !== -1) {
                        let stock = StockService.displayStocks[stockList.currentIndex];
                        if (stock) StockService.togglePin(stock.code);
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
                    if (stockList.currentIndex !== -1) {
                        let stock = StockService.displayStocks[stockList.currentIndex];
                        if (stock) StockService.removeStock(stock.code);
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                    if (event.modifiers & Qt.ShiftModifier) {
                        if (stockList.currentIndex > 0) {
                            let oldIdx = stockList.currentIndex;
                            StockService.moveStock(oldIdx, -1);
                            // currentIndex will be updated by the model change, but let's be explicit
                            Qt.callLater(() => stockList.currentIndex = oldIdx - 1);
                        }
                    } else {
                        if (stockList.currentIndex > 0) stockList.currentIndex--;
                        else if (stockList.currentIndex === -1 && stockList.count > 0) stockList.currentIndex = 0;
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                    if (event.modifiers & Qt.ShiftModifier) {
                        if (stockList.currentIndex !== -1 && stockList.currentIndex < stockList.count - 1) {
                            let oldIdx = stockList.currentIndex;
                            StockService.moveStock(oldIdx, 1);
                            Qt.callLater(() => stockList.currentIndex = oldIdx + 1);
                        }
                    } else {
                        if (stockList.currentIndex < stockList.count - 1) stockList.currentIndex++;
                        else if (stockList.currentIndex === -1 && stockList.count > 0) stockList.currentIndex = 0;
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_G) {
                    if (event.modifiers & Qt.ShiftModifier) {
                        // Shift + G -> End
                        stockList.currentIndex = stockList.count - 1;
                    } else {
                        // Double G -> Home
                        if (pluginRoot.lastKey === "g") {
                            stockList.currentIndex = 0;
                            pluginRoot.lastKey = "";
                        } else {
                            pluginRoot.lastKey = "g";
                            sequenceTimer.start();
                        }
                    }
                    event.accepted = true;
                } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
                    const keys = ["name", "code", "price", "change", "percent"];
                    StockService.sortStocks(keys[event.key - Qt.Key_1]);
                    event.accepted = true;
                }
            }

            // Monitor visibility to close states when hidden
            onVisibleChanged: {
                if (!visible) {
                    pluginRoot.isEditMode = false;
                    closeAllDeleteButtons();
                    addDialog.close();
                } else {
                    popoutComp.forceActiveFocus();
                }
            }

            Item {
                width: parent.width
                implicitHeight: pluginRoot.popoutHeight - popoutComp.headerHeight - popoutComp.detailsHeight - 36

                Column {
                    anchors.fill: parent; anchors.margins: 10; spacing: 8

                    StockTableHeader {
                        translationFunc: pluginRoot.t
                        currentSortKey: StockService.sortKey
                        isAscending: StockService.sortAscending
                        visible: stockListModel.count > 0
                        onSort: function (key) {
                            StockService.sortStocks(key);
                        }
                    }

                    ScrollView {
                        visible: stockListModel.count > 0
                        width: parent.width; height: parent.height - 85; clip: true
                        ListView {
                            id: stockList
                            width: parent.width; height: parent.height

                            property int currentOpenIndex: -1

                            model: stockListModel
                            spacing: Utils.UI.ROW_SPACING
                            currentIndex: -1
                            highlightFollowsCurrentItem: true
                            onCurrentIndexChanged: {
                                if (currentIndex !== -1) {
                                    positionViewAtIndex(currentIndex, ListView.Contain);
                                }
                            }
                            delegate: StockListItem {
                                stockData: (StockService.displayStocks && StockService.displayStocks[index]) ? StockService.displayStocks[index] : null
                                itemIndex: index
                                isAlternate: index % 2 === 1
                                isEditMode: pluginRoot.isEditMode
                                isPinned: stockData ? StockService.isPinned(stockData.code) : false
                                showSparklines: StockService.showSparklines
                                onDelete: (code) => {
                                    StockService.removeStock(code);
                                    ListView.view.currentOpenIndex = -1;
                                }
                                onPin: (code) => StockService.togglePin(code)
                                onSwipeOpen: (idx) => {
                                    var list = ListView.view;
                                    if (list.currentOpenIndex !== -1 && list.currentOpenIndex !== idx) {
                                        var p = list.itemAtIndex(list.currentOpenIndex);
                                        if (p) p.closeSwipe();
                                    }
                                    list.currentOpenIndex = idx;
                                    list.currentIndex = idx;
                                }
                                onSwipeClose: () => ListView.view.currentOpenIndex = -1
                                onShowDetail: (stock, x, y, w, h) => {
                                    // Map coordinates from ListView to PopoutComponent
                                    var pos = stockList.mapToItem(popoutComp, x, y);
                                    detailPopup.open(pos.x, pos.y, w, h, stock);
                                }
                            }
                        }
                    }

                    StockEmptyState {
                        visible: stockListModel.count === 0
                        width: parent.width
                        height: parent.height - bottomBar.height - 10
                        translationFunc: pluginRoot.t
                        onAddClicked: function () {
                            var pos = bottomBar.mapToItem(popoutComp, 0, 0);
                            addDialog.open(pos.x + 8, pos.y, 32, 32);
                        }
                    }

                    StockBottomBar {
                        id: bottomBar
                        displayStocks: StockService.displayStocks
                        lastUpdateDate: StockService.lastUpdateDate
                        isLoading: StockService.isLoading
                        isEditMode: pluginRoot.isEditMode
                        t: pluginRoot.t
                        onAddClicked: (x, y, w, h) => addDialog.open(x, y, w, h)
                        onSettingsClicked: pluginRoot.isEditMode = !pluginRoot.isEditMode
                        onRefreshClicked: StockService.fetchStockData()
                    }
                }
                AddStockDialog {
                    id: addDialog
                    translationFunc: pluginRoot.t
                    onConfirm: (code, name) => {
                        StockService.addStock(code, name);
                        popoutComp.forceActiveFocus();
                    }
                    onCancel: popoutComp.forceActiveFocus()
                }

                StockDetailPopup {
                    id: detailPopup
                    // visible and stock are handled by open()
                    onClose: pluginRoot.selectedStock = null
                }
            }
        }
    }
}