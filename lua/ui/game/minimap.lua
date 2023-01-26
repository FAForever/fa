--*****************************************************************************
--* File: lua/modules/ui/game/multifunction.lua
--* Author: Chris Blackwell
--* Summary: UI for the multifunction display
--*
--* Copyright  2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local Button = import("/lua/maui/button.lua").Button
local Text = import("/lua/maui/text.lua").Text
local Tooltip = import("/lua/ui/game/tooltip.lua")
local Window = import("/lua/maui/window.lua").Window
local Prefs = import("/lua/user/prefs.lua")

local minimap = Prefs.GetFromCurrentProfile('stratview') or false
local minimap_resources = Prefs.GetFromCurrentProfile('MiniMap_resource_icons') or false

controls = {
    displayGroup = false,
    miniMap = false,
}

function SetLayout(layout)
    import(UIUtil.GetLayoutFilename('minimap')).SetLayout()
end

function CommonLogic()
    local controlMap = {
        tl = {controls.miniMap.DragTL},
        tr = {controls.miniMap.DragTR},
        bl = {controls.miniMap.DragBL},
        br = {controls.miniMap.DragBR},
        mr = {controls.miniMap.DragBR,controls.miniMap.DragTR},
        ml = {controls.miniMap.DragBL,controls.miniMap.DragTL},
        tm = {controls.miniMap.DragTL,controls.miniMap.DragTR},
        bm = {controls.miniMap.DragBL,controls.miniMap.DragBR},
    }

    controls.displayGroup.RolloverHandler = function(control, event, xControl, yControl, cursor, controlID)
        if controls.displayGroup._lockSize then return end
        local styles = import("/lua/maui/window.lua").styles
        if not controls.displayGroup._sizeLock then
            if event.Type == 'MouseEnter' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        control:SetTexture(control.textures.over)
                    end
                end
                GetCursor():SetTexture(styles.cursorFunc(cursor))
            elseif event.Type == 'MouseExit' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        control:SetTexture(control.textures.up)
                    end
                end
                GetCursor():Reset()
            elseif event.Type == 'ButtonPress' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        control:SetTexture(control.textures.down)
                    end
                end
                controls.displayGroup.StartSizing(event, xControl, yControl)
                controls.displayGroup._sizeLock = true
            end
        end
    end

    controls.displayGroup.OnResizeSet = function(control)
        controls.miniMap.DragTL:SetTexture(controls.miniMap.DragTL.textures.up)
        controls.miniMap.DragTR:SetTexture(controls.miniMap.DragTR.textures.up)
        controls.miniMap.DragBL:SetTexture(controls.miniMap.DragBL.textures.up)
        controls.miniMap.DragBR:SetTexture(controls.miniMap.DragBR.textures.up)
    end

    controls.displayGroup.OnDestroy = function(self)
        controls.miniMap = false
        Window.OnDestroy(self)
    end
    controls.displayGroup.OnClose = function(self)
        ToggleMinimap()
        import("/lua/ui/game/multifunction.lua").UpdateMinimapState()
    end
    if not minimap then
        controls.displayGroup:Hide()
    end
end

function CreateMinimap(parent)
    controls.savedParent = parent

    local windowTextures = {
        tl = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_ul.dds'),
        tr = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_ur.dds'),
        tm = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_horz_um.dds'),
        ml = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_vert_l.dds'),
        m = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_m.dds'),
        mr = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_vert_r.dds'),
        bl = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_ll.dds'),
        bm = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_lm.dds'),
        br = UIUtil.UIFile('/game/mini-map-brd/mini-map_brd_lr.dds'),
        borderColor = 'ff415055',
    }
    local defPosition = {Left = 10, Top = 157, Bottom = 367, Right = 237}
    controls.displayGroup = Window(GetFrame(0), nil, nil, true, false, false, false, 'mini_ui_minimap',
        defPosition, windowTextures)
    controls.displayGroup.Depth:Set(4)
    controls.displayGroup.window_m:SetRenderPass(UIUtil.UIRP_UnderWorld)
    controls.displayGroup:SetMinimumResize(150, 150)
    ConExecute("cam_DefaultMiniLOD 1.8") -- make sure minimap is created with normal LOD value as we change it later
    controls.miniMap = import("/lua/ui/controls/worldview.lua").WorldView(controls.displayGroup:GetClientGroup(), 'MiniMap', 2, true, 'WorldCamera')    -- depth value is above minimap
    controls.miniMap:SetName("Minimap")
    controls.miniMap:Register('MiniMap', true, '<LOC map_view_0001>MiniMap', 1)
    controls.miniMap:SetCartographic(true)
    controls.miniMap:SetRenderPass(UIUtil.UIRP_UnderWorld) -- don't change this or the camera will lag one frame behind
    controls.miniMap.Depth:Set(controls.displayGroup.Depth)
    controls.miniMap:SetNeedsFrameUpdate(true)
    -- defer the camera reset one frame so a view is created, this causes a fully zoomed out map
    local frameCount = 0
    controls.miniMap.OnFrame = function(self, elapsedTime)
        if frameCount == 1 then
            self:EnableResourceRendering(minimap_resources)
            self:CameraReset()
            GetCamera(self._cameraName):SetMaxZoomMult(1.0)
            self.OnFrame = nil  -- we want the control to continue to get frame updates in the engine, but not in Lua. PLEASE DON'T CHANGE THIS OR IT BREAKS CAMERA DRAGGING
        end
        frameCount = frameCount + 1
    end
    controls.displayGroup.OnPinCheck = function(control, checked)
        control:SetSizeLock(checked)
        control:SetPositionLock(checked)
        -- add save pin in prefs
    end
    Tooltip.AddCheckboxTooltip(controls.displayGroup._pinBtn, 'minimap_pin')

    controls.displayGroup.resetBtn = Button(controls.displayGroup.TitleGroup,
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_up.dds'),
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_down.dds'),
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_over.dds'),
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_dis.dds'))
    LayoutHelpers.LeftOf(controls.displayGroup.resetBtn, controls.displayGroup._pinBtn )
    controls.displayGroup.resetBtn.OnClick = function(self, modifiers)
        for index, val in defPosition do
            local i = index
            local v = val
            controls.displayGroup[i]:Set(v)
        end
        controls.displayGroup:SaveWindowLocation()
    end
    Tooltip.AddButtonTooltip(controls.displayGroup.resetBtn, 'minimap_reset')

    controls.miniMap.GlowTL = Bitmap(controls.miniMap)
    controls.miniMap.GlowTR = Bitmap(controls.miniMap)
    controls.miniMap.GlowBR = Bitmap(controls.miniMap)
    controls.miniMap.GlowBL = Bitmap(controls.miniMap)
    controls.miniMap.GlowL = Bitmap(controls.miniMap)
    controls.miniMap.GlowR = Bitmap(controls.miniMap)
    controls.miniMap.GlowT = Bitmap(controls.miniMap)
    controls.miniMap.GlowB = Bitmap(controls.miniMap)

    controls.miniMap.GlowTL.Depth:Set(controls.displayGroup.Depth)
    controls.miniMap.GlowTR.Depth:Set(controls.displayGroup.Depth)
    controls.miniMap.GlowBR.Depth:Set(controls.displayGroup.Depth)
    controls.miniMap.GlowBL.Depth:Set(controls.displayGroup.Depth)
    controls.miniMap.GlowL.Depth:Set(controls.displayGroup.Depth)
    controls.miniMap.GlowR.Depth:Set(controls.displayGroup.Depth)
    controls.miniMap.GlowT.Depth:Set(controls.displayGroup.Depth)
    controls.miniMap.GlowB.Depth:Set(controls.displayGroup.Depth)

    controls.miniMap.DragTL = Bitmap(controls.miniMap, UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
    controls.miniMap.DragTR = Bitmap(controls.miniMap, UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
    controls.miniMap.DragBL = Bitmap(controls.miniMap, UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
    controls.miniMap.DragBR = Bitmap(controls.miniMap, UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))

    SetLayout(UIUtil.currentLayout)
    controls.displayGroup._windowGroup:DisableHitTest(true)
    controls.displayGroup.ClientGroup:DisableHitTest()
    controls.miniMap:EnableHitTest()
    CommonLogic()
    if Prefs.GetFromCurrentProfile('disableMinimapMesh') ~= false then
        ConExecute("cam_DefaultMiniLOD 0")
    end
end

function ToggleMinimap()
    ---- disable when in Screen Capture mode
    if import("/lua/ui/game/gamemain.lua").gameUIHidden then
        return
    end

    PlaySound(Sound({Bank = 'Interface', Cue = 'UI_Economy_Rollover'}))

    minimap = not minimap
    if minimap then
        controls.displayGroup:Show()
        SetLayout(UIUtil.currentLayout, true)
    else
        controls.displayGroup:Hide()
        SetLayout(UIUtil.currentLayout, true)
    end
    Prefs.SetToCurrentProfile('stratview', minimap)
end

function GetMinimapState()
    return not controls.displayGroup:IsHidden()
end

local preContractState = false

function Expand()
    controls.displayGroup:SetHidden(preContractState)
end

function Contract()
    preContractState = controls.displayGroup:IsHidden()
    controls.displayGroup:Hide()
end