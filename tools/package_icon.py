"""Wrap the Aseprite-exported 256px PNG in a Windows ICO without changing its pixels."""
from pathlib import Path
import struct

folder = Path(__file__).resolve().parents[1] / "assets/exported/branding"
png = (folder / "d_infinity_icon.png").read_bytes()
assert png[:8] == b"\x89PNG\r\n\x1a\n"
assert struct.unpack(">II", png[16:24]) == (256, 256)
header = struct.pack("<HHH", 0, 1, 1)
entry = struct.pack("<BBBBHHII", 0, 0, 0, 0, 1, 32, len(png), 22)
(folder / "d_infinity_icon.ico").write_bytes(header + entry + png)
