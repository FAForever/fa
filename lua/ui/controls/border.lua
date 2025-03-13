local NinePatch = import("/lua/ui/controls/ninepatch.lua").NinePatch

-- A nine-patch without a background, useful for laying out around things. An eight-patch.
---@class Border : NinePatch
Border = ClassUI(NinePatch) {
    ---@param self Border
    ---@param parent Control
    ---@param topLeft LazyOrValue<FileName>
    ---@param topRight LazyOrValue<FileName>
    ---@param bottomLeft LazyOrValue<FileName>
    ---@param bottomRight LazyOrValue<FileName>
    ---@param left LazyOrValue<FileName>
    ---@param right LazyOrValue<FileName>
    ---@param top LazyOrValue<FileName>
    ---@param bottom LazyOrValue<FileName>
    __init = function(self, parent, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom)
        NinePatch.__init(self, parent, nil, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom)
    end
}
