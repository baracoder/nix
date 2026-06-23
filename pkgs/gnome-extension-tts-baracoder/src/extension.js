import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Gio from 'gi://Gio';
import St from 'gi://St';

import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';

const TtsButton = GObject.registerClass(
  class TtsButton extends PanelMenu.Button {
    _init(iconPath) {
      super._init(0.0, 'TTS', true);

      this._proc = null;

      // Ships with the extension; the `-symbolic.svg` suffix lets St treat
      // it as a symbolic icon and recolor it via the .tts-running CSS class.
      this._icon = new St.Icon({
        gicon: Gio.icon_new_for_string(iconPath),
        style_class: 'system-status-icon',
      });
      this.add_child(this._icon);

      // PanelMenu.Button reacts to button-press; toggle the script there.
      this.connect('button-press-event', () => {
        this._toggle();
        return Clutter.EVENT_STOP;
      });
      this.connect('touch-event', () => {
        this._toggle();
        return Clutter.EVENT_STOP;
      });
    }

    get _running() {
      return this._proc !== null;
    }

    _toggle() {
      if (this._running)
        this._stop();
      else
        this._start();
    }

    _start() {
      let proc;
      try {
        proc = Gio.Subprocess.new(
          ['voluble'],
          Gio.SubprocessFlags.NONE
        );
      } catch (e) {
        Main.notifyError('TTS', `Could not start voluble: ${e.message}`);
        return;
      }

      this._proc = proc;
      this._setRunning(true);

      // Reset the icon when the script exits on its own.
      proc.wait_async(null, (source, result) => {
        try {
          source.wait_finish(result);
        } catch (e) {
          // Ignore — typically a cancelled/forced exit.
        }

        // Only clear state if this is still the current process; a newer
        // start could have replaced it.
        if (this._proc === proc) {
          this._proc = null;
          this._setRunning(false);
        }
      });
    }

    _stop() {
      if (!this._proc)
        return;

      const pid = this._proc.get_identifier();
      if (pid) {
        console.log("got pid ${pid}");
        Gio.Subprocess.new(['pkill', '-P', `${pid}`], Gio.SubprocessFlags.NONE);
      } else {
        console.warn("no pid");
      }

    }


    _setRunning(running) {
      if (running)
        this._icon.add_style_class_name('tts-running');
      else
        this._icon.remove_style_class_name('tts-running');
    }

    destroy() {
      // Make sure we don't leave the script running when the extension
      // is disabled or the shell reloads.
      if (this._proc) {
        this._proc._stop();
        this._proc = null;
      }
      super.destroy();
    }
  });

export default class TtsExtension extends Extension {
  enable() {
    const iconPath = GLib.build_filenamev([
      this.path, 'assistive-listening-symbolic.svg',
    ]);
    this._button = new TtsButton(iconPath);
    Main.panel.addToStatusArea(this.uuid, this._button);
  }

  disable() {
    this._button?.destroy();
    this._button = null;
  }
}
