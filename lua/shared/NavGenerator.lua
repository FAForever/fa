
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

---@class NavDebugPathToState
---@field Origin Vector 
---@field Destination Vector 
---@field Layer NavLayers

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
    local r = string.format("%x", math.mod(math.sin(label) * 256 + 512, 256) ^ 0)
    local g = string.format("%x", math.mod(math.sin(label + 2) * 256 + 512, 256) ^ 0)
    local b = string.format("%x", math.mod(math.cos(label) * 256 + 512, 256) ^ 0)

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
