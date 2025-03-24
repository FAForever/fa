---@meta

---@alias BeamBlendmode
---| 0 # Alpha blend
---| 1 # Modulate Inverse
---| 2 # Modulate2X Inverse
---| 3 # Add
---| 4 # Premodulated Alpha

---@class BeamBlueprint : EmitterBlueprint
---@field Length number                # Total length of beam
---@field Lifetime number              # Lifetime of the emitter
---@field Thickness number             # Thickness of the beam in both directions from the center
---@field TextureName FileName         # Filename of texture
---@field StartColor NamedQuaternion   # Color multiplier from 0 to 1 of beam texture at start point. `w, x, y, z = ARGB`
---@field EndColor NamedQuaternion     # Color multiplier from 0 to 1 of beam texture at end point. `w, x, y, z = ARGB`
---@field UShift number                # Proportional shift of beam texture per tick in the U direction (across width of beam, X direction of texture)
---@field VShift number                # Proportional shift of beam texture per tick in the V direction (across the length of the beam, Y direction of texture)
---@field RepeatRate number            # How often the texture repeats per ogrid. `0` stretches the texture over the length of the beam.
---@field Blendmode BeamBlendmode      # Blend mode of the beam.
