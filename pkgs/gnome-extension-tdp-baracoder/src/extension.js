import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import St from 'gi://St';

import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import { QuickSlider, SystemIndicator } from 'resource:///org/gnome/shell/ui/quickSettings.js';

const BUS_NAME = 'org.shadowblip.PowerStation';
const GPU_PATH = '/org/shadowblip/Performance/GPU';
const GPU_IFACE = 'org.shadowblip.GPU';
const TDP_IFACE = 'org.shadowblip.GPU.Card.TDP';
const PROPS_IFACE = 'org.freedesktop.DBus.Properties';
const INTROSPECT_IFACE = 'org.freedesktop.DBus.Introspectable';

// Slider drags emit a value change per motion event; only the last one is
// worth a round trip to PowerStation.
const APPLY_DEBOUNCE_MS = 250;

function dbusCall(connection, path, iface, method, params, replyType) {
  return new Promise((resolve, reject) => {
    connection.call(
      BUS_NAME, path, iface, method, params,
      replyType === null ? null : new GLib.VariantType(replyType),
      Gio.DBusCallFlags.NONE, -1, null,
      (conn, result) => {
        try {
          resolve(conn.call_finish(result));
        } catch (e) {
          reject(e);
        }
      });
  });
}

async function getProperty(connection, path, iface, name) {
  const reply = await dbusCall(connection, path, PROPS_IFACE, 'Get',
    new GLib.Variant('(ss)', [iface, name]), '(v)');
  return reply.recursiveUnpack()[0];
}

async function setProperty(connection, path, iface, name, value) {
  await dbusCall(connection, path, PROPS_IFACE, 'Set',
    new GLib.Variant('(ssv)', [iface, name, value]), null);
}

/// Returns the object path of the first card exposing a TDP interface, or
/// null when PowerStation found no controllable APU.
async function findTdpCard(connection) {
  const reply = await dbusCall(connection, GPU_PATH, GPU_IFACE,
    'EnumerateCards', null, '(ao)');
  const [paths] = reply.deepUnpack();

  for (const path of paths) {
    // Introspection rather than a property read: the property getters talk to
    // the hardware and a card without TDP support answers with an error.
    const xml = await dbusCall(connection, path, INTROSPECT_IFACE,
      'Introspect', null, '(s)');
    if (xml.deepUnpack()[0].includes(`"${TDP_IFACE}"`))
      return path;
  }

  return null;
}

const TdpSlider = GObject.registerClass(
  class TdpSlider extends QuickSlider {
    _init(settings) {
      super._init({
        iconName: 'power-profile-performance-symbolic',
        menuEnabled: true,
        menuButtonAccessibleName: 'Open TDP menu',
        visible: false,
      });

      this._settings = settings;
      this._connection = null;
      this._cardPath = null;
      this._signalId = 0;
      this._applyId = 0;
      this._syncing = false;
      this._syncingBoost = false;
      this._dragging = false;
      this._boost = null;
      this._min = settings.get_double('min-tdp');
      this._max = settings.get_double('max-tdp');
      this._watts = null;

      this.slider.accessible_name = 'TDP';

      // QuickSlider lays out [icon, slider, menu button]; the readout goes
      // between the slider and the menu button.
      this._valueLabel = new St.Label({
        style_class: 'tdp-value-label',
        y_align: Clutter.ActorAlign.CENTER,
      });
      this.get_child().insert_child_at_index(this._valueLabel, 2);

      this.menu.setHeader('power-profile-performance-symbolic', 'TDP');
      this._boostItem = new PopupMenu.PopupSwitchMenuItem('Boost', false);
      this._boostItem.connect('toggled', (item, state) => {
        if (!this._syncingBoost)
          this._applyBoost(state);
      });
      this.menu.addMenuItem(this._boostItem);

      this.slider.connect('notify::value', () => this._onSliderChanged());
      this.slider.connect('drag-begin', () => (this._dragging = true));
      this.slider.connect('drag-end', () => {
        this._dragging = false;
        this._flush();
      });

      this._settings.connectObject(
        'changed::min-tdp', () => this._refreshRange(),
        'changed::max-tdp', () => this._refreshRange(),
        'changed::use-device-limits', () => this._refreshRange(),
        this);

      this._nameWatchId = Gio.bus_watch_name(
        Gio.BusType.SYSTEM, BUS_NAME, Gio.BusNameWatcherFlags.NONE,
        () => this._onAppeared(),
        () => this._onVanished());
    }

    _onAppeared() {
      this._setup().catch(e => {
        console.error(`TDP: unable to talk to PowerStation: ${e.message}`);
        this._onVanished();
      });
    }

    async _setup() {
      this._connection = Gio.DBus.system;
      this._cardPath = await findTdpCard(this._connection);

      if (!this._cardPath) {
        console.warn('TDP: PowerStation reports no card with TDP control');
        this.visible = false;
        return;
      }

      this._subscribe();
      await this._refreshRange();
      await this._refreshValue();
      await this._refreshBoost();
    }

    _onVanished() {
      this._unsubscribe();
      this._cardPath = null;
      this._connection = null;
      this._watts = null;
      this._boost = null;
      this.visible = false;
    }

    _subscribe() {
      this._unsubscribe();
      this._signalId = this._connection.signal_subscribe(
        BUS_NAME, PROPS_IFACE, 'PropertiesChanged', this._cardPath, TDP_IFACE,
        Gio.DBusSignalFlags.NONE,
        (conn, sender, path, iface, signal, params) => {
          const [, changed] = params.recursiveUnpack();

          if ('Boost' in changed)
            this._setBoost(changed['Boost']);

          // Our own writes echo back as PropertiesChanged; ignore them while
          // the user still owns the slider.
          if ('TDP' in changed && !this._dragging && !this._applyId)
            this._setWatts(changed['TDP']);
        });
    }

    _unsubscribe() {
      if (this._signalId) {
        this._connection?.signal_unsubscribe(this._signalId);
        this._signalId = 0;
      }
    }

    /// PowerStation is the authority on the range: its DMI override database
    /// carries the per-chassis limits, so a cap belongs there rather than
    /// here. The settings are only for platforms where it cannot report a
    /// range at all -- it needs an APU database entry or a usable hwmon.
    async _refreshRange() {
      let min = this._settings.get_double('min-tdp');
      let max = this._settings.get_double('max-tdp');

      if (this._cardPath && this._settings.get_boolean('use-device-limits')) {
        try {
          const [deviceMin, deviceMax] = await Promise.all([
            getProperty(this._connection, this._cardPath, TDP_IFACE, 'MinTdp'),
            getProperty(this._connection, this._cardPath, TDP_IFACE, 'MaxTdp'),
          ]);
          if (deviceMax > deviceMin) {
            min = deviceMin;
            max = deviceMax;
          }
        } catch (e) {
          console.debug(`TDP: no device limits, using settings: ${e.message}`);
        }
      }

      this._min = min;
      this._max = Math.max(max, min + 1);
      this._sync();
    }

    async _refreshValue() {
      try {
        const watts = await getProperty(
          this._connection, this._cardPath, TDP_IFACE, 'TDP');
        this._setWatts(watts);
      } catch (e) {
        console.error(`TDP: could not read current TDP: ${e.message}`);
        this.visible = false;
      }
    }

    async _refreshBoost() {
      try {
        const boost = await getProperty(
          this._connection, this._cardPath, TDP_IFACE, 'Boost');
        this._setBoost(boost);
      } catch (e) {
        console.debug(`TDP: could not read boost: ${e.message}`);
      }
    }

    /// PowerStation's boost is the headroom above the sustained limit, in
    /// watts: the slow PPT becomes TDP + boost and the fast PPT 1.25x that.
    /// hhd offered it as a checkbox, so this does too -- on means the watts
    /// from settings, off means none.
    _setBoost(boost) {
      this._boost = boost;

      this._syncingBoost = true;
      this._boostItem.setToggleState(boost > 0);
      this._syncingBoost = false;
    }

    async _applyBoost(enabled) {
      if (!this._cardPath)
        return;

      const watts = enabled ? this._settings.get_double('boost-watts') : 0;
      try {
        await setProperty(this._connection, this._cardPath, TDP_IFACE, 'Boost',
          new GLib.Variant('d', watts));
        this._boost = watts;
      } catch (e) {
        console.error(`TDP: could not set boost to ${watts} W: ${e.message}`);
        await this._refreshBoost();
      }
    }

    _setWatts(watts) {
      this._watts = watts;
      this.visible = true;
      this._sync();
    }

    /// Pushes `this._watts` into the slider without triggering a write back.
    _sync() {
      if (this._watts === null)
        return;

      this._syncing = true;
      this.slider.value = Math.clamp(
        (this._watts - this._min) / (this._max - this._min), 0, 1);
      this._syncing = false;

      this._updateLabel(this._watts);
    }

    _updateLabel(watts) {
      const decimals = Number.isInteger(this._settings.get_double('step')) ? 0 : 1;
      this._valueLabel.text = `${watts.toFixed(decimals)} W`;
    }

    _sliderWatts() {
      const step = this._settings.get_double('step');
      const raw = this._min + this.slider.value * (this._max - this._min);
      return Math.clamp(Math.round(raw / step) * step, this._min, this._max);
    }

    _onSliderChanged() {
      if (this._syncing || !this._cardPath)
        return;

      const watts = this._sliderWatts();
      this._updateLabel(watts);

      if (this._applyId)
        GLib.source_remove(this._applyId);
      this._applyId = GLib.timeout_add(
        GLib.PRIORITY_DEFAULT, APPLY_DEBOUNCE_MS, () => {
          this._applyId = 0;
          this._apply(this._sliderWatts());
          return GLib.SOURCE_REMOVE;
        });
    }

    /// Applies a pending change right away instead of waiting out the debounce.
    _flush() {
      if (!this._applyId)
        return;
      GLib.source_remove(this._applyId);
      this._applyId = 0;
      this._apply(this._sliderWatts());
    }

    async _apply(watts) {
      if (!this._cardPath)
        return;

      try {
        await setProperty(this._connection, this._cardPath, TDP_IFACE, 'TDP',
          new GLib.Variant('d', watts));
        this._watts = watts;
      } catch (e) {
        console.error(`TDP: could not set TDP to ${watts} W: ${e.message}`);
        // Snap back to whatever the hardware actually ended up at.
        await this._refreshValue();
      }
    }

    destroy() {
      if (this._applyId) {
        GLib.source_remove(this._applyId);
        this._applyId = 0;
      }
      if (this._nameWatchId) {
        Gio.bus_unwatch_name(this._nameWatchId);
        this._nameWatchId = 0;
      }
      this._unsubscribe();
      this._settings?.disconnectObject(this);
      this._settings = null;
      super.destroy();
    }
  });

const TdpIndicator = GObject.registerClass(
  class TdpIndicator extends SystemIndicator {
    _init(settings) {
      super._init();
      this.quickSettingsItems.push(new TdpSlider(settings));
    }
  });

export default class TdpExtension extends Extension {
  enable() {
    this._indicator = new TdpIndicator(this.getSettings());
    Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator, 2);

    // Quick settings builds its own indicators asynchronously, so the
    // brightness slider we want to sit under may not exist yet.
    if (!this._placeBelowBrightness()) {
      this._placeId = GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
        this._placeId = 0;
        this._placeBelowBrightness();
        return GLib.SOURCE_REMOVE;
      });
    }
  }

  _placeBelowBrightness() {
    const quickSettings = Main.panel.statusArea.quickSettings;
    const brightness = quickSettings._brightness?.quickSettingsItems?.[0];
    const item = this._indicator?.quickSettingsItems[0];
    if (!brightness || !item)
      return false;

    const grid = item.get_parent();
    if (!grid || brightness.get_parent() !== grid)
      return false;

    grid.set_child_above_sibling(item, brightness);
    return true;
  }

  disable() {
    if (this._placeId) {
      GLib.source_remove(this._placeId);
      this._placeId = 0;
    }
    this._indicator?.quickSettingsItems.forEach(item => item.destroy());
    this._indicator?.destroy();
    this._indicator = null;
  }
}
