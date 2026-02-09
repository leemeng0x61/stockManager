import QtQuick
import Quickshell
import Quickshell.Io
import "./StockUtils.js" as Utils

/*
 * StockApiService.qml - Specialized service for handling external API requests
 * Encapsulates fetch and parse logic to allow easy swapping of data providers.
 */

Item {
    id: root

    // --- Configuration: Current Providers ---
    readonly property string quoteProvider: "tencent"
    readonly property string intradayProvider: "sina"

    // --- Internal Process Helper ---
    Component {
        id: procComp
        Process {
            id: procInstance
            property var callback
            property string outputBuffer: ""

            stdout: StdioCollector {
                onStreamFinished: procInstance.outputBuffer = text
            }

            onExited: (ec) => {
                // Wait for the next event loop to ensure any pending dataRead 
                // signals have been processed.
                Qt.callLater(function () {
                    if (callback) {
                        callback(outputBuffer, ec);
                        callback = null;
                    }
                    destroy();
                });
            }
        }
    }

    function runCommand(args, callback) {
        var p = procComp.createObject(root, {
            command: args,
            callback: callback
        });
        p.running = true;
    }

    // --- Public Interface ---

    /**
     * Fetch real-time quotes for a list of stock codes
     */
    function fetchQuotes(codes, callback) {
        if (!codes || codes.length === 0) return callback([]);

        var url = "";
        if (quoteProvider === "tencent") {
            url = "https://qt.gtimg.cn/q=" + codes.join(",");
        }

        var cmd = `curl -s --max-time 10 "${url}" | iconv -f GBK -t UTF-8`;

        runCommand(["sh", "-c", cmd], function (out, ec) {
            if (ec !== 0 || !out) return callback([]);

            var results = [];
            var lines = out.trim().split('\n');
            for (var i = 0; i < lines.length; i++) {
                var parsed = parseQuoteLine(lines[i], quoteProvider);
                if (parsed) results.push(parsed);
            }
            if (callback) callback(results);
        });
    }

    /**
     * Fetch intraday time-sharing data for a single stock
     */
    function fetchIntraday(code, callback) {
        if (!code) return callback([]);

        var url = "";
        if (intradayProvider === "sina") {
            url = `https://quotes.sina.cn/cn/api/jsonp.php/var_${code}=/CN_MarketDataService.getKLineData?symbol=${code}&scale=5&ma=no&datalen=80`;
        }

        var cmd = `curl -s --max-time 5 "${url}"`;

        runCommand(["sh", "-c", cmd], function (out, ec) {
            if (ec !== 0 || !out) return callback([]);
            var history = parseIntradayData(out, intradayProvider);
            callback(history);
        });
    }

    /**
     * Search/Suggest stocks by keyword
     */
    function searchStocks(keyword, callback) {
        if (!keyword || keyword.trim().length < 1) return callback([]);

        var url = `http://suggest3.sinajs.cn/suggest/type=11,12&key=${encodeURIComponent(keyword)}`;
        var cmd = `curl -s --max-time 5 "${url}" | iconv -f GBK -t UTF-8`;

        runCommand(["sh", "-c", cmd], function (out, ec) {
            if (ec === 0 && out) callback(Utils.parseSuggestions(out.trim()));
            else callback([]);
        });
    }

    // --- Private Parsers ---

    function parseQuoteLine(line, provider) {
        if (provider === "tencent") {
            return Utils.parseApiLine(line);
        }
        return null;
    }

    function parseIntradayData(data, provider) {
        if (provider === "sina") {
            try {
                var startIdx = data.indexOf('=(');
                var endIdx = data.lastIndexOf(');');
                if (startIdx !== -1 && endIdx !== -1) {
                    var jsonStr = data.substring(startIdx + 2, endIdx);
                    var json = JSON.parse(jsonStr);
                    if (Array.isArray(json) && json.length > 0) {
                        // Get the date of the latest data point
                        var lastItem = json[json.length - 1];
                        var lastDate = lastItem.day.split(' ')[0];
                        
                        // Filter to keep only items from the same day
                        var todaysData = json.filter(item => item.day.startsWith(lastDate));
                        
                        return todaysData.map(function(item) {
                            var timeStr = item.day.split(' ')[1]; // "13:05:00"
                            if (timeStr && timeStr.length >= 5) {
                                timeStr = timeStr.substring(0, 5); // "13:05"
                            }
                            return {
                                time: timeStr,
                                price: parseFloat(item.close)
                            };
                        });
                    }
                }
            } catch (e) {
            }
        }
        return [];
    }
}