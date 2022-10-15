

---@class NavProfileData
---@field TimeSetupCaches number
---@field TimeLabelTrees number

---@class NavLayerDataInstance
---@field Trees number
---@field Subdivisions number
---@field PathableLeafs number
---@field UnpathableLeafs number

---@class NavLayerData
---@field land NavLayerDataInstance
---@field naval NavLayerDataInstance
---@field amph NavLayerDataInstance
---@field hover NavLayerDataInstance

---@alias NavLayers 'land' | 'naval' | 'amph' | 'hover'

Layers = {
    'land',
    'naval',
    'amph',
    'hover'
}