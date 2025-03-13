local NinePatch = import("/lua/ui/controls/ninepatch.lua").NinePatch

-- A nine-patch without a background, useful for laying out around things. An eight-patch.
---@class Border : NinePatch
Border = ClassUI(NinePatch) {
    ---@param self Border
    ---@param parent Control
    ---@param topLeft LazyValue<FileName>
    ---@param topRight LazyValue<FileName>
    ---@param bottomLeft LazyValue<FileName>
    ---@param bottomRight LazyValue<FileName>
    ---@param left LazyValue<FileName>
    ---@param right LazyValue<FileName>
    ---@param top LazyValue<FileName>
    ---@param bottom LazyValue<FileName>
    __init = function(self, parent, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom)
        NinePatch.__init(self, parent, nil, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom)
    end
}
