import QtQuick
import QtQuick.Shapes
import qs.Common
import "../services/StockUtils.js" as Utils

/*
 * StockSparkline.qml - Draws a mini trend chart based on price history
 * When trading is in progress, the chart uses trading time progress to scale the X-axis
 */

Item {
    id: root
    property var history: []
    property color lineColor: Theme.primary
    property real tradingProgress: Utils.getTradingProgress()

    width: 40; height: 16
    opacity: history && history.length > 1 ? 0.8 : 0

    // Update trading progress during trading hours
    Timer {
        interval: 5000 // Update every 5 seconds
        running: true
        repeat: true
        onTriggered: root.tradingProgress = Utils.getTradingProgress()
    }

    Shape {
        id: chartShape
        anchors.fill: parent
        antialiasing: true
        vendorExtensionsEnabled: true

        // 1. Fill Gradient
        ShapePath {
            strokeColor: "transparent"
            fillColor: "transparent"

            fillGradient: LinearGradient {
                y1: 0; y2: root.height
                GradientStop {
                    position: 0.0; color: Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, 0.3)
                }
                GradientStop {
                    position: 1.0; color: "transparent"
                }
            }

            PathPolyline {
                path: {
                    if (!root.history || root.history.length < 2) return [];
                    var pts = root.calculatePoints();
                    if (pts.length === 0) return [];
                    // Close the path for filling
                    return pts.concat([Qt.point(root.width, root.height), Qt.point(0, root.height)]);
                }
            }
        }

        // 2. Stroke Line
        ShapePath {
            strokeColor: root.lineColor
            strokeWidth: 1.5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: root.calculatePoints()
            }
        }
    }

    function calculatePoints() {
        if (!root.history || root.history.length < 2) return [];

        // Convert to JS array if needed (handle QList/ListModel types)
        var data = root.history;
        if (!Array.isArray(data)) {
            data = Array.from(data);
        }

        var points = [];
        
        // Handle both objects {time, price} and raw numbers
        var prices = data.map(function(d) {
            return (d && typeof d === 'object') ? d.price : d;
        });

        var min = Math.min.apply(null, prices);
        var max = Math.max.apply(null, prices);
        var range = max - min;
        if (range === 0) range = 1;

        // Use trading progress to scale the X-axis
        // When trading is in progress, the chart should only occupy the portion
        // of the day that has elapsed in trading time
        var maxX = root.width * root.tradingProgress;

        var stepX = data.length > 1 ? maxX / (data.length - 1) : root.width;
        for (var i = 0; i < data.length; i++) {
            var x = i * stepX;
            var val = prices[i];
            var y = root.height - ((val - min) / range * root.height);
            points.push(Qt.point(x, y));
        }
        return points;
    }
}