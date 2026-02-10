/*
 * StockUtils.js - Utility functions for StockManager plugin
 * Constants and helper functions for stock data processing
 */
"use strict";

// i18n data
var i18n = {
    "zh_CN": {
        "Name": "名字",
        "Code": "编码",
        "Price": "最新",
        "Change": "涨跌",
        "Percent": "涨幅",
        "Loading...": "加载中...",
        "Stocks": "只股票",
        "Updated: ": "最后更新: ",
        "Never": "从未",
        "Stock Manager": "Stock Manager",
        "Add Stock": "添加股票",
        "Stock Code": "股票代码",
        "Stock Name": "股票名称",
        "Confirm": "确认",
        "Cancel": "取消",
        "e.g., 600000": "例如: 600000",
        "e.g., Bank Name": "例如: 浦发银行",
        "Delete": "删除",
        "Search Name/Code/Pinyin": "搜索名称/代码/拼音",
        "Use Raw Code: ": "使用原始代码: ",
        "Stock not found: ": "无法查询到股票信息: ",
        "Stock Manager Settings": "Stock Manager 设置",
        "Trend Colors": "涨跌颜色",
        "Up (Rise)": "上涨 (红/涨)",
        "Down (Fall)": "下跌 (绿/跌)",
        "Status Bar Display": "状态栏显示",
        "Max Stocks:": "最大显示数量:",
        "Allow Scrolling (Status Bar)": "允许滚动 (状态栏)",
        "List Display": "列表显示",
        "Show Sparklines (Charts)": "显示走势图 (图表)",
        "Display Mode": "状态栏显示模式",
        "No stocks tracked": "暂无关注股票",
        "Add stocks to monitor real-time prices and trends.": "添加股票以监控实时价格和走势。",
        "Choose how values are displayed in the status bar.": "选择状态栏中数值的显示方式",
        "Percent (%)": "百分比 (%)",
        "Amount": "数值",
        "Name Format": "名称显示格式",
        "Choose how stock names are displayed.": "选择状态栏中股票名称的显示方式",
        "None": "无",
        "Pinyin (P)": "拼音首字母 (P)",
        "Hanzi (汉)": "汉字首字 (汉)",
        "Alert Settings": "涨跌提醒设置",
        "Enable Alert": "启用提醒",
        "Alert Threshold (%)": "涨跌阈值 (%)",
        "Alert when change exceeds": "当涨跌幅超过此值时提醒",
        "Save": "保存",
        "Stock Alert Settings": "股票提醒设置",
        "Full Name": "完整名称",
        "Refresh Interval": "后台刷新间隔",
        "Choose background update frequency.": "选择后台数据更新频率",
        "About": "关于",
        "To pin stocks, click 'Edit' in the main panel and toggle the pin icon. Font size can be adjusted in system settings.": "如需固定股票到状态栏，请在主面板点击\"编辑\"按钮进入模式，点击置顶图标。状态栏字体大小可在系统状态栏设置中调整。",
        "Stock Alert": "股票提醒",
        "up": "上涨",
        "down": "下跌",
        "changed": "涨跌幅达到"
    },
    "en_US": {
        "Name": "Name",
        "Code": "Code",
        "Price": "Price",
        "Change": "Change",
        "Percent": "Percent",
        "Stock Alert": "Stock Alert",
        "up": "up",
        "down": "down",
        "changed": "changed"
    }
};

/**
 * Global translate function
 * Returns translated text based on current locale
 */
function t(key) {
    var locale = Qt.locale().name.startsWith("zh") ? "zh_CN" : "en_US";
    return (i18n[locale] && i18n[locale][key]) ? i18n[locale][key] : key;
}

// Market type prefixes
var MARKET_PREFIX = {
    SHANGHAI: "sh",
    SHENZHEN: "sz",
    HONG_KONG: "hk",
    USA: "us"
};

// Color constants - will be updated by StockService
var COLORS = {
    UP: "#ff4d4f",      // Default Red
    DOWN: "#52c41a",    // Default Green
    NEUTRAL: "#888888",
    WHITE: "#ffffff",
    DELETE: "#ff4d4f"
};

// UI Constants
var UI = {
    HEADER_HEIGHT: 30,
    ROW_HEIGHT: 32,
    ROW_SPACING: 2,
    DIALOG_WIDTH: 280,
    DIALOG_HEIGHT: 160,
    DELETE_BUTTON_WIDTH: 52,
    DELETE_THRESHOLD: -35,
    DELETE_MAX_DRAG: -70,
    REFRESH_INTERVAL: 30000, // 30 seconds
    POPOUT_MIN_HEIGHT: 320,
    POPOUT_MAX_HEIGHT: 750,
    POPOUT_BASE_HEIGHT: 180
};

// Column widths
var COLUMN_WIDTH = {
    NAME: 120,
    CODE: 70,
    PRICE: 60,
    CHANGE: 60,
    PERCENT: 70
};

// API endpoints
var API = {
    TENCENT_QUOTE: "https://qt.gtimg.cn/q="
};

// Stock codes
var STOCK_CODES = {
    SH_INDEX: "sh000001"
};

/**
 * Get country emoji from stock code
 * @param {string} code - Stock code with prefix
 * @returns {string} Emoji representing the market
 */
function getCountryEmoji(code) {
    if (!code) return "🌐";
    if (code.startsWith(MARKET_PREFIX.SHANGHAI) || code.startsWith(MARKET_PREFIX.SHENZHEN)) {
        return "🇨🇳";
    }
    if (code.startsWith(MARKET_PREFIX.USA)) return "🇺🇸";
    if (code.startsWith(MARKET_PREFIX.HONG_KONG)) return "🇭🇰";
    return "🌐";
}

/**
 * Get pure stock code without market prefix
 * @param {string} code - Stock code with prefix
 * @returns {string} Stock code without prefix
 */
function getPureCode(code) {
    if (!code) return "";
    return code.replace(/^(sh|sz|us|hk)/i, "");
}

/**
 * Determine market prefix from stock number
 * @param {string} number - Stock number (6 digits)
 * @returns {string} Market prefix (sh/sz)
 */
function getMarketPrefix(number) {
    if (!number || number.length !== 6) return MARKET_PREFIX.SHANGHAI;
    var firstDigit = number.charAt(0);
    // Shenzhen: 0xxxxx, 3xxxxx
    if (firstDigit === '0' || firstDigit === '3') {
        return MARKET_PREFIX.SHENZHEN;
    }
    // Shanghai: 6xxxxx, others default to sh
    return MARKET_PREFIX.SHANGHAI;
}

/**
 * Auto-complete stock code from input
 * @param {string} input - User input
 * @returns {string|null} Complete stock code or null
 */
function autoCompleteStockCode(input) {
    if (!input) return null;
    var pureNumber = input.replace(/[^0-9]/g, '');
    if (pureNumber.length !== 6) return null;
    return getMarketPrefix(pureNumber) + pureNumber;
}

/**
 * Get color based on profit
 * @param {number} profit - Profit amount
 * @returns {string} Color code
 */
function getProfitColor(profit) {
    if (profit > 0) return COLORS.UP;
    if (profit < 0) return COLORS.DOWN;
    return COLORS.WHITE;
}

/**
 * Format number with fixed decimal places
 * @param {number} value - Number to format
 * @param {number} digits - Decimal places (default 2)
 * @returns {string} Formatted string
 */
function formatNumber(value, digits) {
    digits = digits || 2;
    if (value === undefined || value === null || isNaN(value)) return "--";
    return value.toFixed(digits);
}

/**
 * Format change value with sign
 * @param {number} value - Change value
 * @param {number} digits - Decimal places
 * @returns {string} Formatted string with sign
 */
function formatChange(value, digits) {
    digits = digits || 2;
    if (value === undefined || value === null || isNaN(value) || value === 0) return "--";
    return (value >= 0 ? "+" : "") + value.toFixed(digits);
}

/**
 * Format percentage with sign and % symbol
 * @param {number} value - Percentage value
 * @param {number} digits - Decimal places
 * @returns {string} Formatted string with %
 */
function formatPercent(value, digits) {
    digits = digits || 2;
    if (value === undefined || value === null || isNaN(value) || value === 0) return "--";
    return (value >= 0 ? "+" : "") + value.toFixed(digits) + "%";
}

/**
 * Format time smartly.
 * If same day: HH:mm:ss
 * If different day: MM-dd HH:mm:ss
 * @param {Date} date - Date to format
 * @returns {string} Formatted string
 */
function formatSmartTime(date) {
    if (!date) return "--";

    var now = new Date();
    var isToday = (date.getDate() === now.getDate() &&
        date.getMonth() === now.getMonth() &&
        date.getFullYear() === now.getFullYear());

    var timeStr = padZero(date.getHours()) + ":" +
        padZero(date.getMinutes()) + ":" +
        padZero(date.getSeconds());

    if (isToday) {
        return timeStr;
    } else {
        return padZero(date.getMonth() + 1) + "-" +
            padZero(date.getDate()) + " " +
            timeStr;
    }
}

/**
 * Format current time as HH:MM:SS
 * @returns {string} Formatted time
 */
function getCurrentTimeString() {
    return formatSmartTime(new Date());
}

/**
 * Pad number with leading zero
 * @param {number} num - Number to pad
 * @returns {string} Padded string
 */
function padZero(num) {
    return num.toString().padStart(2, '0');
}

/**
 * Create empty stock object
 * @param {string} code - Stock code
 * @param {string} name - Stock name
 * @param {number} costPrice - Cost price (optional)
 * @returns {object} Stock object
 */
function createStock(code, name, alertEnabled, alertThreshold) {
    return {
        code: code || "",
        name: name || "",
        currentPrice: 0,
        prevClose: 0,
        changeAmount: 0,
        changePercent: 0,
        alertEnabled: alertEnabled !== undefined ? alertEnabled : false,
        alertThreshold: alertThreshold !== undefined ? alertThreshold : 3.0
    };
}

/**
 * Check if stock is market index
 * @param {string} code - Stock code
 * @returns {boolean} True if index
 */
function isMarketIndex(code) {
    return code === STOCK_CODES.SH_INDEX;
}

/**
 * Get display stocks count (excluding index)
 * @param {Array} stocks - Stock array
 * @returns {number} Count
 */
function getDisplayStockCount(stocks) {
    if (!stocks || !Array.isArray(stocks)) return 0;
    return stocks.filter(function (s) {
        return !isMarketIndex(s.code);
    }).length;
}

/**
 * Calculate popout height based on stock count
 * @param {Array} stocks - Stock array
 * @returns {number} Calculated height
 */
function calculatePopoutHeight(stocks) {
    var count = getDisplayStockCount(stocks);
    // Include row spacing in the height calculation (Row + Spacing)
    var calculated = UI.POPOUT_BASE_HEIGHT + (count * (UI.ROW_HEIGHT + UI.ROW_SPACING));
    return Math.max(UI.POPOUT_MIN_HEIGHT, Math.min(UI.POPOUT_MAX_HEIGHT, calculated));
}

/**
 * Parse API response line
 * @param {string} line - Raw API response line
 * @returns {object|null} Parsed data or null
 */
function parseApiLine(line) {
    if (!line) return null;

    var match = line.match(/v_.*="(.*)"/);
    if (!match || match.length < 2) return null;

    var parts = match[1].split('~');
    if (parts.length < 33) return null;

    var codePart = match[0].split('=')[0];
    var code = codePart.substring(codePart.indexOf('_') + 1);

    return {
        code: code,
        name: parts[1],
        currentPrice: parseFloat(parts[3]) || 0,
        prevClose: parseFloat(parts[4]) || 0,
        changeAmount: parseFloat(parts[31]) || 0,
        changePercent: parseFloat(parts[32]) || 0
    };
}

/**
 * Parse Sina suggestion API response
 * @param {string} data - Raw API response string
 * @returns {Array} List of stock objects
 */
function parseSuggestions(data) {
    if (!data) return [];

    // Remove 'var suggestvalue="' and '";'
    var match = data.match(/var suggestvalue="(.*)";/);
    if (!match || !match[1]) return [];

    var raw = match[1];
    if (!raw) return [];

    var results = [];
    var items = raw.split(';');

    for (var i = 0; i < items.length; i++) {
        var parts = items[i].split(',');
        if (parts.length < 4) continue;

        // Sina format varies, but usually:
        // parts[0]: suggest key (often name or code)
        // parts[2]: pure code
        // parts[3]: full code with prefix
        // parts[4]: name (often more accurate)

        var name = parts[0];
        if (parts.length > 4 && parts[4] && parts[4].trim() !== "") {
            name = parts[4].trim();
        }

        results.push({
            name: name,
            pureCode: parts[2],
            code: parts[3]
        });
    }

    return results;
}

/**
 * Deep clone array of stocks
 * @param {Array} stocks - Stock array
 * @returns {Array} Cloned array
 */
function cloneStocks(stocks) {
    if (!stocks || !Array.isArray(stocks)) return [];
    return stocks.map(s => ({
        code: s.code,
        name: s.name,
        currentPrice: s.currentPrice,
        prevClose: s.prevClose,
        changeAmount: s.changeAmount,
        changePercent: s.changePercent,
        history: s.history,
        _uiIndex: s._uiIndex,
        alertEnabled: s.alertEnabled,
        alertThreshold: s.alertThreshold
    }));
}

// Pinyin reference characters (approximate boundaries)
var PINYIN_REFS = [
    ['A', '阿'], ['B', '芭'], ['C', '擦'], ['D', '搭'], ['E', '蛾'],
    ['F', '发'], ['G', '噶'], ['H', '哈'], ['J', '击'], ['K', '喀'],
    ['L', '垃'], ['M', '妈'], ['N', '拿'], ['O', '哦'], ['P', '啪'],
    ['Q', '期'], ['R', '然'], ['S', '撒'], ['T', '塌'], ['W', '挖'],
    ['X', '昔'], ['Y', '压'], ['Z', '匝']
];

/**
 * Get the first letter of the Pinyin of the first Chinese character
 * @param {string} str - Input string
 * @returns {string} Pinyin first letter or original first char
 */
function getFirstPinyinLetter(str) {
    if (!str || str.length === 0) return "";
    var firstChar = str.charAt(0);

    // If it's ASCII, return uppercase
    if (firstChar.match(/[a-zA-Z]/)) {
        return firstChar.toUpperCase();
    }

    // Check against Pinyin boundaries using localeCompare
    // Note: localeCompare returns 1 if reference is "before" firstChar
    // We want the last reference that is <= firstChar

    // Check if it's a Chinese character
    if (!firstChar.match(/[\u4e00-\u9fa5]/)) {
        return firstChar;
    }

    // Iterate backwards
    for (var i = PINYIN_REFS.length - 1; i >= 0; i--) {
        var letter = PINYIN_REFS[i][0];
        var ref = PINYIN_REFS[i][1];
        if (firstChar.localeCompare(ref, 'zh-CN') >= 0) {
            return letter;
        }
    }
    return firstChar;
}

/**
 * Format status bar text
 * @param {object} stock - Stock object
 * @param {string} valueMode - "amount" or "percent"
 * @param {string} nameMode - "none", "pinyin", "hanzi"
 * @returns {string} Formatted text
 */
function formatBarText(stock, valueMode, nameMode) {
    if (!stock) return "--";

    var value = "";
    var changePercent = stock.changePercent || 0;
    var changeAmount = stock.changeAmount || 0;

    if (isNaN(changePercent)) changePercent = 0;
    if (isNaN(changeAmount)) changeAmount = 0;

    // Use Math.abs to remove sign, as color indicates direction
    if (valueMode === "percent") {
        value = Math.abs(changePercent).toFixed(2) + "%";
    } else {
        value = Math.abs(changeAmount).toFixed(2);
    }

    var prefix = "";
    if (nameMode === "pinyin") {
        prefix = getFirstPinyinLetter(stock.name) + " ";
    } else if (nameMode === "hanzi") {
        prefix = (stock.name && stock.name.length > 0 ? stock.name.charAt(0) : "") + " ";
    } else if (nameMode === "full") {
        prefix = (stock.name || "") + " ";
    }

    return prefix + value;
}

/**
 * Check if current time is within trading hours
 * A-share: Mon-Fri, 09:15-11:30, 13:00-15:00
 * We allow a buffer: 09:00-15:05
 * @returns {boolean} True if trading time
 */
function isTradingTime() {
    var now = new Date();
    var day = now.getDay();
    var hour = now.getHours();
    var minute = now.getMinutes();

    // Weekend (0=Sun, 6=Sat)
    if (day === 0 || day === 6) return false;

    // Time (09:00 - 15:05), exclude lunch break (11:35 - 12:55)
    var time = hour * 100 + minute;
    return (time >= 900 && time <= 1135) || (time >= 1255 && time <= 1505);
}

/**
 * Calculate trading progress for today (0.0 to 1.0)
 * A-share trading hours: 09:30-11:30, 13:00-15:00
 * Total: 4 hours = 240 minutes
 * @returns {number} Progress ratio, 1.0 if market closed or not trading day
 */
function getTradingProgress() {
    var now = new Date();
    var day = now.getDay();

    // Weekend - return 1.0 (full day)
    if (day === 0 || day === 6) return 1.0;

    var hour = now.getHours();
    var minute = now.getMinutes();
    var totalMinutes = hour * 60 + minute;

    // Morning session: 09:30-11:30 (570-690)
    // Afternoon session: 13:00-15:00 (780-900)

    // Before market opens
    if (totalMinutes < 570) return 0.0;

    // Morning session
    if (totalMinutes >= 570 && totalMinutes < 690) {
        return (totalMinutes - 570) / 240; // 240 = total trading minutes
    }

    // Lunch break (11:30-13:00)
    if (totalMinutes >= 690 && totalMinutes < 780) {
        return 120 / 240; // 120 minutes of morning session completed
    }

    // Afternoon session
    if (totalMinutes >= 780 && totalMinutes < 900) {
        return (120 + (totalMinutes - 780)) / 240;
    }

    // After market closes
    return 1.0;
}
