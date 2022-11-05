
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Combo = import("/lua/ui/controls/combo.lua").Combo
local IntegerSlider = import("/lua/maui/slider.lua").IntegerSlider

function CreateControls(controls)
    if not controls.bg then
        controls.bg = Bitmap(controls.controlClusterGroup)
    end
    if not controls.armycombo then
        controls.armycombo = Combo(controls.bg)
    end
    if not controls.speedSlider then
        controls.speedSlider = IntegerSlider(controls.bg, false, -10, 10, 1, 
            UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'), 
            UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'), 
            UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'), 
            UIUtil.SkinnableFile('/dialogs/options/slider-back_bmp.dds'))    
    end
    if not controls.currentSpeed then
        controls.currentSpeed = UIUtil.CreateText(controls.speedSlider, "", 12)
    end
end

function SetLayout()
    CreateControls(import("/lua/ui/game/replay.lua").controls)
    
    local controls = import("/lua/ui/game/replay.lua").controls
    
    controls.bg:SetTexture(UIUtil.SkinnableFile('/game/replay/panel_bmp.dds'))
    LayoutHelpers.AtLeftIn(controls.bg, controls.controlClusterGroup, 6)
    LayoutHelpers.AtBottomIn(controls.bg, controls.controlClusterGroup, -3)
    LayoutHelpers.ResetRight(controls.bg)
    LayoutHelpers.ResetTop(controls.bg)
    
    controls.armycombo.Left:Set(function() return controls.bg.Left() + 10 end)
    controls.armycombo.Top:Set(function() return controls.bg.Top() + 10 end)
    controls.armycombo.Width:Set(140)
    controls.armycombo.Height:Set(20)
        
    controls.speedSlider.Left:Set(function() return controls.bg.Left() + 10 end)
    controls.speedSlider.Right:Set(function() return controls.bg.Right() - 40 end)
    controls.speedSlider.Top:Set(function() return controls.bg.Bottom() - 40 end)
    controls.speedSlider._background.Left:Set(controls.speedSlider.Left)
    controls.speedSlider._background.Right:Set(controls.speedSlider.Right)
    controls.speedSlider._background.Top:Set(controls.speedSlider.Top)
    controls.speedSlider._background.Bottom:Set(controls.speedSlider.Bottom)
    
    LayoutHelpers.RightOf(controls.currentSpeed, controls.speedSlider)
end