local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local GameMain = import("/lua/ui/game/gamemain.lua")

local gameParent = false
mapSplitState = false

controls = {
-- general controls
    borderGroup = false,
    
-- controls returned to outline the size of certain areas
    statusClusterGroup = false,
    controlClusterGroup = false,
    mapGroup = false,
    mapGroupLeft = false,
    mapGroupRight = false,
    
-- these bits make up the control regions
    bottom = false,
    left = false,
    right = false,
    top = false,
    
-- these bits are on top of the map
    bottomOS = false,
    bottomLeftOS = false,
    bottomRightOS = false,
    leftOS = false,
    rightOS = false,
    topOS = false,
    topLeftOS = false,
    topRightOS = false
}

function HideBorder(hide)
    if controls.borderGroup then controls.borderGroup:SetHidden(hide) end
end

function CreateControls()
    if not controls.top then controls.top = Bitmap(controls.borderGroup) end
    if not controls.statusClusterGroup then controls.statusClusterGroup = Group(controls.borderGroup, "statusClusterGroup") end
    if not controls.left then controls.left = Bitmap(controls.borderGroup) end
    if not controls.controlClusterGroup then controls.controlClusterGroup = Group(controls.borderGroup, "controlClusterGroup") end
    if not controls.windowGroup then controls.windowGroup = Group(gameParent, "windowArea") end
    if not controls.bottom then controls.bottom = Bitmap(controls.borderGroup) end
    if not controls.right then controls.right = Bitmap(controls.borderGroup) end 
    if not controls.mapGroup then controls.mapGroup = Group(gameParent, "mapGroup") end 
    if not controls.bottomLeftOS then controls.bottomLeftOS = Bitmap(controls.borderGroup) end
    if not controls.bottomRightOS then controls.bottomRightOS = Bitmap(controls.borderGroup) end
    if not controls.topLeftOS then controls.topLeftOS = Bitmap(controls.borderGroup) end
    if not controls.topRightOS then controls.topRightOS = Bitmap(controls.borderGroup) end
    if not controls.bottomOS then controls.bottomOS = Bitmap(controls.borderGroup) end
    if not controls.topOS then controls.topOS = Bitmap(controls.borderGroup) end
    if not controls.leftOS then controls.leftOS = Bitmap(controls.borderGroup) end
    if not controls.rightOS then controls.rightOS = Bitmap(controls.borderGroup) end
    controls.controlClusterGroup.Depth:Set(10)
    controls.statusClusterGroup.Depth:Set(10)
    LayoutHelpers.Reset(controls.controlClusterGroup)
    LayoutHelpers.Reset(controls.statusClusterGroup)
    LayoutHelpers.Reset(controls.mapGroup)
    LayoutHelpers.Reset(controls.windowGroup)
end

function SetLayout(layout)
    if not gameParent then 
        WARN("gameParent not set in borders:SetLayout") 
    end

    if not controls.borderGroup then
        controls.borderGroup = Group(gameParent, "borderGroup")
    end
    controls.borderGroup.Left:Set(0)
    controls.borderGroup.Right:Set(0)
    controls.borderGroup.Width:Set(0)
    controls.borderGroup.Height:Set(0)

    CreateControls()
    import(UIUtil.GetLayoutFilename('borders')).SetLayout(gameParent)
end

function SetupBorderControl(parent)
    gameParent = parent
   
    SetLayout(UIUtil.currentLayout)
     
    return controls.controlClusterGroup, controls.statusClusterGroup, controls.mapGroup, controls.windowGroup
end

function GetMapGroup(NeedPrimary)
    if controls.mapGroupLeft and NeedPrimary then
        return controls.mapGroupLeft
    else
        return controls.mapGroup
    end
end

function SplitMapGroup(splitState, forceSplit)
    if GetCurrentUIState() != "game" then 
        return 
    end
    
    if not forceSplit then
        if import("/lua/ui/game/worldview.lua").IsInputLocked() or GameMain.gameUIHidden then
            return
        end
    end
    
    import("/lua/ui/game/tracking.lua").ClearModeText()
    SelectUnits(nil)
    
    mapSplitState = splitState
    if splitState then
        if not controls.mapGroupLeft then
            controls.mapGroupLeft = Group(gameParent, "mapGroupLeft")
        end
        
        if not controls.mapGroupRight then
            controls.mapGroupRight = Group(gameParent, "mapGroupRight")
        end
        
        if not controls.mapGroup then
            controls.mapGroup = Group(gameParent, "mapGroup")
        end
        
        import("/lua/ui/game/worldview.lua").CreateMainWorldView(gameParent, controls.mapGroupLeft, controls.mapGroupRight)
    else
        if not controls.mapGroup then
            controls.mapGroup = Group(gameParent, "mapGroup")
        end
        
        import("/lua/ui/game/worldview.lua").CreateMainWorldView(gameParent, controls.mapGroup)
    end
    SetLayout()
end