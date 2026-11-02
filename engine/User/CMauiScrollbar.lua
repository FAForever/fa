---@meta

---@class moho.scrollbar_methods : moho.control_methods
local CMauiScrollbar = {}

--- Scrolls the attached control by pages. The engine calls the control's `ScrollLines`, not
--- `ScrollPages`, with `pages` as the delta
---@see moho.control_methods.ScrollLines # Receives the scroll
---@param pages number
function CMauiScrollbar:DoScrollPages(pages)
end

--- Scrolls the attached control by lines
---@see moho.control_methods.ScrollLines # Receives the scroll
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
---@see moho.control_methods.GetScrollValues # Called to size the thumb
---@see moho.control_methods.ScrollLines # Called to scroll by lines or pages
---@see moho.control_methods.ScrollSetTop # Called when the thumb is dragged
---@param scrollable Control
function CMauiScrollbar:SetScrollable(scrollable)
end

return CMauiScrollbar