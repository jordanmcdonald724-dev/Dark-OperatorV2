//@ pragma IconTheme Papirus-Dark
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property color panel: "#E811161C"
    readonly property color elevated: "#F2171E26"
    readonly property color border: "#40505F70"
    readonly property color textMain: "#E7EDF3"
    readonly property color textMuted: "#7F8B98"
    readonly property color accent: "#74D7E8"
    readonly property color accentStrong: "#00D7FF"
    readonly property bool fullscreenActive:
        Hyprland.activeToplevel !== null && Hyprland.activeToplevel.fullscreen

    function stationActive(n) {
        return Hyprland.focusedWorkspace !== null
            && Hyprland.focusedWorkspace.id === n
    }

    function gotoStation(n) {
        Hyprland.dispatch("workspace " + n)
    }

    function launch(name) {
        var e = DesktopEntries.heuristicLookup(name)
        if (e) e.execute()
    }

    function appIcon(appId) {
        if (!appId || appId.length === 0)
            return Quickshell.iconPath("application-x-executable")
        var e = DesktopEntries.heuristicLookup(appId)
        if (e && e.icon)
            return Quickshell.iconPath(e.icon, "application-x-executable")
        return Quickshell.iconPath(appId, "application-x-executable")
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ONE coherent shell surface:
    // Stations are persistent project contexts at the left.
    // Pinned and running applications form the task area.
    // System identity/clock stays restrained at the right.
    // The entire shell disappears for a true fullscreen application.
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: shellWindow
            property var modelData
            screen: modelData

            visible: !root.fullscreenActive
            implicitHeight: 82
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            focusable: false

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "dark-operator-alpha3-shell"

            anchors {
                left: true
                right: true
                bottom: true
            }

            Rectangle {
                id: bar
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 12

                width: Math.min(parent.width - 28, 920)
                height: 58
                radius: 12
                color: root.panel
                border.width: 1
                border.color: root.border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    // STATIONS: persistent project contexts, not a top debug strip.
                    Row {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Repeater {
                            model: 5

                            delegate: Rectangle {
                                required property int index
                                property int station: index + 1
                                property bool active: root.stationActive(station)

                                width: active ? 74 : 38
                                height: 40
                                radius: 9
                                color: active
                                    ? "#263540"
                                    : (stationMouse.containsMouse ? root.elevated : "transparent")
                                border.width: active ? 1 : 0
                                border.color: root.accent

                                Behavior on width {
                                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                                }
                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 7
                                        height: 7
                                        radius: 4
                                        color: parent.parent.active
                                            ? root.accentStrong
                                            : root.textMuted
                                    }

                                    Text {
                                        visible: parent.parent.active
                                        text: "STN " + parent.parent.station
                                        color: root.textMain
                                        font.family: "Noto Sans"
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    id: stationMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.gotoStation(parent.station)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter
                        color: root.border
                    }

                    // PINNED APPLICATIONS: familiar permanent launch targets.
                    Row {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        Repeater {
                            model: [
                                { entry: "Google Chrome", fallback: "google-chrome" },
                                { entry: "Dolphin", fallback: "system-file-manager" },
                                { entry: "Visual Studio Code", fallback: "visual-studio-code" },
                                { entry: "kitty", fallback: "utilities-terminal" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                width: 42
                                height: 42
                                radius: 9
                                color: pinMouse.containsMouse ? root.elevated : "transparent"

                                property var entryObject:
                                    DesktopEntries.heuristicLookup(modelData.entry)

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 25
                                    source: Quickshell.iconPath(
                                        parent.entryObject && parent.entryObject.icon
                                            ? parent.entryObject.icon
                                            : modelData.fallback,
                                        "application-x-executable"
                                    )
                                }

                                MouseArea {
                                    id: pinMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (parent.entryObject)
                                            parent.entryObject.execute()
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation { duration: 150 }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter
                        color: root.border
                    }

                    // RUNNING WINDOWS: real taskbar state from Hyprland.
                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        Layout.alignment: Qt.AlignVCenter
                        clip: true
                        contentWidth: runningRow.width
                        contentHeight: height
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: runningRow
                            height: parent.height
                            spacing: 4

                            Repeater {
                                model: Hyprland.toplevels

                                delegate: Rectangle {
                                    required property var modelData
                                    property bool active: modelData.activated

                                    width: 44
                                    height: 42
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 9
                                    color: active
                                        ? "#263540"
                                        : (taskMouse.containsMouse ? root.elevated : "transparent")
                                    border.width: active ? 1 : 0
                                    border.color: root.accent

                                    IconImage {
                                        anchors.centerIn: parent
                                        implicitSize: 24
                                        source: root.appIcon(parent.modelData.appId)
                                        opacity: parent.modelData.minimized ? 0.48 : 1.0
                                    }

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: 2
                                        width: parent.active ? 18 : 8
                                        height: 2
                                        radius: 1
                                        color: parent.active ? root.accentStrong : root.textMuted
                                    }

                                    MouseArea {
                                        id: taskMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                                        onClicked: function(mouse) {
                                            if (mouse.button === Qt.MiddleButton) {
                                                parent.modelData.close()
                                            } else if (parent.active) {
                                                parent.modelData.minimized = true
                                            } else {
                                                parent.modelData.minimized = false
                                                parent.modelData.activate()
                                            }
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter
                        color: root.border
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 9
                        color: launcherMouse.containsMouse ? root.elevated : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "◈"
                            color: root.accent
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: launcherMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["wofi", "--show", "drun"])
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }

                    Text {
                        Layout.leftMargin: 2
                        Layout.rightMargin: 4
                        Layout.alignment: Qt.AlignVCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: root.textMain
                        font.family: "Noto Sans"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
