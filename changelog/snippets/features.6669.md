- (#6669) Add several utilities when modding blueprints with merge blueprints:

    - Setting a field to `"__nil"` in a merge blueprint removes that field from the resulting blueprint. Previously merge blueprints had no way of removing fields.
    - Add a function and table field to mod weapon blueprints: merging by label or otherwise adding the new weapon blueprint to a specified index.
    - Add a function to add categories to a blueprint, and document the old way of adding/removing categories using merge blueprints.
    - Add the function `SetModBlueprintFunction` which allows lua scripts to mod blueprints from hot-reloadable files instead of hooking `ModBlueprints` (which requires a session restart to reload).
