"""List, extract and inspect files inside FA archives (.scd, .nx2, .zip) without modifying them

The archives are plain zip files with forward-slash paths. Matching is a case-insensitive
fnmatch glob on the full path inside the archive

Examples:
    python extract.py "<fa_path>/gamedata/textures.scd" "textures/ui/common/game/cursors/guard*" -o orig
    python extract.py "<fa_path>/gamedata/textures.scd" "textures/ui/common/game/cursors/*" --list
    python extract.py "<fa_path>/gamedata/units.scd" "units/uel0001/*.dds" --headers
    python extract.py "<fa_path>/gamedata/textures.scd" "textures/ui/common/icons/units/*.dds" --survey
"""
import argparse
import fnmatch
import os
import sys
import zipfile
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import dds  # noqa: E402


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("archive", help="path to a .scd / .nx2 / .zip archive (opened read-only)")
    ap.add_argument("pattern", help="glob on the path inside the archive, case-insensitive")
    ap.add_argument("-o", "--out", default=".", help="output directory for extracted files (default: .)")
    ap.add_argument("--keep-paths", action="store_true", help="keep the archive's folder structure under --out")
    ap.add_argument("--list", action="store_true", help="only list matching names and sizes")
    ap.add_argument("--headers", action="store_true", help="only print DDS header summaries, do not extract")
    ap.add_argument("--survey", action="store_true", help="only count DDS formats among the matches")
    args = ap.parse_args()

    pattern = args.pattern.lower()
    with zipfile.ZipFile(args.archive) as z:
        infos = [i for i in z.infolist() if not i.is_dir() and fnmatch.fnmatch(i.filename.lower(), pattern)]
        if not infos:
            print("no matches", file=sys.stderr)
            return 1
        if args.list:
            for i in infos:
                print(f"{i.file_size:10d}  {i.filename}")
            return 0
        if args.survey:
            counts = Counter()
            for i in infos:
                if i.filename.lower().endswith(".dds"):
                    h = dds.parse_header(z.read(i)[:dds.HEADER_SIZE])
                    counts[(h["format"], h["width"], h["height"], h["mipmaps"])] += 1
            for (fmt, w, h, m), n in counts.most_common():
                print(f"{n:6d}  {fmt:8s} {w}x{h} mips={m}")
            return 0
        if not args.headers:
            os.makedirs(args.out, exist_ok=True)
        for i in infos:
            data = z.read(i)
            if data[:4] == b"DDS ":
                print(dds.describe(data, os.path.basename(i.filename)))
            elif args.headers:
                continue
            if not args.headers:
                rel = i.filename if args.keep_paths else os.path.basename(i.filename)
                dst = os.path.join(args.out, rel)
                os.makedirs(os.path.dirname(dst) or ".", exist_ok=True)
                with open(dst, "wb") as f:
                    f.write(data)
    return 0


if __name__ == "__main__":
    sys.exit(main())
