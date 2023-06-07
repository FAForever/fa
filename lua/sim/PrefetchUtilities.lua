----  File     : PrefetchUtilities.lua
----  Author(s): Robert Oates
----  Summary  : Functions to simplify prefetching by base, unit, etc...
----  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.

local TableGetn = table.getn
local TableInsert = table.insert

---@class PrefetchSet
---@field d3d_textures string[]
---@field batch_textures string[]
---@field models string[]
---@field anims string[]
---@field UnitCache table<UnitBlueprint, boolean>

---@param ids BlueprintId[]
---@return PrefetchSet
function CreatePrefetchSetFromBlueprints(ids)
    local set = { d3d_textures = {}, batch_textures = {}, models = {}, anims = {} }
    local unitCache = {}
    local blueprints = __blueprints
    -- local tarmacCache = {}
    for _, id in ids do

        ---@type UnitBlueprint
        local blueprint = blueprints[id]
        if blueprint then

            if not unitCache[id] then
                local commonPath = '/units/' .. blueprint.BlueprintId .. '/' .. blueprint.BlueprintId

                TableInsert(set.d3d_textures, commonPath .. '_albedo.dds')
                TableInsert(set.d3d_textures, commonPath .. '_specteam.dds')
                TableInsert(set.d3d_textures, commonPath .. '_normalsts.dds')
                TableInsert(set.models, commonPath .. '_lod0.scm')

                -- preload additional textures
                if blueprint.Display.Mesh and blueprint.Display.Mesh.LODs and TableGetn(blueprint.Display.Mesh.LODs) > 0 then
                    for lodNum, lod in blueprint.Display.Mesh.LODs do
                        --Mesh for this LOD
                        if lodNum > 1 then
                            TableInsert(set.models, commonPath .. '_lod' .. (lodNum - 1) .. '.scm')
                        end

                        if lod.AlbedoName and lod.AlbedoName ~= "" then
                            TableInsert(set.d3d_textures, lod.AlbedoName)
                        end

                        if lod.SpecularName and lod.SpecularName ~= "" then
                            TableInsert(set.d3d_textures, lod.SpecularName)
                        end
                    end
                end

                -- preload tarmacs of units
                -- if blueprint.Display.Tarmacs then
                --     for k = 1, table.getn(blueprint.Display.Tarmacs) do
                --         local tarmac = blueprint.Display.Tarmacs[k]

                --         if tarmac.Albedo and tarmac.Albedo != "" and not PrefetchInfo.TarmacCache[tarmac.Albedo] then
                --             TableInsert(set.d3d_textures, tarmac.Albedo)
                --             PrefetchInfo.TarmacCache[tarmac.Albedo] = true
                --         end

                --         if tarmac.Glow and tarmac.Glow != "" and not PrefetchInfo.TarmacCache[tarmac.Glow]  then
                --             TableInsert(set.d3d_textures, tarmac.Glow)
                --             PrefetchInfo.TarmacCache[tarmac.Glow] = true
                --         end

                --         if tarmac.Normal and tarmac.Normal != "" and not PrefetchInfo.TarmacCache[tarmac.Normal]  then
                --             TableInsert(set.d3d_textures, tarmac.Normal)
                --             PrefetchInfo.TarmacCache[tarmac.Normal] = true
                --         end
                --     end
                -- end

                unitCache[id] = true
            end
        end

    end

    local count = 0
    count = count + table.getsize(set.d3d_textures)
    count = count + table.getsize(set.batch_textures)
    count = count + table.getsize(set.models)
    count = count + table.getsize(set.anims)
    SPEW(string.format("Prefetching %d files", count))

    return set
end
