import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets

// Controls shared by the bar popout and the Control Center detail page.
// `tdp` is the TdpWidget instance holding the PowerStation state.
Column {
    id: panel

    property var tdp: null

    spacing: Theme.spacingM

    StyledText {
        width: parent.width
        visible: !panel.tdp.available && !panel.tdp.loading
        text: I18n.trFor("tdpBaracoder", "PowerStation reports no card with TDP control. Check `systemctl status powerstation`.")
        color: Theme.surfaceVariantText
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.WordWrap
    }

    Item {
        width: parent.width
        height: Math.max(valueLabel.implicitHeight, rangeLabel.implicitHeight)

        StyledText {
            id: valueLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: panel.tdp.wattsText
            color: panel.tdp.available ? Theme.surfaceText : Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeXLarge
            font.weight: Theme.fontWeightMedium
        }

        StyledText {
            id: rangeLabel
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: panel.tdp.available
            text: panel.tdp.hasDeviceRange ? I18n.trFor("tdpBaracoder", "device range") : I18n.trFor("tdpBaracoder", "fallback range")
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    DSlider {
        id: slider
        width: parent.width
        minimum: Math.floor(panel.tdp.minTdp)
        maximum: Math.ceil(panel.tdp.maxTdp)
        step: panel.tdp.step
        unit: "W"
        showValue: true
        enabled: panel.tdp.available
        startIcon: "battery_saver"
        endIcon: "bolt"
        Accessible.name: "TDP"
        onSliderValueChanged: newValue => panel.tdp.setTdp(newValue, false)

        // Follow the hardware, but leave the handle alone while it is held.
        Binding {
            target: slider
            property: "value"
            value: Math.round(panel.tdp.shownWatts)
            when: !slider.isDragging && !isNaN(panel.tdp.shownWatts)
            restoreMode: Binding.RestoreNone
        }
    }

    DButtonGroup {
        width: parent.width
        visible: panel.tdp.presets.length > 0
        fillWidth: true
        checkEnabled: false
        enabled: panel.tdp.available
        model: panel.tdp.presets.map(p => ({
                    text: p + " W"
                }))
        currentIndex: panel.tdp.presets.indexOf(Math.round(panel.tdp.shownWatts))
        onSelectionChanged: (index, selected) => {
            if (selected)
                panel.tdp.setTdp(panel.tdp.presets[index], true);
        }
    }

    DToggle {
        width: parent.width
        enabled: panel.tdp.available
        text: I18n.trFor("tdpBaracoder", "Boost")
        description: I18n.trFor("tdpBaracoder", "Allow %1 W above the limit for short bursts").arg(panel.tdp.formatWatts(panel.tdp.boostWatts))
        checked: panel.tdp.boostOn
        onToggled: checked => panel.tdp.setBoost(checked)
    }

    Column {
        width: parent.width
        spacing: Theme.spacingS
        visible: panel.tdp.showPowerProfile && PowerProfileWatcher.available

        StyledText {
            text: I18n.trFor("tdpBaracoder", "Power profile")
            color: Theme.surfaceVariantText
            font.pixelSize: Theme.fontSizeSmall
        }

        DButtonGroup {
            readonly property var profiles: PowerProfileWatcher.availableProfiles

            width: parent.width
            fillWidth: true
            checkEnabled: false
            model: profiles.map(profile => ({
                        text: Theme.getPowerProfileLabel(profile),
                        icon: ["eco", "bolt", "speed"][profile]
                    }))
            currentIndex: profiles.indexOf(PowerProfileWatcher.currentProfile)
            onSelectionChanged: (index, selected) => {
                if (selected && !PowerProfileWatcher.applyProfile(profiles[index]))
                    ToastService.showError(I18n.tr("Failed to set power profile"));
            }
        }
    }
}
