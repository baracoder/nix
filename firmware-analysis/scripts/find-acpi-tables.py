#!/usr/bin/env python3
"""Carve ACPI tables (DSDT/SSDT/...) out of a UEFIExtract dump tree.

AMI/AMD firmware embeds AML in many DXE drivers' raw/freeform sections rather
than one file, so instead of relying on GUIDs we scan every extracted body for
a plausible ACPI header with a matching length and checksum.

Usage: find-acpi-tables.py <bios.rom.dump> <out-dir>
Run with `python3 -I` since the input tree is untrusted vendor data.
"""

import hashlib
import os
import re
import struct
import sys

SIGNATURES = [
    b"DSDT", b"SSDT", b"FACP", b"APIC", b"HPET", b"MCFG", b"FPDT", b"BGRT",
    b"IVRS", b"CRAT", b"CDIT", b"VFCT", b"TPM2", b"WSMT", b"FIDT", b"BERT",
    b"HEST", b"EINJ", b"ERST", b"SLIC", b"MSDM", b"DBGP", b"DBG2", b"PHAT",
    b"SDEV", b"WDAT", b"WDRT", b"LPIT", b"PPTT", b"SRAT", b"SLIT", b"UEFI",
    b"PCCT", b"ABLT",
]
HEADER = struct.Struct("<4sIBB6s8sI4sI")  # 36 bytes


def oem_table_id(raw):
    return raw.rstrip(b"\x00 ").decode("ascii", "replace")


def scan(data):
    pattern = re.compile(b"|".join(re.escape(s) for s in SIGNATURES))
    for m in pattern.finditer(data):
        off = m.start()
        if off + HEADER.size > len(data):
            continue
        sig, length, rev, _csum, oem, table_id, oem_rev, _cid, _crev = HEADER.unpack_from(data, off)
        if length < HEADER.size or off + length > len(data):
            continue
        table = data[off : off + length]
        if sum(table) & 0xFF:
            continue
        yield off, sig.decode(), rev, oem_table_id(oem), oem_table_id(table_id), oem_rev, table


def module_name(path, root):
    """Nearest ancestor directory UEFIExtract named after a file's UI section."""
    rel = os.path.relpath(path, root).split(os.sep)
    for part in reversed(rel[:-1]):
        # UEFIExtract dirs look like "12 AmdAcpiDxe", "3 <file GUID>" (no UI
        # section) or "0 Raw section"
        name = part.split(" ", 1)[-1]
        if not re.match(r"(.* section$|Padding|Volume|AMI ROM hole)", name):
            return name
    return rel[0]


def main(root, out):
    os.makedirs(out, exist_ok=True)
    seen = {}
    rows = []
    # Bottom-up so a table is attributed to the innermost module containing it,
    # not to the compressed volume that also holds a copy.
    for dirpath, _dirs, files in os.walk(root, topdown=False):
        for fn in sorted(files):
            if not fn.endswith(".bin") or fn == "header.bin":
                continue
            path = os.path.join(dirpath, fn)
            with open(path, "rb") as f:
                data = f.read()
            for off, sig, rev, oem, tid, orev, table in scan(data):
                digest = hashlib.sha256(table).hexdigest()
                if digest in seen:
                    continue
                mod = module_name(path, root)
                safe = re.sub(r"[^A-Za-z0-9_.-]", "_", f"{sig}-{tid}-{mod}")
                name = safe
                n = 1
                while name in seen.values():
                    n += 1
                    name = f"{safe}-{n}"
                seen[digest] = name
                with open(os.path.join(out, name + ".aml"), "wb") as f:
                    f.write(table)
                rows.append((sig, tid, oem, rev, orev, len(table), mod,
                             os.path.relpath(path, root), off))

    rows.sort()
    with open(os.path.join(out, "index.tsv"), "w") as f:
        f.write("sig\ttable_id\toem\trev\toem_rev\tlength\tmodule\tsource\toffset\n")
        for r in rows:
            f.write("\t".join(str(x) for x in r[:-1]) + f"\t{r[-1]:#x}\n")
    for r in rows:
        print(f"{r[0]}  {r[1]:<10} rev={r[3]} oemrev={r[4]:#010x} len={r[5]:<7} {r[6]}")
    print(f"{len(rows)} unique tables -> {out}", file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    main(sys.argv[1], sys.argv[2])
