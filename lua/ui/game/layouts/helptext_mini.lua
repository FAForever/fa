
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
function SetLayout()
    local controls = import("/lua/ui/game/helptext.lua").controls
local worldView = import("/lua/ui/game/borders.lua").GetMapGroup()
    LayoutHelpers.AtHorizontalCenterIn(controls.helpIcon, worldView)
    controls.helpIcon.Top:Set(function() return worldView.Bottom() - 200 end)
end