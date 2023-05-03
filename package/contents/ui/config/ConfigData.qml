import QtQuick 2.2
import QtQuick.Controls 2.12 as QtControls
import QtQuick.Layouts 1.15 as QtLayouts
import org.kde.kirigami 2.6 as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import "../components" as RMComponents
import "../controls" as RMControls
import "../components/functions.js" as Functions

PlasmaExtras.Representation {
    id: dataPage
    anchors.fill: parent

    signal configurationChanged

    // Network
    readonly property var networkDialect: Functions.getNetworkDialectInfo(Plasmoid.configuration.networkUnit)
    property alias cfg_networkReceivingTotal: networkReceiving.realValue
    property alias cfg_networkSendingTotal: networkSending.realValue

    // Disks I/O
    property alias cfg_diskReadTotal: diskRead.realValue
    property alias cfg_diskWriteTotal: diskWrite.realValue

    // Thresholds
    property alias cfg_thresholdWarningCpuTemp: thresholdWarningCpuTemp.realValue
    property alias cfg_thresholdCriticalCpuTemp: thresholdCriticalCpuTemp.realValue
    property alias cfg_thresholdWarningMemory: thresholdWarningMemory.value
    property alias cfg_thresholdCriticalMemory: thresholdCriticalMemory.value
    property alias cfg_thresholdWarningGpuTemp: thresholdWarningGpuTemp.realValue
    property alias cfg_thresholdCriticalGpuTemp: thresholdCriticalGpuTemp.realValue

    readonly property var networkSpeedOptions: [{
            "label": i18n("Custom"),
            "value": -1
        }, {
            "label": "100 " + networkDialect.kiloChar + networkDialect.suffix,
            "value": 100.0
        }, {
            "label": "1 M" + networkDialect.suffix,
            "value": 1000.0
        }, {
            "label": "10 M" + networkDialect.suffix,
            "value": 10000.0
        }, {
            "label": "100 M" + networkDialect.suffix,
            "value": 100000.0
        }, {
            "label": "1 G" + networkDialect.suffix,
            "value": 1000000.0
        }, {
            "label": "2.5 G" + networkDialect.suffix,
            "value": 2500000.0
        }, {
            "label": "5 G" + networkDialect.suffix,
            "value": 5000000.0
        }, {
            "label": "10 G" + networkDialect.suffix,
            "value": 10000000.0
        }]
    readonly property var diskSpeedOptions: [{
            "label": i18n("Custom"),
            "value": -1
        }, {
            "label": "10 MiB/s",
            "value": 10000.0
        }, {
            "label": "100 MiB/s",
            "value": 100000.0
        }, {
            "label": "200 MiB/s",
            "value": 200000.0
        }, {
            "label": "500 MiB/s",
            "value": 500000.0
        }, {
            "label": "1 GiB/s",
            "value": 1000000.0
        }, {
            "label": "2 GiB/s",
            "value": 2000000.0
        }, {
            "label": "5 GiB/s",
            "value": 5000000.0
        }, {
            "label": "10 GiB/s",
            "value": 10000000.0
        }]

    // Detect network interfaces
    RMComponents.NetworkInterfaceDetector {
        id: networkInterfaces
    }

    // Tab bar
    header: PlasmaExtras.PlasmoidHeading {
        location: PlasmaExtras.PlasmoidHeading.Location.Header

        PlasmaComponents.TabBar {
            id: bar

            position: PlasmaComponents.TabBar.Header
            anchors.fill: parent
            implicitHeight: contentHeight

            PlasmaComponents.TabButton {
                icon.name: "network-wired-symbolic"
                icon.height: PlasmaCore.Units.iconSizes.smallMedium
                text: i18nc("Chart name", "Network")
            }
            PlasmaComponents.TabButton {
                icon.name: "drive-harddisk-symbolic"
                icon.height: PlasmaCore.Units.iconSizes.smallMedium
                text: i18nc("Chart name", "Disks I/O")
            }
            PlasmaComponents.TabButton {
                icon.name: "dialog-warning"
                icon.height: PlasmaCore.Units.iconSizes.smallMedium
                text: i18nc("Config header", "Thresholds")
            }
        }
    }

    QtLayouts.StackLayout {
        id: pageContent
        anchors.fill: parent
        currentIndex: bar.currentIndex

        // Network
        Kirigami.ScrollablePage {
            Kirigami.FormLayout {
                wideMode: true

                // Network interfaces
                QtLayouts.GridLayout {
                    Kirigami.FormData.label: i18n("Network interfaces:")
                    QtLayouts.Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Kirigami.Units.smallSpacing
                    columnSpacing: Kirigami.Units.largeSpacing

                    Repeater {
                        model: networkInterfaces.model
                        QtControls.CheckBox {
                            readonly property string interfaceName: modelData
                            readonly property bool ignoredByDefault: {
                                return /^(docker|tun|tap)(\d+)/.test(interfaceName); // Ignore docker and tun/tap networks
                            }

                            text: interfaceName
                            checked: Plasmoid.configuration.ignoredNetworkInterfaces.indexOf(interfaceName) == -1 && !ignoredByDefault
                            enabled: !ignoredByDefault

                            onClicked: {
                                var ignoredNetworkInterfaces = Plasmoid.configuration.ignoredNetworkInterfaces.slice(0); // copy()
                                if (checked) {
                                    // Checking, and thus removing from the ignoredNetworkInterfaces
                                    var i = ignoredNetworkInterfaces.indexOf(interfaceName);
                                    ignoredNetworkInterfaces.splice(i, 1);
                                } else {
                                    // Unchecking, and thus adding to the ignoredNetworkInterfaces
                                    ignoredNetworkInterfaces.push(interfaceName);
                                }
                                Plasmoid.configuration.ignoredNetworkInterfaces = ignoredNetworkInterfaces;
                                // To modify a StringList we need to manually trigger configurationChanged.
                                dataPage.configurationChanged();
                            }
                        }
                    }
                }

                // Separator
                Rectangle {
                    height: Kirigami.Units.largeSpacing * 2
                    color: "transparent"
                }

                PlasmaComponents.Label {
                    text: i18n("Maximum transfer speed")
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
                }

                // Separator
                Rectangle {
                    height: Kirigami.Units.largeSpacing
                    color: "transparent"
                }

                // Receiving speed
                RMControls.PredefinedSpinBox {
                    id: networkReceiving
                    Kirigami.FormData.label: i18nc("Chart config", "Receiving:")
                    QtLayouts.Layout.fillWidth: true
                    factor: 1000

                    predefinedChoices {
                        textRole: "label"
                        valueRole: "value"
                        model: networkSpeedOptions
                    }

                    spinBox {
                        decimals: 3
                        stepSize: 1
                        minimumValue: 0.001

                        textFromValue: function (value, locale) {
                            return spinBox.valueToText(value, locale) + " M" + networkDialect.suffix;
                        }
                    }
                }

                // Separator
                Rectangle {
                    height: Kirigami.Units.largeSpacing
                    color: "transparent"
                }

                // Sending speed
                RMControls.PredefinedSpinBox {
                    id: networkSending
                    Kirigami.FormData.label: i18nc("Chart config", "Sending:")
                    QtLayouts.Layout.fillWidth: true
                    factor: 1000

                    predefinedChoices {
                        textRole: "label"
                        valueRole: "value"
                        model: networkSpeedOptions
                    }

                    spinBox {
                        decimals: 3
                        stepSize: 1
                        minimumValue: 0.001

                        textFromValue: function (value, locale) {
                            return spinBox.valueToText(value, locale) + " M" + networkDialect.suffix;
                        }
                    }
                }
            }
        }

        // Disk I/O
        Kirigami.ScrollablePage {
            Kirigami.FormLayout {
                wideMode: true

                PlasmaComponents.Label {
                    text: i18n("Maximum transfer speed")
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
                }

                // Separator
                Rectangle {
                    height: Kirigami.Units.largeSpacing
                    color: "transparent"
                }

                // Read speed
                RMControls.PredefinedSpinBox {
                    id: diskRead
                    Kirigami.FormData.label: i18nc("Chart config", "Read:")
                    QtLayouts.Layout.fillWidth: true
                    factor: 1000

                    predefinedChoices {
                        textRole: "label"
                        valueRole: "value"
                        model: diskSpeedOptions
                    }

                    spinBox {
                        decimals: 3
                        stepSize: 1
                        minimumValue: 0.001

                        textFromValue: function (value, locale) {
                            return spinBox.valueToText(value, locale) + " M" + networkDialect.suffix;
                        }
                    }
                }

                // Separator
                Rectangle {
                    height: Kirigami.Units.largeSpacing
                    color: "transparent"
                }

                // Write speed
                RMControls.PredefinedSpinBox {
                    id: diskWrite
                    Kirigami.FormData.label: i18nc("Chart config", "Write:")
                    QtLayouts.Layout.fillWidth: true
                    factor: 1000

                    predefinedChoices {
                        textRole: "label"
                        valueRole: "value"
                        model: diskSpeedOptions
                    }

                    spinBox {
                        decimals: 3
                        stepSize: 1
                        minimumValue: 0.001

                        textFromValue: function (value, locale) {
                            return spinBox.valueToText(value, locale) + " M" + networkDialect.suffix;
                        }
                    }
                }
            }
        }

        // Threshold
        Kirigami.ScrollablePage {
            Kirigami.FormLayout {
                wideMode: true

                QtLayouts.GridLayout {
                    QtLayouts.Layout.fillWidth: true
                    columns: 3
                    columnSpacing: Kirigami.Units.largeSpacing

                    PlasmaComponents.Label {
                        id: warningText
                        text: i18n("Warning")
                        font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
                    }

                    // Separator
                    Rectangle {
                        width: thresholdWarningMemory.implicitWidth - warningText.contentWidth - Kirigami.Units.largeSpacing
                        color: "transparent"
                    }

                    PlasmaComponents.Label {
                        text: i18n("Critical")
                        font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
                    }
                }

                // CPU Temperature
                QtLayouts.GridLayout {
                    Kirigami.FormData.label: i18n("CPU Temperature:")
                    QtLayouts.Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Kirigami.Units.smallSpacing
                    columnSpacing: Kirigami.Units.largeSpacing

                    RMControls.SpinBox {
                        id: thresholdWarningCpuTemp
                        QtLayouts.Layout.fillWidth: true
                        decimals: 1
                        stepSize: 1
                        minimumValue: 0.1
                        maximumValue: 120

                        textFromValue: function (value, locale) {
                            return valueToText(value, locale) + " °C";
                        }
                    }
                    RMControls.SpinBox {
                        id: thresholdCriticalCpuTemp
                        QtLayouts.Layout.fillWidth: true
                        decimals: 1
                        stepSize: 1
                        minimumValue: 0.1
                        maximumValue: 120

                        textFromValue: function (value, locale) {
                            return valueToText(value, locale) + " °C";
                        }
                    }
                }

                // Memory usage
                QtLayouts.GridLayout {
                    Kirigami.FormData.label: i18n("Physical Memory Usage:")
                    QtLayouts.Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Kirigami.Units.smallSpacing
                    columnSpacing: Kirigami.Units.largeSpacing

                    RMControls.SpinBox {
                        id: thresholdWarningMemory
                        QtLayouts.Layout.fillWidth: true

                        textFromValue: function (value, locale) {
                            return value + " %";
                        }
                    }
                    RMControls.SpinBox {
                        id: thresholdCriticalMemory
                        QtLayouts.Layout.fillWidth: true

                        textFromValue: function (value, locale) {
                            return value + " %";
                        }
                    }
                }

                // GPU Temperature
                QtLayouts.GridLayout {
                    Kirigami.FormData.label: i18n("GPU Temperature:")
                    QtLayouts.Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Kirigami.Units.smallSpacing
                    columnSpacing: Kirigami.Units.largeSpacing

                    RMControls.SpinBox {
                        id: thresholdWarningGpuTemp
                        QtLayouts.Layout.fillWidth: true
                        decimals: 1
                        stepSize: 1
                        minimumValue: 0.1
                        maximumValue: 120

                        textFromValue: function (value, locale) {
                            return valueToText(value, locale) + " °C";
                        }
                    }
                    RMControls.SpinBox {
                        id: thresholdCriticalGpuTemp
                        QtLayouts.Layout.fillWidth: true
                        decimals: 1
                        stepSize: 1
                        minimumValue: 0.1
                        maximumValue: 120

                        textFromValue: function (value, locale) {
                            return valueToText(value, locale) + " °C";
                        }
                    }
                }
            }
        }
    }
}
