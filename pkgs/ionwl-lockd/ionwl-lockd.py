"""Run a screen locker when logind asks the session to lock, or before sleep.

swayidle does this elsewhere, but refuses to start on compositors without an
idle-notify protocol, which ionwl handles itself instead. Usage:

    ionwl-lockd [LOCKER ARGS...]    (default: gtklock -d)

The locker must return once the screen is locked (gtklock -d, swaylock -f),
since suspend is held off until then.
"""

import os
import subprocess
import sys

from gi.repository import Gio, GLib

LOGIN1 = 'org.freedesktop.login1'
MANAGER_PATH = '/org/freedesktop/login1'
MANAGER_IFACE = 'org.freedesktop.login1.Manager'
SESSION_IFACE = 'org.freedesktop.login1.Session'

locker = sys.argv[1:] or ['gtklock', '-d']
bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
inhibit_fd = None


def manager_call(method, args, reply_type):
    return bus.call_with_unix_fd_list_sync(
        LOGIN1, MANAGER_PATH, MANAGER_IFACE, method, args,
        GLib.VariantType(reply_type), Gio.DBusCallFlags.NONE, -1, None, None,
    )


def session_path():
    session_id = os.environ.get('XDG_SESSION_ID')
    if session_id:
        reply, _ = manager_call('GetSession', GLib.Variant('(s)', (session_id,)), '(o)')
    else:
        reply, _ = manager_call('GetSessionByPID', GLib.Variant('(u)', (os.getpid(),)), '(o)')
    return reply.unpack()[0]


def inhibit():
    '''Delay sleep until the lock screen is up.'''
    global inhibit_fd
    if inhibit_fd is not None:
        return
    args = GLib.Variant('(ssss)', ('sleep', 'ionwl-lockd', 'Lock the screen before sleep', 'delay'))
    reply, fds = manager_call('Inhibit', args, '(h)')
    inhibit_fd = fds.steal_fds()[reply.unpack()[0]]


def uninhibit():
    global inhibit_fd
    if inhibit_fd is not None:
        os.close(inhibit_fd)
        inhibit_fd = None


def lock(reason):
    print(f'Locking ({reason}): {" ".join(locker)}', flush=True)
    try:
        # Exits non-zero when already locked, which is fine.
        subprocess.run(locker, check=False)
    except OSError as ex:
        print(f'Cannot run locker: {ex}', file=sys.stderr, flush=True)


def on_lock(*_args):
    lock('lock-session')


def on_prepare_for_sleep(_conn, _sender, _path, _iface, _signal, params, *_args):
    (sleeping,) = params.unpack()
    if sleeping:
        lock('before sleep')
        uninhibit()
    else:
        inhibit()


def main():
    path = session_path()
    bus.signal_subscribe(LOGIN1, SESSION_IFACE, 'Lock', path, None,
                         Gio.DBusSignalFlags.NONE, on_lock)
    bus.signal_subscribe(LOGIN1, MANAGER_IFACE, 'PrepareForSleep', MANAGER_PATH, None,
                         Gio.DBusSignalFlags.NONE, on_prepare_for_sleep)
    inhibit()
    print(f'Watching {path}', flush=True)
    GLib.MainLoop().run()


if __name__ == '__main__':
    main()
