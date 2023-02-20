local NinePatch = import("/lua/ui/controls/ninepatch.lua").NinePatch

-- A nine-patch without a background, useful for laying out around things. An eight-patch.
---@class Border : NinePatch
Border = ClassUI(NinePatch) {
    ---@param self Border
    ---@param parent Control
    ---@param topLeft Lazy<FileName>
    ---@param topRight Lazy<FileName>
    ---@param bottomLeft Lazy<FileName>
    ---@param bottomRight Lazy<FileName>
    ---@param left Lazy<FileName>
    ---@param right Lazy<FileName>
    ---@param top Lazy<FileName>
    ---@param bottom Lazy<FileName>
    __init = function(self, parent, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom)
        NinePatch.__init(self, parent, nil, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom)
    end
}
