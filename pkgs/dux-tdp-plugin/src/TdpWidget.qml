import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.ControlCenter.Widgets
import qs.Modules.Plugins

// TDP control backed by PowerStation (org.shadowblip.PowerStation), the same
// interface the tdp@baracoder GNOME extension drives. Reads and writes go
// through the powerstation-tdp CLI; changes made elsewhere (steamos-manager,
// tdp-auto-adjust, the CLI) arrive via `gdbus monitor` on the bus name.
//
// Every surface (each bar pill, the Control Center tile) gets its own
// instance, so each keeps its own state and monitor process.
PluginComponent {
    id: root

    property var popoutService: null

    // Store paths, substituted by the Nix build.
    readonly property string shell: "@shell@"
    readonly property string powerstationTdp: "@powerstationTdp@"
    readonly property string gdbus: "@gdbus@"

    readonly property string busName: "org.shadowblip.PowerStation"
    readonly property string uid: Math.random().toString(36).slice(2)

    // Settings, see TdpSettings.qml. The fallback range only applies when
    // PowerStation reports none (or useDeviceLimits is off).
    readonly property bool useDeviceLimits: pluginData.useDeviceLimits ?? true
    readonly property real fallbackMin: Number(pluginData.minTdp ?? 5)
    readonly property real fallbackMax: Number(pluginData.maxTdp ?? 28)
    readonly property real boostWatts: Number(pluginData.boostWatts ?? 2)
    readonly property int step: Math.max(1, Number(pluginData.step ?? 1))
    readonly property bool showPowerProfile: pluginData.showPowerProfile ?? true
    readonly property var presets: parsePresets(pluginData.presets ?? "8 14 22 28").filter(w => w >= minTdp && w <= maxTdp)

    // PowerStation state
    property string cardPath: ""
    property bool available: false
    property bool loading: true
    property real watts: NaN
    property real boost: 0
    property real deviceMin: NaN
    property real deviceMax: NaN
    // What the user just asked for, shown until the write finishes.
    property real pendingWatts: NaN

    readonly property bool hasDeviceRange: useDeviceLimits && deviceMax > deviceMin
    readonly property real minTdp: hasDeviceRange ? deviceMin : fallbackMin
    readonly property real maxTdp: Math.max(hasDeviceRange ? deviceMax : fallbackMax, minTdp + 1)
    readonly property real shownWatts: isNaN(pendingWatts) ? watts : pendingWatts
    readonly property bool boostOn: boost > 0
    readonly property string wattsText: isNaN(shownWatts) ? "–" : formatWatts(shownWatts) + " W"
    readonly property string statusText: {
        if (loading)
            return I18n.tr("Loading…");
        if (!available)
            return I18n.trFor("tdpBaracoder", "PowerStation unavailable");
        return wattsText + (boostOn ? " · " + I18n.trFor("tdpBaracoder", "Boost") : "");
    }

    function parsePresets(text) {
        const seen = {};
        return String(text).split(/[\s,;]+/).map(Number).filter(w => {
            if (!isFinite(w) || w <= 0 || seen[w])
                return false;
            seen[w] = true;
            return true;
        }).sort((a, b) => a - b);
    }

    // PowerStation reports the float32 it stored, e.g. 22.000001907348633.
    function formatWatts(w) {
        const r = Math.round(w * 10) / 10;
        return Number.isInteger(r) ? r.toFixed(0) : r.toFixed(1);
    }

    function snap(w) {
        const snapped = Math.round(w / step) * step;
        return Math.min(maxTdp, Math.max(minTdp, snapped));
    }

    // One round trip for everything the UI shows. Runs powerstation-tdp
    // ($1) per value; a failing `range` just leaves that line empty.
    readonly property string queryScript: [
        'pt=$1',
        'p=$("$pt" path) || exit 1',
        'echo "path $p"',
        'echo "tdp $("$pt" get)"',
        'echo "range $("$pt" range)"',
        'echo "boost $("$pt" boost)"'
    ].join("\n")

    function refresh() {
        Proc.runCommand("tdpBaracoder.query." + uid, [shell, "-c", queryScript, "tdp-query", powerstationTdp], (out, code) => applyQuery(out, code), 100, 15000, root);
    }

    function applyQuery(out, code) {
        loading = false;
        if (code !== 0) {
            available = false;
            cardPath = "";
            return;
        }
        for (const line of out.split("\n")) {
            const parts = line.trim().split(/\s+/);
            const nums = parts.slice(1).map(Number);
            switch (parts[0]) {
            case "path":
                cardPath = parts[1] || "";
                break;
            case "tdp":
                if (isFinite(nums[0]))
                    watts = nums[0];
                break;
            case "range":
                if (nums.length === 2 && isFinite(nums[0]) && isFinite(nums[1])) {
                    deviceMin = nums[0];
                    deviceMax = nums[1];
                }
                break;
            case "boost":
                if (isFinite(nums[0]))
                    boost = nums[0];
                break;
            }
        }
        available = cardPath !== "" && !isNaN(watts);
    }

    // `gdbus monitor` prints one line per signal, e.g.
    //   /org/.../card1: org.freedesktop.DBus.Properties.PropertiesChanged
    //     ('org.shadowblip.GPU.Card.TDP', {'TDP': <22.000001907348633>}, @as [])
    // plus "The name ... is owned by / does not have an owner" lines when
    // PowerStation (re)starts.
    function onMonitorLine(line) {
        if (line.startsWith("The name")) {
            // Also printed once at startup; harmless, refresh() is debounced.
            if (line.includes("does not have an owner"))
                available = false;
            else
                refresh();
            return;
        }
        if (!cardPath || !line.startsWith(cardPath + ":") || !line.includes("org.shadowblip.GPU.Card.TDP"))
            return;
        const num = name => {
            const m = line.match(new RegExp("'" + name + "': <([-+0-9.eE]+)>"));
            return m ? Number(m[1]) : NaN;
        };
        const t = num("TDP");
        if (!isNaN(t))
            watts = t;
        const b = num("Boost");
        if (!isNaN(b))
            boost = b;
        const lo = num("MinTdp");
        if (!isNaN(lo))
            deviceMin = lo;
        const hi = num("MaxTdp");
        if (!isNaN(hi))
            deviceMax = hi;
    }

    // Slider drags call this per step; the debounce collapses them into the
    // last value. Presets pass immediate.
    function setTdp(w, immediate) {
        if (!available)
            return;
        const target = snap(w);
        pendingWatts = target;
        Proc.runCommand("tdpBaracoder.set." + uid, [powerstationTdp, "set", String(target)], (out, code) => {
            pendingWatts = NaN;
            if (code === 0) {
                watts = target;
            } else {
                ToastService.showError(I18n.trFor("tdpBaracoder", "Could not set TDP to %1 W").arg(target));
                refresh();
            }
        }, immediate ? 0 : 250, 15000, root);
    }

    // PowerStation's boost is headroom above the sustained limit: slow PPT =
    // TDP + boost, fast PPT = 1.25x that. Like hhd it is offered as on/off.
    function setBoost(on) {
        if (!available)
            return;
        const w = on ? boostWatts : 0;
        Proc.runCommand("tdpBaracoder.boost." + uid, [powerstationTdp, "boost", String(w)], (out, code) => {
            if (code === 0) {
                boost = w;
            } else {
                ToastService.showError(I18n.trFor("tdpBaracoder", "Could not set boost"));
                refresh();
            }
        }, 0, 15000, root);
    }

    function cyclePreset() {
        if (presets.length === 0)
            return;
        const current = Math.round(shownWatts);
        const next = presets.find(p => p > current) ?? presets[0];
        setTdp(next, true);
    }

    Component.onCompleted: {
        refresh();
        monitor.running = true;
    }
    Component.onDestruction: {
        for (const op of ["query", "set", "boost"])
            Proc.release("tdpBaracoder." + op + "." + uid);
    }

    Process {
        id: monitor
        // Not tied to an object path: watching the whole name also reports
        // PowerStation starting and stopping, and the card path may change.
        command: [root.gdbus, "monitor", "--system", "--dest", root.busName]
        running: false
        stdout: SplitParser {
            onRead: line => root.onMonitorLine(line)
        }
        onExited: monitorRestart.start()
    }

    // gdbus monitor follows the bus name itself, so this only fires if the
    // process dies.
    Timer {
        id: monitorRestart
        interval: 5000
        onTriggered: {
            monitor.running = true;
            root.refresh();
        }
    }

    // Belt and braces for missed signals: resync whenever the UI is opened.
    onCcWidgetExpanded: refresh()

    pillRightClickAction: () => root.cyclePreset()

    popoutWidth: 360
    popoutContent: Component {
        PopoutComponent {
            headerText: I18n.trFor("tdpBaracoder", "TDP")
            detailsText: root.available ? I18n.trFor("tdpBaracoder", "APU power limit, %1–%2 W").arg(root.formatWatts(root.minTdp)).arg(root.formatWatts(root.maxTdp)) : root.statusText
            Component.onCompleted: root.refresh()

            TdpPanel {
                tdp: root
                width: parent.width
            }
        }
    }

    ccWidgetIcon: "bolt"
    ccWidgetPrimaryText: I18n.trFor("tdpBaracoder", "TDP")
    ccWidgetSecondaryText: statusText
    ccWidgetIsActive: available && boostOn
    // Clicking the tile opens the detail page instead of toggling.
    ccWidgetIsToggle: false
    ccDetailHeight: 340

    ccDetailContent: Component {
        Item {
            readonly property string title: I18n.trFor("tdpBaracoder", "TDP")
            Component.onCompleted: root.refresh()

            Flickable {
                anchors.fill: parent
                contentHeight: panel.implicitHeight
                clip: true

                TdpPanel {
                    id: panel
                    tdp: root
                    width: parent.width
                }
            }
        }
    }

    // Larger CC tiles list the presets and boost directly.
    ccExpandedContent: Component {
        CcTileActions {
            actions: root.presets.map(p => ({
                        text: p + " W",
                        icon: "bolt",
                        active: Math.round(root.shownWatts) === p,
                        enabled: root.available,
                        trigger: () => root.setTdp(p, true)
                    })).concat([{
                        text: I18n.trFor("tdpBaracoder", "Boost"),
                        icon: "rocket_launch",
                        toggle: true,
                        active: root.boostOn,
                        enabled: root.available,
                        trigger: () => root.setBoost(!root.boostOn)
                    }])
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DIcon {
                name: root.boostOn ? "rocket_launch" : "bolt"
                color: root.available ? Theme.primary : Theme.surfaceVariantText
                size: root.iconSize
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.wattsText
                color: Theme.surfaceText
                font.pixelSize: root.textSize
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXXS

            DIcon {
                name: root.boostOn ? "rocket_launch" : "bolt"
                color: root.available ? Theme.primary : Theme.surfaceVariantText
                size: root.iconSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: isNaN(root.shownWatts) ? "–" : root.formatWatts(root.shownWatts)
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
