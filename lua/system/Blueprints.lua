--
-- Blueprint loading
--
--   During preloading of the map, we run loadBlueprints() from this file. It scans
--   the game directories and runs all .bp files it finds.
--
--   The .bp files call UnitBlueprint(), PropBlueprint(), etc. to define a blueprint.
--   All those functions do is fill in a couple of default fields and store off the
--   table in 'original_blueprints'.
--
--   Once that scan is complete, ModBlueprints() is called. It can arbitrarily mess
--   with the data in original_blueprints.
--
--   Finally, the engine registers all blueprints in original_blueprints to define the
--   "real" blueprints used by the game. A separate copy of these blueprints is made
--   available to the sim-side and user-side scripts.
--
-- How mods can affect blueprints
--
--   First, a mod can simply add a new blueprint file that defines a new blueprint.
--
--   Second, a mod can contain a blueprint with the same ID as an existing blueprint.
--   In this case it will completely override the original blueprint. Note that in
--   order to replace an original non-unit blueprint, the mod must set the "BlueprintId"
--   field to name the blueprint to be replaced. Otherwise the BlueprintId is defaulted
--   off the source file name. (Units don't have this problem because the BlueprintId is
--   shortened and doesn't include the original path).
--
--   Third, a mod can contain a blueprint with the same ID as an existing blueprint,
--   and with the special field "Merge = true". This causes the mod to be merged with,
--   rather than replace, the original blueprint.
--
--   Finally, a mod can hook the ModBlueprints() function which manipulates the
--   blueprints table in arbitrary ways.
--      1. create a file /mod/s.../hook/system/Blueprints.lua
--      2. override ModBlueprints(all_bps) in that file to manipulate the blueprints
--
-- Reloading of changed blueprints
--
--   When the disk watcher notices that a .bp file has changed, it calls
--   ReloadBlueprint() on it. ReloadBlueprint() repeats the above steps, but with
--   original_blueprints containing just the one blueprint.
--
--   Changing an existing blueprint is not 100% reliable; some changes will be picked
--   up by existing units, some not until a new unit of that type is created, and some
--   not at all. Also, if you remove a field from a blueprint and then reload, it will
--   default to its old value, not to 0 or its normal default.
--

local sub = string.sub
local gsub = string.gsub
local lower = string.lower
local getinfo = debug.getinfo
local here = getinfo(1).source

local original_blueprints
local current_mod

--- Load in the pre game data that is defined in the lobby through the preference file.
local function LoadPreGameData()

    -- load in the prefs file
    local file = DiskFindFiles("/preferences", "Game.prefs")[1]
    if not file then 
        WARN('Blueprints.lua - Preferences file is not found. Skipping pre game data.') 
        return 
    end

    -- try and load the pre game data of prefs file
    local preGameData = false 
    ok, msg = pcall(
        function() 
            local data = { }
            doscript(file, data)
            preGameData = data.PreGameData 
        end 
    )

    -- tell us if something went wrong
    if not ok then 
        WARN("Blueprints.lua - Preferences file is corrupted. Skipping pre game data.")
        WARN(msg)
    end

    return preGameData
end

--- Attempts to assign icons to units if they exist.
-- @units All unit blueprints.
-- @assignments A list of assignments { { BlueprintId = ..., IconSet = ... }, }.
-- @identifier The identifier of the UI mod that ensures compatibility when turned off (/textures/ui/game/common/strategicicons/identifier)
local function AssignIcons(units, assignments, identifier)

    local function AssignBlueprintId(units, id, icon)
        local unit = units[id]
        if unit then 
            local path = identifier .. "/" .. icon
            unit.StrategicIconName =  path
        end
    end

    local function AssignTypeId(units, id, icon)
        -- todo :)
    end

    if assignments then 
        for k, info in assignments do 
            if info.BlueprintId then 
                AssignBlueprintId(units, info.BlueprintId, info.IconSet)
                continue 
            end

            if info.TypeId then 
                AssignTypeId(units, info.TypeId, info.IconSet)
                continue
            end
        end
    end
end

--- Finds and applies custom strategic icons defined by UI mods.
-- @param all_bps The table with all blueprint values.
local function FindCustomStrategicIcons(all_bps)

    -- STRATEGIC ICON REPLACEMENT --

    -- try and load in pre game data
    local preGameData = LoadPreGameData()
    if preGameData and preGameData.IconReplacements then 
        for _, info in preGameData.IconReplacements do 

            -- data that is set in the lobby
            -- info.Name = mod.name 
            -- info.Author = mod.author 
            -- info.Location = mod.location
            -- info.Identifier = string.lower(utils.StringSplit(mod.location, '/')[2])
            -- info.UID = uid

            -- all the functionality that is available in the _icons.lua
            local state = {
                LOG = LOG,
                WARN = WARN, 
                _ALERT = _ALERT,
                SPEW = SPEW,
                repr = repr,
                table = table,
                math = math, 
                string = string,
                tonumber = tonumber,
                type = type,
            }

            -- try to get the icons file
            local ok, msg = pcall(
                function()
                    doscript(info.Location .. "/mod_icons.lua", state)
                end
            )

            -- if we can't, report it
            if not ok then 
                WARN("Blueprints.lua - Unable to load icons from mod '" .. mod.name .. "' with uuid '" .. uuid .. "'. Please inform the author: " .. mod.author)
                WARN(msg)
            end

            ok, msg = pcall (
                function()
                    -- scripted approach
                    if state.ScriptedIconAssignments then 
                        -- retrieve data, make sure it is a deepcopy to prevent ui mods messing with the original
                        local units = table.deepcopy(all_bps.Unit)
                        local projectiles = table.deepcopy(all_bps.Projectile)
                        local icons = DiskFindFiles(info.Location .. "/custom-strategic-icons", "*.dds")

                        -- find scripted icons and assign them
                        local scriptedIcons = state.ScriptedIconAssignments(units, projectiles, icons)
                        AssignIcons(all_bps.Unit, scriptedIcons, info.Identifier)

                        -- inform the dev
                        local n = table.getsize(scriptedIcons)
                        if n > 1 then 
                            SPEW("Blueprints.lua - Found (" .. n .. ") scripted icon assignments in " .. info.Name .. " by " .. info.Author .. ".")
                        end
                    end

                    -- manual approach
                    if state.UnitIconAssignments then 
                        AssignIcons(all_bps.Unit, state.UnitIconAssignments, info.Identifier)

                        -- inform the dev
                        local n = table.getsize(state.UnitIconAssignments)
                        if n > 1 then 
                            SPEW("Blueprints.lua - Found (" .. n .. ") manual icon assignments in " .. info.Name .. " by " .. info.Author .. ".")
                        end
                    end
                end
            )

            -- if we can't, report it
            if not ok then 
                WARN("Blueprints.lua - Unable to load icons from mod '" .. info.Name .. "' with uuid '" .. info.UID .. "'. Please inform the author: " .. info.Author)
                WARN(msg)
            end
        end
    end
end

local function InitOriginalBlueprints()
    current_mod = nil
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
    -- Find the first calling function not in this source file
    local n = 2
    local there
    while true do
        there = getinfo(n).source
        if there ~= here then break end
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
--
-- Figure out what to name this blueprint based on the name of the file it came from.
-- Returns the entire filename. Either this or SetLongId() should really be got rid of.
--
local function SetBackwardsCompatId(bp)
    bp.Source = bp.Source or GetSource()
    bp.BlueprintId = lower(bp.Source)
end
--
-- Figure out what to name this blueprint based on the name of the file it came from.
-- Returns the full resource name except with ".bp" stripped off
--
local function SetLongId(bp)
    bp.Source = bp.Source or GetSource()
    if not bp.BlueprintId then
        local id = lower(bp.Source)
        id = gsub(id, "%.bp$", "")                          -- strip trailing .bp
        --id = gsub(id, "/([^/]+)/%1_([a-z]+)$", "/%1_%2")    -- strip redundant directory name
        bp.BlueprintId = id
    end
end
--
-- Figure out what to name this blueprint based on the name of the file it came from.
-- Returns just the base filename, without any blueprint type info or extension. Used
-- for units only.
--
local function SetShortId(bp)
    bp.Source = bp.Source or GetSource()
    bp.BlueprintId = bp.BlueprintId or
        gsub(lower(bp.Source), "^.*/([^/]+)_[a-z]+%.bp$", "%1")
end
--
-- If the bp contains a 'Mesh' section, move that over to a separate Mesh blueprint, and
-- point bp.MeshBlueprint at it.
--
-- Also fill in a default value for bp.MeshBlueprint if one was not given at all.
--
function ExtractMeshBlueprint(bp)
    local disp = bp.Display or {}
    bp.Display = disp

    if disp.MeshBlueprint=='' then
        LOG('Warning: ',bp.Source,': MeshBlueprint should not be an empty string')
        disp.MeshBlueprint = nil
    end

    if type(disp.MeshBlueprint)=='string' then
        if disp.MeshBlueprint~=lower(disp.MeshBlueprint) then
            --Should we allow mixed-case blueprint names?
            --LOG('Warning: ',bp.Source,' (MeshBlueprint): ','Blueprint IDs must be all lowercase')
            disp.MeshBlueprint = lower(disp.MeshBlueprint)
        end

        -- strip trailing .bp
        disp.MeshBlueprint = gsub(disp.MeshBlueprint, "%.bp$", "")

        if disp.Mesh then
            LOG('Warning: ',bp.Source,' has mesh defined both inline and by reference')
        end
    end

    if disp.MeshBlueprint==nil then
        -- For a blueprint file "/units/uel0001/uel0001_unit.bp", the default
        -- mesh blueprint is "/units/uel0001/uel0001_mesh"
        local meshname,subcount = gsub(bp.Source, "_[a-z]+%.bp$", "_mesh")
        if subcount==1 then
            disp.MeshBlueprint = meshname
        end

        if type(disp.Mesh)=='table' then
            local meshbp = disp.Mesh
            meshbp.Source = meshbp.Source or bp.Source
            meshbp.BlueprintId = disp.MeshBlueprint
            -- roates:  Commented out so the info would stay in the unit BP and I could use it to precache by unit.
            -- disp.Mesh = nil
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
    -- fill in default values
    SetLongId(bp)
    StoreBlueprint('Mesh', bp)
end

function UnitBlueprint(bp)
    -- save info about mods that changed this blueprint
    bp.Mod = current_mod
    SetShortId(bp)
    StoreBlueprint('Unit', bp)
end

function PropBlueprint(bp)
    SetBackwardsCompatId(bp)
    StoreBlueprint('Prop', bp)
end

function ProjectileBlueprint(bp)
    -- save info about mods that changed this blueprint
    bp.Mod = current_mod
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

-- Brute51 - Adding support for SCU presets: allows building units that get enhancements at the factory, so no need to enhance
-- after building SCU.
function HandleUnitWithBuildPresets(bps, all_bps)

    -- hashing sort categories for quick lookup
    local sortCategories = { ['SORTOTHER'] = true, ['SORTINTEL'] = true, ['SORTSTRATEGIC'] = true, ['SORTDEFENSE'] = true, ['SORTECONOMY'] = true, ['SORTCONSTRUCTION'] = true, }

    local tempBp = {}

    for k, bp in bps do

        for name, preset in bp.EnhancementPresets do
            -- start with clean copy of the original unit BP
            tempBp = table.deepcopy(bp)

            -- create BP table for the assigned preset with required info
            tempBp.EnhancementPresetAssigned = {
                Enhancements = table.deepcopy(preset.Enhancements),
                Name = name,
                BaseBlueprintId = bp.BlueprintId,
            }

            -- change cost of the new unit to match unit base cost + preset enhancement costs. An override is provided for cases where this is not desired.
            local e, m, t = 0, 0, 0
            if not preset.BuildCostEnergyOverride or not preset.BuildCostMassOverride or not preset.BuildTimeOverride then
                for k, enh in preset.Enhancements do
                    -- replaced continue by reversing if statement
                    if tempBp.Enhancements[enh] then
                        e = e + (tempBp.Enhancements[enh].BuildCostEnergy or 0)
                        m = m + (tempBp.Enhancements[enh].BuildCostMass or 0)
                        t = t + (tempBp.Enhancements[enh].BuildTime or 0)
                        -- HUSSAR added name of the enhancement so that preset units cannot be built
                        -- if they have restricted enhancement(s)
                        tempBp.CategoriesHash[enh] = true -- hashing without changing case of enhancements
                    else
                        WARN('*DEBUG: Enhancement '..repr(enh)..' used in preset '..repr(name)..' for unit '..repr(tempBp.BlueprintId)..' does not exist')
                    end
                end
            end
            tempBp.Economy.BuildCostEnergy = preset.BuildCostEnergyOverride or (tempBp.Economy.BuildCostEnergy + e)
            tempBp.Economy.BuildCostMass = preset.BuildCostMassOverride or (tempBp.Economy.BuildCostMass + m)
            tempBp.Economy.BuildTime = preset.BuildTimeOverride or (tempBp.Economy.BuildTime + t)

            -- teleport cost adjustments. Manually enhanced SCU with teleport is cheaper than a prebuild SCU because the latter has its cost
            -- adjusted (up). This code sets bp values used in the code to calculate with different base values than the unit cost.
            if preset.TeleportNoCostAdjustment ~= false then
                -- set teleport cost overrides to cost of base unit
                tempBp.Economy.TeleportEnergyCost = bp.Economy.BuildCostEnergy or 0
                tempBp.Economy.TeleportMassCost = bp.Economy.BuildMassEnergy or 0
            end

            -- Add a sorting category so similar SCUs are grouped together in the build menu
            if preset.SortCategory then
                if sortCategories[preset.SortCategory] or preset.SortCategory == 'None' then
                    for k, v in sortCategories do
                        tempBp.CategoriesHash[k] = false
                    end
                    if preset.SortCategory ~= 'None' then
                        tempBp.CategoriesHash[preset.SortCategory] = true
                    end
                end
            end

            -- change other things relevant things as well
            tempBp.BaseBlueprintId = tempBp.BlueprintId
            tempBp.BlueprintId = tempBp.BlueprintId .. '_' .. name
            tempBp.BuildIconSortPriority = preset.BuildIconSortPriority or tempBp.BuildIconSortPriority or 0
            tempBp.General.UnitName = preset.UnitName or tempBp.General.UnitName
            tempBp.Interface.HelpText = preset.HelpText or tempBp.Interface.HelpText
            tempBp.Description = preset.Description or tempBp.Description
            tempBp.CategoriesHash['ISPREENHANCEDUNIT'] = true
            tempBp.CategoriesHash[string.upper(name..'PRESET')] = true
            -- clean up some data that's not needed anymore
            tempBp.CategoriesHash['USEBUILDPRESETS'] = false
            tempBp.EnhancementPresets = nil
            -- synchronizing Categories with CategoriesHash for compatibility
            tempBp.Categories = table.unhash(tempBp.CategoriesHash)

            table.insert(all_bps.Unit, tempBp)

            BlueprintLoaderUpdateProgress()
        end
    end
end

-- Assign shader and mesh for visual Cloaking FX
function ExtractCloakMeshBlueprint(bp)
    local meshid = bp.Display.MeshBlueprint
    if not meshid then return end

    local meshbp = original_blueprints.Mesh[meshid]
    if not meshbp then return end

    local shadernameE = 'ShieldCybran'
    local shadernameA = 'ShieldAeon'
    local shadernameC = 'ShieldCybran'
    local shadernameS = 'ShieldAeon'

    local cloakmeshbp = table.deepcopy(meshbp)
    if cloakmeshbp.LODs then
        for i, cat in bp.Categories do
            if cat == 'UEF' or cat == 'CYBRAN' then
                for i, lod in cloakmeshbp.LODs do
                    lod.ShaderName = shadernameE
                end
            elseif cat == 'AEON' or cat == 'SERAPHIM' then
                for i, lod in cloakmeshbp.LODs do
                    lod.ShaderName = shadernameA
                end
            end
        end
    end
    cloakmeshbp.BlueprintId = meshid .. '_cloak'
    bp.Display.CloakMeshBlueprint = cloakmeshbp.BlueprintId
    MeshBlueprint(cloakmeshbp)
end

-- Mod unit blueprints before allowing mods to modify it as well, to pass the most correct unit blueprint to mods
function PreModBlueprints(all_bps)

    -- Brute51: Modified code for ship wrecks and added code for SCU presets.
    -- removed the pairs() function call in the for loops for better efficiency and because it is not necessary.

    for _, bp in all_bps.Unit do

        ExtractCloakMeshBlueprint(bp)

        -- skip units without categories
        if not bp.Categories then
            continue
        end

        -- saving Categories as a hash table for later usage by sim/ui functions
        bp.CategoriesHash = table.hash(bp.Categories)

        -- adding or deleting categories on the fly
        if bp.DelCategories then
            for k, v in bp.DelCategories do
                bp.CategoriesHash[v] = false
            end
            bp.DelCategories = nil
        end
        if bp.AddCategories then
            for k, v in bp.AddCategories do
                bp.CategoriesHash[v] = true
            end
            bp.AddCategories = nil
        end

        if bp.CategoriesHash.ENGINEER then -- show build range overlay for engineers
            if not bp.AI then bp.AI = {} end
            bp.AI.StagingPlatformScanRadius = (bp.Economy.MaxBuildDistance or 5) + 2
            if not bp.CategoriesHash.POD then -- excluding Build Drones
                bp.CategoriesHash.OVERLAYMISC = true
            end
        end

        if bp.CategoriesHash.NAVAL and not bp.Wreckage then
            -- Add naval wreckage
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
                },
            }
        end

        -- Create new keys so that unit scripting can more easily reference the most common data needed
        for _, category in {'EXPERIMENTAL', 'SUBCOMMANDER', 'COMMAND', 'TECH1', 'TECH2', 'TECH3'} do
            if bp.CategoriesHash[category] then
                bp.TechCategory = category
                break
            end
        end

        for i, w in bp.Weapon or {} do
            if w.TargetPriorities then

                local newPriorities = {}

                for g, transcendentPritority in w.TranscendentPriorities or {} do
                    table.insert(newPriorities, transcendentPritority)
                end

                table.insert(newPriorities, 'SPECIALHIGHPRI')

                for _, priority in w.TargetPriorities do
                    table.insert(newPriorities, priority)
                end

                table.insert(newPriorities, 'SPECIALLOWPRI')

                w.TargetPriorities = newPriorities
            end
        end

        for _, category in {'LAND', 'AIR', 'NAVAL'} do
            if bp.CategoriesHash[category] then
                bp.LayerCategory = category
                break
            end
        end

        bp.FactionCategory = string.upper(bp.General.FactionName or 'Unknown')

        -- Mod in AI.GuardScanRadius = Longest weapon range * longest tracking radius
        -- Takes ACU/SCU enhancements into account
        -- fixes move-attack range issues
        -- Most Air units have the GSR defined already, this is just making certain they don't get included
        local modGSR = not (bp.AI and bp.AI.GuardScanRadius) and (
                       (bp.CategoriesHash.MOBILE and (bp.CategoriesHash.LAND or bp.CategoriesHash.NAVAL) and (bp.CategoriesHash.DIRECTFIRE or bp.CategoriesHash.INDIRECTFIRE or bp.CategoriesHash.ANTINAVY or bp.CategoriesHash.ENGINEER)) or
                       (bp.CategoriesHash.STRUCTURE and (bp.CategoriesHash.DIRECTFIRE or bp.CategoriesHash.INDIRECTFIRE) and (bp.CategoriesHash.DEFENSE or bp.CategoriesHash.ARTILLERY)) or bp.CategoriesHash.DUMMYGSRWEAPON
                       )

        if modGSR then
            local br = nil

            if bp.CategoriesHash.ENGINEER and not bp.CategoriesHash.SUBCOMMANDER and not bp.CategoriesHash.COMMAND then
                br = 26
            elseif bp.CategoriesHash.SCOUT then
                br = 10
            elseif bp.Weapon then
                local range = 0
                local tracking = 1.05

                for i, w in bp.Weapon do
                    local ignore = w.CountedProjectile or w.RangeCategory == 'UWRC_AntiAir' or w.WeaponCategory == 'Defense'
                    if not ignore then
                        if w.MaxRadius then
                            range = math.max(w.MaxRadius, range)
                        end
                        if w.TrackingRadius then
                            tracking = math.max(w.TrackingRadius, tracking)
                        end
                    end
                end

                for name, array in bp.Enhancements or {} do
                    for key, value in array do
                        if key == 'NewMaxRadius' then
                            range = math.max(value, range)
                        end
                    end
                end

                br = (range * tracking)
            end

            if br then
                if not bp.AI then bp.AI = {} end
                bp.AI.GuardScanRadius = br
                if not bp.AI.GuardReturnRadius then
                    bp.AI.GuardReturnRadius = 3
                end
            end
        end
        -- synchronizing bp.Categories with bp.CategoriesHash for compatibility
        bp.Categories = table.unhash(bp.CategoriesHash)

        BlueprintLoaderUpdateProgress()
    end
end

-- Hook for mods to manipulate the entire blueprint table
function ModBlueprints(all_bps)
end

function PostModBlueprints(all_bps)

    -- Brute51: Modified code for ship wrecks and added code for SCU presets.
    -- removed the pairs() function call in the for loops for better efficiency and because it is not necessary.
    local preset_bps = {}

    for _, bp in all_bps.Unit do
        -- skip units without categories
        if not bp.Categories then
            continue
        end

        -- check if blueprint was changed in ModBlueprints(all_bps)
        if bp.Mod or table.getsize(bp.CategoriesHash) ~= table.getsize(bp.Categories) then
           bp.CategoriesHash = table.hash(bp.Categories)
        end

        if bp.CategoriesHash.USEBUILDPRESETS then
            -- HUSSAR adding logic for finding issues in enhancements table
            local issues = {}
            if not bp.Enhancements then table.insert(issues, 'no Enhancements value') end
            if type(bp.Enhancements) ~= 'table' then table.insert(issues, 'no Enhancements table') end
            if not bp.EnhancementPresets then table.insert(issues, 'no EnhancementPresets value') end
            if type(bp.EnhancementPresets) ~= 'table' then table.insert(issues, 'no EnhancementPresets table') end
            -- check blueprint, if correct info for presets then put this unit on the list to handle later
            if table.empty(issues) then
                table.insert(preset_bps, table.deepcopy(bp))
            else
                issues = table.concat(issues,', ')
                WARN('UnitBlueprint '..repr(bp.BlueprintId)..' has a category USEBUILDPRESETS but ' .. issues)
            end
        end
        BlueprintLoaderUpdateProgress()
    end
    HandleUnitWithBuildPresets(preset_bps, all_bps)

    -- find custom strategic icons defined by ui mods, this should be the very last thing 
    -- we do before releasing the blueprint values to the game as we want to catch all
    -- units, even those included by mods.
    FindCustomStrategicIcons(all_bps)
end
-----------------------------------------------------------------------------------------------
--- Loads all blueprints with optional parameters
--- @param pattern           - specifies pattern of files to load, defaults to '*.bp'
--- @param directories       - specifies table of directory paths to load blueprints from, defaults to all directories
--- @param mods              - specifies table of mods to load blueprints from, defaults to active mods
--- @param skipGameFiles     - specifies whether skip loading original game files, defaults to false
--- @param skipExtraction    - specifies whether skip extraction of meshes, defaults to false
--- @param skipRegistration  - specifies whether skip registration of blueprints, defaults to false
--- @param taskNotifier      - specifies reference to a notifier that is updating UI when loading blueprints
--- NOTE now it supports loading blueprints on UI-side in addition to loading on Sim-side
--- Sim -> LoadBlueprints() - no arguments, no changes!
--- UI  -> LoadBlueprints('*_unit.bp', {'/units'}, mods, true, true, true, taskNotifier)  used in ModsManager.lua
--- UI  -> LoadBlueprints('*_unit.bp', {'/units'}, mods, false, true, true, taskNotifier) used in UnitsAnalyzer.lua

function LoadBlueprints(pattern, directories, mods, skipGameFiles, skipExtraction, skipRegistration, taskNotifier)

    local task = 'Blueprints Loading... '
    local progress = nil
    local total = nil
    local files = {}

    -- set default parameters if they are not provided
    if not pattern then pattern = '*.bp' end
    if not directories then
        directories = {'/effects', '/env', '/meshes', '/projectiles', '/props', '/units'}
    end

    LOG('Blueprints Loading... \'' .. tostring(pattern) .. '\' files')

    if not mods then
        mods = __active_mods or import('/lua/mods.lua').GetGameMods()
    end
    InitOriginalBlueprints()

    if not skipGameFiles then
        for i,dir in directories do
            task = 'Blueprints Loading: original files from ' .. dir .. ' directory'
            files = DiskFindFiles(dir, pattern)
            total = table.getsize(files)
            LOG(task)

            for k,file in files do
                BlueprintLoaderUpdateProgress()
                -- update UnitManager UI via taskNotifier only if it exists
                if taskNotifier then
                   taskNotifier:Update(task, total, k)
                end
                safecall(task .. ': ' .. file, doscript, file)
            end
        end
    end

    local stats = {}
    stats.UnitsOrg = table.getsize(original_blueprints.Unit)
    stats.ProjsOrg = table.getsize(original_blueprints.Projectile)

    -- try and load in pre game data for current map directory
    local preGameData = LoadPreGameData()
    if preGameData and preGameData.CurrentMapDir then
        task = 'Blueprints Loading: Blueprints from current map'
        files = DiskFindFiles(preGameData.CurrentMapDir, pattern)
        for k,file in files do
            BlueprintLoaderUpdateProgress()
            -- update UnitManager UI via taskNotifier only if it exists
            if taskNotifier then
               taskNotifier:Update(task, total, k)
            end

            safecall(task .. ': ' .. file, doscript, file)
        end
    end

    for i,mod in mods or {} do
        current_mod = mod -- used in UnitBlueprint()
        task = 'Blueprints Loading: modded files from "' .. mod.name .. '" mod'
        files = DiskFindFiles(mod.location, pattern)
        total = table.getsize(files)
        LOG(task)

        for k,file in files do
            BlueprintLoaderUpdateProgress()
            -- update UnitManager UI via taskNotifier only if it exists
            if taskNotifier then
               taskNotifier:Update(task, total, k)
            end
            safecall(task .. ': ' .. file, doscript, file)
        end
    end
    stats.UnitsMod = table.getsize(original_blueprints.Unit) - stats.UnitsOrg
    stats.ProjsMod = table.getsize(original_blueprints.Projectile) - stats.ProjsOrg


    if not skipExtraction then
        BlueprintLoaderUpdateProgress()
        LOG('Blueprints Extracting mesh...')
        ExtractAllMeshBlueprints()
    end

    BlueprintLoaderUpdateProgress()
    LOG('Blueprints Modding...')
    PreModBlueprints(original_blueprints)
    ModBlueprints(original_blueprints)
    PostModBlueprints(original_blueprints)

    stats.UnitsTotal = table.getsize(original_blueprints.Unit)
    stats.UnitsPreset = stats.UnitsTotal - stats.UnitsOrg - stats.UnitsMod
    if stats.UnitsTotal > 0 then
        LOG('Blueprints Loading... completed: ' .. stats.UnitsOrg .. ' original, '
                                                .. stats.UnitsMod .. ' modded, and '
                                                .. stats.UnitsPreset .. ' preset units')
    end
    stats.ProjsTotal = table.getsize(original_blueprints.Projectile)
    if stats.ProjsTotal > 0 then
        LOG('Blueprints Loading... completed: ' .. stats.ProjsOrg .. ' original and '
                                                .. stats.ProjsMod .. ' modded projectiles')
    end

    if not skipRegistration then
        BlueprintLoaderUpdateProgress()
        LOG('Blueprints Registering...')
        RegisterAllBlueprints(original_blueprints)
        original_blueprints = nil
    else
        return original_blueprints
    end
end

-- Reload a single blueprint
function ReloadBlueprint(file)
    InitOriginalBlueprints()

    safecall("Blueprints Reloading... "..file, doscript, file)

    ExtractAllMeshBlueprints()
    ModBlueprints(original_blueprints)
    RegisterAllBlueprints(original_blueprints)
    original_blueprints = nil
end
