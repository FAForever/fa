---@param prop PropBlueprint
local function PostProcessProp(prop)

    prop.Categories = prop.Categories or {}

    prop.CategoriesHash = {}
    for k, category in prop.Categories do
        prop.CategoriesHash[category] = true
    end

    -- make invulnerable props actually invulnerable
    if prop.Categories then
        if table.find(prop.Categories, 'INVULNERABLE') then
            prop.ScriptClass = 'PropInvulnerable'
            prop.ScriptModule = '/lua/sim/prop.lua'
        end
    end

    -- an little bit of an odd hack to guarantee wrecks block construction sites. The file that wrecks use is here:
    -- - /props/DefaultWreckage/DefaultWreckage_prop.bp
    -- 
    -- but we do not distribute the `props` folder, which means that everything that is in there is ignored in production
    -- therefore we try and catch all wreck related props here
    if prop.ScriptClass == "Wreckage" and prop.ScriptModule == '/lua/wreckage.lua' then
        table.insert(prop.Categories, 'OBSTRUCTSBUILDING')
        prop.CategoriesHash['OBSTRUCTSBUILDING'] = true
    end

    -- check for props that should block pathing
    if not (prop.ScriptClass == "Tree" or prop.ScriptClass == "TreeGroup") and prop.CategoriesHash['RECLAIMABLE'] then
        if prop.Economy and prop.Economy.ReclaimMassMax and prop.Economy.ReclaimMassMax > 0 and not prop.CategoriesHash['OBSTRUCTSBUILDING'] then
            if not prop.CategoriesHash['OBSTRUCTSBUILDING'] then
                WARN("Prop is missing 'OBSTRUCTSBUILDING' category: " .. prop.BlueprintId)
            end
        end
    end
end

---@param props PropBlueprint[]
local function CreateUnreclaimableVersion(props, prop)
    ---@type PropBlueprint
    local staticProp = table.deepcopy(prop)

    -- update categories
    staticProp.CategoriesHash['GENERATED'] = true
    staticProp.CategoriesHash['RECLAIMABLE'] = nil
    staticProp.Categories = table.keys(staticProp.CategoriesHash)

    -- update blueprint id
    staticProp.BlueprintId = string.sub(prop.BlueprintId, 1, string.len(prop.BlueprintId) -3) .. '_generated.bp'

    -- add to the props we load in
    props[staticProp.BlueprintId] = staticProp
end

---@param allBlueprints BlueprintsTable
---@param prop PropBlueprint
local function CreateInvisblePropMesh(allBlueprints, prop)

    local meshid = prop.Display.MeshBlueprint
    if not meshid then
        return
    end

    local meshbp = allBlueprints.Mesh[meshid]
    if not meshbp then
        return
    end

    local mesh = table.deepcopy(meshbp)
    if mesh.LODs then
        for _, lod in mesh.LODs do
            lod.ShaderName = 'Invisible'
            lod.LODCutoff  = 1
        end
    end

    mesh.BlueprintId = prop.Display.MeshBlueprint .. '_invisible'
    MeshBlueprint(mesh)

    LOG("Created invisible blueprint mesh:", mesh.BlueprintId)

    -- keep track of the mesh blueprint
    prop.Display.MeshBlueprintInvisible = mesh.BlueprintId

end

--- Post-processes all props
---@param allBlueprints BlueprintsTable
---@param props PropBlueprint[]
function PostProcessProps(allBlueprints, props)
    for _, prop in props do
        PostProcessProp(prop)
    end

    local generatedProps = {}
    for _, prop in props do
        CreateUnreclaimableVersion(generatedProps, prop)
    end

    for _, prop in props do
        CreateInvisblePropMesh(allBlueprints, prop)
    end

    for id, blueprint in generatedProps do
        props[id] = blueprint
    end
end
