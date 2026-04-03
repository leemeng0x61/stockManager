import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "./services/StockUtils.js" as Utils
import "./services"

PluginSettings {
    id: root
    pluginId: "stockManager"

    // Helper to get translated strings
    function t(key) {
        let val = Utils.t(key);
        return val !== null ? val : I18n.tr(key);
    }

    StyledText {
        text: root.t("Stock Manager Settings")
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    StyledText {
        text: root.t("Trend Colors")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    Row {
        width: parent.width
        spacing: Theme.spacingL

        // Up Color
        Column {
            width: (parent.width - Theme.spacingL) / 2
            spacing: Theme.spacingS
            StyledText {
                text: root.t("Up (Rise)"); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText
            }

            Row {
                spacing: Theme.spacingS
                Rectangle {
                    width: 32; height: 32; radius: 16; color: StockService.upColor
                    border.color: Theme.surfaceVariant; border.width: 1
                }
                ColorOption {
                    optionColor: "#ff4d4f"; active: StockService.upColor === "#ff4d4f"; onClicked: StockService.upColor = "#ff4d4f"
                }
                ColorOption {
                    optionColor: "#52c41a"; active: StockService.upColor === "#52c41a"; onClicked: StockService.upColor = "#52c41a"
                }
                ColorOption {
                    optionColor: "#fadb14"; active: StockService.upColor === "#fadb14"; onClicked: StockService.upColor = "#fadb14"
                }
            }

            // HEX Input for Up Color
            Rectangle {
                width: parent.width - Theme.spacingM
                height: 32; radius: 6; color: Theme.surfaceContainer
                border.color: upHexInput.activeFocus ? Theme.primary : Theme.surfaceVariant
                border.width: 1

                TextInput {
                    id: upHexInput
                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    text: StockService.upColor
                    color: Theme.surfaceText
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeSmall
                    onTextEdited: {
                        if (/^#[0-9A-Fa-f]{6}$/.test(text)) StockService.upColor = text;
                    }
                    onEditingFinished: {
                        if (/^#[0-9A-Fa-f]{6}$/.test(text)) StockService.upColor = text;
                        else text = StockService.upColor;
                    }
                }
            }
        }

        // Down Color
        Column {
            width: (parent.width - Theme.spacingL) / 2
            spacing: Theme.spacingS
            StyledText {
                text: root.t("Down (Fall)"); font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText
            }

            Row {
                spacing: Theme.spacingS
                Rectangle {
                    width: 32; height: 32; radius: 16; color: StockService.downColor
                    border.color: Theme.surfaceVariant; border.width: 1
                }
                ColorOption {
                    optionColor: "#52c41a"; active: StockService.downColor === "#52c41a"; onClicked: StockService.downColor = "#52c41a"
                }
                ColorOption {
                    optionColor: "#ff4d4f"; active: StockService.downColor === "#ff4d4f"; onClicked: StockService.downColor = "#ff4d4f"
                }
                ColorOption {
                    optionColor: "#1890ff"; active: StockService.downColor === "#1890ff"; onClicked: StockService.downColor = "#1890ff"
                }
            }

            // HEX Input for Down Color
            Rectangle {
                width: parent.width - Theme.spacingM
                height: 32; radius: 6; color: Theme.surfaceContainer
                border.color: downHexInput.activeFocus ? Theme.primary : Theme.surfaceVariant
                border.width: 1

                TextInput {
                    id: downHexInput
                    anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                    verticalAlignment: Text.AlignVCenter
                    text: StockService.downColor
                    color: Theme.surfaceText
                    font.family: "monospace"
                    font.pixelSize: Theme.fontSizeSmall
                    onTextEdited: {
                        if (/^#[0-9A-Fa-f]{6}$/.test(text)) StockService.downColor = text;
                    }
                    onEditingFinished: {
                        if (/^#[0-9A-Fa-f]{6}$/.test(text)) StockService.downColor = text;
                        else text = StockService.downColor;
                    }
                }
            }
        }
    }

    component ColorOption: Rectangle {
        property string optionColor: "#000000"
        property bool active: false

        signal clicked()

        width: 24; height: 24; radius: 12
        color: optionColor
        border.color: active ? Theme.primary : "transparent"
        border.width: 2
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.clicked()
        }
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    StyledText {
        text: root.t("Display Mode")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        StyledText {
            text: root.t("Choose how values are displayed in the status bar.")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            width: parent.width
            wrapMode: Text.WordWrap
        }

        Row {
            spacing: Theme.spacingM

            // Percent Option
            Row {
                spacing: Theme.spacingS

                DankIcon {
                    name: StockService.displayMode === "percent" ? "radio_button_checked" : "radio_button_unchecked"
                    size: Theme.iconSize
                    color: StockService.displayMode === "percent" ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.displayMode = "percent"
                    }
                }

                StyledText {
                    text: root.t("Percent (%)")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.displayMode = "percent"
                    }
                }
            }

            // Amount Option
            Row {
                spacing: Theme.spacingS

                DankIcon {
                    name: StockService.displayMode === "amount" ? "radio_button_checked" : "radio_button_unchecked"
                    size: Theme.iconSize
                    color: StockService.displayMode === "amount" ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.displayMode = "amount"
                    }
                }

                StyledText {
                    text: root.t("Amount")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.displayMode = "amount"
                    }
                }
            }
        }
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    StyledText {
        text: root.t("Name Format")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        StyledText {
            text: root.t("Choose how stock names are displayed.")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            width: parent.width
            wrapMode: Text.WordWrap
        }

        Row {
            spacing: Theme.spacingM

            // None Option
            Row {
                spacing: Theme.spacingS

                DankIcon {
                    name: StockService.nameDisplayMode === "none" ? "radio_button_checked" : "radio_button_unchecked"
                    size: Theme.iconSize
                    color: StockService.nameDisplayMode === "none" ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.nameDisplayMode = "none"
                    }
                }

                StyledText {
                    text: root.t("None")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.nameDisplayMode = "none"
                    }
                }
            }

            // Pinyin Option
            Row {
                spacing: Theme.spacingS

                DankIcon {
                    name: StockService.nameDisplayMode === "pinyin" ? "radio_button_checked" : "radio_button_unchecked"
                    size: Theme.iconSize
                    color: StockService.nameDisplayMode === "pinyin" ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.nameDisplayMode = "pinyin"
                    }
                }

                StyledText {
                    text: root.t("Pinyin (P)")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.nameDisplayMode = "pinyin"
                    }
                }
            }

            // Hanzi Option
            Row {
                spacing: Theme.spacingS

                DankIcon {
                    name: StockService.nameDisplayMode === "hanzi" ? "radio_button_checked" : "radio_button_unchecked"
                    size: Theme.iconSize
                    color: StockService.nameDisplayMode === "hanzi" ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.nameDisplayMode = "hanzi"
                    }
                }

                StyledText {
                    text: root.t("Hanzi (汉)")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.nameDisplayMode = "hanzi"
                    }
                }
            }

            // Full Name Option
            Row {
                spacing: Theme.spacingS

                DankIcon {
                    name: StockService.nameDisplayMode === "full" ? "radio_button_checked" : "radio_button_unchecked"
                    size: Theme.iconSize
                    color: StockService.nameDisplayMode === "full" ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.nameDisplayMode = "full"
                    }
                }

                StyledText {
                    text: root.t("Full Name")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StockService.nameDisplayMode = "full"
                    }
                }
            }
        }
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    StyledText {
        text: root.t("Status Bar Display")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    Column {
        width: parent.width
        spacing: Theme.spacingM

        // Font Scale Input
        Row {
            spacing: Theme.spacingM
            height: 32

            StyledText {
                text: root.t("Font Scale:")
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 60; height: 32
                color: Theme.surfaceContainer
                radius: 4
                border.color: Theme.surfaceVariant; border.width: 1

                TextInput {
                    anchors.fill: parent; anchors.margins: 4
                    text: StockService.statusBarFontScale.toFixed(1)
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    validator: DoubleValidator {
                        bottom: 0.5; top: 3.0; decimals: 1
                    }
                    onEditingFinished: {
                        var val = parseFloat(text);
                        if (!isNaN(val) && val >= 0.5 && val <= 3.0) StockService.statusBarFontScale = val;
                        else text = StockService.statusBarFontScale.toFixed(1);
                    }
                }
            }
        }

        // Max Stocks Input
        Row {
            spacing: Theme.spacingM
            height: 32

            StyledText {
                text: root.t("Max Stocks:")
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 60; height: 32
                color: Theme.surfaceContainer
                radius: 4
                border.color: Theme.surfaceVariant; border.width: 1

                TextInput {
                    anchors.fill: parent; anchors.margins: 4
                    text: StockService.statusBarMaxCount
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    validator: IntValidator {
                        bottom: 1; top: 99
                    }
                    onEditingFinished: {
                        var val = parseInt(text);
                        if (!isNaN(val) && val > 0) StockService.statusBarMaxCount = val;
                        else text = StockService.statusBarMaxCount;
                    }
                }
            }
        }

        // Scrollable Switch
        Row {
            spacing: Theme.spacingM
            height: 32

            DankIcon {
                name: StockService.statusBarScrollable ? "check_box" : "check_box_outline_blank"
                size: Theme.iconSize
                color: StockService.statusBarScrollable ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: StockService.statusBarScrollable = !StockService.statusBarScrollable
                }
            }

            StyledText {
                text: root.t("Allow Scrolling (Status Bar)")
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: StockService.statusBarScrollable = !StockService.statusBarScrollable
                }
            }
        }
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    StyledText {
        text: root.t("List Display")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    // Sparklines Switch
    Row {
        spacing: Theme.spacingM
        height: 32

        DankIcon {
            name: StockService.showSparklines ? "check_box" : "check_box_outline_blank"
            size: Theme.iconSize
            color: StockService.showSparklines ? Theme.primary : Theme.surfaceVariantText
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: StockService.showSparklines = !StockService.showSparklines
            }
        }

        StyledText {
            text: root.t("Show Sparklines (Charts)")
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.surfaceText
            anchors.verticalCenter: parent.verticalCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: StockService.showSparklines = !StockService.showSparklines
            }
        }
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    StyledText {
        text: root.t("Refresh Interval")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS

        StyledText {
            text: root.t("Choose background update frequency.")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            width: parent.width
            wrapMode: Text.WordWrap
        }

        Flow {
            width: parent.width
            spacing: Theme.spacingM

            IntervalOption {
                label: "2s"; value: 2000; active: StockService.refreshInterval === 2000; onClicked: StockService.refreshInterval = 2000
            }
            IntervalOption {
                label: "10s"; value: 10000; active: StockService.refreshInterval === 10000; onClicked: StockService.refreshInterval = 10000
            }
            IntervalOption {
                label: "30s"; value: 30000; active: StockService.refreshInterval === 30000; onClicked: StockService.refreshInterval = 30000
            }
            IntervalOption {
                label: "1m"; value: 60000; active: StockService.refreshInterval === 60000; onClicked: StockService.refreshInterval = 60000
            }
            IntervalOption {
                label: "3m"; value: 180000; active: StockService.refreshInterval === 180000; onClicked: StockService.refreshInterval = 180000
            }
            IntervalOption {
                label: "5m"; value: 300000; active: StockService.refreshInterval === 300000; onClicked: StockService.refreshInterval = 300000
            }
            IntervalOption {
                label: "10m"; value: 600000; active: StockService.refreshInterval === 600000; onClicked: StockService.refreshInterval = 600000
            }
        }
    }

    component IntervalOption: MouseArea {
        property string label: ""
        property int value: 0
        property bool active: false

        width: contentRow.width
        height: 32
        cursorShape: Qt.PointingHandCursor

        Row {
            id: contentRow
            spacing: Theme.spacingS
            height: parent.height

            DankIcon {
                name: active ? "radio_button_checked" : "radio_button_unchecked"
                size: Theme.iconSize
                color: active ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: label
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    StyledText {
        text: root.t("About")
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    StyledText {
        text: root.t("To pin stocks, click 'Edit' in the main panel and toggle the pin icon. Font size can be adjusted in system settings.")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        width: parent.width
        wrapMode: Text.WordWrap
    }
}
