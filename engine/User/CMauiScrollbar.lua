---@meta

---@class moho.scrollbar_methods : moho.control_methods
local CMauiScrollbar = {}

---
---@param pages number
function CMauiScrollbar:DoScrollPages(pages)
end

---
---@param lines number
function CMauiScrollbar:DoScrollLines(lines)
end

---
---@param background string
---@param thumbMiddle string
---@param thumbTop string
---@param thumbBottom string
function CMauiScrollbar:SetNewTextures(background, thumbMiddle, thumbTop, thumbBottom)
end

--- Sets the scrollable object connected to this scrollbar
---@param scrollable Control
function CMauiScrollbar:SetScrollable(scrollable)
end

return CMauiScrollbar