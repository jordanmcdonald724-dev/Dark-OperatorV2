//@ pragma IconTheme Papirus-Dark
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Dark Operator 1.0 shell: quiet desktop, floating controls, no permanent taskbar.
    readonly property color voidColor: "#0A0D10"
    readonly property color glass: "#E812171D"
    readonly property color glassRaised: "#F21A222B"
    readonly property color glassHover: "#F226323D"
    readonly property color border: "#40516070"
    readonly property color borderSoft: "#26384654"
    readonly property color textMain: "#EDF4F8"
    readonly property color textMuted: "#8E9BA7"
    readonly property color accent: "#72D8E8"
    readonly property color accentStrong: "#00D9FF"
    readonly property color good: "#83E1B3"

    property string profile: "GENERAL"
    property bool launcherOpen: false
    property bool aiOpen: false
    property bool stripOpen: false
    property bool profileOpen: false
    property string launcherQuery: ""

    readonly property bool workspaceFullscreen: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.hasFullscreen : false
    readonly property bool desktopEmpty: !Hyprland.focusedWorkspace || Hyprland.focusedWorkspace.toplevels.values.length === 0
    readonly property bool gamingMode: profile === "GAMING"
    readonly property bool shellSuppressed: workspaceFullscreen

    function gotoWorkspace(n) {
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(n)])
    }

    function setProfile(name) {
        profile = name
        launcherOpen = false
        aiOpen = false
        profileOpen = false
        if (name === "GAMING") stripOpen = false
    }

    function launchByCandidates(candidates) {
        for (let i = 0; i < candidates.length; ++i) {
            const entry = DesktopEntries.heuristicLookup(candidates[i])
            if (entry) {
                entry.execute()
                launcherOpen = false
                return
            }
        }
    }

    function appRunning(entry) {
        if (!entry) return false
        const startup = (entry.startupClass || "").toLowerCase()
        const id = (entry.id || "").toLowerCase()
        const name = (entry.name || "").toLowerCase()
        const tops = Hyprland.toplevels.values
        for (let i = 0; i < tops.length; ++i) {
            const appId = (tops[i].appId || "").toLowerCase()
            if ((startup && appId.indexOf(startup) >= 0) ||
                (id && appId.indexOf(id.replace(".desktop", "")) >= 0) ||
                (name && appId.indexOf(name.replace(/\s+/g, "")) >= 0)) return true
        }
        return false
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Timer {
        id: stripHideTimer
        interval: 900
        repeat: false
        onTriggered: if (!root.profileOpen) root.stripOpen = false
    }

    // Controls are exposed by the shell itself. This package does not add or edit Hyprland key bindings.

    // Invisible top-edge reveal target. It never reserves screen space.
    Variants {
        model: Quickshell.screens
        PanelWindow {
            property var modelData
            screen: modelData
            implicitHeight: 3
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            visible: !root.shellSuppressed
            anchors { top: true; left: true; right: true }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    stripHideTimer.stop()
                    root.stripOpen = true
                }
            }
        }
    }

    // Edge-reveal system strip. No permanent bar.
    Variants {
        model: Quickshell.screens
        PanelWindow {
            property var modelData
            screen: modelData
            implicitHeight: 68
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            visible: root.stripOpen && !root.shellSuppressed
            anchors { top: true; left: true; right: true }
            mask: Region { item: stripCard }

            Rectangle {
                id: stripCard
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 10
                width: Math.min(parent.width - 40, 770)
                height: 46
                radius: 15
                color: root.glass
                border.width: 1
                border.color: root.border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 12
                    spacing: 7

                    Rectangle {
                        Layout.preferredWidth: 116
                        Layout.preferredHeight: 32
                        radius: 10
                        color: profileMouse.containsMouse ? root.glassHover : root.glassRaised
                        border.width: 1
                        border.color: root.profile === "GAMING" ? root.good : root.borderSoft

                        Row {
                            anchors.centerIn: parent
                            spacing: 7
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7; height: 7; radius: 4
                                color: root.profile === "GAMING" ? root.good : root.accent
                            }
                            Text {
                                text: root.profile
                                color: root.textMain
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }
                        MouseArea {
                            id: profileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.profileOpen = !root.profileOpen
                        }
                    }

                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 22; color: root.borderSoft }

                    Repeater {
                        model: 5
                        delegate: Rectangle {
                            required property int index
                            property int ws: index + 1
                            Layout.preferredWidth: 33
                            Layout.preferredHeight: 32
                            radius: 10
                            color: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === ws ? root.glassHover : "transparent"
                            border.width: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === ws ? 1 : 0
                            border.color: root.accent

                            Text {
                                anchors.centerIn: parent
                                text: ws
                                color: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === ws ? root.textMain : root.textMuted
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.gotoWorkspace(parent.ws) }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"
                        color: root.textMuted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.maximumWidth: 220
                    }

                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 22; color: root.borderSoft }

                    Text {
                        text: Qt.formatDateTime(clock.date, "ddd  HH:mm")
                        color: root.textMain
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onEntered: stripHideTimer.stop()
                    onExited: stripHideTimer.restart()
                }
            }

            Rectangle {
                id: profileMenu
                visible: root.profileOpen
                anchors.top: stripCard.bottom
                anchors.horizontalCenter: stripCard.horizontalCenter
                anchors.topMargin: 8
                width: 390
                height: 92
                radius: 15
                color: root.glassRaised
                border.width: 1
                border.color: root.border

                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Repeater {
                        model: ["GENERAL", "DEVELOPMENT", "AI LAB", "GAMING"]
                        delegate: Rectangle {
                            required property string modelData
                            width: modelData === "DEVELOPMENT" ? 98 : (modelData === "AI LAB" ? 72 : 78)
                            height: 48
                            radius: 11
                            color: root.profile === modelData ? root.glassHover : "transparent"
                            border.width: root.profile === modelData ? 1 : 0
                            border.color: modelData === "GAMING" ? root.good : root.accent
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: root.profile === modelData ? root.textMain : root.textMuted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.setProfile(parent.modelData) }
                        }
                    }
                }
            }
        }
    }

    // Desktop-only floating shortcut pods. They disappear as soon as a workspace has an app.
    Variants {
        model: Quickshell.screens
        PanelWindow {
            property var modelData
            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: false
            visible: root.desktopEmpty && !root.shellSuppressed && !root.gamingMode
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {
                Region { item: devPod }
                Region { item: gamePod }
            }

            Rectangle {
                id: devPod
                x: 38; y: 92
                width: 238; height: 154
                radius: 18
                color: root.glass
                border.width: 1
                border.color: root.border

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10
                    Row {
                        width: parent.width
                        spacing: 8
                        Text { text: "DEVELOPMENT"; color: root.textMain; font.pixelSize: 11; font.weight: Font.Bold }
                        Text { text: "DRAG"; color: root.textMuted; font.pixelSize: 8; anchors.verticalCenter: parent.verticalCenter }
                    }
                    Row {
                        spacing: 8
                        Repeater {
                            model: [
                                {label:"CODE", icon:"visual-studio-code", apps:["Visual Studio Code", "Code"]},
                                {label:"TERM", icon:"utilities-terminal", apps:["kitty", "Alacritty", "Konsole"]},
                                {label:"FILES", icon:"system-file-manager", apps:["Dolphin", "Nautilus", "Thunar"]}
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 64; height: 78; radius: 12
                                color: dMouse.containsMouse ? root.glassHover : root.glassRaised
                                border.width: 1; border.color: root.borderSoft
                                Column {
                                    anchors.centerIn: parent; spacing: 7
                                    IconImage { anchors.horizontalCenter: parent.horizontalCenter; implicitSize: 29; source: Quickshell.iconPath(modelData.icon, "application-x-executable") }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: root.textMuted; font.pixelSize: 9; font.weight: Font.DemiBold }
                                }
                                MouseArea { id: dMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.launchByCandidates(modelData.apps) }
                            }
                        }
                    }
                }

                MouseArea {
                    x: 0; y: 0; width: parent.width; height: 40
                    acceptedButtons: Qt.LeftButton
                    drag.target: devPod
                    drag.axis: Drag.XAndYAxis
                }
            }

            Rectangle {
                id: gamePod
                x: parent.width - width - 38; y: 92
                width: 176; height: 154
                radius: 18
                color: root.glass
                border.width: 1
                border.color: root.border

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10
                    Text { text: "GAMING"; color: root.textMain; font.pixelSize: 11; font.weight: Font.Bold }
                    Row {
                        spacing: 8
                        Repeater {
                            model: [
                                {label:"STEAM", icon:"steam", apps:["Steam"]},
                                {label:"GAMES", icon:"applications-games", apps:["Lutris", "Heroic Games Launcher"]}
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 68; height: 78; radius: 12
                                color: gMouse.containsMouse ? root.glassHover : root.glassRaised
                                border.width: 1; border.color: root.borderSoft
                                Column {
                                    anchors.centerIn: parent; spacing: 7
                                    IconImage { anchors.horizontalCenter: parent.horizontalCenter; implicitSize: 29; source: Quickshell.iconPath(modelData.icon, "application-x-executable") }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: root.textMuted; font.pixelSize: 9; font.weight: Font.DemiBold }
                                }
                                MouseArea { id: gMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.launchByCandidates(modelData.apps) }
                            }
                        }
                    }
                }

                MouseArea {
                    x: 0; y: 0; width: parent.width; height: 40
                    acceptedButtons: Qt.LeftButton
                    drag.target: gamePod
                    drag.axis: Drag.XAndYAxis
                }
            }
        }
    }

    // Compact bottom Quick Dock. Content-sized, floating, click-through everywhere else.
    Variants {
        model: Quickshell.screens
        PanelWindow {
            property var modelData
            screen: modelData
            implicitHeight: 88
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            visible: !root.shellSuppressed
            anchors { bottom: true; left: true; right: true }
            mask: Region { item: dock }

            Rectangle {
                id: dock
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 12
                width: dockRow.implicitWidth + 20
                height: 62
                radius: 19
                color: root.glass
                border.width: 1
                border.color: root.border

                Row {
                    id: dockRow
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        width: 48; height: 48; radius: 13
                        color: launchMouse.containsMouse || root.launcherOpen ? root.glassHover : "transparent"
                        Text { anchors.centerIn: parent; text: "◈"; color: root.accent; font.pixelSize: 20; font.weight: Font.Bold }
                        MouseArea {
                            id: launchMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: { root.launcherOpen = !root.launcherOpen; root.aiOpen = false }
                        }
                    }

                    Rectangle { width: 1; height: 30; anchors.verticalCenter: parent.verticalCenter; color: root.borderSoft }

                    Repeater {
                        model: [
                            {name:"Google Chrome", fallback:"google-chrome", candidates:["Google Chrome", "Chromium", "Firefox"]},
                            {name:"Files", fallback:"system-file-manager", candidates:["Dolphin", "Nautilus", "Thunar"]},
                            {name:"Code", fallback:"visual-studio-code", candidates:["Visual Studio Code", "Code"]},
                            {name:"Terminal", fallback:"utilities-terminal", candidates:["kitty", "Alacritty", "Konsole"]},
                            {name:"Steam", fallback:"steam", candidates:["Steam"]}
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            property var entry: {
                                for (let i = 0; i < modelData.candidates.length; ++i) {
                                    const e = DesktopEntries.heuristicLookup(modelData.candidates[i])
                                    if (e) return e
                                }
                                return null
                            }
                            width: 48; height: 48; radius: 13
                            color: dockMouse.containsMouse ? root.glassHover : "transparent"
                            scale: dockMouse.containsMouse ? 1.08 : 1.0

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 28
                                source: Quickshell.iconPath(parent.entry && parent.entry.icon ? parent.entry.icon : modelData.fallback, "application-x-executable")
                            }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                width: root.appRunning(parent.entry) ? 12 : 0
                                height: 2; radius: 1
                                color: root.accentStrong
                            }
                            MouseArea { id: dockMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.launchByCandidates(modelData.candidates) }
                            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        }
                    }

                    Rectangle { width: 1; height: 30; anchors.verticalCenter: parent.verticalCenter; color: root.borderSoft }

                    Rectangle {
                        width: 48; height: 48; radius: 13
                        color: aiMouse.containsMouse || root.aiOpen ? root.glassHover : "transparent"
                        Text { anchors.centerIn: parent; text: "AI"; color: root.accent; font.pixelSize: 12; font.weight: Font.Bold }
                        MouseArea {
                            id: aiMouse; anchors.fill: parent; hoverEnabled: true
                            onClicked: { root.aiOpen = !root.aiOpen; root.launcherOpen = false }
                        }
                    }
                }
            }
        }
    }

    // Native launcher surface. Searches DesktopEntries, no external launcher required.
    Variants {
        model: Quickshell.screens
        PanelWindow {
            property var modelData
            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            focusable: true
            visible: root.launcherOpen && !root.shellSuppressed && (!Hyprland.focusedMonitor || Hyprland.monitorFor(screen) === Hyprland.focusedMonitor)
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region { item: launcherCard }

            Rectangle {
                id: launcherCard
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(80, parent.height * 0.17)
                width: Math.min(660, parent.width - 48)
                height: 452
                radius: 22
                color: "#FA111820"
                border.width: 1
                border.color: root.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        radius: 14
                        color: root.glassRaised
                        border.width: 1
                        border.color: search.activeFocus ? root.accent : root.borderSoft

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            spacing: 10
                            Text { text: "⌕"; color: root.accent; font.pixelSize: 24 }
                            TextInput {
                                id: search
                                Layout.fillWidth: true
                                color: root.textMain
                                selectionColor: root.accent
                                font.pixelSize: 16
                                text: root.launcherQuery
                                onTextChanged: root.launcherQuery = text
                                Keys.onEscapePressed: root.launcherOpen = false
                                Component.onCompleted: if (parent.parent.parent.visible) forceActiveFocus()
                            }
                            Text { text: "ESC"; color: root.textMuted; font.pixelSize: 9 }
                        }
                    }

                    Text {
                        text: root.launcherQuery.length ? "APPLICATIONS" : "QUICK LAUNCH"
                        color: root.textMuted
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        Layout.leftMargin: 4
                    }

                    ListView {
                        id: appList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 5
                        clip: true
                        model: ScriptModel {
                            values: DesktopEntries.applications.values.filter(function(e) {
                                if (!root.launcherQuery.length) {
                                    const n = e.name.toLowerCase()
                                    return n.indexOf("code") >= 0 || n.indexOf("steam") >= 0 || n.indexOf("terminal") >= 0 || n.indexOf("chrome") >= 0 || n.indexOf("firefox") >= 0 || n.indexOf("dolphin") >= 0
                                }
                                const q = root.launcherQuery.toLowerCase()
                                return e.name.toLowerCase().indexOf(q) >= 0 || (e.genericName || "").toLowerCase().indexOf(q) >= 0
                            }).slice(0, 10)
                        }
                        delegate: Rectangle {
                            required property var modelData
                            width: appList.width
                            height: 50
                            radius: 12
                            color: appMouse.containsMouse ? root.glassHover : "transparent"
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10; anchors.rightMargin: 12
                                spacing: 11
                                IconImage { implicitSize: 29; source: Quickshell.iconPath(modelData.icon, "application-x-executable") }
                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 0
                                    Text { text: modelData.name; color: root.textMain; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    Text { text: modelData.genericName || modelData.comment || "Application"; color: root.textMuted; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                                }
                                Text { text: root.appRunning(modelData) ? "RUNNING" : "OPEN"; color: root.appRunning(modelData) ? root.good : root.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                            }
                            MouseArea { id: appMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { modelData.execute(); root.launcherOpen = false; root.launcherQuery = "" } }
                        }
                    }
                }
            }

            onVisibleChanged: if (visible) { root.launcherQuery = ""; search.forceActiveFocus() }
        }
    }

    // AI is a shell surface now, not a fake assistant implementation. This is the integration socket for the future local/remote agent.
    Variants {
        model: Quickshell.screens
        PanelWindow {
            property var modelData
            screen: modelData
            implicitWidth: 440
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            focusable: true
            visible: root.aiOpen && !root.shellSuppressed && (!Hyprland.focusedMonitor || Hyprland.monitorFor(screen) === Hyprland.focusedMonitor)
            anchors { right: true; top: true; bottom: true }
            mask: Region { item: aiCard }

            Rectangle {
                id: aiCard
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 18
                width: 394
                height: 430
                radius: 22
                color: "#FA111820"
                border.width: 1
                border.color: root.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "AI"; color: root.accent; font.pixelSize: 18; font.weight: Font.Bold }
                        Text { text: "SYSTEM SURFACE"; color: root.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: 28; height: 28; radius: 9; color: closeAi.containsMouse ? root.glassHover : "transparent"
                            Text { anchors.centerIn: parent; text: "×"; color: root.textMuted; font.pixelSize: 18 }
                            MouseArea { id: closeAi; anchors.fill: parent; hoverEnabled: true; onClicked: root.aiOpen = false }
                        }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: root.borderSoft }
                    Text { text: "Context"; color: root.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 78; radius: 13; color: root.glassRaised
                        Column {
                            anchors.fill: parent; anchors.margins: 12; spacing: 4
                            Text { text: "PROFILE   " + root.profile; color: root.textMain; font.pixelSize: 11 }
                            Text { text: "WORKSPACE   " + (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : "-"); color: root.textMuted; font.pixelSize: 11 }
                            Text { text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"; color: root.textMuted; font.pixelSize: 11; width: parent.width; elide: Text.ElideRight }
                        }
                    }
                    Text { text: "Agent provider is intentionally unbound in this shell build. The UI and context boundary are ready for the AI service layer."; color: root.textMuted; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Item { Layout.fillHeight: true }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 54; radius: 14; color: root.glassRaised; border.width: 1; border.color: root.borderSoft
                        Text { anchors.centerIn: parent; text: "AI SERVICE CONNECTION SLOT"; color: root.textMuted; font.pixelSize: 10; font.weight: Font.Bold }
                    }
                }
            }
        }
    }
}
