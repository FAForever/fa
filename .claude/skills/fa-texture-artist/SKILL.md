---
name: fa-texture-artist
description: Create or modify Forged Alliance textures (cursors, unit and strategic icons, UI art) and inspect DDS files. Use when the user asks to make a new texture or a variant of an existing one, extract or read base-game textures from .scd/.nx2 archives, check a DDS format (A8R8G8B8 vs DXT1/DXT3/DXT5, flags, mipmaps), judge DXT block-compression artifacts, add an animated cursor to skins.lua, or preview texture frames for review. Headless Python + Pillow workflow with reusable scripts.
---

# FA texture work

Use this to find, extract, inspect, edit, verify and ship FA textures from the command line.

**Scripts live in `scripts/`. Run them with `python <script> -h` for usage:**
- [extract.py](/.claude/skills/fa-texture-artist/scripts/extract.py): list, extract or survey files in `.scd`/`.nx2` archives (read-only), and dump DDS headers.
- [dds.py](/.claude/skills/fa-texture-artist/scripts/dds.py): `parse_header`, `describe`, `read_rgba`, `save_like` (reuse the original 128-byte header), `save_new`, `verify_roundtrip`.
- [bc.py](/.claude/skills/fa-texture-artist/scripts/bc.py): alpha-aware DXT1/DXT5 encoder and decoder, plus a per-4x4-block error check and heatmap.
- [preview.py](/.claude/skills/fa-texture-artist/scripts/preview.py): nearest-neighbour contact sheets and side-by-side animated GIFs.

Work in a scratch directory. **Never write inside the game install.** Copy finished files into the repo at the end.

## 1. Find the texture's path

| Kind | Where the path comes from |
|---|---|
| Cursors | `lua/skins/skins.lua`, `cursors` table (~line 183): `{texture, hotspotX, hotspotY, [frames], [fps]}` |
| UI art | `UIUtil.UIFile('/game/...')` resolves against the skin's `texturesPath` (`/textures/ui/<faction>`), falling back along `default` to `/textures/ui/common` (`lua/ui/uiutil.lua:423`) |
| Unit icons | `/textures/ui/common/icons/units/<bpid>_icon.dds` |
| Strategic icons | `/textures/ui/common/game/strategicicons/<StrategicIconName>_rest.dds` (the archive also has `_over`, `_selected`, `_selectedover`), see `lua/ui/game/construction.lua:581` |
| Unit meshes | next to the blueprint: `units/<ID>/<ID>_Albedo.dds`, `_NormalsTS.dds`, `_SpecTeam.dds`, `_lod1_*` |

Otherwise, grep the Lua for the file name or folder (`textures/ui/...`).

## 2. Is it in the repo or a base archive?

1. Repo: `git ls-tree --name-only origin/develop <dir>/`. The repo holds only FAF additions and overrides (around 3800 files under `textures/`).
2. Base game: `init_faf.lua` mounts `<fa_path>/gamedata/*.scd` whitelisted in `allowedAssetsScd` (`textures.scd` at line 186, mount at line 653). The install path is in `C:\ProgramData\FAForever\fa_path.lua` (`fa_path = ".../supreme commander forged alliance"`).
3. FAF packaged copies: `init_faf.lua:652` mounts `<FAF data>/gamedata/*.nx2` from `allowedAssetsNxy` (e.g. `C:\ProgramData\FAForever\gamedata\textures.nx2`). These are the deployed versions of the repo's folders: `textures.nx2` contains the repo's `attack_move-*`, `overcharge_*` and so on. Prefer the repo copy when editing.

`.scd` and `.nx2` files are plain zip archives with forward-slash paths. Stock cursors such as `guard-01.dds` exist only in `textures.scd`.

## 3. Extract (read-only)

```bash
S=scripts; FA="C:/Program Files (x86)/Steam/steamapps/common/supreme commander forged alliance/gamedata"
python $S/extract.py "$FA/textures.scd" "textures/ui/common/game/cursors/guard*" -o orig   # extract + header lines
python $S/extract.py "$FA/textures.scd" "textures/ui/common/game/cursors/*" --list
python $S/extract.py "$FA/units.scd" "units/uel0001/*.dds" --headers                      # inspect only
python $S/extract.py "$FA/textures.scd" "textures/ui/common/icons/units/*.dds" --survey   # count formats
git -C <repo> show origin/develop:textures/ui/common/game/cursors/attack_move-01.dds > orig/attack_move-01.dds
```
Globs are case-insensitive fnmatch on the full archive path. `zipfile.ZipFile(path)` defaults to read mode, which is all these scripts use.

## 4. Formats FA uses (measured on base `.scd`)

| Asset | Format |
|---|---|
| Cursors (`textures.scd`, all 205) | 32x32 **A8R8G8B8**, no mipmaps, 4224 bytes |
| Unit icons | mostly 64x64 DXT5, with or without mipmaps (534 DXT5, 4 A8R8G8B8) |
| Strategic icons | DXT5 (all 1102) |
| Unit albedo / normalsTS / specteam | mostly DXT1 or DXT5 / DXT5 / DXT3, with full mip chains |

Header fields to check (`python scripts/dds.py FILE`): `flags`, the pixel-format FourCC (`DXT1`/`DXT3`/`DXT5`) or the 32-bit masks (`00FF0000 0000FF00 000000FF FF000000` = A8R8G8B8, bytes on disk B,G,R,A), `mipMapCount`, and the size.

Stock cursor headers use `flags=0x00081007` (LINEARSIZE, value 4096). FAF's `overcharge_*` cursors use Pillow's `0x0000100F` (PITCH, value 128). Both load.

**Engine evidence: textures load in the file's format, and cursors are never block-compressed** (decompilation at `faf-re/src/sdk`):
- `moho/ui/UiRuntimeTypes.cpp:4210` `CMauiCursor::SetTexture` loads through `GetResources()->GetTexture(handle, path, 0, false)`, the normal texture path with no watcher and no fallback.
- `moho/render/d3d/RD3DTextureResource.cpp:115` sets `mContext.format_ = 0`. Then `gpg/gal/backends/d3d9/D3D9Interfaces.cpp:2676` calls `D3DXCreateTextureFromFileInMemoryEx(..., FormatGalToD3D(0), ...)`. Format 0 has no entry in the table (lines 686-747, 832-843), so it becomes `D3DFMT_UNKNOWN`, which keeps the file's format.
- D3D9 cursor: `D3D9Interfaces.cpp:3395` `SetCursorProperties` with the level-0 surface. D3D9 requires A8R8G8B8 for this call.
- D3D10 cursor: `gpg/gal/backends/d3d10/D3D10Interfaces.cpp:515` `BuildCursorIcon` copies exactly 32x32 32-bit texels into a Win32 icon. **Cursors must be 32x32.**

So cursor art reaches the screen texel for texel. Block artifacts in a cursor come from the source file, never from the game. Save cursors uncompressed. Other assets are DXT because their files are DXT.

Not traced: how the texture-quality setting's skip-mip-levels (`RD3DTextureResource.cpp:129`) treats a file with no mipmaps. Stock cursors have none, so matching their format is safe.

## 5. Edit while keeping the header

```python
import sys; sys.path.insert(0, ".claude/skills/fa-texture-artist/scripts")
import dds
img = dds.read_rgba("orig/guard-01.dds")          # Pillow reads A8R8G8B8 and DXT1/3/5
# ... edit img (PIL.ImageDraw, putpixel, paste) ...
dds.save_like("orig/guard-01.dds", img, "out/guard_new-01.dds")  # same header bytes, BGRA pixels, verified
dds.save_new(img, "out/new.dds")                  # fresh header for a new texture
```
`save_like` refuses DXT or mipmapped templates. To ship a DXT texture, encode with a real tool or with `bc.encode` plus `bc.write_dds` (no mipmaps). Composite edits in RGBA, keep the hotspot texel, and keep frame sizes identical.

Art conventions seen in stock cursors: near-black outlines (about `12,8,0`), white RGB stored in fully transparent texels, and a faint halo with alpha 1-30. Modifier badges go top-right (`guard-invalid.dds`).

## 6. DXT survival check (when it matters)

Only needed when the asset ships as DXT (icons, unit textures) or might be compressed later. Cursors don't need it (section 4).

**Don't judge with Pillow's encoder** (`im.save(p, pixel_format="DXT5")`). It fits colour endpoints to every texel without alpha weighting, so the invisible white texels drag gold blocks to grey (error 170 on untouched stock cursors). Its BC3 alpha block spans 0..255, so alpha 1-2 decodes as 51. Solid-colour tests look fine and hide this. Pillow's DDS *reader* is correct.

Use `bc.py` instead: alpha-weighted, with an exhaustive endpoint search. Its decoder is bit-identical to Pillow's, cross-checked both ways.
```bash
python scripts/bc.py out/guard_new-01.dds --heatmap heat.png --decoded dec.png   # auto DXT1/DXT5, --rgb 24 --alpha 16
```
- Error per 4x4 block = max |premultiplied RGB| difference (invisible colour ignored) and max |alpha| difference. Default threshold: RGB 24, alpha 16.
- Format: auto picks DXT1 when every alpha is <= 8 or >= 247, else DXT5.
- Compare against the untouched original: stock art often fails on its own (the stock guard animation has 37-42 of 64 blocks over threshold, because white, gold and black share blocks). Judge only the blocks you touched.
- To make edits compression-friendly, align new shapes and colour changes to the 4x4 grid and keep each block to about 2 colours plus alpha.

## 7. Preview for review

```bash
python scripts/preview.py sheet sheet.png --row original "orig/guard-??.dds" --row new "out/guard_new-??.dds" --scale 8
python scripts/preview.py gif anim.gif "orig/guard-??.dds" "out/guard_new-??.dds" --fps 12 --scale 4
```
Previews use nearest-neighbour scaling on a green terrain-like background. GIF stores durations in 10 ms steps, so 12 fps becomes 80 ms. Look at the images (Read tool) before reporting.

## 8. Animated cursors and skins.lua

```lua
-- cursor format is: texture name, hotspotx, hotspoty, [optional] num frames, [optional] fps
RULEUCC_Guard = {'/textures/ui/common/game/cursors/guard-.dds', 15, 15, 10, 12},
```
- Frames are `<prefix>NN.dds` with two digits starting at 01 (`guard-01.dds` .. `guard-10.dds`). Lua expands them, not the engine: `lua/maui/cursor.lua:39` `SetTexture` cuts at `.dds` and cycles `("%s%02d.dds"):format(...)` in a thread at `1/fps`. Animated cursors must therefore be `.dds`.
- The hotspot is in texels from the top-left (15,15 is the centre of 32x32).
- For a new id, add the entry and a `---| "NAME"` line to `---@alias CursorType` (`skins.lua:15`). Select it with `UIUtil.GetCursor(id)` (`uiutil.lua:518`) in a `WorldView:OnCursor*` handler (e.g. `OnCursorGuard`, `worldview.lua:535`), or via `cursor = 'NAME'` (lowercase, read by `WorldView:OnUpdateCursor`) in command-mode data. A missing id logs `Requested cursor not found` and then errors.

## 9. Commit

Put files under the repo's `textures/...` mirror path (e.g. `textures/ui/common/game/cursors/`). Textures are committed as **plain git binaries, without LFS**: `.gitattributes` uses LFS only for `promotion/*`. `* text=auto` detects `.dds` as binary, so check `git diff --cached --stat` shows `Bin`. Don't commit scratch previews or generator scripts unless asked.

## 10. Verify in game

1. Use the dev init `setup/bin/init_local_development.lua`, which mounts the repo root at `/` (line 612): `ForgedAlliance.exe /init "init_local_development.lua" /EnableDiskWatch /showlog /log "local-development.log" /nomovie` (see `docs/development-start-here/lua-setup.md`).
2. `/EnableDiskWatch` hot-reloads Lua, but **textures are not hot-reloaded**: cursors load with no watcher and loaded textures are cached. Restart the game (or use a new filename) after changing a `.dds`.
3. Missing cursor files fail quietly (`allowFallback=false`, so no `Can't find texture` log). Double-check paths and frame numbering.
4. Check the animation speed, the hotspot position, and readability on dark and bright terrain.

## Tools

- **Recommended (headless):** Python 3 + Pillow + stdlib `zipfile`, plus the scripts here. That's enough to read and write A8R8G8B8, read DXT1/3/5, write DXT1/5 (via `bc.py`), and make previews. Check with `python -c "import PIL; print(PIL.__version__)"` (tested with Pillow 12.3). If something seems to need numpy or another package, ask before installing.
- **GIMP 3:** only for hand-painting. Export as DDS, then re-check the header with `dds.py`.
- **Not needed:** the old DirectX SDK DxTex or texconv.

## Worked example: instant-assist cursor (FAForever/fa#7329)

A variant of the guard cursor with a cyan lightning badge.
1. Extract `guard-01..10.dds` and `guard-invalid.dds` from `textures.scd`, and dump the headers (all identical, A8R8G8B8 32x32).
2. Design: a 12x12 badge aligned to the 4x4 grid in the top-right (x 20-31, y 0-11). Clear that region, draw a bolt mask with an outline from 8-neighbour dilation, and cap the cut ring ends with outline colour. Ring, plus, hotspot and animation stay untouched. The bolt flashes pale in frames 9-10, when the ring corners flash white.
3. Save each frame with `save_like` from the matching stock frame, using the name `guard_instant-NN.dds`.
4. `bc.py` check: badge blocks max error 4. Every touched block is at or below the stock error for that block.
5. Contact sheet (original / new / DXT / heatmap) and a 4x GIF for review, then copy the files into the repo and add the skins.lua entry.
