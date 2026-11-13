"""Pure-Python BC1 (DXT1) / BC3 (DXT5) encoder, decoder and per-block error check

Why not Pillow's writer (im.save(p, pixel_format="DXT1"/"DXT5")): it fits colour endpoints to
every texel without weighting by alpha, so invisible texels steer the result. FA art often
stores RGB 255,255,255 in transparent texels, which makes gold or dark blocks decode grey.
Its BC3 alpha block also spans 0..255, so alpha 1-2 decodes as 51. Pillow's DDS *reader* is fine

This encoder is a small quality-encoder stand-in:
  * colour: alpha-weighted squared error, exhaustive over endpoint pairs from the block's own
    565-quantised colours (plus bbox corners for BC1)
  * BC1: 3-colour + transparent mode for blocks with any alpha < 128
  * BC3 alpha: exhaustive over pairs of the block's alpha values, 8-value and 6-value modes
  * decoder rounding is truncating and bit-identical to Pillow's decoder; GPUs differ by +-1
Cost is O(colours^2) per block: about 0.03 s for 32x32, a few seconds for 256x256. DXT3 is not
implemented (Pillow can read it)

API:
    encode(img, "DXT1"|"DXT5") -> bytes        block data, no header
    decode(data, w, h, fmt) -> RGBA image
    roundtrip(img, fmt) -> RGBA image
    write_dds(path, data, w, h, fmt)           minimal FourCC DDS so other tools can open it
    pick_format(img, tol=8) -> "DXT1"|"DXT5"   DXT1 when alpha is effectively 1-bit
    block_errors(a, b) -> grid[by][bx] = (max premultiplied RGB error, max alpha error)
    heatmap(grid, rgb_thr, a_thr) -> RGBA image, one texel per 4x4 block

CLI:
    python bc.py IMAGE [--format auto|DXT1|DXT5] [--rgb 24] [--alpha 16] [--heatmap out.png] [--decoded out.png]
"""
import argparse
import struct
import sys

from PIL import Image, ImageDraw


def _to565(r, g, b):
    return ((r * 31 + 127) // 255) << 11 | ((g * 63 + 127) // 255) << 5 | ((b * 31 + 127) // 255)


def _from565(c):
    r, g, b = (c >> 11) & 31, (c >> 5) & 63, c & 31
    return (r << 3 | r >> 2, g << 2 | g >> 4, b << 3 | b >> 2)


def _palette(c0, c1, four):
    p0, p1 = _from565(c0), _from565(c1)
    if four:
        return [p0, p1,
                tuple((2 * a + b) // 3 for a, b in zip(p0, p1)),
                tuple((a + 2 * b) // 3 for a, b in zip(p0, p1))]
    return [p0, p1, tuple((a + b) // 2 for a, b in zip(p0, p1)), (0, 0, 0)]


def _alpha_palette(a0, a1):
    if a0 > a1:
        return [a0, a1] + [((7 - i) * a0 + i * a1) // 7 for i in range(1, 7)]
    return [a0, a1] + [((5 - i) * a0 + i * a1) // 5 for i in range(1, 5)] + [0, 255]


def _dist(p, q):
    return (p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2


def _best_indices(texels, weights, pal, skip=None):
    err, idx = 0, []
    for n, (t, w) in enumerate(zip(texels, weights)):
        if skip is not None and skip[n]:
            idx.append(3)
            continue
        k = min(range(len(pal)), key=lambda j: _dist(t, pal[j]))
        err += w * _dist(t, pal[k])
        idx.append(k)
    return err, idx


def _pack_color(c0, c1, idx):
    bits = 0
    for n, k in enumerate(idx):
        bits |= k << (2 * n)
    return struct.pack("<HHI", c0, c1, bits)


def _encode_bc1(texels):
    transparent = [t[3] < 128 for t in texels]
    weights = [0 if tr else t[3] for t, tr in zip(texels, transparent)]
    vis = [t for t, tr in zip(texels, transparent) if not tr]
    if not vis:
        return _pack_color(0, 0xFFFF, [3] * 16)  # c0 <= c1, every texel transparent
    lo = tuple(min(t[i] for t in vis) for i in range(3))
    hi = tuple(max(t[i] for t in vis) for i in range(3))
    cands = sorted({_to565(*t[:3]) for t in vis} | {_to565(*lo), _to565(*hi)})
    need_transparent = any(transparent)
    best = None
    for i, a in enumerate(cands):
        for b in cands[i:]:
            modes = [(min(a, b), max(a, b), False)]  # c0 <= c1: 3 colours + transparent
            if not need_transparent and a != b:
                modes.append((max(a, b), min(a, b), True))  # c0 > c1: 4 colours
            for c0, c1, four in modes:
                pal = _palette(c0, c1, four)
                err, idx = _best_indices(texels, weights, pal if four else pal[:3],
                                         None if four else transparent)
                if best is None or err < best[0]:
                    best = (err, c0, c1, idx)
    return _pack_color(*best[1:])


def _encode_bc3_color(texels):
    # BC3 colour blocks always decode in 4-colour mode; weight by alpha, never use transparency
    weights = [t[3] for t in texels]
    if not any(weights):
        weights = [1] * 16
    cands = sorted({_to565(*t[:3]) for t, w in zip(texels, weights) if w > 0})
    best = None
    for i, a in enumerate(cands):
        for b in cands[i:]:
            c0, c1 = max(a, b), min(a, b)
            err, idx = _best_indices(texels, weights, _palette(c0, c1, True))
            if best is None or err < best[0]:
                best = (err, c0, c1, idx)
    return _pack_color(*best[1:])


def _encode_bc3_alpha(alphas):
    vals = sorted(set(alphas))
    best = None
    for a0 in vals:
        for a1 in vals:
            pal = _alpha_palette(a0, a1)
            err, idx = 0, []
            for a in alphas:
                k = min(range(8), key=lambda j: abs(a - pal[j]))
                err += (a - pal[k]) ** 2
                idx.append(k)
            if best is None or err < best[0]:
                best = (err, a0, a1, idx)
    _, a0, a1, idx = best
    bits = 0
    for n, k in enumerate(idx):
        bits |= k << (3 * n)
    return struct.pack("<BB", a0, a1) + bits.to_bytes(6, "little")


def encode(img, fmt):
    img = img.convert("RGBA")
    w, h = img.size
    if w % 4 or h % 4:
        raise ValueError("width and height must be multiples of 4")
    px = img.load()
    out = bytearray()
    for by in range(0, h, 4):
        for bx in range(0, w, 4):
            texels = [px[bx + x, by + y] for y in range(4) for x in range(4)]
            if fmt == "DXT1":
                out += _encode_bc1(texels)
            elif fmt == "DXT5":
                out += _encode_bc3_alpha([t[3] for t in texels]) + _encode_bc3_color(texels)
            else:
                raise ValueError(fmt)
    return bytes(out)


def decode(data, w, h, fmt):
    img = Image.new("RGBA", (w, h))
    px = img.load()
    off = 0
    for by in range(0, h, 4):
        for bx in range(0, w, 4):
            if fmt == "DXT5":
                apal = _alpha_palette(data[off], data[off + 1])
                abits = int.from_bytes(data[off + 2:off + 8], "little")
                off += 8
            c0, c1, bits = struct.unpack_from("<HHI", data, off)
            off += 8
            four = fmt == "DXT5" or c0 > c1
            pal = _palette(c0, c1, four)
            for n in range(16):
                k = (bits >> (2 * n)) & 3
                if fmt == "DXT5":
                    a = apal[(abits >> (3 * n)) & 7]
                else:
                    a = 0 if (not four and k == 3) else 255
                px[bx + n % 4, by + n // 4] = pal[k] + (a,)
    return img


def roundtrip(img, fmt):
    w, h = img.size
    return decode(encode(img, fmt), w, h, fmt)


def write_dds(path, data, w, h, fmt):
    """Minimal DDS: CAPS|HEIGHT|WIDTH|PIXELFORMAT|LINEARSIZE, FourCC, no mipmaps"""
    hdr = struct.pack("<4sIIIIIII", b"DDS ", 124, 0x81007, h, w, len(data), 0, 0)
    hdr += b"\0" * 44
    hdr += struct.pack("<II4sIIIII", 32, 0x4, fmt.encode(), 0, 0, 0, 0, 0)
    hdr += struct.pack("<IIII", 0x1000, 0, 0, 0) + b"\0" * 4
    with open(path, "wb") as f:
        f.write(hdr + data)


def pick_format(img, tol=8):
    alphas = img.convert("RGBA").getchannel("A").tobytes()
    return "DXT1" if all(a <= tol or a >= 255 - tol for a in alphas) else "DXT5"


def block_errors(a, b):
    """Per 4x4 block: (max |premultiplied RGB| difference, max |alpha| difference)

    Premultiplying (rgb * a / 255) makes the colour of invisible texels irrelevant
    """
    a, b = a.convert("RGBA"), b.convert("RGBA")
    pa, pb = a.load(), b.load()
    w, h = a.size
    grid = []
    for by in range(h // 4):
        row = []
        for bx in range(w // 4):
            ec = ea = 0
            for y in range(by * 4, by * 4 + 4):
                for x in range(bx * 4, bx * 4 + 4):
                    r1, g1, b1, a1 = pa[x, y]
                    r2, g2, b2, a2 = pb[x, y]
                    ea = max(ea, abs(a1 - a2))
                    for c1, c2 in ((r1, r2), (g1, g2), (b1, b2)):
                        ec = max(ec, abs(c1 * a1 - c2 * a2) // 255)
            row.append((ec, ea))
        grid.append(row)
    return grid


def heatmap(grid, rgb_thr=24, a_thr=16):
    """Dark green = 0, yellow = at threshold, red = 2x threshold or worse; one pixel per block"""
    im = Image.new("RGBA", (len(grid[0]), len(grid)))
    d = ImageDraw.Draw(im)
    for by, row in enumerate(grid):
        for bx, (ec, ea) in enumerate(row):
            t = max(ec / rgb_thr, ea / a_thr)
            if t <= 1.0:
                col = (int(255 * t), int(80 + 175 * t), 0, 255)
            else:
                col = (255, int(255 * max(0.0, 2.0 - t)), 0, 255)
            d.point((bx, by), fill=col)
    return im


def main():
    ap = argparse.ArgumentParser(description="DXT round-trip an image and report per-4x4-block error")
    ap.add_argument("image")
    ap.add_argument("--format", default="auto", choices=["auto", "DXT1", "DXT5"])
    ap.add_argument("--rgb", type=int, default=24, help="premultiplied RGB threshold (default 24)")
    ap.add_argument("--alpha", type=int, default=16, help="alpha threshold (default 16)")
    ap.add_argument("--heatmap", help="write the block heatmap, scaled to image size")
    ap.add_argument("--decoded", help="write the decoded image (PNG)")
    args = ap.parse_args()

    src = Image.open(args.image)
    src.load()
    src = src.convert("RGBA")
    fmt = pick_format(src) if args.format == "auto" else args.format
    dec = roundtrip(src, fmt)
    grid = block_errors(src, dec)
    flat = [e for row in grid for e in row]
    over = [(bx, by, e) for by, row in enumerate(grid) for bx, e in enumerate(row)
            if e[0] > args.rgb or e[1] > args.alpha]
    print(f"{args.image}: {fmt}, max rgb {max(e[0] for e in flat)}, max alpha {max(e[1] for e in flat)}, "
          f"{len(over)}/{len(flat)} blocks over (rgb>{args.rgb} or alpha>{args.alpha})")
    for bx, by, (ec, ea) in over:
        print(f"  block ({bx},{by}) px ({bx * 4},{by * 4}): rgb {ec} alpha {ea}")
    if args.heatmap:
        heatmap(grid, args.rgb, args.alpha).resize(src.size, Image.NEAREST).save(args.heatmap)
    if args.decoded:
        dec.save(args.decoded)
    return 0


if __name__ == "__main__":
    sys.exit(main())
