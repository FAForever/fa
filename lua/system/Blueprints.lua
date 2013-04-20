#
# Blueprint loading
#
#   During preloading of the map, we run loadBlueprints() from this file. It scans
#   the game directories and runs all .bp files it finds.
#
#   The .bp files call UnitBlueprint(), PropBlueprint(), etc. to define a blueprint.
#   All those functions do is fill in a couple of default fields and store off the
#   table in 'original_blueprints'.
#
#   Once that scan is complete, ModBlueprints() is called. It can arbitrarily mess
#   with the data in original_blueprints.
#
#   Finally, the engine registers all blueprints in original_blueprints to define the
#   "real" blueprints used by the game. A separate copy of these blueprints is made
#   available to the sim-side and user-side scripts.
#
# How mods can affect blueprints
#
#   First, a mod can simply add a new blueprint file that defines a new blueprint.
#
#   Second, a mod can contain a blueprint with the same ID as an existing blueprint.
#   In this case it will completely override the original blueprint. Note that in
#   order to replace an original non-unit blueprint, the mod must set the "BlueprintId"
#   field to name the blueprint to be replaced. Otherwise the BlueprintId is defaulted
#   off the source file name. (Units don't have this problem because the BlueprintId is
#   shortened and doesn't include the original path).
#
#   Third, a mod can can contain a blueprint with the same ID as an existing blueprint,
#   and with the special field "Merge = true". This causes the mod to be merged with,
#   rather than replace, the original blueprint.
#
#   Finally, a mod can hook the ModBlueprints() function which manipulates the
#   blueprints table in arbitrary ways.
#      1. create a file /mod/s.../hook/system/Blueprints.lua
#      2. override ModBlueprints(all_bps) in that file to manipulate the blueprints
#
# Reloading of changed blueprints
#
#   When the disk watcher notices that a .bp file has changed, it calls
#   ReloadBlueprint() on it. ReloadBlueprint() repeats the above steps, but with
#   original_blueprints containing just the one blueprint.
#
#   Changing an existing blueprint is not 100% reliable; some changes will be picked
#   up by existing units, some not until a new unit of that type is created, and some
#   not at all. Also, if you remove a field from a blueprint and then reload, it will
#   default to its old value, not to 0 or its normal default.
#

local sub = string.sub
local gsub = string.gsub
local lower = string.lower
local getinfo = debug.getinfo
local here = getinfo(1).source

local original_blueprints

local function InitOriginalBlueprints()
    original_blueprints = {
        Mesh = {},
        Unit = {},
        Prop = {},
        Projectile = {},
        TrailEmitter = {},
        Emitter = {},
        Beam = {},
    }
end

local function GetSource()
    # Find the first calling function not in this source file
    local n = 2
    local there
    while true do
        there = getinfo(n).source
        if there!=here then break end
        n = n+1
    end
    if sub(there,1,1)=="@" then
        there = sub(there,2)
    end
    return DiskToLocal(there)
end


local function StoreBlueprint(group, bp)
    local id = bp.BlueprintId
    local t = original_blueprints[group]

    if t[id] and bp.Merge then
        bp.Merge = nil
        bp.Source = nil
        t[id] = table.merged(t[id], bp)
    else
        t[id] = bp
    end
end


#
# Figure out what to name this blueprint based on the name of the file it came from.
# Returns the entire filename. Either this or SetLongId() should really be got rid of.
#
local function SetBackwardsCompatId(bp)
    bp.Source = bp.Source or GetSource()
    bp.BlueprintId = lower(bp.Source)
end


#
# Figure out what to name this blueprint based on the name of the file it came from.
# Returns the full resource name except with ".bp" stripped off
#
local function SetLongId(bp)
    bp.Source = bp.Source or GetSource()
    if not bp.BlueprintId then
        local id = lower(bp.Source)
        id = gsub(id, "%.bp$", "")                          # strip trailing .bp
        #id = gsub(id, "/([^/]+)/%1_([a-z]+)$", "/%1_%2")    # strip redundant directory name
        bp.BlueprintId = id
    end
end


#
# Figure out what to name this blueprint based on the name of the file it came from.
# Returns just the base filename, without any blueprint type info or extension. Used
# for units only.
#
local function SetShortId(bp)
    bp.Source = bp.Source or GetSource()
    bp.BlueprintId = bp.BlueprintId or
        gsub(lower(bp.Source), "^.*/([^/]+)_[a-z]+%.bp$", "%1")
end


#
# If the bp contains a 'Mesh' section, move that over to a separate Mesh blueprint, and
# point bp.MeshBlueprint at it.
#
# Also fill in a default value for bp.MeshBlueprint if one was not given at all.
#
function ExtractMeshBlueprint(bp)
    local disp = bp.Display or {}
    bp.Display = disp

    if disp.MeshBlueprint=='' then
        LOG('Warning: ',bp.Source,': MeshBlueprint should not be an empty string')
        disp.MeshBlueprint = nil
    end

    if type(disp.MeshBlueprint)=='string' then
        if disp.MeshBlueprint!=lower(disp.MeshBlueprint) then
            #Should we allow mixed-case blueprint names?
            #LOG('Warning: ',bp.Source,' (MeshBlueprint): ','Blueprint IDs must be all lowercase')
            disp.MeshBlueprint = lower(disp.MeshBlueprint)
        end

        # strip trailing .bp
        disp.MeshBlueprint = gsub(disp.MeshBlueprint, "%.bp$", "")

        if disp.Mesh then
            LOG('Warning: ',bp.Source,' has mesh defined both inline and by reference')
        end
    end

    if disp.MeshBlueprint==nil then
        # For a blueprint file "/units/uel0001/uel0001_unit.bp", the default
        # mesh blueprint is "/units/uel0001/uel0001_mesh"
        local meshname,subcount = gsub(bp.Source, "_[a-z]+%.bp$", "_mesh")
        if subcount==1 then
            disp.MeshBlueprint = meshname
        end

        if type(disp.Mesh)=='table' then
            local meshbp = disp.Mesh
            meshbp.Source = meshbp.Source or bp.Source
            meshbp.BlueprintId = disp.MeshBlueprint
            # roates:  Commented out so the info would stay in the unit BP and I could use it to precache by unit.
            # disp.Mesh = nil
            MeshBlueprint(meshbp)
        end
    end
end


function ExtractWreckageBlueprint(bp)
    local meshid = bp.Display.MeshBlueprint
    if not meshid then return end

    local meshbp = original_blueprints.Mesh[meshid]
    if not meshbp then return end

    local wreckbp = table.deepcopy(meshbp)
    if wreckbp.LODs then
        for i,lod in wreckbp.LODs do
            if lod.ShaderName == 'TMeshAlpha' or lod.ShaderName == 'NormalMappedAlpha' or lod.ShaderName == 'UndulatingNormalMappedAlpha' then
                lod.ShaderName = 'BlackenedNormalMappedAlpha'
            else
                lod.ShaderName = 'Wreckage'
                lod.SpecularName = '/env/common/props/wreckage_noise.dds'
            end
        end
    end
    wreckbp.BlueprintId = meshid .. '_wreck'
    bp.Display.MeshBlueprintWrecked = wreckbp.BlueprintId
    MeshBlueprint(wreckbp)
end

function ExtractBuildMeshBlueprint(bp)
	local FactionName = bp.General.FactionName

	if FactionName == 'Aeon' or FactionName == 'UEF' or FactionName == 'Cybran' or FactionName == 'Seraphim' then 
		local meshid = bp.Display.MeshBlueprint
		if not meshid then return end

		local meshbp = original_blueprints.Mesh[meshid]
		if not meshbp then return end

		local shadername = FactionName .. 'Build'
		local secondaryname = '/textures/effects/' .. FactionName .. 'BuildSpecular.dds'

		local buildmeshbp = table.deepcopy(meshbp)
		if buildmeshbp.LODs then
			for i,lod in buildmeshbp.LODs do
				lod.ShaderName = shadername
				lod.SecondaryName = secondaryname
				if FactionName == 'Seraphim' then
				    lod.LookupName = '/textures/environment/Falloff_seraphim_lookup.dds'
				end
			end
		end
		buildmeshbp.BlueprintId = meshid .. '_build'
		bp.Display.BuildMeshBlueprint = buildmeshbp.BlueprintId
		MeshBlueprint(buildmeshbp)
	end
end


function MeshBlueprint(bp)
    # fill in default values
    SetLongId(bp)
    StoreBlueprint('Mesh', bp)
end


function UnitBlueprint(bp)
    SetShortId(bp)
    StoreBlueprint('Unit', bp)
end


function PropBlueprint(bp)
    SetBackwardsCompatId(bp)
    StoreBlueprint('Prop', bp)
end


function ProjectileBlueprint(bp)
    SetBackwardsCompatId(bp)
    StoreBlueprint('Projectile', bp)
end


function TrailEmitterBlueprint(bp)
    SetBackwardsCompatId(bp)
    StoreBlueprint('TrailEmitter', bp)
end


function EmitterBlueprint(bp)
    SetBackwardsCompatId(bp)
    StoreBlueprint('Emitter', bp)
end


function BeamBlueprint(bp)
    SetBackwardsCompatId(bp)
    StoreBlueprint('Beam', bp)
end


function ExtractAllMeshBlueprints()

    for id,bp in original_blueprints.Unit do
        ExtractMeshBlueprint(bp)
        ExtractWreckageBlueprint(bp)
        ExtractBuildMeshBlueprint(bp)
    end

    for id,bp in original_blueprints.Prop do
        ExtractMeshBlueprint(bp)
        ExtractWreckageBlueprint(bp)
    end

    for id,bp in original_blueprints.Projectile do
		--just to remove the "Warning: \000/projectiles/tananglertorpedo06/tananglertorpedo06_proj.bp\000 has mesh defined both inline and by reference" error
		if bp and bp.BlueprintId and bp.BlueprintId == '/projectiles/tananglertorpedo06/tananglertorpedo06_proj.bp' then
			if bp.Display.MeshBlueprint then 
				bp.Display.MeshBlueprint = nil
			end
		end
        ExtractMeshBlueprint(bp)
    end
end


function RegisterAllBlueprints(blueprints)

    local function RegisterGroup(g, fun)
        for id,bp in sortedpairs(g) do
            fun(g[id])
        end
    end

    RegisterGroup(blueprints.Mesh, RegisterMeshBlueprint)
    RegisterGroup(blueprints.Unit, RegisterUnitBlueprint)
    RegisterGroup(blueprints.Prop, RegisterPropBlueprint)
    RegisterGroup(blueprints.Projectile, RegisterProjectileBlueprint)
    RegisterGroup(blueprints.TrailEmitter, RegisterTrailEmitterBlueprint)
    RegisterGroup(blueprints.Emitter, RegisterEmitterBlueprint)
    RegisterGroup(blueprints.Beam, RegisterBeamBlueprint)
end


# Hook for mods to manipulate the entire blueprint table
function ModBlueprints(all_bps)
	
	##This whole bit added for shipwreck mod
	for id,bp in pairs(all_bps.Unit) do	
		if (bp.Categories) then	
			local cats = {}
			for k,cat in pairs(bp.Categories) do
				cats[cat] = true
			end
			if cats.NAVAL and not bp.Wreckage then
				--LOG("Adding wreckage information to ", bp.Description)
				bp.Wreckage = {
					Blueprint = '/props/DefaultWreckage/DefaultWreckage_prop.bp',
					EnergyMult = 0,
					HealthMult = 0.9,
					MassMult = 0.9,
					ReclaimTimeMultiplier = 1,
					WreckageLayers = {
						Air = false,
						Land = false,
						Seabed = true,
						Sub = true,
						Water = true,
					};
				}
			end
		end
	end
	##end shipwreck mod bit
end


# Load all blueprints
function LoadBlueprints()
    LOG('Loading blueprints...')
    InitOriginalBlueprints()

    for i,dir in {'/effects', '/env', '/meshes', '/projectiles', '/props', '/units'} do
        for k,file in DiskFindFiles(dir, '*.bp') do
            BlueprintLoaderUpdateProgress()
            safecall("loading blueprint "..file, doscript, file)
        end
    end

    for i,m in __active_mods do
        for k,file in DiskFindFiles(m.location, '*.bp') do
            BlueprintLoaderUpdateProgress()
            LOG("applying blueprint mod "..file)
            safecall("loading mod blueprint "..file, doscript, file)
        end
    end

    BlueprintLoaderUpdateProgress()
    LOG('Extracting mesh blueprints.')
    ExtractAllMeshBlueprints()

    BlueprintLoaderUpdateProgress()
    LOG('Modding blueprints.')
    ModBlueprints(original_blueprints)

    BlueprintLoaderUpdateProgress()
    LOG('Registering blueprints...')
    RegisterAllBlueprints(original_blueprints)
    original_blueprints = nil

    LOG('Blueprints loaded')

end


# Reload a single blueprint
function ReloadBlueprint(file)
    InitOriginalBlueprints()

    safecall("reloading blueprint "..file, doscript, file)

    ExtractAllMeshBlueprints()
    ModBlueprints(original_blueprints)
    RegisterAllBlueprints(original_blueprints)
    original_blueprints = nil
end





