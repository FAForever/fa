import os
from gi.repository import Gimp, Gio

def export_scaled_dds():
    scales = [0.8, 1.25, 1.5, 1.75, 2.0]
    pdb = Gimp.get_pdb()
    export_proc = None
    for proc_name in ['file-dds-save', 'file-dds-export', 'gimp-dds-export', 'gimp-file-save']:
        proc = pdb.lookup_procedure(proc_name)
        if proc:
            export_proc = proc
            print(f"Using procedure: {proc_name}")
            break
    if not export_proc:
        print("ERROR: Could not locate a valid file export procedure in GIMP PDB.")
        return
    Gimp.context_set_interpolation(Gimp.InterpolationType.NOHALO)
    processed_count = 0
    for img in Gimp.get_images():
        file = img.get_file()
        if not file:
            print(f"Skipped unsaved image: {img.get_name()}")
            continue
        filepath = file.get_path()
        if not filepath or not filepath.lower().endswith('.xcf'):
            continue
        dirname, filename = os.path.split(filepath)
        base = filename[:-4] if filename.lower().endswith('.xcf') else filename
        if base.lower().endswith('.dds'):
            base = base[:-4]
        print(f"Processing: {filename}")
        for scale in scales:
            duplicate = img.duplicate()
            new_width = max(1, int(duplicate.get_width() * scale))
            new_height = max(1, int(duplicate.get_height() * scale))
            duplicate.scale(new_width, new_height)
            if len(duplicate.get_layers()) > 1:
                duplicate.merge_visible_layers(Gimp.MergeType.CLIP_TO_IMAGE)
            out_path = os.path.join(dirname, f"{base}_{scale}x.dds")
            out_file = Gio.File.new_for_path(out_path)
            config = export_proc.create_config()
            config.set_property('run-mode', Gimp.RunMode.NONINTERACTIVE)
            config.set_property('image', duplicate)
            config.set_property('file', out_file)
            result = export_proc.run(config)
            status = result.index(0) if result and result.length() > 0 else None
            if status == Gimp.PDBStatusType.SUCCESS:
                print(f"  [OK] Saved: {out_path}")
            else:
                print(f"  [FAILED] Status code {status} for {out_path}")
            duplicate.delete()
        processed_count += 1
    print(f"\nDone: Processed {processed_count} XCF file(s).")

export_scaled_dds()