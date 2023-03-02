local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
function SetLayout(gameParent)
    local controls = import("/lua/ui/game/borders.lua").controls

    controls.bottom:Destroy()
    controls.top:Destroy()
    controls.left:Destroy()
    controls.right:Destroy()
    controls.bottomLeftOS:Destroy()
    controls.bottomRightOS:Destroy()
    controls.topLeftOS:Destroy()
    controls.topRightOS:Destroy()
    controls.bottomOS:Destroy()
    controls.topOS:Destroy()
    controls.leftOS:Destroy()
    controls.rightOS:Destroy()

    controls.bottom = false
    controls.top = false
    controls.left = false
    controls.right = false
    controls.bottomLeftOS = false
    controls.bottomRightOS = false
    controls.topLeftOS = false
    controls.topRightOS = false
    controls.bottomOS = false
    controls.topOS = false
    controls.leftOS = false
    controls.rightOS = false

    controls.controlClusterGroup.Left:Set(gameParent.Left)
    controls.controlClusterGroup.Bottom:Set(gameParent.Bottom)
    LayoutHelpers.AnchorToBottom(controls.controlClusterGroup, controls.statusClusterGroup)
    LayoutHelpers.AnchorToLeft(controls.controlClusterGroup, gameParent, -150)
    controls.controlClusterGroup:SetRenderPass(UIUtil.UIRP_PostGlow)
    controls.controlClusterGroup:DisableHitTest()

    controls.statusClusterGroup.Left:Set(gameParent.Left)
    controls.statusClusterGroup.Top:Set(gameParent.Top)
    controls.statusClusterGroup.Right:Set(gameParent.Right)
    LayoutHelpers.SetHeight(controls.statusClusterGroup, controls.statusClusterGroup.Top() + 150)
    controls.statusClusterGroup:DisableHitTest()
    controls.statusClusterGroup:DisableHitTest()

    controls.mapGroup.Left:Set(gameParent.Left)
    controls.mapGroup.Top:Set(gameParent.Top)
    controls.mapGroup.Right:Set(gameParent.Right)
    controls.mapGroup.Bottom:Set(gameParent.Bottom)
    controls.mapGroup:DisableHitTest()

    LayoutHelpers.FillParent(controls.windowGroup, gameParent)
    controls.windowGroup:DisableHitTest()

    controls.controlClusterGroup:DisableHitTest()
    controls.statusClusterGroup:DisableHitTest()
    controls.mapGroup:DisableHitTest()

    if controls.mapGroupLeft then
        controls.mapGroupLeft.Left:Set(gameParent.Left)
        controls.mapGroupLeft.Top:Set(gameParent.Top)
        controls.mapGroupLeft.Right:Set(function() return (gameParent.Left() - 3) + ((gameParent.Right() - gameParent.Left()) / 2) end)
        controls.mapGroupLeft.Bottom:Set(gameParent.Bottom)

        controls.mapGroupRight.Left:Set(function() return (gameParent.Left() + 3) + ((gameParent.Right() - gameParent.Left()) / 2) end)
        controls.mapGroupRight.Top:Set(gameParent.Top)
        controls.mapGroupRight.Right:Set(gameParent.Right)
        controls.mapGroupRight.Bottom:Set(gameParent.Bottom)

        controls.mapGroup.Left:Set(controls.mapGroupLeft.Left)
        controls.mapGroup.Top:Set(controls.mapGroupLeft.Top)
        controls.mapGroup.Right:Set(controls.mapGroupRight.Right)
        controls.mapGroup.Bottom:Set(controls.mapGroupLeft.Bottom)
    else
        controls.mapGroup.Left:Set(gameParent.Left)
        controls.mapGroup.Top:Set(gameParent.Top)
        controls.mapGroup.Right:Set(gameParent.Right)
        controls.mapGroup.Bottom:Set(gameParent.Bottom)
    end
end