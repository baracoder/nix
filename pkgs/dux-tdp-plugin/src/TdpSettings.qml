import QtQuick
import qs.Common
import qs.Modules.Plugins

// Mirrors the org.gnome.shell.extensions.tdp-baracoder schema, plus presets.
PluginSettings {
    pluginId: "tdpBaracoder"

    StringSetting {
        settingKey: "presets"
        label: I18n.trFor("tdpBaracoder", "Presets")
        description: I18n.trFor("tdpBaracoder", "Watts offered as buttons, separated by spaces or commas. Values outside the slider range are hidden. Right-clicking the bar pill cycles through them.")
        placeholder: "8 14 22 28"
        defaultValue: "8 14 22 28"
    }

    ToggleSetting {
        settingKey: "useDeviceLimits"
        label: I18n.trFor("tdpBaracoder", "Take the slider range from the device")
        description: I18n.trFor("tdpBaracoder", "Read MinTdp/MaxTdp from PowerStation, which sources them from its APU and DMI override databases. The bounds below cover platforms that report no range.")
        defaultValue: true
    }

    SliderSetting {
        settingKey: "minTdp"
        label: I18n.trFor("tdpBaracoder", "Fallback minimum")
        defaultValue: 5
        minimum: 1
        maximum: 60
        unit: "W"
    }

    SliderSetting {
        settingKey: "maxTdp"
        label: I18n.trFor("tdpBaracoder", "Fallback maximum")
        defaultValue: 28
        minimum: 2
        maximum: 120
        unit: "W"
    }

    SliderSetting {
        settingKey: "boostWatts"
        label: I18n.trFor("tdpBaracoder", "Boost headroom")
        description: I18n.trFor("tdpBaracoder", "PowerStation sets the slow PPT to TDP plus this and the fast PPT to 1.25x that. 2 W mirrors hhd's boost.")
        defaultValue: 2
        minimum: 1
        maximum: 20
        unit: "W"
    }

    SliderSetting {
        settingKey: "step"
        label: I18n.trFor("tdpBaracoder", "Slider step")
        defaultValue: 1
        minimum: 1
        maximum: 5
        unit: "W"
    }

    ToggleSetting {
        settingKey: "showPowerProfile"
        label: I18n.trFor("tdpBaracoder", "Show power profile buttons")
        description: I18n.trFor("tdpBaracoder", "power-profiles-daemon profiles, below the TDP controls.")
        defaultValue: true
    }
}
