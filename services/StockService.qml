pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import "./StockUtils.js" as Utils

Singleton
{
    id: root

    readonly property string pluginId: "stockManager"

    // --- Configuration Settings (Persistent) ---
    property var pinnedCodes: []
    property string displayMode: "percent"
    property string nameDisplayMode: "none"
    property color upColor: "#ff4d4f"
    property color downColor: "#52c41a"
    property int refreshInterval: 30000
    property int statusBarMaxCount: 3
    property bool statusBarScrollable: false
    property bool showSparklines: true

    // --- State Properties (Source of Truth) ---
    property var stocks: []
    property var displayStocks: []
    property var pinnedStocks: []
    property var shIndex: Utils.createStock(Utils.STOCK_CODES.SH_INDEX, "上证指数")
    property bool isLoading: false
    property var lastUpdateDate: null

    property string sortKey: ""
    property bool sortAscending: true
    property string filterText: ""
    property bool globalShowSparklines: true // Kept for compatibility if needed, but showSparklines should be used

    // --- Dependencies ---
    StockApiService {
        id: stockApi
    }

    Timer {
        id: updateDebounceTimer
        interval: 200
        repeat: false
        onTriggered: forceUpdateLists()
    }

    // --- Auto-Save Handlers ---
    onPinnedCodesChanged: updateDerivedLists()
    onDisplayModeChanged: saveSetting("displayMode", displayMode)
    onNameDisplayModeChanged: saveSetting("nameDisplayMode", nameDisplayMode)
    onUpColorChanged: saveSetting("upColor", upColor)
    onDownColorChanged: saveSetting("downColor", downColor)
    onRefreshIntervalChanged: saveSetting("refreshInterval", refreshInterval)
    onStatusBarMaxCountChanged: saveSetting("statusBarMaxCount", statusBarMaxCount)
    onStatusBarScrollableChanged: saveSetting("statusBarScrollable", statusBarScrollable)
    onShowSparklinesChanged: {
        globalShowSparklines = showSparklines; // Sync internal var
        saveSetting("showSparklines", showSparklines);
    }

    // --- Initialization ---
    Component.onCompleted: {
        loadSettings();
        loadStockData();
    }

    function saveSetting(key, value) {
        if (typeof PluginService !== "undefined") {
            PluginService.savePluginData(pluginId, key, value);
        }
    }

    function loadSettings() {
        if (typeof PluginService === "undefined") return;

        var val;

        val = PluginService.loadPluginData(pluginId, "pinnedCodes");
        if (val !== undefined && val !== null) pinnedCodes = val;

        val = PluginService.loadPluginData(pluginId, "displayMode");
        if (val) displayMode = val;

        val = PluginService.loadPluginData(pluginId, "nameDisplayMode");
        if (val) nameDisplayMode = val;

        val = PluginService.loadPluginData(pluginId, "upColor");
        if (val) upColor = val;

        val = PluginService.loadPluginData(pluginId, "downColor");
        if (val) downColor = val;

        val = PluginService.loadPluginData(pluginId, "refreshInterval");
        if (val) refreshInterval = val;

        val = PluginService.loadPluginData(pluginId, "statusBarMaxCount");
        if (val) statusBarMaxCount = val;

        val = PluginService.loadPluginData(pluginId, "statusBarScrollable");
        if (val !== undefined && val !== null) statusBarScrollable = val;

        val = PluginService.loadPluginData(pluginId, "showSparklines");
        if (val !== undefined && val !== null) showSparklines = val;
    }

    function loadStockData() {
        // Use the standard PluginService to load the stock list
        var savedStocks = PluginService.loadPluginData(pluginId, "stocks");

        if (savedStocks && Array.isArray(savedStocks) && savedStocks.length > 0) {
            var loaded = [];
            for (var i = 0; i < savedStocks.length; i++) {
                var s = Utils.createStock(savedStocks[i].code, savedStocks[i].name);
                s._uiIndex = i;
                loaded.push(s);
            }
            stocks = loaded;
            forceUpdateLists();
            fetchStockData();
            return;
        }

        loadDefaultStocks();
    }

    function loadDefaultStocks() {
        var defaults = [
            {code: Utils.STOCK_CODES.SH_INDEX, name: "上证指数"},
            {code: "sz000559", name: "万向钱潮"},
            {code: "sz002195", name: "岩山科技"}
        ];
        var s = [];
        for (var i = 0; i < defaults.length; i++) {
            var item = Utils.createStock(defaults[i].code, defaults[i].name);
            item._uiIndex = i;
            s.push(item);
        }
        stocks = s;
        forceUpdateLists();
        fetchStockData();
    }

    function saveStockData() {
        var toSave = stocks.slice();
        toSave.sort(function (a, b) {
            return (a._uiIndex || 0) - (b._uiIndex || 0);
        });
        var data = toSave.map(s => ({code: s.code, name: s.name}));
        PluginService.savePluginData(pluginId, "stocks", data);
    }

    function getChangeColor(change) {
        if (change > 0) return upColor;
        if (change < 0) return downColor;
        return Utils.COLORS.NEUTRAL;
    }

    // Trigger a debounced update
    function updateDerivedLists() {
        updateDebounceTimer.restart();
    }

    function forceUpdateLists() {
        // 1. Display Stocks (excluding SH Index)
        var dResult = [];
        var filter = root.filterText.toLowerCase().trim();

        for (var i = 0; i < stocks.length; i++) {
            var s = stocks[i];
            if (Utils.isMarketIndex(s.code)) continue;

            if (filter !== "") {
                var name = (s.name || "").toLowerCase();
                var code = (s.code || "").toLowerCase();
                var pinyin = Utils.getFirstPinyinLetter(s.name || "").toLowerCase();
                if (name.indexOf(filter) === -1 && code.indexOf(filter) === -1 && pinyin.indexOf(filter) === -1) {
                    continue;
                }
            }
            dResult.push(s);
        }
        displayStocks = dResult;

        // 2. Pinned Stocks
        var pResult = [];
        if (pinnedCodes && pinnedCodes.length > 0) {
            for (var j = 0; j < pinnedCodes.length; j++) {
                var c = String(pinnedCodes[j]).trim().toLowerCase();
                var found = false;
                for (var k = 0; k < stocks.length; k++) {
                    if (String(stocks[k].code).toLowerCase() === c) {
                        pResult.push(stocks[k]);
                        found = true;
                        break;
                    }
                }
                
                // If not found in main stocks (e.g. SH Index is separate), check if it's the index
                if (!found && c === Utils.STOCK_CODES.SH_INDEX.toLowerCase()) {
                    if (shIndex) pResult.push(shIndex);
                }
            }
        }
        pinnedStocks = pResult;

        // Removed global var syncs as we are now using properties directly
    }

    // --- API Actions ---

    function fetchStockData() {
        if (stocks.length === 0) return;
        isLoading = true;

        var codes = stocks.map(s => s.code);
        var batchSize = 50;
        var pendingRequests = Math.ceil(codes.length / batchSize);
        var completedRequests = 0;

        for (var i = 0; i < codes.length; i += batchSize) {
            var batchCodes = codes.slice(i, i + batchSize);
            stockApi.fetchQuotes(batchCodes, function (results) {
                if (results && results.length > 0) {
                    applyQuotes(results);
                }
                completedRequests++;
                if (completedRequests >= pendingRequests) isLoading = false;
            });
        }

        fetchHistoryData();
    }

    function fetchHistoryData() {
        var count = Math.min(displayStocks.length, 30);
        for (var i = 0; i < count; i++) {
            let stockCode = displayStocks[i].code;
            stockApi.fetchIntraday(stockCode, function (history) {
                if (history && history.length > 0) {
                    var updated = false;
                    for (var j = 0; j < stocks.length; j++) {
                        if (stocks[j].code === stockCode) {
                            stocks[j].history = history;
                            updated = true;
                            break;
                        }
                    }
                    if (updated) updateDerivedLists();
                }
            });
        }
    }

    function applyQuotes(results) {
        var stockMap = {};
        for (var i = 0; i < stocks.length; i++) stockMap[stocks[i].code] = i;

        var newStocks = Utils.cloneStocks(stocks);

        for (var j = 0; j < results.length; j++) {
            var parsed = results[j];
            var idx = stockMap[parsed.code];

            if (idx === undefined) continue;

            var oldStock = newStocks[idx];
            var newStock = {
                code: oldStock.code,
                name: parsed.name || oldStock.name,
                currentPrice: parsed.currentPrice > 0 ? parsed.currentPrice : oldStock.currentPrice,
                prevClose: parsed.currentPrice > 0 ? parsed.prevClose : oldStock.prevClose,
                changeAmount: parsed.currentPrice > 0 ? parsed.changeAmount : oldStock.changeAmount,
                changePercent: parsed.currentPrice > 0 ? parsed.changePercent : oldStock.changePercent,
                history: oldStock.history,
                _uiIndex: oldStock._uiIndex
            };

            if (parsed.currentPrice > 0 && Utils.isMarketIndex(newStock.code)) {
                shIndex = newStock;
            }

            newStocks[idx] = newStock;
        }

        stocks = newStocks;
        lastUpdateDate = new Date();
        updateDerivedLists();
    }

    // --- UI Helpers ---

    function isPinned(code) {
        if (!code) return false;
        var codes = (pinnedCodes && Array.isArray(pinnedCodes)) ? pinnedCodes : [];
        return codes.indexOf(String(code).toLowerCase()) >= 0;
    }

    function getPopoutHeight() {
        return Utils.calculatePopoutHeight(stocks);
    }

    function togglePin(code) {
        var codes = Array.from(pinnedCodes);
        var idx = codes.indexOf(code);
        if (idx >= 0) codes.splice(idx, 1);
        else codes.push(code);
        pinnedCodes = codes; 
        saveSetting("pinnedCodes", pinnedCodes);
        forceUpdateLists();
    }

    function addStock(code, name) {
        if (stocks.some(s => s.code === code)) return;

        var newStock = Utils.createStock(code, name);
        var maxIndex = -1;
        for (var i = 0; i < stocks.length; i++) {
            if ((stocks[i]._uiIndex || 0) > maxIndex) maxIndex = stocks[i]._uiIndex || 0;
        }
        newStock._uiIndex = maxIndex + 1;

        var newStocks = Utils.cloneStocks(stocks);

        if (root.sortKey === "") {
            var insertIdx = 0;
            if (newStocks.length > 0 && Utils.isMarketIndex(newStocks[0].code)) {
                insertIdx = 1;
            }
            newStocks.splice(insertIdx, 0, newStock);
            for (var j = 0; j < newStocks.length; j++) newStocks[j]._uiIndex = j;
            stocks = newStocks;
        } else {
            newStocks.push(newStock);
            stocks = newStocks;
            applyCurrentSort();
        }

        saveStockData();
        forceUpdateLists();
        fetchStockData();
    }

    function removeStock(code) {
        var oldLen = stocks.length;
        stocks = stocks.filter(s => s.code !== code);
        if (stocks.length !== oldLen) {
            saveStockData();
            if (pinnedCodes.indexOf(code) !== -1) {
                pinnedCodes = pinnedCodes.filter(c => c !== code); 
                saveSetting("pinnedCodes", pinnedCodes);
            }
            forceUpdateLists();
        }
    }

    function moveStock(displayIndex, direction) {
        if (displayIndex === -1 || displayStocks.length <= 1) return;

        var stockToMove = displayStocks[displayIndex];
        var actualIndex = -1;
        for (var i = 0; i < stocks.length; i++) {
            if (stocks[i].code === stockToMove.code) {
                actualIndex = i;
                break;
            }
        }

        if (actualIndex === -1) return;
        var targetIndex = actualIndex + direction;

        if (targetIndex < 0 || targetIndex >= stocks.length) return;
        if (Utils.isMarketIndex(stocks[targetIndex].code) || Utils.isMarketIndex(stocks[actualIndex].code)) return;

        root.sortKey = "";

        var newStocks = Utils.cloneStocks(stocks);
        var temp = newStocks[actualIndex];
        newStocks[actualIndex] = newStocks[targetIndex];
        newStocks[targetIndex] = temp;

        for (var j = 0; j < newStocks.length; j++) {
            newStocks[j]._uiIndex = j;
        }

        stocks = newStocks;
        saveStockData();
        forceUpdateLists();
    }

    function sortStocks(key) {
        if (stocks.length === 0) return;

        if (root.sortKey === key) {
            var defaultAsc = (key === "name" || key === "code");
            if (root.sortAscending === defaultAsc) {
                root.sortAscending = !root.sortAscending;
            } else {
                root.sortKey = "";
                root.sortAscending = true;
            }
        } else {
            root.sortKey = key;
            root.sortAscending = (key === "name" || key === "code");
        }

        applyCurrentSort();
    }

    function applyCurrentSort() {
        if (stocks.length === 0) return;

        var key = root.sortKey;
        var indexStock = null;
        var others = [];
        for (var i = 0; i < stocks.length; i++) {
            if (Utils.isMarketIndex(stocks[i].code)) indexStock = stocks[i];
            else others.push(stocks[i]);
        }

        others.sort(function (a, b) {
            if (!key) {
                return (a._uiIndex || 0) - (b._uiIndex || 0);
            }

            var dir = root.sortAscending ? 1 : -1;
            var av, bv;
            switch (key) {
                case "name":
                    av = a.name || "";
                    bv = b.name || "";
                    break;
                case "code":
                    av = Utils.getPureCode(a.code);
                    bv = Utils.getPureCode(b.code);
                    break;
                case "price":
                    av = a.currentPrice || 0;
                    bv = b.currentPrice || 0;
                    break;
                case "change":
                    av = a.changeAmount || 0;
                    bv = b.changeAmount || 0;
                    break;
                case "percent":
                    av = a.changePercent || 0;
                    bv = b.changePercent || 0;
                    break;
                default:
                    return 0;
            }
            if (av === bv) return 0;
            return av > bv ? dir : -dir;
        });

        var newStocks = [];
        if (indexStock) newStocks.push(indexStock);
        for (var j = 0; j < others.length; j++) newStocks.push(others[j]);
        stocks = newStocks;
        forceUpdateLists();
    }

    function previewStock(code, callback) {
        if (!code) return callback(null);
        stockApi.fetchQuotes([code], function (results) {
            if (results && results.length > 0) callback(results[0]);
            else callback(null);
        });
    }

    function searchStocks(keyword, callback) {
        stockApi.searchStocks(keyword, callback);
    }
}
