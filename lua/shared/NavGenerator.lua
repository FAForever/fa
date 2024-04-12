
---@alias NavLayers 'Land' | 'Water' | 'Amphibious' | 'Hover' | 'Air'

---@type NavLayers[]
Layers = {
    'Land', 'Water', 'Amphibious', 'Hover', 'Air'
}

LayerColors = {
    Land = '00ff00',
    Water = '0000ff',
    Amphibious = 'ffa500',
    Hover = '008080',
    Air = 'add8e6'
}

---@class NavDebugGetLabelState
---@field Position Vector 
---@field Layer NavLayers

---@class NavDebugGetLabelMetadataState
---@field Id number

---@class NavDebugPathToState
---@field Origin Vector 
---@field Destination Vector 
---@field Layer NavLayers

---@class NavDebugPathToStateWithThreatThreshold
---@field Origin Vector 
---@field Destination Vector 
---@field Layer NavLayers
---@field Radius number
---@field Threshold number
---@field ThreatFunctionName AIThreatFunctionNames
---@field Army Army

---@class NavDebugCanPathToState
---@field Origin Vector 
---@field Destination Vector 
---@field Layer NavLayers

---@class NavLayerDataInstance
---@field Subdivisions number
---@field PathableLeafs number
---@field UnpathableLeafs number
---@field Neighbors number
---@field Labels number

---@class NavLayerData
---@field Land NavLayerDataInstance
---@field Naval NavLayerDataInstance
---@field Amph NavLayerDataInstance
---@field Hover NavLayerDataInstance
---@field Air NavLayerDataInstance

---@return NavLayerData
function CreateEmptyNavLayerData()
    return {
        Land = {
            Subdivisions = 0,
            PathableLeafs = 0,
            UnpathableLeafs = 0,
            Neighbors = 0,
            Labels = 0
        },
        Amphibious = {
            Subdivisions = 0,
            PathableLeafs = 0,
            UnpathableLeafs = 0,
            Neighbors = 0,
            Labels = 0
        },
        Hover = {
            Subdivisions = 0,
            PathableLeafs = 0,
            UnpathableLeafs = 0,
            Neighbors = 0,
            Labels = 0
        },
        Water = {
            Subdivisions = 0,
            PathableLeafs = 0,
            UnpathableLeafs = 0,
            Neighbors = 0,
            Labels = 0
        },
        Air = {
            Subdivisions = 0,
            PathableLeafs = 0,
            UnpathableLeafs = 0,
            Neighbors = 0,
            Labels = 0
        }
    }
end

---@return NavProfileData
function CreateEmptyProfileData()
    return {
        TimeSetupCaches = 0,
        TimeLabelTrees = 0,
    }
end

--- Converts a label to a color, used for debugging
---@param label number
---@return string
function LabelToColor(label)
    if label == -1 then
        return 'ff0000'
    end

    local r = string.format("%x", math.floor(math.mod(math.sin(label) * 256 + 512, 256)))
    local g = string.format("%x", math.floor(math.mod(math.sin(label + 2) * 256 + 512, 256)))
    local b = string.format("%x", math.floor(math.mod(math.cos(label) * 256 + 512, 256)))

    if string.len(r) == 1 then
        r = '0' .. r
    end

    if string.len(g) == 1 then
        g = '0' .. g
    end

    if string.len(b) == 1 then
        b = '0' .. b
    end

    return r .. g .. b
end

---@alias AIThreatFunctionNames
--- | 'AntiSurface' 
--- | 'AntiAir'
--- | 'MobileAntiSurface'
--- | 'StructureAntiSurface'
--- | 'Land'
--- | 'Air' 
--- | 'Naval'

---@type table<AIThreatFunctionNames, fun(aiBrain: AIBrain, position: Vector, radius: number) : number>
ThreatFunctions = {
    ---@param aibrain AIBrain
    ---@param position Vector
    ---@param radius number
    Land = function(aibrain, position, radius)
        return aibrain:GetThreatAtPosition(position, radius, true, 'Land')
    end,

    ---@param aibrain AIBrain
    ---@param position Vector
    ---@param radius number
    Air = function(aibrain, position, radius)
        return aibrain:GetThreatAtPosition(position, radius, true, 'Air')
    end,

    ---@param aibrain AIBrain
    ---@param position Vector
    ---@param radius number
    Naval = function(aibrain, position, radius)
        return aibrain:GetThreatAtPosition(position, radius, true, 'Naval')
    end,

    ---@param aibrain AIBrain
    ---@param position Vector
    ---@param radius number
    AntiSurface = function(aibrain, position, radius)
        return aibrain:GetThreatAtPosition(position, radius, true, 'AntiSurface')
    end,

    ---@param aibrain AIBrain
    ---@param position Vector
    ---@param radius number
    AntiSub = function(aibrain, position, radius)
        return aibrain:GetThreatAtPosition(position, radius, true, 'AntiSub')
    end,

    ---@param aibrain AIBrain
    ---@param position Vector
    ---@param radius number
    AntiAir = function(aibrain, position, radius)
        return aibrain:GetThreatAtPosition(position, radius, true, 'AntiAir')
    end,

    ---@param aibrain AIBrain
    ---@param position Vector
    ---@param radius number
    MobileAntiSurface = function(aibrain, position, radius)
        local antiSurface = aibrain:GetThreatAtPosition(position, radius, true, 'AntiSurface')
        local structure = aibrain:GetThreatAtPosition(position, radius, true, 'Structures')
        local economic = aibrain:GetThreatAtPosition(position, radius, true, 'Economy')

        return antiSurface - (structure - economic)
    end,

    ---@param aibrain AIBrain
    ---@param position Vector
    ---@param radius number
    StructureAntiSurface = function(aibrain, position, radius)
        local antiSurface = aibrain:GetThreatAtPosition(position, radius, true, 'AntiSurface')
        local land = aibrain:GetThreatAtPosition(position, radius, true, 'Land')
        local air = aibrain:GetThreatAtPosition(position, radius, false, 'Air')

        return antiSurface - (land + air)
    end,
}

-- list of the available threat functions for the debug UI
---@type AIThreatFunctionNames[]
ThreatFunctionsList = table.keys(ThreatFunctions)