"""DDS header inspection and header-preserving save helpers for FA textures

Only needs Pillow and the stdlib. Import it from your own scripts:

    import sys; sys.path.insert(0, r"<repo>/.claude/skills/fa-texture-artist/scripts")
    import dds
    info = dds.parse_header(open("guard-01.dds", "rb").read())
    img = dds.read_rgba("guard-01.dds")
    dds.save_like("guard-01.dds", img, "guard_new-01.dds")

Run directly to dump headers: python dds.py FILE.dds [FILE.dds ...]
"""
import struct
import sys

from PIL import Image

HEADER_SIZE = 128

# DDSD_* header flags
FLAG_NAMES = {
    0x1: "CAPS", 0x2: "HEIGHT", 0x4: "WIDTH", 0x8: "PITCH",
    0x1000: "PIXELFORMAT", 0x20000: "MIPMAPCOUNT", 0x80000: "LINEARSIZE", 0x800000: "DEPTH",
}
# DDPF_* pixel format flags
PF_FLAG_NAMES = {0x1: "ALPHAPIXELS", 0x2: "ALPHA", 0x4: "FOURCC", 0x40: "RGB", 0x20000: "LUMINANCE"}


def _names(value, table):
    return "|".join(n for bit, n in table.items() if value & bit) or "0"


def parse_header(data):
    """Parse the 128-byte DDS header into a dict, raise ValueError if it is not a DDS"""
    if len(data) < HEADER_SIZE or data[:4] != b"DDS ":
        raise ValueError("not a DDS file")
    _, size, flags, height, width, pitch, depth, mips = struct.unpack_from("<4s7I", data, 0)
    pf_size, pf_flags, fourcc, bpp, rmask, gmask, bmask, amask = struct.unpack_from("<2I4s5I", data, 76)
    caps, caps2 = struct.unpack_from("<2I", data, 108)
    fourcc_str = fourcc.decode("latin-1") if pf_flags & 0x4 else ""
    if fourcc_str:
        fmt = fourcc_str  # DXT1, DXT3, DXT5 and so on
    elif bpp == 32 and (rmask, gmask, bmask, amask) == (0xFF0000, 0xFF00, 0xFF, 0xFF000000):
        fmt = "A8R8G8B8"  # bytes on disk are B, G, R, A
    elif bpp == 32 and (rmask, gmask, bmask) == (0xFF0000, 0xFF00, 0xFF):
        fmt = "X8R8G8B8"
    else:
        fmt = f"RGB{bpp} masks {rmask:08X}/{gmask:08X}/{bmask:08X}/{amask:08X}"
    return {
        "width": width, "height": height, "flags": flags, "flag_names": _names(flags, FLAG_NAMES),
        "pitch_or_linear_size": pitch, "mipmaps": mips, "depth": depth,
        "pf_flags": pf_flags, "pf_flag_names": _names(pf_flags, PF_FLAG_NAMES),
        "fourcc": fourcc_str, "bpp": bpp, "masks": (rmask, gmask, bmask, amask),
        "caps": caps, "caps2": caps2, "format": fmt,
        "cube": bool(caps2 & 0x200), "volume": bool(caps2 & 0x200000),
    }


def describe(data, name=""):
    """One-line summary of a DDS header, for logs"""
    h = parse_header(data)
    return (f"{name:32s} {h['width']}x{h['height']} {h['format']:8s} mips={h['mipmaps']} "
            f"flags=0x{h['flags']:08X}({h['flag_names']}) pitch={h['pitch_or_linear_size']} "
            f"pf=0x{h['pf_flags']:X}({h['pf_flag_names']}) caps=0x{h['caps']:X} caps2=0x{h['caps2']:X} bytes={len(data)}")


def read_rgba(path):
    """Open any DDS Pillow understands (A8R8G8B8, DXT1/3/5) as an RGBA image"""
    im = Image.open(path)
    im.load()
    return im.convert("RGBA")


def save_like(template_path, img, out_path):
    """Write img as an uncompressed A8R8G8B8 DDS that reuses template_path's 128-byte header

    Keeps the header flags byte-identical to the original. Only valid when the template is
    uncompressed 32-bit BGRA without mipmaps and the image has the same size
    """
    with open(template_path, "rb") as f:
        header = f.read(HEADER_SIZE)
    h = parse_header(header)
    if h["format"] != "A8R8G8B8" or h["mipmaps"] > 1:
        raise ValueError(f"{template_path}: template is {h['format']} mips={h['mipmaps']}, use save_new")
    img = img.convert("RGBA")
    if img.size != (h["width"], h["height"]):
        raise ValueError(f"size {img.size} does not match template {h['width']}x{h['height']}")
    with open(out_path, "wb") as f:
        f.write(header)
        f.write(img.tobytes("raw", "BGRA"))
    verify_roundtrip(out_path, img)


def save_new(img, out_path):
    """Write img as a fresh uncompressed A8R8G8B8 DDS (Pillow header: flags 0x100F, PITCH)"""
    img = img.convert("RGBA")
    img.save(out_path)
    verify_roundtrip(out_path, img)


def verify_roundtrip(path, img):
    """Re-read path and assert the pixels match img exactly"""
    back = read_rgba(path)
    if back.tobytes() != img.convert("RGBA").tobytes():
        raise AssertionError(f"{path}: written DDS does not read back identically")


if __name__ == "__main__":
    for p in sys.argv[1:]:
        with open(p, "rb") as f:
            print(describe(f.read(), p))
