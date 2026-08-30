//@ pragma IconTheme Papirus-Dark
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import Quickshell.Io

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
    property bool controlCenterOpen: false
    property bool powerOpen: false
    property bool dockRevealOpen: false
    property string launcherQuery: ""

    readonly property bool workspaceFullscreen: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.hasFullscreen : false
    readonly property bool desktopEmpty: !Hyprland.focusedWorkspace || Hyprland.focusedWorkspace.toplevels.values.length === 0
    readonly property bool gamingMode: profile === "GAMING"
    readonly property bool shellSuppressed: workspaceFullscreen
    readonly property var audioSink: Pipewire.defaultAudioSink
    readonly property int volumePercent: audioSink && audioSink.audio ? Math.round(audioSink.audio.volume * 100) : 0
    readonly property bool audioMuted: audioSink && audioSink.audio ? audioSink.audio.muted : false
    readonly property bool batteryReady: UPower.displayDevice && UPower.displayDevice.ready
    readonly property int batteryPercent: batteryReady ? Math.round(UPower.displayDevice.percentage * 100) : -1
    readonly property bool onBatteryPower: UPower.onBattery
    readonly property bool batteryCharging: batteryReady && !UPower.onBattery
    readonly property string batteryStatusText: batteryPercent < 0 ? "NO BATTERY" : (batteryCharging ? "CHARGING  " + batteryPercent + "%" : "BAT  " + batteryPercent + "%")
    readonly property string connectedNetworkName: root.findConnectedNetworkName()
    readonly property int bluetoothConnected: Bluetooth.devices ? Bluetooth.devices.values.filter(function(d) { return d.connected }).length : 0
    readonly property var wifiDevice: root.findWifiDevice()
    readonly property var mediaPlayer: root.findMediaPlayer()
    readonly property var audioOutputs: Pipewire.nodes ? Pipewire.nodes.values.filter(function(n) { return n && !n.isStream && n.isSink && n.audio }) : []
    property var pendingWifi: null
    property string wifiPsk: ""
    property int brightnessPercent: -1
    property string cpuText: "CPU --"
    property string ramText: "RAM --"
    property string temperatureText: ""
    property string aiBridgeState: "UNBOUND"
    property string aiBridgeProvider: ""
    property string aiBridgeEndpoint: ""
    property string aiDraft: ""
    property string aiLastResponse: ""


    function gotoWorkspace(n) {
        Quickshell.execDetached(["hyprctl", "dispatch", "workspace", String(n)])
    }

    function findWifiDevice() {
        const devices = Networking.devices ? Networking.devices.values : []
        for (let i = 0; i < devices.length; ++i) {
            if (devices[i] && devices[i].networks && devices[i].networks.values)
                return devices[i]
        }
        return null
    }

    function findMediaPlayer() {
        const players = Mpris.players ? Mpris.players.values : []
        for (let i = 0; i < players.length; ++i)
            if (players[i].isPlaying) return players[i]
        return players.length > 0 ? players[0] : null
    }

    function connectWifi(network) {
        if (!network) return
        if (network.connected) {
            network.disconnect()
            pendingWifi = null
            wifiPsk = ""
            return
        }
        pendingWifi = null
        wifiPsk = ""
        network.connect()
    }

    function submitWifiPsk() {
        if (!pendingWifi || wifiPsk.length === 0) return
        pendingWifi.connectWithPsk(wifiPsk)
        pendingWifi = null
        wifiPsk = ""
    }

    function toggleBluetoothDevice(device) {
        if (!device) return
        if (device.connected) device.disconnect()
        else if (device.paired) device.connect()
        else device.pair()
    }

    function chooseAudioOutput(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node
    }

    function setBrightness(delta) {
        brightnessSet.command = ["sh", "-lc",
            "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl set " +
            (delta > 0 ? "+5%" : "5%-") + " >/dev/null 2>&1; fi"]
        brightnessSet.running = true
        brightnessProbe.running = true
    }

    function sendAiDraft() {
        // Deliberately no network listener, socket, shell execution, or privilege path here.
        // A future trusted AI service binds to this seam explicitly.
        if (aiBridgeState !== "READY") {
            aiLastResponse = "AI service is not connected yet."
            return
        }
        aiLastResponse = "AI bridge ready for provider: " + aiBridgeProvider
    }

    function findConnectedNetworkName() {
        const devices = Networking.devices ? Networking.devices.values : []
        for (let i = 0; i < devices.length; ++i) {
            const nets = devices[i].networks ? devices[i].networks.values : []
            for (let j = 0; j < nets.length; ++j) {
                if (nets[j].connected) return nets[j].name
            }
        }
        return Networking.wifiEnabled ? "Disconnected" : "Wi-Fi Off"
    }

    function matchingToplevel(entry) {
        if (!entry) return null
        const startup = (entry.startupClass || "").toLowerCase()
        const id = (entry.id || "").toLowerCase().replace(".desktop", "")
        const name = (entry.name || "").toLowerCase().replace(/\s+/g, "")
        const tops = Hyprland.toplevels.values
        for (let i = 0; i < tops.length; ++i) {
            const appId = (tops[i].appId || "").toLowerCase()
            const compact = appId.replace(/\s+/g, "")
            if ((startup && appId.indexOf(startup) >= 0) ||
                (id && appId.indexOf(id) >= 0) ||
                (name && compact.indexOf(name) >= 0)) return tops[i]
        }
        return null
    }

    function focusOrLaunch(entry, candidates) {
        const top = matchingToplevel(entry)
        if (top) {
            top.activate()
            return
        }
        launchByCandidates(candidates)
    }

    function setVolume(v) {
        if (audioSink && audioSink.audio) audioSink.audio.volume = Math.max(0, Math.min(1.5, v))
    }

    function cyclePowerProfile() {
        if (PowerProfiles.profile === PowerProfile.PowerSaver) PowerProfiles.profile = PowerProfile.Balanced
        else if (PowerProfiles.profile === PowerProfile.Balanced && PowerProfiles.hasPerformanceProfile) PowerProfiles.profile = PowerProfile.Performance
        else PowerProfiles.profile = PowerProfile.PowerSaver
    }

    function powerProfileText() {
        if (PowerProfiles.profile === PowerProfile.Performance) return "PERFORMANCE"
        if (PowerProfiles.profile === PowerProfile.PowerSaver) return "POWER SAVER"
        return "BALANCED"
    }

    function setProfile(name) {
        profile = name
        launcherOpen = false
        aiOpen = false
        profileOpen = false
        if (name === "GAMING") stripOpen = false
    }

    function launchBrowser() {
        // Prefer the installed desktop entry so distro-specific Chrome commands stay correct.
        const apps = DesktopEntries.applications.values
        const exactIds = ["google-chrome.desktop", "google-chrome-stable.desktop", "com.google.Chrome.desktop", "chromium.desktop"]
        for (let i = 0; i < exactIds.length; ++i) {
            const byId = DesktopEntries.byId(exactIds[i])
            if (byId) { byId.execute(); launcherOpen = false; return }
        }
        for (let j = 0; j < apps.length; ++j) {
            const n = (apps[j].name || "").toLowerCase()
            const id = (apps[j].id || "").toLowerCase()
            if (n === "google chrome" || id.indexOf("google-chrome") >= 0 || id.indexOf("google.chrome") >= 0) {
                apps[j].execute(); launcherOpen = false; return
            }
        }
        // Last-resort runtime fallback only. This changes no system configuration.
        Quickshell.execDetached(["sh", "-lc", "command -v google-chrome-stable >/dev/null && exec google-chrome-stable || command -v google-chrome >/dev/null && exec google-chrome || command -v chromium >/dev/null && exec chromium || command -v chromium-browser >/dev/null && exec chromium-browser"])
        launcherOpen = false
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

    function entryForToplevel(top) {
        if (!top) return null
        const ids = [top.appId || "", (top.appId || "") + ".desktop"]
        for (let i = 0; i < ids.length; ++i) {
            const e = DesktopEntries.heuristicLookup(ids[i])
            if (e) return e
        }
        return null
    }

    function appRunning(entry) { return matchingToplevel(entry) !== null }

    function appActive(entry) {
        const top = matchingToplevel(entry)
        return top ? top.activated : false
    }

    PwObjectTracker {
        objects: {
            const tracked = [root.audioSink]
            for (let i = 0; i < root.audioOutputs.length; ++i) tracked.push(root.audioOutputs[i])
            return tracked
        }
    }

    Process {
        id: brightnessProbe
        command: ["sh", "-lc", "if command -v brightnessctl >/dev/null 2>&1; then p=$(brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,\"\",$4); print $4; exit}'); printf '%s' \"$p\"; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text.trim())
                root.brightnessPercent = isNaN(v) ? -1 : v
            }
        }
    }

    Process {
        id: brightnessSet
        stdout: StdioCollector {}
    }

    Process {
        id: telemetryProbe
        command: ["sh", "-lc", "read _ u1 n1 s1 i1 w1 x1 y1 z1 _ < /proc/stat; t1=$((u1+n1+s1+i1+w1+x1+y1+z1)); b1=$((i1+w1)); sleep 0.20; read _ u2 n2 s2 i2 w2 x2 y2 z2 _ < /proc/stat; t2=$((u2+n2+s2+i2+w2+x2+y2+z2)); b2=$((i2+w2)); dt=$((t2-t1)); db=$((b2-b1)); cpu=0; [ $dt -gt 0 ] && cpu=$(((dt-db)*100/dt)); awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{if(t>0)printf \"RAM %d%%\",(t-a)*100/t}' /proc/meminfo; printf '|CPU %d%%|' $cpu; for f in /sys/class/thermal/thermal_zone*/temp; do [ -r \"$f\" ] || continue; v=$(cat \"$f\" 2>/dev/null); [ \"$v\" -gt 0 ] 2>/dev/null && { printf 'TEMP %d°C' $((v/1000)); break; }; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|")
                if (p.length > 0 && p[0]) root.ramText = p[0]
                if (p.length > 1 && p[1]) root.cpuText = p[1]
                root.temperatureText = p.length > 2 ? p[2] : ""
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!telemetryProbe.running) telemetryProbe.running = true
            if (!brightnessProbe.running) brightnessProbe.running = true
        }
    }


    NotificationServer {
        id: notificationServer
        actionsSupported: true
        bodySupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true
        onNotification: function(notification) { notification.tracked = true }
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
                        Layout.maximumWidth: 150
                    }

                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 22; color: root.borderSoft }

                    Row {
                        spacing: 10
                        Text { text: root.audioMuted ? "VOL ×" : "VOL " + root.volumePercent + "%"; color: root.textMain; font.pixelSize: 10; font.weight: Font.DemiBold }
                        Text { text: root.connectedNetworkName; color: root.textMuted; font.pixelSize: 10; width: 92; elide: Text.ElideRight }
                        Text { text: Bluetooth.defaultAdapter ? (Bluetooth.defaultAdapter.enabled ? (root.bluetoothConnected > 0 ? "BT " + root.bluetoothConnected : "BT ON") : "BT OFF") : ""; visible: Bluetooth.defaultAdapter !== null; color: root.textMuted; font.pixelSize: 10 }
                        Text { visible: root.batteryPercent >= 0; text: root.batteryStatusText; color: root.batteryPercent < 20 ? "#FFB86B" : root.textMain; font.pixelSize: 10; font.weight: Font.DemiBold }
                        Text { text: root.powerProfileText(); color: root.textMuted; font.pixelSize: 9 }
                    }

                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 22; color: root.borderSoft }

                    Rectangle {
                        Layout.preferredWidth: 38; Layout.preferredHeight: 32; radius: 10
                        color: ccMouse.containsMouse || root.controlCenterOpen ? root.glassHover : "transparent"
                        Text { anchors.centerIn: parent; text: "⚙"; color: root.accent; font.pixelSize: 15 }
                        MouseArea { id: ccMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { root.controlCenterOpen = !root.controlCenterOpen; root.powerOpen = false } }
                    }

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

    // Live system control center. All controls use Quickshell services; no helper daemon is installed.
    Variants {
        model: Quickshell.screens
        PanelWindow {
            property var modelData
            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            focusable: true
            visible: root.controlCenterOpen && !root.shellSuppressed && (!Hyprland.focusedMonitor || Hyprland.monitorFor(screen) === Hyprland.focusedMonitor)
            anchors { top: true; right: true; bottom: true }
            implicitWidth: 410
            mask: Region { item: controlCard }

            Rectangle {
                id: controlCard
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 72
                anchors.rightMargin: 18
                width: 380
                height: Math.min(760, parent.height - 100)
                radius: 22
                color: "#FA111820"
                border.width: 1
                border.color: root.border

                Flickable {
                    id: controlScroll
                    anchors.fill: parent
                    anchors.margins: 12
                    clip: true
                    contentWidth: width
                    contentHeight: controlContent.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: controlContent
                        width: controlScroll.width
                        spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "CONTROL CENTER"; color: root.textMain; font.pixelSize: 12; font.weight: Font.Bold }
                        Item { Layout.fillWidth: true }
                        Text { text: Qt.formatDateTime(clock.date, "HH:mm"); color: root.textMuted; font.pixelSize: 11 }
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: root.borderSoft }

                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 14
                            color: Networking.wifiEnabled ? root.glassHover : root.glassRaised
                            border.width: 1; border.color: Networking.wifiEnabled ? root.accent : root.borderSoft
                            Column { anchors.centerIn: parent; spacing: 5
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "WI-FI"; color: root.textMain; font.pixelSize: 10; font.weight: Font.Bold }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; width: 130; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: root.connectedNetworkName; color: root.textMuted; font.pixelSize: 10 }
                            }
                            MouseArea { anchors.fill: parent; onClicked: Networking.wifiEnabled = !Networking.wifiEnabled }
                        }
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 14
                            property bool btOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
                            color: btOn ? root.glassHover : root.glassRaised
                            border.width: 1; border.color: btOn ? root.accent : root.borderSoft
                            Column { anchors.centerIn: parent; spacing: 5
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "BLUETOOTH"; color: root.textMain; font.pixelSize: 10; font.weight: Font.Bold }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Bluetooth.defaultAdapter ? (root.bluetoothConnected > 0 ? root.bluetoothConnected + " CONNECTED" : (parent.parent.btOn ? "ON" : "OFF")) : "UNAVAILABLE"; color: root.textMuted; font.pixelSize: 10 }
                            }
                            MouseArea { anchors.fill: parent; enabled: Bluetooth.defaultAdapter !== null; onClicked: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 88; radius: 14; color: root.glassRaised; border.width: 1; border.color: root.borderSoft
                        ColumnLayout { anchors.fill: parent; anchors.margins: 12; spacing: 7
                            RowLayout { Layout.fillWidth: true
                                Text { text: root.audioMuted ? "AUDIO  MUTED" : "AUDIO  " + root.volumePercent + "%"; color: root.textMain; font.pixelSize: 10; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: root.audioSink ? (root.audioSink.description || root.audioSink.name) : "No output"; color: root.textMuted; font.pixelSize: 9; elide: Text.ElideRight; Layout.maximumWidth: 170 }
                            }
                            RowLayout { Layout.fillWidth: true; spacing: 7
                                Rectangle { width: 34; height: 30; radius: 9; color: root.glassHover; Text { anchors.centerIn: parent; text: "−"; color: root.textMain; font.pixelSize: 16 } MouseArea { anchors.fill: parent; onClicked: root.setVolume((root.audioSink && root.audioSink.audio ? root.audioSink.audio.volume : 0) - 0.05) } }
                                Rectangle { Layout.fillWidth: true; height: 7; radius: 4; color: root.borderSoft
                                    Rectangle { width: parent.width * Math.min(root.volumePercent / 100, 1); height: parent.height; radius: 4; color: root.accent }
                                    MouseArea { anchors.fill: parent; onClicked: function(mouse) { root.setVolume(mouse.x / width) } }
                                }
                                Rectangle { width: 34; height: 30; radius: 9; color: root.glassHover; Text { anchors.centerIn: parent; text: "+"; color: root.textMain; font.pixelSize: 16 } MouseArea { anchors.fill: parent; onClicked: root.setVolume((root.audioSink && root.audioSink.audio ? root.audioSink.audio.volume : 0) + 0.05) } }
                                Rectangle { width: 48; height: 30; radius: 9; color: root.audioMuted ? "#55364145" : root.glassHover; Text { anchors.centerIn: parent; text: root.audioMuted ? "UNMUTE" : "MUTE"; color: root.textMain; font.pixelSize: 8; font.weight: Font.Bold } MouseArea { anchors.fill: parent; enabled: root.audioSink && root.audioSink.audio; onClicked: root.audioSink.audio.muted = !root.audioSink.audio.muted } }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 64; radius: 14; color: root.glassRaised; border.width: 1; border.color: root.borderSoft
                        RowLayout { anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 9
                            Text { text: "POWER"; color: root.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                            Text { visible: root.batteryPercent >= 0; text: root.batteryCharging ? ("⚡ " + root.batteryPercent + "%") : (root.batteryPercent + "%"); color: root.batteryCharging ? root.good : root.textMain; font.pixelSize: 12; font.weight: Font.Bold }
                            Item { Layout.fillWidth: true }
                            Rectangle { width: 116; height: 36; radius: 10; color: root.glassHover; border.width: 1; border.color: root.borderSoft
                                Text { anchors.centerIn: parent; text: root.powerProfileText(); color: root.accent; font.pixelSize: 9; font.weight: Font.Bold }
                                MouseArea { anchors.fill: parent; onClicked: root.cyclePowerProfile() }
                            }
                        }
                    }

                    // Available Wi-Fi networks. Connection secrets are only held in memory for the active attempt.
                    Text { text: "NETWORKS"; color: root.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Repeater {
                            model: ScriptModel {
                                values: root.wifiDevice && root.wifiDevice.networks ? root.wifiDevice.networks.values.slice(0, 5) : []
                            }
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: 9
                                color: modelData.connected ? root.glassHover : root.glassRaised
                                border.width: 1
                                border.color: modelData.connected ? root.accent : root.borderSoft
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    Text { text: modelData.name; color: root.textMain; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Text { text: Math.round((modelData.signalStrength || 0) * 100) + "%"; color: root.textMuted; font.pixelSize: 9 }
                                    Text { text: modelData.connected ? "CONNECTED" : (modelData.stateChanging ? "..." : "CONNECT"); color: modelData.connected ? root.good : root.accent; font.pixelSize: 8; font.weight: Font.Bold }
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.connectWifi(parent.modelData) }
                                Connections {
                                    target: modelData
                                    function onConnectionFailed(reason) {
                                        root.pendingWifi = modelData
                                        root.wifiPsk = ""
                                    }
                                }
                            }
                        }
                        Rectangle {
                            visible: root.pendingWifi !== null
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 9
                            color: root.glassRaised
                            border.width: 1
                            border.color: root.accent
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                TextInput {
                                    id: wifiPasswordInput
                                    Layout.fillWidth: true
                                    color: root.textMain
                                    selectionColor: root.accent
                                    font.pixelSize: 10
                                    echoMode: TextInput.Password
                                    text: root.wifiPsk
                                    onTextChanged: root.wifiPsk = text
                                    Keys.onReturnPressed: root.submitWifiPsk()
                                }
                                Rectangle {
                                    width: 72; height: 30; radius: 8; color: root.glassHover
                                    Text { anchors.centerIn: parent; text: "CONNECT"; color: root.accent; font.pixelSize: 8; font.weight: Font.Bold }
                                    MouseArea { anchors.fill: parent; onClicked: root.submitWifiPsk() }
                                }
                            }
                        }
                    }

                    Text { text: "AUDIO OUTPUT"; color: root.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Repeater {
                            model: ScriptModel { values: root.audioOutputs.slice(0, 3) }
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                radius: 9
                                color: root.audioSink === modelData ? root.glassHover : root.glassRaised
                                border.width: 1
                                border.color: root.audioSink === modelData ? root.accent : root.borderSoft
                                Text { anchors.centerIn: parent; width: parent.width - 12; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: modelData.description || modelData.nickname || modelData.name; color: root.textMain; font.pixelSize: 8 }
                                MouseArea { anchors.fill: parent; onClicked: root.chooseAudioOutput(parent.modelData) }
                            }
                        }
                    }

                    Text { visible: Bluetooth.defaultAdapter !== null; text: "BLUETOOTH DEVICES"; color: root.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                    RowLayout {
                        visible: Bluetooth.defaultAdapter !== null
                        Layout.fillWidth: true
                        spacing: 5
                        Repeater {
                            model: ScriptModel { values: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.devices ? Bluetooth.defaultAdapter.devices.values.slice(0, 3) : [] }
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 42
                                radius: 9
                                color: modelData.connected ? root.glassHover : root.glassRaised
                                border.width: 1
                                border.color: modelData.connected ? root.accent : root.borderSoft
                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width - 8
                                    spacing: 2
                                    Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: modelData.name || modelData.deviceName; color: root.textMain; font.pixelSize: 8 }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.connected ? "CONNECTED" : (modelData.pairing ? "PAIRING" : (modelData.paired ? "CONNECT" : "PAIR")); color: modelData.connected ? root.good : root.textMuted; font.pixelSize: 7 }
                                }
                                MouseArea { anchors.fill: parent; onClicked: root.toggleBluetoothDevice(parent.modelData) }
                            }
                        }
                        Rectangle {
                            width: 62; Layout.preferredHeight: 42; radius: 9; color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? root.glassHover : root.glassRaised
                            Text { anchors.centerIn: parent; text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering ? "SCANNING" : "SCAN"; color: root.accent; font.pixelSize: 8; font.weight: Font.Bold }
                            MouseArea { anchors.fill: parent; enabled: Bluetooth.defaultAdapter !== null; onClicked: Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 42; radius: 10; color: root.glassRaised; border.width: 1; border.color: root.borderSoft
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                Text { text: root.brightnessPercent >= 0 ? ("BRIGHT " + root.brightnessPercent + "%") : "BRIGHTNESS UNAVAILABLE"; color: root.textMain; font.pixelSize: 9; Layout.fillWidth: true }
                                Rectangle { visible: root.brightnessPercent >= 0; width: 28; height: 26; radius: 7; color: root.glassHover; Text { anchors.centerIn: parent; text: "−"; color: root.textMain } MouseArea { anchors.fill: parent; onClicked: root.setBrightness(-1) } }
                                Rectangle { visible: root.brightnessPercent >= 0; width: 28; height: 26; radius: 7; color: root.glassHover; Text { anchors.centerIn: parent; text: "+"; color: root.textMain } MouseArea { anchors.fill: parent; onClicked: root.setBrightness(1) } }
                            }
                        }
                    }

                    Rectangle {
                        visible: root.mediaPlayer !== null
                        Layout.fillWidth: true
                        Layout.preferredHeight: 58
                        radius: 11
                        color: root.glassRaised
                        border.width: 1
                        border.color: root.borderSoft
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 9; spacing: 7
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 1
                                Text { text: root.mediaPlayer ? (root.mediaPlayer.trackTitle || root.mediaPlayer.identity) : ""; color: root.textMain; font.pixelSize: 10; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text { text: root.mediaPlayer ? (root.mediaPlayer.trackArtist || root.mediaPlayer.identity) : ""; color: root.textMuted; font.pixelSize: 8; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                            Rectangle { width: 30; height: 30; radius: 8; color: root.glassHover; Text { anchors.centerIn: parent; text: "‹"; color: root.textMain; font.pixelSize: 16 } MouseArea { anchors.fill: parent; enabled: root.mediaPlayer && root.mediaPlayer.canGoPrevious; onClicked: root.mediaPlayer.previous() } }
                            Rectangle { width: 38; height: 30; radius: 8; color: root.glassHover; Text { anchors.centerIn: parent; text: root.mediaPlayer && root.mediaPlayer.isPlaying ? "Ⅱ" : "▶"; color: root.accent; font.pixelSize: 12 } MouseArea { anchors.fill: parent; enabled: root.mediaPlayer && root.mediaPlayer.canTogglePlaying; onClicked: root.mediaPlayer.togglePlaying() } }
                            Rectangle { width: 30; height: 30; radius: 8; color: root.glassHover; Text { anchors.centerIn: parent; text: "›"; color: root.textMain; font.pixelSize: 16 } MouseArea { anchors.fill: parent; enabled: root.mediaPlayer && root.mediaPlayer.canGoNext; onClicked: root.mediaPlayer.next() } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: root.cpuText; color: root.textMuted; font.pixelSize: 8 }
                        Text { text: root.ramText; color: root.textMuted; font.pixelSize: 8 }
                        Text { visible: root.temperatureText !== ""; text: root.temperatureText; color: root.textMuted; font.pixelSize: 8 }
                    }

                    Text { text: "SYSTEM TRAY"; color: root.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                    Flow {
                        Layout.fillWidth: true; spacing: 7
                        Repeater {
                            model: SystemTray.items
                            delegate: Rectangle {
                                required property var modelData
                                width: 40; height: 40; radius: 11; color: trayMouse.containsMouse ? root.glassHover : root.glassRaised; border.width: 1; border.color: root.borderSoft
                                IconImage { anchors.centerIn: parent; implicitSize: 22; source: modelData.icon }
                                MouseArea { id: trayMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.MiddleButton) modelData.secondaryActivate()
                                        else if (mouse.button === Qt.RightButton && modelData.hasMenu) modelData.display(controlCard, parent.x + width / 2, parent.y + height)
                                        else modelData.activate()
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 42; radius: 12; color: root.powerOpen ? root.glassHover : root.glassRaised; border.width: 1; border.color: root.borderSoft
                        Text { anchors.centerIn: parent; text: root.powerOpen ? "CLOSE POWER ACTIONS" : "POWER ACTIONS"; color: root.textMain; font.pixelSize: 10; font.weight: Font.Bold }
                        MouseArea { anchors.fill: parent; onClicked: root.powerOpen = !root.powerOpen }
                    }
                    RowLayout {
                        visible: root.powerOpen
                        Layout.fillWidth: true; spacing: 6
                        Repeater {
                            model: [
                                {label:"LOCK", cmd:["loginctl","lock-session"]},
                                {label:"SLEEP", cmd:["systemctl","suspend"]},
                                {label:"REBOOT", cmd:["systemctl","reboot"]},
                                {label:"OFF", cmd:["systemctl","poweroff"]}
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true; Layout.preferredHeight: 38; radius: 10; color: pMouse.containsMouse ? root.glassHover : root.glassRaised; border.width: 1; border.color: root.borderSoft
                                Text { anchors.centerIn: parent; text: modelData.label; color: root.textMain; font.pixelSize: 8; font.weight: Font.Bold }
                                MouseArea { id: pMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(modelData.cmd) }
                            }
                        }
                    }
                    }
                }
            }
        }
    }

    // Station surface. It is intentionally empty until the user populates that station.
    // Gaming is not represented here; gaming remains its own shell mode.
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
            mask: Region { item: stationPod }

            Rectangle {
                id: stationPod
                x: 38; y: 92
                width: 238; height: 154
                radius: 18
                color: root.glass
                border.width: 1
                border.color: root.border

                Text {
                    x: 14; y: 14
                    text: "STATION " + (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : "-")
                    color: root.textMain
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                // No default shortcuts. Station contents are user-owned and will be populated later.
                MouseArea {
                    x: 0; y: 0; width: parent.width; height: 40
                    acceptedButtons: Qt.LeftButton
                    drag.target: stationPod
                    drag.axis: Drag.XAndYAxis
                }
            }
        }
    }

    // Apple-style floating dock. Visible on the desktop, hidden while working, bottom-edge reveal on demand.
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

            Timer {
                id: dockHideTimer
                interval: 650
                repeat: false
                onTriggered: if (!root.desktopEmpty) root.dockRevealOpen = false
            }

            Rectangle {
                id: dock
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: (root.desktopEmpty || root.dockRevealOpen) ? 12 : -58
                opacity: (root.desktopEmpty || root.dockRevealOpen) ? 1 : 0
                Behavior on anchors.bottomMargin { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 110 } }
                width: dockRow.implicitWidth + 20
                height: 62
                radius: 19
                color: root.glass
                border.width: 1
                border.color: root.border

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: { root.dockRevealOpen = true; dockHideTimer.stop() }
                    onExited: dockHideTimer.restart()
                }

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

                    Repeater {
                        model: ScriptModel { values: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.toplevels.values : [] }
                        delegate: Rectangle {
                            required property var modelData
                            property var entry: root.entryForToplevel(modelData)
                            width: 48; height: 48; radius: 13
                            color: modelData.activated ? root.glassHover : (runningMouse.containsMouse ? root.glassHover : "transparent")
                            scale: runningMouse.containsMouse ? 1.08 : 1.0
                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 28
                                source: Quickshell.iconPath(parent.entry && parent.entry.icon ? parent.entry.icon : (modelData.appId || "application-x-executable"), "application-x-executable")
                            }
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                width: 12; height: 2; radius: 1
                                color: root.accentStrong
                            }
                            MouseArea { id: runningMouse; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.activate() }
                            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                        }
                    }

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

    // Native notification surface. Notifications are tracked by Quickshell itself.
    Variants {
        model: Quickshell.screens
        PanelWindow {
            property var modelData
            screen: modelData
            implicitWidth: 390
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            visible: !root.shellSuppressed && notificationServer.trackedNotifications.values.length > 0 && (!Hyprland.focusedMonitor || Hyprland.monitorFor(screen) === Hyprland.focusedMonitor)
            anchors { right: true; top: true; bottom: true }
            mask: Region { item: notificationColumn }

            Column {
                id: notificationColumn
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 78
                anchors.rightMargin: 18
                width: 350
                spacing: 8

                Repeater {
                    model: ScriptModel { values: notificationServer.trackedNotifications.values.slice(-4).reverse() }
                    delegate: Rectangle {
                        required property var modelData
                        width: notificationColumn.width
                        height: 92
                        radius: 16
                        color: "#FA111820"
                        border.width: 1
                        border.color: root.border
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12; spacing: 10
                            IconImage { visible: modelData.appIcon !== ""; implicitSize: 30; source: modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, "dialog-information") : "" }
                            ColumnLayout { Layout.fillWidth: true; spacing: 3
                                Text { text: modelData.appName || "Notification"; color: root.accent; font.pixelSize: 9; font.weight: Font.Bold }
                                Text { text: modelData.summary; color: root.textMain; font.pixelSize: 12; font.weight: Font.DemiBold; Layout.fillWidth: true; elide: Text.ElideRight }
                                Text { text: modelData.body; color: root.textMuted; font.pixelSize: 10; Layout.fillWidth: true; maximumLineCount: 2; wrapMode: Text.WordWrap; textFormat: Text.PlainText }
                            }
                            Rectangle { width: 28; height: 28; radius: 9; color: nClose.containsMouse ? root.glassHover : "transparent"
                                Text { anchors.centerIn: parent; text: "×"; color: root.textMuted; font.pixelSize: 16 }
                                MouseArea { id: nClose; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.dismiss() }
                            }
                        }
                    }
                }
            }
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
                    Text { text: "Trusted AI bridge"; color: root.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 42; radius: 11; color: root.glassRaised; border.width: 1; border.color: root.borderSoft
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 9
                            Text { text: root.aiBridgeState; color: root.aiBridgeState === "READY" ? root.good : root.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                            Text { text: root.aiBridgeProvider || "No provider bound"; color: root.textMuted; font.pixelSize: 9; Layout.fillWidth: true; elide: Text.ElideRight }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 90; radius: 13; color: root.glassRaised; border.width: 1; border.color: root.borderSoft
                        TextEdit {
                            anchors.fill: parent; anchors.margins: 12
                            color: root.textMain; selectionColor: root.accent
                            font.pixelSize: 11; wrapMode: TextEdit.Wrap
                            text: root.aiDraft
                            onTextChanged: root.aiDraft = text
                        }
                    }
                    Text { visible: root.aiLastResponse !== ""; text: root.aiLastResponse; color: root.textMuted; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    Item { Layout.fillHeight: true }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 44; radius: 12; color: root.glassHover; border.width: 1; border.color: root.aiBridgeState === "READY" ? root.accent : root.borderSoft
                        Text { anchors.centerIn: parent; text: root.aiBridgeState === "READY" ? "SEND TO AI" : "AI SERVICE NOT CONNECTED"; color: root.aiBridgeState === "READY" ? root.accent : root.textMuted; font.pixelSize: 9; font.weight: Font.Bold }
                        MouseArea { anchors.fill: parent; onClicked: root.sendAiDraft() }
                    }
                }
            }
        }
    }
}
