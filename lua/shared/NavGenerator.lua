

---@class NavProfileData
---@field TimeSetupCaches number
---@field TimeLabelTrees number

---@class NavLayerDataInstance
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

colors = {
    land = '00ff00',
    naval = '0000ff',
    amph = 'ffa500',
    hover = '008080'
}
