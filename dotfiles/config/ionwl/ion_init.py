# SPDX-License-Identifier: GPL-3.0-or-later

# IonWL sample configuration.
#
# Copy this file to ~/.config/ionwl/ion_init.py and customize as needed.
#
# This config uses VIM-style navigation.

# Only needed for Python < 3.14.
from __future__ import annotations

__all__ = (
    "main",
)

import subprocess
from typing import Annotated, NamedTuple

import ion
from ion.app import preferences as prefs
from ion.types import MatchKey, MatchPointer
import ion.constants.keys as kbd
import ion.constants.pointer_buttons as btn
import ion.constants.event_actions as act
import ion.ops as ops
import ion_utils.config

# True when this module is being reloaded.
reload = "main" in locals()

# -----------------------------------------------------------------------------
# Settings

TERMINAL = ('ghostty',)
LAUNCHER = ('fuzzel',)
SCRATCHPAD = '*scratch*'  # Workspace used as a scratchpad.
SHELL = 'dux'  # Bar/notification shell: 'dux' (dux-shell) or 'way-shell'.
LOOK = 'Other/i3'  # Window decoration look, as named in the frame menu's "Looks".


# -----------------------------------------------------------------------------
# Custom operators

# Each operator needs its own properties type: registering stores the
# operator on the type.
class DesktopGotoProperties(NamedTuple):
    index: Annotated[int, 'Desktop index, starting at 0.']


class WindowSendToDesktopProperties(NamedTuple):
    index: Annotated[int, 'Desktop index, starting at 0.']


def desktop_get(index: int) -> ion.types.Desktop | None:
    desktops = list(ion.wm.desktops)
    return desktops[index] if index < len(desktops) else None


# Exec callbacks return True/False to consume the key; None would pass it
# through to the focused window.
def desktop_goto_exec(properties: DesktopGotoProperties, event: ion.types.Event) -> bool:
    if (desktop := desktop_get(properties.index)) is None:
        return False
    desktop.focus()
    return True


def window_send_to_desktop_exec(properties: WindowSendToDesktopProperties, event: ion.types.Event) -> bool:
    from ion.wm import context
    if (window := context.window) is None:
        return False
    if (desktop := desktop_get(properties.index)) is None or not desktop.items_tiling:
        return False
    # Lands in the target workspace's last-active frame, focus stays here.
    window.move_to_workspace(desktop.items_tiling[0].workspace)
    return True


def desktop_ops_register() -> None:
    # Registering again on reload replaces the earlier operator.
    ion.ops.register(
        'desktop_goto',
        name=lambda properties: f'Go to Desktop {properties.index + 1}',
        exec=desktop_goto_exec,
        description='Focus the desktop at an index.',
        properties_type=DesktopGotoProperties,
    )
    ion.ops.register(
        'window_send_to_desktop',
        name=lambda properties: f'Send to Desktop {properties.index + 1}',
        exec=window_send_to_desktop_exec,
        description='Move the focused window to the desktop at an index.',
        properties_type=WindowSendToDesktopProperties,
    )


def main() -> None:
    '''Apply preferences and declare keymaps, menus and hooks.'''

    if reload:
        ion_utils.config.reset_defaults(desktops=False)

    # -------------------------------------------------------------------------
    # Preferences

    # Enable numlock on startup.
    prefs.startup.use_numlock = True

    # Enable sloppy focus (focus follows mouse).
    prefs.focus.pointer_follow = True

    # Warp pointer to frame on directional focus.
    prefs.focus.pointer_warp = True
    prefs.focus.pointer_warp_factor = (0.5, 0.5)  # Centered.
    prefs.focus.pointer_warp_margin = 5

    # Key repeat: 40 Hz, 300ms delay.
    prefs.input.keyboard_defaults.repeat_rate = 40
    prefs.input.keyboard_defaults.repeat_delay = 300

    # Python errors show in a popup with their traceback; uncomment to only
    # log them.
    # prefs.system.notify_on_error = False

    # Cursor size.
    prefs.cursor.size = 32

    # Font settings.
    prefs.fonts.titlebar_font.face = 'DejaVu Sans:size=11:weight=bold'

    # Keyboard layout, same as GNOME (modules/gnome in the nix config).
    prefs.input.keyboard_defaults.layout = 'us'
    prefs.input.keyboard_defaults.variant = 'altgr-intl'
    prefs.input.keyboard_defaults.options = 'eurosign:e,compose:menu,lv3:caps_switch'

    # Touchpad: natural scrolling, 2/3 finger click for right/middle button.
    prefs.input.touchpad_defaults.natural_scroll = True
    prefs.input.touchpad_defaults.click_method = 'CLICKFINGER'

    # -------------------------------------------------------------------------
    # Keymaps

    km_global = ion.app.keymaps['global']
    km_tiling = ion.app.keymaps['tiling']
    km_floating = ion.app.keymaps['floating']
    km_window = ion.app.keymaps['window']
    km_fullscreen = ion.app.keymaps['fullscreen']

    # -------------------------------------------------------------------------
    # Startup

    @ion.app.hooks.compositor_startup_post.append
    def on_startup() -> None:
        '''Create 4 desktops with a horizontal split, start background services.'''
        # Desktop 0 already exists, create 3 more.
        # Names must be unique (a clash gets a ".1" suffix), so desktop 0 is
        # named before creating "2".."4" rather than renaming afterwards.
        desktops = [ion.wm.desktops[0]]
        desktops[0].name = '1'
        for i in range(3):
            desktops.append(ion.wm.desktops.new(str(i + 2)))

        # Give each desktop a workspace with a horizontal split.
        for desktop in desktops:
            ws = ion.wm.workspaces.new(ion.types.Rect((0, 0), (800, 600)))
            desktop.items_tiling.add(ws)
            node = ws.frames[0].split_node
            assert node is not None
            node.split(0, 1)

        ion_utils.config.setup_session(dbus=True, systemd=True)

        ion.utils.exec(('kanshi',))
        # dux locks itself (on `loginctl lock-session` and before suspend).
        # Otherwise: same for gtklock; suspend waits until it is up.
        if SHELL != 'dux':
            ion.utils.exec(('ionwl-lockd', 'gtklock', '-d'))
        # An ionwl without the hook (e.g. GDM still on the old one after a
        # switch) starts it now, as before.
        if not prefs.startup.use_xwayland or not hasattr(ion.app.hooks, 'xwayland_ready_post'):
            session_start()

    # What launches apps waits for XWayland: only then is DISPLAY known, and
    # without it X11 apps (Steam) started from the shell or autostart fail.
    def session_start() -> None:
        # Activates graphical-session.target (portals, etc.) and through it
        # XDG autostart. --no-block: what it starts may talk to the
        # compositor, which waits on this hook.
        ion.utils.exec(('systemctl', '--user', 'start', '--no-block', 'ionwl-session.target'))
        # One shell at a time: all are the notification daemon.
        ion.utils.exec(('dms', 'run') if SHELL == 'dux' else ('way-shell',))

    def on_xwayland_ready(display: str) -> None:
        for cmd in (
            ('systemctl', '--user', 'set-environment', f'DISPLAY={display}'),
            ('dbus-update-activation-environment', f'DISPLAY={display}'),
        ):
            subprocess.call(cmd)
        session_start()

    if hasattr(ion.app.hooks, 'xwayland_ready_post'):
        ion.app.hooks.xwayland_ready_post.append(on_xwayland_ready)

    @ion.app.hooks.compositor_shutdown_pre.append
    def on_shutdown() -> None:
        # graphical-session.target too: the user manager outlives the session
        # and units like the portal keep it needed, and while it's up GNOME
        # refuses to start ("A graphical session is already running").
        ion.utils.exec(
            ('systemctl', '--user', 'stop', '--no-block', 'ionwl-session.target', 'graphical-session.target')
        )
        ion.utils.exec(('systemctl', '--user', 'unset-environment', 'DISPLAY'))

    # dux runs the idle timers (fade, lock, screen off) through ext-idle-notify
    # and its own settings; ionwl's would lock first, without the fade.
    if SHELL == 'dux':
        prefs.idle.timeout = 0
        prefs.idle.dpms_timeout = 0

    # After prefs.idle.timeout seconds without input (unless a client, e.g. a
    # video player, inhibits idle); the screens blank at prefs.idle.dpms_timeout.
    @ion.app.hooks.idle_lock.append
    def on_idle_lock(*_args) -> None:
        ion.utils.exec(('loginctl', 'lock-session'))

    # -------------------------------------------------------------------------
    # Context menus and pointer bindings

    ion_utils.config.setup_defaults()

    # GNOME-style Super+drag: left moves, right resizes (defaults are swapped).
    for item in list(km_global.items):
        if item.operator_idname in {'floating_move', 'floating_resize'}:
            km_global.items.remove(item)
    km_global.items.new(MatchPointer(btn.LEFT, logo=True, action=act.DRAG), ops.floating_move())
    km_global.items.new(MatchPointer(btn.RIGHT, logo=True, action=act.DRAG), ops.floating_resize())

    # -------------------------------------------------------------------------
    # Window management

    # Close window, or join frame if no window focused.
    for km in (km_window, km_tiling):
        km.items.new(MatchKey(kbd.Q, logo=True), ops.window_close(delete_empty_frame=True, delete_empty_workspace=True))

    # Toggle fullscreen.
    km_window.items.new(MatchKey(kbd.F, logo=True), ops.window_fullscreen_set())

    # Toggle fullscreen spanning all outputs.
    km_window.items.new(MatchKey(kbd.F, logo=True, shift=True), ops.window_fullscreen_all_set(name='*fullscreen*'))

    # Toggle floating (detach/reattach).
    km_window.items.new(MatchKey(kbd.X, logo=True), ops.window_floating_set())

    # Toggle tag on current window.
    km_window.items.new(MatchKey(kbd.T, logo=True), ops.tag_set())

    # Attach tagged windows to current frame.
    for km in (km_tiling, km_floating):
        km.items.new(MatchKey(kbd.A, logo=True), ops.tag_attach())

    # -------------------------------------------------------------------------
    # Fullscreen overrides (block operations that don't apply in fullscreen)

    # Exit fullscreen.
    km_fullscreen.items.new(MatchKey(kbd.F, logo=True), ops.window_fullscreen_set())

    # Block tiling move (vim-style).
    km_fullscreen.items.new(MatchKey(kbd.H, logo=True, shift=True), ops.system_noop())
    km_fullscreen.items.new(MatchKey(kbd.J, logo=True, shift=True), ops.system_noop())
    km_fullscreen.items.new(MatchKey(kbd.K, logo=True, shift=True), ops.system_noop())
    km_fullscreen.items.new(MatchKey(kbd.L, logo=True, shift=True), ops.system_noop())

    # -------------------------------------------------------------------------
    # Tab cycling within frame

    # Alt+Tab - next tab.
    km_window.items.new(MatchKey(kbd.TAB, logo=True), ops.frame_tab_cycle(direction=1))
    km_window.items.new(MatchKey(kbd.TAB, alt=True), ops.frame_tab_cycle(direction=1))

    # Alt+Shift+Tab - previous tab.
    km_window.items.new(MatchKey(kbd.TAB, logo=True, shift=True, alt=False), ops.frame_tab_cycle(direction=-1))
    km_window.items.new(MatchKey(kbd.TAB, alt=True, shift=True), ops.frame_tab_cycle(direction=-1))

    # -------------------------------------------------------------------------
    # Tiling navigation (vim-style)

    km_global.items.new(MatchKey(kbd.H, logo=True), ops.tiling_focus_directional(direction='LEFT'))
    km_global.items.new(MatchKey(kbd.J, logo=True), ops.tiling_focus_directional(direction='DOWN'))
    km_global.items.new(MatchKey(kbd.K, logo=True), ops.tiling_focus_directional(direction='UP'))
    km_global.items.new(MatchKey(kbd.L, logo=True), ops.tiling_focus_directional(direction='RIGHT'))

    # -------------------------------------------------------------------------
    # Moving windows between frames (vim-style)

    km_tiling.items.new(MatchKey(kbd.H, logo=True, shift=True), ops.window_tiling_move_directional(direction='LEFT'))
    km_tiling.items.new(MatchKey(kbd.J, logo=True, shift=True), ops.window_tiling_move_directional(direction='DOWN'))
    km_tiling.items.new(MatchKey(kbd.K, logo=True, shift=True), ops.window_tiling_move_directional(direction='UP'))
    km_tiling.items.new(MatchKey(kbd.L, logo=True, shift=True), ops.window_tiling_move_directional(direction='RIGHT'))

    # -------------------------------------------------------------------------
    # Splitting frames

    # Split horizontal (new frame to the right) - backslash key.
    km_tiling.items.new(MatchKey(kbd.BACK_SLASH, logo=True), ops.tiling_split(direction='RIGHT'))

    # Split vertical (new frame below).
    km_tiling.items.new(MatchKey(kbd.BACK_SLASH, logo=True, shift=True), ops.tiling_split(direction='DOWN'))

    # Join frame with sibling, moving windows.
    km_tiling.items.new(MatchKey(kbd.X, logo=True, shift=True), ops.frame_join())

    # -------------------------------------------------------------------------
    # Layout manipulation

    # Move focused item to the next output (wraps back to the left).
    km_global.items.new(MatchKey(kbd.Z, logo=True), ops.output_move_directional(direction='RIGHT'))

    # Toggle split axis at current frame.
    km_tiling.items.new(MatchKey(kbd.Z, logo=True, shift=True), ops.tiling_split_axis_set())

    # Toggle split axis at workspace root.
    km_tiling.items.new(MatchKey(kbd.Z, logo=True, ctrl=True), ops.tiling_split_axis_set(parent_depth=-1))

    # -------------------------------------------------------------------------
    # Launchers

    # Terminal.
    km_global.items.new(MatchKey(kbd.RETURN, logo=True), ops.system_exec(command=TERMINAL))

    # App launcher.
    km_global.items.new(MatchKey(kbd.P, logo=True), ops.system_exec(command=LAUNCHER))

    # -------------------------------------------------------------------------
    # Floating workspace (scratch)

    km_global.items.new(MatchKey(kbd.SPACE, logo=True), ops.workspace_floating_set(name=SCRATCHPAD))
    km_window.items.new(MatchKey(kbd.W, logo=True), ops.window_workspace_push(name=SCRATCHPAD))
    km_global.items.new(MatchKey(kbd.W, logo=True, shift=True), ops.window_workspace_pop(name=SCRATCHPAD))

    # -------------------------------------------------------------------------
    # Compositor control

    # Logout (graceful): close all windows, exit when none remain.
    km_global.items.new(MatchKey(kbd.Q, logo=True, shift=True), ops.compositor_logout())

    # Exit (force): quit immediately without closing windows.
    km_global.items.new(MatchKey(kbd.Q, logo=True, shift=True, ctrl=True), ops.compositor_quit())

    # Reload config.
    km_global.items.new(MatchKey(kbd.R, logo=True, shift=True), ops.compositor_reload())

    # -------------------------------------------------------------------------
    # Workspace cycling

    # Cycle to next/previous occupied desktop.
    km_global.items.new(MatchKey(kbd.M, logo=True), ops.desktop_focus_occupied_cycle(direction=1))
    km_global.items.new(MatchKey(kbd.COMMA, logo=True), ops.desktop_focus_occupied_cycle(direction=-1))

    # Super+wheel steps through all desktops, stopping at the ends. The wheel
    # buttons come from pkgs/ionwl/wheel-bindings.patch; older builds lack them.
    if hasattr(btn, 'WHEEL_DOWN'):
        km_global.items.new(
            MatchPointer(btn.WHEEL_DOWN, logo=True), ops.desktop_focus_cycle(direction=1, wrap=False)
        )
        km_global.items.new(
            MatchPointer(btn.WHEEL_UP, logo=True), ops.desktop_focus_cycle(direction=-1, wrap=False)
        )

    # Cycle to next empty desktop.
    km_global.items.new(MatchKey(kbd.RETURN, logo=True, ctrl=True), ops.desktop_focus_empty_cycle(direction=1))

    # Go to desktop N (Logo-1..4), send the focused window there (Logo-Shift-1..4).
    desktop_ops_register()
    for i, key in enumerate((kbd.NUMBER_1, kbd.NUMBER_2, kbd.NUMBER_3, kbd.NUMBER_4)):
        km_global.items.new(MatchKey(key, logo=True), ops.desktop_goto(index=i))  # type: ignore[attr-defined]
        km_window.items.new(MatchKey(key, logo=True, shift=True), ops.window_send_to_desktop(index=i))  # type: ignore[attr-defined]

    # Window carousel.
    km = ion.app.keymaps['window_carousel']
    km.items.new(MatchKey(kbd.RETURN, action=act.CLICK), ops.window_carousel_confirm())
    km.items.new(MatchKey(kbd.ESCAPE, action=act.CLICK), ops.window_carousel_cancel())
    km.items.new(MatchPointer(btn.LEFT, action=act.CLICK), ops.window_carousel_cancel())

    km_global.items.new(MatchKey(kbd.TAB, logo=True, ctrl=True), ops.window_cycle_carousel(keymap=km.name))

    # Desktop item carousel.
    km = ion.app.keymaps['desktop_item_carousel']
    km.items.new(MatchKey(kbd.RETURN, action=act.CLICK), ops.desktop_item_carousel_confirm())
    km.items.new(MatchKey(kbd.ESCAPE, action=act.CLICK), ops.desktop_item_carousel_cancel())
    km.items.new(MatchPointer(btn.LEFT, action=act.CLICK), ops.desktop_item_carousel_cancel())

    km_global.items.new(
        MatchKey(kbd.TAB, logo=True, alt=True),
        ops.desktop_item_cycle_carousel(keymap=km.name),
    )

    # Window switcher, confirmed once Logo is released.
    km = ion.app.keymaps['window_switcher']
    km.items.new(MatchKey(kbd.TAB, logo=None), ops.window_switcher_next())
    km.items.new(MatchKey(kbd.TAB, logo=None, shift=True), ops.window_switcher_prev())
    km.items.new(MatchKey(kbd.ESCAPE, action=act.CLICK), ops.window_switcher_cancel())

    # km_global.items.new(MatchKey(kbd.TAB, logo=True), ops.window_switcher(keymap=km.name, direction=1))
    # km_global.items.new(
    #     MatchKey(kbd.TAB, logo=True, shift=True),
    #     ops.window_switcher(keymap=km.name, direction=-1),
    # )

    # Desktop overview on logo key click.
    km = ion.app.keymaps['desktop_overview']
    km.items.new(MatchKey(kbd.H), ops.desktop_overview_navigate(direction='LEFT'))
    km.items.new(MatchKey(kbd.J), ops.desktop_overview_navigate(direction='DOWN'))
    km.items.new(MatchKey(kbd.K), ops.desktop_overview_navigate(direction='UP'))
    km.items.new(MatchKey(kbd.L), ops.desktop_overview_navigate(direction='RIGHT'))
    km.items.new(MatchKey(kbd.RETURN, action=act.CLICK), ops.desktop_overview_confirm())
    km.items.new(MatchKey(kbd.ESCAPE, action=act.CLICK), ops.desktop_overview_cancel())
    km.items.new(MatchPointer(btn.LEFT, action=act.CLICK), ops.desktop_overview_select())

    for key in (kbd.LOGO_L, kbd.LOGO_R):
        km_global.items.new(
            MatchKey(key, action=act.CLICK),
            ops.desktop_overview(keymap=km.name, trim_empty=True),
        )

    # Window overview.
    km = ion.app.keymaps['window_overview']
    km.items.new(MatchKey(kbd.H), ops.window_overview_navigate(direction='LEFT'))
    km.items.new(MatchKey(kbd.J), ops.window_overview_navigate(direction='DOWN'))
    km.items.new(MatchKey(kbd.K), ops.window_overview_navigate(direction='UP'))
    km.items.new(MatchKey(kbd.L), ops.window_overview_navigate(direction='RIGHT'))
    km.items.new(MatchKey(kbd.RETURN, action=act.CLICK), ops.window_overview_confirm())
    km.items.new(MatchKey(kbd.ESCAPE, action=act.CLICK), ops.window_overview_cancel())
    km.items.new(MatchPointer(btn.LEFT, action=act.CLICK), ops.window_overview_select())

    km_global.items.new(MatchKey(kbd.Y, logo=True), ops.window_overview(keymap=km.name))

    # -------------------------------------------------------------------------
    # Media keys

    # Through the shell, which shows an OSD for them.
    if SHELL == 'dux':
        dms_bindings = (
            (MatchKey(kbd.XF86_AUDIO_RAISE_VOLUME), ('audio', 'increment', '3')),
            (MatchKey(kbd.XF86_AUDIO_LOWER_VOLUME), ('audio', 'decrement', '3')),
            (MatchKey(kbd.XF86_AUDIO_MUTE), ('audio', 'mute')),
            (MatchKey(kbd.XF86_AUDIO_MIC_MUTE), ('audio', 'micmute')),
            # Empty device: the shell's current backlight.
            (MatchKey(kbd.XF86_MON_BRIGHTNESS_UP), ('brightness', 'increment', '5', '')),
            (MatchKey(kbd.XF86_MON_BRIGHTNESS_DOWN), ('brightness', 'decrement', '5', '')),
            # Whichever MPRIS player is active.
            (MatchKey(kbd.XF86_AUDIO_PLAY), ('mpris', 'playPause')),
            (MatchKey(kbd.XF86_AUDIO_PAUSE), ('mpris', 'playPause')),
            (MatchKey(kbd.XF86_AUDIO_STOP), ('mpris', 'stop')),
            (MatchKey(kbd.XF86_AUDIO_PREV), ('mpris', 'previous')),
            (MatchKey(kbd.XF86_AUDIO_NEXT), ('mpris', 'next')),
            # dux's panels (Super+A/X, its defaults, are taken here).
            (MatchKey(kbd.E, logo=True), ('spotlight', 'toggle')),  # app search
            (MatchKey(kbd.V, logo=True), ('clipboard', 'toggle')),
            (MatchKey(kbd.C, logo=True), ('control-center', 'toggle')),
            (MatchKey(kbd.N, logo=True), ('notifications', 'toggle')),
            (MatchKey(kbd.ESCAPE, logo=True, shift=True), ('powermenu', 'toggle')),
        )
        for match, args in dms_bindings:
            km_global.items.new(match, ops.system_exec(command=('dms', 'ipc', 'call', *args)))
    else:
        km_global.items.new(MatchKey(kbd.XF86_AUDIO_RAISE_VOLUME), ops.system_exec(command=('way-sh', 'volume', 'up')))
        km_global.items.new(MatchKey(kbd.XF86_AUDIO_LOWER_VOLUME), ops.system_exec(command=('way-sh', 'volume', 'down')))
        km_global.items.new(MatchKey(kbd.XF86_AUDIO_MUTE), ops.system_exec(command=('way-sh', 'volume', 'mute')))
        km_global.items.new(MatchKey(kbd.XF86_MON_BRIGHTNESS_UP), ops.system_exec(command=('way-sh', 'brightness', 'up')))
        km_global.items.new(MatchKey(kbd.XF86_MON_BRIGHTNESS_DOWN), ops.system_exec(command=('way-sh', 'brightness', 'down')))

        # way-shell switchers (its defaults Super+Tab/W/A clash with the above)
        way_sh_bindings = (
            (kbd.D, 'workspace-switcher'),  # go to a desktop by name, or create it
            (kbd.G, 'workspace-app-switcher'),  # send the window to a desktop by name
            (kbd.R, 'rename-switcher'),  # rename the current desktop
            (kbd.O, 'output-switcher'),  # focus an output
            (kbd.E, 'activities'),  # app search
        )
        for key, widget in way_sh_bindings:
            km_global.items.new(MatchKey(key, logo=True), ops.system_exec(command=('way-sh', widget, 'toggle')))

        km_global.items.new(MatchKey(kbd.XF86_AUDIO_PLAY), ops.system_exec(command=('cmus-remote', '--pause')))
        km_global.items.new(MatchKey(kbd.XF86_AUDIO_PREV), ops.system_exec(command=('cmus-remote', '--prev')))
        km_global.items.new(MatchKey(kbd.XF86_AUDIO_NEXT), ops.system_exec(command=('cmus-remote', '--next')))
        km_global.items.new(MatchKey(kbd.XF86_AUDIO_REWIND), ops.system_exec(command=('cmus-remote', '--seek', '-10')))
        km_global.items.new(MatchKey(kbd.XF86_AUDIO_FORWARD), ops.system_exec(command=('cmus-remote', '--seek', '+10')))

    # Lock screen (Super+L is focus-right here).
    km_global.items.new(MatchKey(kbd.ESCAPE, logo=True), ops.system_exec(command=('loginctl', 'lock-session')))

    # -------------------------------------------------------------------------
    # Looks

    # A reload resets the look, so apply it on every load. Looks are the
    # scripts the "Looks" menu runs, from share/ionwl/resources/looks, named
    # with "/" escaped as "%2F".
    if LOOK:
        import os.path
        import urllib.parse
        looks_dir = os.path.join(os.path.dirname(ion_utils.__file__), '..', '..', 'resources', 'looks')
        look_path = os.path.realpath(os.path.join(looks_dir, urllib.parse.quote(LOOK, safe='') + '.py'))
        ops.python_exec(filepath=look_path).call(ion.types.EventCommand())

    ion.utils.log('Config loaded')


main()
