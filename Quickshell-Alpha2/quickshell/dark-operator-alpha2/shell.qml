//@ pragma IconTheme Papirus-Dark
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property color bg: "#0A0D10"
    readonly property color panel: "#E611161C"
    readonly property color elevated: "#F2171E26"
    readonly property color border: "#33445464"
    readonly property color textMain: "#E7EDF3"
    readonly property color textMuted: "#7F8B98"
    readonly property color accent: "#74D7E8"
    readonly property color accentStrong: "#00D7FF"

    function stationActive(n) {
        return Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === n
    }

    function gotoStation(n) {
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(n)])
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // Dark Operator Alpha 2:
    // Explicit TOP layer + ignored exclusion zone.
    // Normal/maximized windows use the whole monitor.
    // True fullscreen windows render above the shell.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: topWindow
            property var modelData
            screen: modelData

            implicitHeight: 68
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            focusable: false

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "dark-operator-alpha2-top"

            anchors {
                top: true
                left: true
                right: true
            }

            Rectangle {
                id: operatorIsland
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 10

                width: 486
                height: 46
                radius: 12
                color: root.panel
                border.width: 1
                border.color: root.border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 32
                        radius: 9
                        color: sysArea.containsMouse ? root.elevated : "transparent"
                        border.width: sysArea.containsMouse ? 1 : 0
                        border.color: root.accent

                        Text {
                            anchors.centerIn: parent
                            text: "◈"
                            color: root.accent
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: sysArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["wofi", "--show", "drun"])
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 20
                        color: root.border
                    }

                    Repeater {
                        model: 5

                        delegate: Rectangle {
                            required property int index
                            property int station: index + 1

                            Layout.preferredWidth: 58
                            Layout.preferredHeight: 32
                            radius: 9
                            color: root.stationActive(station)
                                ? "#263540"
                                : (stationArea.containsMouse ? root.elevated : "transparent")
                            border.width: root.stationActive(station) ? 1 : 0
                            border.color: root.accent

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 5
                                    height: 5
                                    radius: 3
                                    color: root.stationActive(station)
                                        ? root.accentStrong
                                        : root.textMuted
                                }

                                Text {
                                    text: station
                                    color: root.stationActive(station)
                                        ? root.textMain
                                        : root.textMuted
                                    font.family: "Noto Sans"
                                    font.pixelSize: 13
                                    font.weight: root.stationActive(station)
                                        ? Font.DemiBold
                                        : Font.Medium
                                }
                            }

                            MouseArea {
                                id: stationArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.gotoStation(station)
                            }

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        Layout.rightMargin: 8
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: root.textMain
                        font.family: "Noto Sans"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockWindow
            property var modelData
            screen: modelData

            implicitHeight: 86
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            focusable: false

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "dark-operator-alpha2-dock"

            anchors {
                bottom: true
                left: true
                right: true
            }

            Rectangle {
                id: dock
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 14

                width: 294
                height: 60
                radius: 14
                color: root.panel
                border.width: 1
                border.color: root.border

                Row {
                    anchors.centerIn: parent
                    spacing: 10

                    Repeater {
                        model: [
                            { name: "Google Chrome", fallback: "google-chrome" },
                            { name: "Dolphin", fallback: "system-file-manager" },
                            { name: "Visual Studio Code", fallback: "visual-studio-code" },
                            { name: "kitty", fallback: "utilities-terminal" }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            width: 48
                            height: 48
                            radius: 11
                            color: dockArea.containsMouse ? root.elevated : "transparent"
                            border.width: dockArea.containsMouse ? 1 : 0
                            border.color: root.border
                            scale: dockArea.containsMouse ? 1.06 : 1.0

                            property var entry: DesktopEntries.heuristicLookup(modelData.name)

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 27
                                source: Quickshell.iconPath(
                                    parent.entry && parent.entry.icon
                                        ? parent.entry.icon
                                        : modelData.fallback,
                                    "application-x-executable"
                                )
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 3
                                width: 14
                                height: 2
                                radius: 1
                                color: dockArea.containsMouse ? root.accent : "transparent"
                            }

                            MouseArea {
                                id: dockArea
                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: {
                                    if (parent.entry)
                                        parent.entry.execute()
                                }
                            }

                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
