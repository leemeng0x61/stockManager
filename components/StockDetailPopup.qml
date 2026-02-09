import QtQuick
import QtQuick.Shapes
import "../services/StockUtils.js" as Utils
import "../services"
import ".."
import qs.Common
import qs.Widgets

/*
 * StockDetailPopup.qml - Overlay detail chart for a specific stock
 */

Item {
    id: root
    anchors.fill: parent
    z: 100 // On top of everything

    property var stock: null // The stock data object
    signal close()

    // Geometry for animation
    property real startX: 0
    property real startY: 0
    property real startW: 0
    property real startH: 0

    visible: opacity > 0
    opacity: 0
    enabled: state === "expanded"
    focus: true

    Keys.enabled: state === "expanded"
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            root.closeRequest();
            event.accepted = true;
        }
    }

    // Tooltip properties
    property real tooltipX: 0
    property real tooltipY: 0
    property var tooltipData: null
    property bool isHovering: false

    // Dimmed background
    Rectangle {
        id: dimBackground
        anchors.fill: parent
        color: "#80000000"
        opacity: 0
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequest()
        }
    }

    // Chart Container
    Rectangle {
        id: chartCard
        // Initial state matches start geometry
        x: startX
        y: startY
        width: startW
        height: startH
        
        color: Theme.surface
        radius: 8
        border.color: Theme.primary
        border.width: 1
        clip: true

        // Consume clicks inside the card to also close it
        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequest()
        }

        // Content Wrapper for Opacity Animation
        Item {
            id: contentWrapper
            anchors.fill: parent
            opacity: 0

            // Title Header
            Item {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                height: 30

                Row {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    spacing: 10

                    StyledText {
                        text: root.stock ? root.stock.name : ""
                        font.bold: true
                        font.pixelSize: Theme.fontSizeLarge
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: root.stock ? Utils.getPureCode(root.stock.code) : ""
                        color: Theme.secondary
                        font.pixelSize: Theme.fontSizeMedium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    spacing: 10

                                    StyledText {
                                        text: root.stock ? Utils.formatNumber(root.stock.currentPrice) : ""
                                        font.bold: true
                                        font.pixelSize: Theme.fontSizeLarge
                                        color: root.stock ? StockService.getChangeColor(root.stock.changeAmount) : Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    
                                    StyledText {
                                        text: root.stock ? Utils.formatPercent(root.stock.changePercent) : ""
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: root.stock ? StockService.getChangeColor(root.stock.changeAmount) : Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }                }
            }

            // Canvas for drawing the chart
            Canvas {
                id: chartCanvas
                anchors.top: header.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 10
                
                renderTarget: Canvas.FramebufferObject
                renderStrategy: Canvas.Threaded
            }

            // Hover MouseArea
            MouseArea {
                id: hoverArea
                anchors.fill: chartCanvas
                hoverEnabled: true
                onClicked: root.closeRequest() // Click still closes
                onPositionChanged: (mouse) => {
                     // Need chart metrics for interaction
                     var w = chartCanvas.width;
                     var leftMargin = 0; 
                     var chartW = w - leftMargin;
                     var xStep = chartW / 47; 
                     
                     // We need to pass raw mouse coords to paint or do logic here?
                     // Let's pass raw mouse coords and let onPaint handle mapping
                     
                     root.tooltipX = mouse.x;
                     root.tooltipY = mouse.y;
                     
                     // Approximate data for tooltip (optional, precise one done in onPaint)
                     // But we need to know if we are hovering valid area?
                     root.isHovering = true;
                     chartCanvas.requestPaint();
                }
                onExited: {
                    root.isHovering = false;
                    chartCanvas.requestPaint();
                }
            }

            // QML Tooltip Overlay
            Rectangle {
                id: tooltip
                width: tooltipRow.width + 16
                height: tooltipRow.height + 12
                radius: 6
                color: Theme.surface
                border.color: Theme.surfaceVariant
                border.width: 1
                
                visible: root.isHovering
                opacity: visible ? 1 : 0
                
                // Position logic: floating near point
                x: {
                    var tx = root.tooltipX + 10;
                    if (tx + width > chartCanvas.width) tx = root.tooltipX - width - 10;
                    return Math.max(0, tx) + chartCanvas.x; // Add canvas offset
                }
                y: {
                    return root.tooltipY + chartCanvas.y - height - 10; 
                }

                Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
                Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

                Row {
                    id: tooltipRow
                    anchors.centerIn: parent
                    spacing: 8
                    
                                StyledText {
                                    text: root.tooltipData ? (root.tooltipData.time || "--:--") : ""
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceText
                                }
                                StyledText {
                                    text: root.tooltipData ? (typeof root.tooltipData.price === 'number' ? root.tooltipData.price.toFixed(2) : "--") : ""
                                    font.bold: true
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: {
                                        if (!root.tooltipData || typeof root.tooltipData.price !== 'number' || !root.stock) return Theme.surfaceText;
                                        var change = root.tooltipData.price - root.stock.prevClose;
                                        return StockService.getChangeColor(change);
                                    }
                                }
                                StyledText {
                                    text: {
                                         if (!root.tooltipData || typeof root.tooltipData.price !== 'number' || !root.stock) return "--%";
                                         return ((root.tooltipData.price - root.stock.prevClose) / root.stock.prevClose * 100).toFixed(2) + "%";
                                    }
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: {
                                        if (!root.tooltipData || typeof root.tooltipData.price !== 'number' || !root.stock) return Theme.surfaceText;
                                        var change = root.tooltipData.price - root.stock.prevClose;
                                        return StockService.getChangeColor(change);
                                    }
                                }                }
            }
        }
    }

    onStockChanged: chartCanvas.requestPaint()

    // Animation States
    states: [
        State {
            name: "expanded"
            PropertyChanges { target: root; opacity: 1 }
            PropertyChanges { target: dimBackground; opacity: 1 }
            // Center the card
            PropertyChanges { 
                target: chartCard
                x: (root.width - 380) / 2
                y: (root.height - 240) / 2
                width: 380
                height: 240
                radius: 16
                border.color: Theme.surfaceVariant
            }
            PropertyChanges { target: contentWrapper; opacity: 1 }
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "expanded"
            ParallelAnimation {
                NumberAnimation { target: root; property: "opacity"; duration: 150 }
                NumberAnimation { target: dimBackground; property: "opacity"; duration: 250 }
                NumberAnimation { 
                    target: chartCard
                    properties: "x,y,width,height,radius"
                    duration: 350
                    easing.type: Easing.OutCubic
                }
                ColorAnimation { target: chartCard; property: "border.color"; duration: 350 }
                SequentialAnimation {
                    PauseAnimation { duration: 150 }
                    NumberAnimation { target: contentWrapper; property: "opacity"; duration: 200 }
                }
            }
        },
        Transition {
            from: "expanded"
            to: ""
            ParallelAnimation {
                NumberAnimation { target: contentWrapper; property: "opacity"; duration: 100 }
                NumberAnimation { 
                    target: chartCard
                    properties: "x,y,width,height,radius"
                    duration: 250
                    easing.type: Easing.InCubic
                }
                ColorAnimation { target: chartCard; property: "border.color"; duration: 250 }
                NumberAnimation { target: dimBackground; property: "opacity"; duration: 250 }
                NumberAnimation { target: root; property: "opacity"; duration: 250 }
            }
        }
    ]

    function open(x, y, w, h, stockData) {
        root.startX = x;
        root.startY = y;
        root.startW = w;
        root.startH = h;
        root.stock = stockData;
        root.state = "expanded";
        Qt.callLater(() => root.forceActiveFocus());
    }

    function closeRequest() {
        root.state = "";
        root.close(); // Emit signal
    }

    Connections {
        target: chartCanvas
        function onPaint() {
            var ctx = chartCanvas.getContext("2d");
            var w = chartCanvas.width;
            var h = chartCanvas.height;
            
            // Define margins
            var leftMargin = 0; 
            var verticalMargin = 20;
            var chartW = w - leftMargin;
            var drawHeight = h - 2 * verticalMargin;
            
            function toColorStr(c, alpha) {
                // Handle hex strings (e.g. "#ff0000")
                if (typeof c === 'string') return c;
                
                // Handle Qt Color objects
                if (c && c.r !== undefined) {
                    var a = (alpha !== undefined) ? alpha : (c.a !== undefined ? c.a : 1.0);
                    return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")";
                }
                return "black";
            }
            
            ctx.clearRect(0, 0, w, h);
            ctx.beginPath(); // Clear any previous paths to prevent ghosting

            if (!root.stock || !root.stock.history || root.stock.history.length === 0) {
                return;
            }

            var data = root.stock.history; 
            var prevClose = root.stock.prevClose;

            // 1. Calculate Range
            var maxPrice = 0;
            var minPrice = Number.MAX_VALUE;
            
            for (var i = 0; i < data.length; i++) {
                var p = (typeof data[i] === 'object') ? data[i].price : data[i];
                if (p > maxPrice) maxPrice = p;
                if (p < minPrice) minPrice = p;
            }

            if (maxPrice === 0) maxPrice = prevClose;
            if (minPrice === Number.MAX_VALUE) minPrice = prevClose;

            var maxDiff = Math.max(Math.abs(maxPrice - prevClose), Math.abs(minPrice - prevClose));
            if (maxDiff < prevClose * 0.005) maxDiff = prevClose * 0.005;

            var topPrice = prevClose + maxDiff;
            var bottomPrice = prevClose - maxDiff;
            var range = topPrice - bottomPrice;
            
            // Map data to width
            var xStep = chartW / 47; 

            // Helper for Y mapping
            function getY(val) {
                return (h - verticalMargin) - ((val - bottomPrice) / range * drawHeight);
            }
            
            // Helper: Map time string "HH:mm" to X coordinate
            function getX(timeStr) {
                if (!timeStr) return leftMargin;
                var parts = timeStr.split(":");
                if (parts.length < 2) return leftMargin;
                
                var h = parseInt(parts[0]);
                var m = parseInt(parts[1]);
                var totalMin = h * 60 + m;
                
                var offset = 0;
                if (totalMin < 570) offset = 0;
                else if (totalMin <= 690) offset = totalMin - 570;
                else if (totalMin < 780) offset = 120; 
                else if (totalMin <= 900) offset = 120 + (totalMin - 780);
                else offset = 240;
                
                return leftMargin + (offset / 240.0) * chartW;
            }

            // 2. Draw Grid / Axes
            ctx.lineWidth = 0.5;
            ctx.strokeStyle = toColorStr(Utils.COLORS.NEUTRAL, 0.6);

            var zeroY = getY(prevClose);

            ctx.beginPath();
            ctx.setLineDash([4, 2]);
            ctx.moveTo(leftMargin, zeroY);
            ctx.lineTo(w, zeroY);
            ctx.stroke();
            ctx.setLineDash([]);

            // Limit Lines
            var limitUp = prevClose * 1.1;
            var limitDown = prevClose * 0.9;
            ctx.setLineDash([2, 2]);
            
            if (limitUp <= topPrice && limitUp >= bottomPrice) {
                var luY = getY(limitUp);
                ctx.strokeStyle = Utils.COLORS.UP; 
                ctx.beginPath();
                ctx.moveTo(leftMargin, luY);
                ctx.lineTo(w, luY);
                ctx.stroke();
            }

            if (limitDown <= topPrice && limitDown >= bottomPrice) {
                var ldY = getY(limitDown);
                ctx.strokeStyle = Utils.COLORS.DOWN;
                ctx.beginPath();
                ctx.moveTo(leftMargin, ldY);
                ctx.lineTo(w, ldY);
                ctx.stroke();
            }
            ctx.setLineDash([]);

            // Determine dynamic line color
            var lineColor = Theme.primary;
            if (root.stock) {
                 lineColor = StockService.getChangeColor(root.stock.changeAmount);
            }

            // 2.5 Draw Current Price Label & Line (Before Polyline)
            if (data.length > 0) {
                var lastItem = data[data.length - 1];
                var curPrice = (typeof lastItem === 'object') ? lastItem.price : lastItem;
                var curY = getY(curPrice);

                // Label Content - calculate change based on history data point
                var priceChange = curPrice - prevClose;
                var pctVal = priceChange / prevClose * 100;
                var sign = pctVal >= 0 ? "+" : "";
                var txt = sign + pctVal.toFixed(2) + "%";

                // Determine text color based on actual price change
                var priceColor = StockService.getChangeColor(priceChange);

                ctx.font = "bold 11px sans-serif";
                var tm = ctx.measureText(txt);
                var textW = tm.width;

                // Dashed Line (Full width)
                ctx.beginPath();
                ctx.setLineDash([4, 4]);
                ctx.strokeStyle = toColorStr(Theme.primary, 0.8);
                ctx.lineWidth = 0.5;
                ctx.moveTo(0, curY);
                ctx.lineTo(w, curY);
                ctx.stroke();
                ctx.setLineDash([]);

                // Text (Right side, below line)
                // 重置阴影和透明度属性，确保颜色正确显示
                ctx.shadowColor = "transparent";
                ctx.shadowBlur = 0;
                ctx.shadowOffsetX = 0;
                ctx.shadowOffsetY = 0;
                ctx.globalAlpha = 1.0;
                ctx.save();
                ctx.fillStyle = toColorStr(priceColor);
                ctx.textBaseline = "top";
                ctx.fillText(txt, w - textW, curY + 2);
                ctx.restore();
            }

            // 3. Draw Line
            ctx.beginPath();
            
            ctx.strokeStyle = toColorStr(lineColor);
            ctx.lineWidth = 1.5;

            for (var j = 0; j < data.length; j++) {
                var item = data[j];
                var val = (typeof item === 'object') ? item.price : item;
                var time = (typeof item === 'object') ? item.time : "09:30";
                
                var x = getX(time);
                var y = getY(val);
                
                if (j === 0) ctx.moveTo(x, y);
                else ctx.lineTo(x, y);
            }
            ctx.stroke();
            ctx.lineWidth = 1; 

            // 4. Hover Crosshair
            if (root.isHovering) {
                var mx = root.tooltipX; 
                
                var bestDist = Number.MAX_VALUE;
                var bestItem = null;
                var bestX = 0;
                var bestY = 0;
                
                for (var k = 0; k < data.length; k++) {
                    var itemK = data[k];
                    var timeK = (typeof itemK === 'object') ? itemK.time : "09:30";
                    var xK = getX(timeK);
                    var dist = Math.abs(xK - mx);
                    
                    if (dist < bestDist) {
                        bestDist = dist;
                        bestItem = itemK;
                        bestX = xK;
                        var valK = (typeof itemK === 'object') ? itemK.price : itemK;
                        bestY = getY(valK);
                        root.tooltipData = itemK; // Sync tooltip data
                    }
                }
                
                if (bestItem) {
                    ctx.strokeStyle = toColorStr(Theme.primary, 0.8);
                    ctx.lineWidth = 0.5;
                    ctx.setLineDash([4, 4]);
                    
                    ctx.beginPath();
                    ctx.moveTo(bestX, 0);
                    ctx.lineTo(bestX, h);
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.moveTo(leftMargin, bestY);
                    ctx.lineTo(w, bestY);
                    ctx.stroke();
                    
                    ctx.setLineDash([]);
                }
            }
        }
    }
}