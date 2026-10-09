"""Review previews: nearest-neighbour contact sheet and animated GIF

Images are composited on an opaque background because GIF has 1-bit alpha and
dark/transparent art is unreadable on a checkerboard at small sizes

Examples:
    python preview.py sheet sheet.png --row original "orig/guard-??.dds" --row new "guard_new-??.dds" --scale 8
    python preview.py gif anim.gif "guard_new-??.dds" --fps 12 --scale 4
    python preview.py gif compare.gif "orig/guard-??.dds" "guard_new-??.dds" --fps 12
"""
import argparse
import glob
import sys

from PIL import Image, ImageDraw

BG = (70, 95, 70, 255)  # terrain-ish green, close to what cursors and icons sit on


def load(path):
    im = Image.open(path)
    im.load()
    return im.convert("RGBA")


def on_bg(im, bg=BG):
    base = Image.new("RGBA", im.size, bg)
    base.alpha_composite(im)
    return base


def contact_sheet(rows, scale=8, gap=8, label_w=150, bg=BG):
    """rows: list of (label, [RGBA images]); all images the same size"""
    w, h = rows[0][1][0].size
    cw, ch = w * scale, h * scale
    cols = max(len(ims) for _, ims in rows)
    sheet = Image.new("RGBA", (label_w + cols * (cw + gap), len(rows) * (ch + gap)), (30, 30, 30, 255))
    d = ImageDraw.Draw(sheet)
    for r, (label, ims) in enumerate(rows):
        y = r * (ch + gap)
        d.text((4, y + ch // 2), label, fill=(220, 220, 220, 255))
        for i, im in enumerate(ims):
            sheet.paste(on_bg(im, bg).resize((cw, ch), Image.NEAREST), (label_w + i * (cw + gap), y))
    return sheet.convert("RGB")


def animated_gif(path, sequences, fps=12, scale=4, gap=16, bg=BG):
    """sequences: list of frame lists shown side by side; GIF timing has 10 ms resolution"""
    w, h = sequences[0][0].size
    n = max(len(s) for s in sequences)
    frames = []
    for i in range(n):
        f = Image.new("RGBA", (len(sequences) * (w * scale + gap) - gap, h * scale), bg)
        for k, seq in enumerate(sequences):
            f.alpha_composite(on_bg(seq[i % len(seq)], bg).resize((w * scale, h * scale), Image.NEAREST),
                              (k * (w * scale + gap), 0))
        frames.append(f.convert("RGB"))
    frames[0].save(path, save_all=True, append_images=frames[1:], duration=round(1000 / fps), loop=0)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("sheet")
    s.add_argument("out")
    s.add_argument("--row", nargs=2, action="append", metavar=("LABEL", "GLOB"), required=True)
    s.add_argument("--scale", type=int, default=8)
    g = sub.add_parser("gif")
    g.add_argument("out")
    g.add_argument("globs", nargs="+", help="one glob per side-by-side sequence")
    g.add_argument("--fps", type=float, default=12)
    g.add_argument("--scale", type=int, default=4)
    args = ap.parse_args()

    if args.cmd == "sheet":
        rows = [(label, [load(p) for p in sorted(glob.glob(pat))]) for label, pat in args.row]
        contact_sheet(rows, args.scale).save(args.out)
    else:
        seqs = [[load(p) for p in sorted(glob.glob(pat))] for pat in args.globs]
        animated_gif(args.out, seqs, args.fps, args.scale)
    return 0


if __name__ == "__main__":
    sys.exit(main())
