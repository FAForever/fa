require 'testutils.lua'

all_blueprints = {}
current_filename = nil

--
-- Define 'UnitBlueprint' func, which will get called with the blueprint data
--
function UnitBlueprint(spec)
    spec.Filename = current_filename
    table.insert(all_blueprints,spec)
end

function Sound()
end

function RPCSound()
end

--
-- Load all the blueprints
--
for i,f in dir_recursive("../../") do
    if string.find(f, "_unit.bp$") then
        current_filename = f
        dofile(f)
    end
end


--
-- Compute a string describing each unique footprint.
-- We'll use the strings as keys in a table, so we can easily identify unique ones
--
-- Each line is a `MotionType` and the square size its units ask for. The engine matches a ground
-- unit to the spec in `/lua/footprints.lua` with the caps of its `MotionType` and the closest size
-- (see `EntityBlueprint.Footprint` in `/engine/Core/Blueprints/EntityBlueprint.lua`). So every
-- line needs a spec with those caps, and a size close enough to it. This is an approximation:
-- - Motion types with the same caps share specs (Land and Biped, Hover and AmphibiousFloating)
-- - The engine uses `Footprint.SizeX`/`SizeZ` when the blueprint sets them, and compares X and Z
--   separately instead of using the larger of the two
-- - Air units never match a spec, and units with `Physics.MaxSpeed` 0 resolve as structures
--
all_footprints = {}
for i,bp in all_blueprints do
    if bp.Physics.MotionType!=nil and bp.Physics.MotionType!='RULEUMT_None' then
        local x = math.ceil(math.max(bp.SizeX or 0, bp.SizeZ or 0))
        local str = bp.Physics.MotionType .. string.format("%3d",x)
        all_footprints[str] = 1
    end
end

sorted = {}
for fp,_ in all_footprints do
    table.insert(sorted,fp)
end
table.sort(sorted)

for i,fp in sorted do
    print(fp)
end
