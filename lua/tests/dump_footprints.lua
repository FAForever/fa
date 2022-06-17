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
