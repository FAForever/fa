local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group

function CreateUI()
    local mainFrame = GetFrame(0)
    local mainGroup = Group(mainFrame, "gpgnetgroup")
    LayoutHelpers.FillParentFixedBorder(mainGroup, mainFrame, 20)
end

