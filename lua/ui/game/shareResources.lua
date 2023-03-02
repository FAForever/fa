--*****************************************************************************
--* File: lua/modules/ui/game/shareResources.lua
--* Summary: UI for Sharing (and giving) Resources
--*
--* Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Slider = import("/lua/maui/slider.lua").Slider
local StatusBar = import("/lua/maui/statusbar.lua").StatusBar
local Edit = import("/lua/maui/edit.lua").Edit

local radWidth, radHeight = GetTextureDimensions(UIUtil.UIFile('/widgets/large-h_scr/bar-mid_scr_up.dds'))
local lradWidth, lradHeight = GetTextureDimensions(UIUtil.UIFile('/widgets/large-h_scr/bar-left_scr_up.dds'))
local rradWidth, rradHeight = GetTextureDimensions(UIUtil.UIFile('/widgets/large-h_scr/bar-right_scr_up.dds'))

-- creates the actual dialog
--- parent is the calling window
function createShareResourcesDialog(parent, targetPlayer, targetPlayerName)

    local massVal = 0
    local energyVal = 0

    local worldView = import("/lua/ui/game/worldview.lua").view
    local dialog = Bitmap(parent, UIUtil.UIFile('/dialogs/diplomacy-resources_options/diplomacy-panel_bmp.dds'))
    dialog:SetRenderPass(UIUtil.UIRP_PostGlow)  -- just in case our parent is the map
    dialog:SetName("Share Resources Window")
    LayoutHelpers.AtCenterIn(dialog, worldView)

    local chatTitle = UIUtil.CreateText(dialog, LOC("<LOC SHARERES_0000>Send Resources to ") .. targetPlayerName, 16, UIUtil.bodyFont)
    LayoutHelpers.AtLeftIn(chatTitle, dialog, 30)
    LayoutHelpers.AtTopIn(chatTitle, dialog, 25)
    
    local massIcon = Bitmap(dialog, UIUtil.UIFile('/dialogs/diplomacy-resources_options/mass_btn_up.dds'))
    massIcon.Left:Set(function() return dialog.Left() + 27 end)
    massIcon.Top:Set(function() return dialog.Top() + 60 end)

    local massInputContainer = Group(dialog)
    massInputContainer.Top:Set(function() return massIcon.Top() + 12 end)
    massInputContainer.Right:Set(function() return dialog.Right() - 40 end)
    massInputContainer.Height:Set(16)
    massInputContainer.Width:Set(80)
    
    local massInput = UIUtil.CreateText(dialog, "0%", 12, UIUtil.bodyFont)
    LayoutHelpers.AtCenterIn(massInput, massInputContainer)

    local massStatus = StatusBar(dialog, 0, 100, false, false,
        UIUtil.UIFile('/dialogs/diplomacy-resources_options/mass-bar-back_bmp.dds'),
        UIUtil.UIFile('/dialogs/diplomacy-resources_options/mass-bar_bmp.dds'), false)

    local massSlider = Slider(dialog, false, 0, 100,
        UIUtil.UIFile('/dialogs/slider_btn/mass-bar-edge_btn_up.dds'), 
        UIUtil.UIFile('/dialogs/slider_btn/mass-bar-edge_btn_up.dds'),
        UIUtil.UIFile('/dialogs/slider_btn/mass-bar-edge_btn_up.dds'))
    massSlider.Top:Set(function() return massIcon.Top() + 25 end)
    massSlider.Left:Set(function() return massIcon.Right() - 1 end)
    massSlider.Right:Set(function() return massInputContainer.Left() - 10 end)
    massSlider:SetValue( massVal )
    massSlider.OnValueChanged = function(self, newValue)
        massInput:SetText(string.format("%d%%", math.max(math.min(math.floor(newValue), 100), 0)))
        massStatus:SetValue(math.floor(newValue))
    end
    
    massStatus.Top:Set(function() return massIcon.Top() + 12 end)
    massStatus.Left:Set(function() return massIcon.Right()  end)
    massStatus.Right:Set(function() return massInputContainer.Left() - 12 end)
    massStatus.Depth:Set(function() return massSlider.Depth() - 1 end)
    local masswidth = massStatus.Width()
    massStatus:SetMinimumSlidePercentage(7/masswidth)
    massStatus:SetRange(0, 100)
    massStatus:SetValue( massVal )

    local energyIcon = Bitmap(dialog, UIUtil.UIFile('/dialogs/diplomacy-resources_options/energy_btn_up.dds'))
    energyIcon.Left:Set(function() return dialog.Left() + 27 end)
    energyIcon.Top:Set(function() return dialog.Top() + 140 end)

    local energyInputContainer = Group(dialog)
    energyInputContainer.Top:Set(function() return energyIcon.Top() + 12 end)
    energyInputContainer.Right:Set(function() return dialog.Right() - 40 end)
    energyInputContainer.Height:Set(16)
    energyInputContainer.Width:Set(80)
    
    local energyInput = UIUtil.CreateText(dialog, "0%", 12, UIUtil.bodyFont)
    LayoutHelpers.AtCenterIn(energyInput, energyInputContainer)

    local energyStatus = StatusBar(dialog, 0, 100, false, false,
        UIUtil.UIFile('/dialogs/diplomacy-resources_options/energy-bar-back_bmp.dds'),
        UIUtil.UIFile('/dialogs/diplomacy-resources_options/energy-bar_bmp.dds'), false)

    local energySlider = Slider(dialog, false, 0, 100,
        UIUtil.UIFile('/dialogs/slider_btn/energy-bar-edge_btn_up.dds'),
        UIUtil.UIFile('/dialogs/slider_btn/energy-bar-edge_btn_up.dds'),
        UIUtil.UIFile('/dialogs/slider_btn/energy-bar-edge_btn_up.dds'))
    energySlider.Top:Set(function() return energyIcon.Top() + 25 end)
    energySlider.Left:Set(function() return energyIcon.Right() - 1 end)
    energySlider.Right:Set(function() return energyInputContainer.Left() - 10 end)
    energySlider:SetValue( energyVal )
    energySlider.OnValueChanged = function(self, newValue)
        energyInput:SetText(string.format("%d%%", math.max(math.min(math.floor(newValue), 100), 0)))
        energyStatus:SetValue(math.floor(newValue))
    end

    energyStatus.Top:Set(function() return energyIcon.Top() + 12 end)
    energyStatus.Left:Set(function() return energyIcon.Right()  end)
    energyStatus.Right:Set(function() return energyInputContainer.Left() - 12 end)
    energyStatus.Depth:Set(function() return energySlider.Depth() - 1 end)
    energyStatus:SetMinimumSlidePercentage(7/masswidth)
    energyStatus:SetRange(0, 100)
    energyStatus:SetValue( energyVal )

    -- overriden by caller
    dialog.OnOk = function(mass,energy)
        
    end

    -- overriden by caller
    dialog.OnCancel = function()
        dialog:Destroy()
    end

    local cancelButton = UIUtil.CreateButtonStd(dialog, "/dialogs/standard_btn/standard", "<LOC _Cancel>", 12)
    LayoutHelpers.AtBottomIn(cancelButton, dialog, 20)
    LayoutHelpers.AtRightIn(cancelButton, dialog, 24)
    cancelButton.OnClick = function(self, modifiers)
        dialog.OnCancel()
    end

    local okButton = UIUtil.CreateButtonStd(dialog, "/dialogs/standard_btn/standard", "<LOC _OK>", 12)
    LayoutHelpers.LeftOf(okButton, cancelButton, 3)
    okButton.OnClick = function(self, modifiers)
        dialog.OnOk( massSlider:GetValue() / 100.0, energySlider:GetValue() / 100.0 )
    end
    
    dialog:Show()
    
    -- note this will only get called when the bg has input mode
    dialog.HandleEvent = function(self, event)
        if event.Type == 'KeyDown' then
            if event.KeyCode == UIUtil.VK_ESCAPE then
                cancelButton.OnClick(dialog.okButton)
            elseif event.KeyCode == UIUtil.VK_ENTER or event.KeyCode == 345 then
                okButton.OnClick(dialog.okButton)
            end
        end
    end
    AddInputCapture(dialog)
    dialog.OnDestroy = function(self)
        RemoveInputCapture(dialog)
    end
    
    return dialog
end