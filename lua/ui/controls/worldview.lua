#*****************************************************************************
#* File: lua/modules/ui/controls/worldview.lua
#* Summary: World view control
#*
#* Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
#*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Control = import('/lua/maui/control.lua').Control
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Group = import('/lua/maui/group.lua').Group
local Dragger = import('/lua/maui/dragger.lua').Dragger
local Ping = import('/lua/ui/game/ping.lua')
local UserDecal = import('/lua/user/UserDecal.lua').UserDecal
local WorldViewMgr = import('/lua/ui/game/worldview.lua')
local Prefs = import('/lua/user/prefs.lua')
local OverchargeCanKill = import('/lua/ui/game/unitview.lua').OverchargeCanKill

WorldViewParams = {
    ui_SelectTolerance = 7.0,
    ui_DisableCursorFixing = false,
    ui_ExtractSnapTolerance = 4.0,
    ui_MinExtractSnapPixels = 10,
    ui_MaxExtractSnapPixels = 1000,
}

local CommandDecals = {}

function OnStartCommandMode(command_mode, command_data)
    if command_mode == 'order' and DecalFunctions[command_data.name] then
        CommandDecals = DecalFunctions[command_data.name]()
    else
        CommandDecals = {}
    end
end

-- If all selected units with the SHOWATTACKRETICLE flag set are of the same type, return the weapon
-- table from their blueprint. Otherwise returns null.
local function GetSelectedWeaponsWithReticules(filterFunc)
    local selectedUnits = GetSelectedUnits()
    local bp = nil

    local weapons = {};

    for i, u in selectedUnits do
        if EntityCategoryContains(categories.SHOWATTACKRETICLE, u) then
            local bp = u:GetBlueprint()
            for k, v in bp.Weapon do
                if filterFunc(v) then
                    weapons[bp.BlueprintId] = v
                    break
                end
            end
        end
    end

    return weapons
end

--- A generic decal function that maximises the available DamageRadius values.
local function RadiusDecalFunction(filterFunc)
    local weapons = GetSelectedWeaponsWithReticules(filterFunc)

    -- The maximum damage radius of a selected missile weapon.
    local maxRadius = 0
    for _, w in weapons do
        if w.FixedSpreadRadius and w.FixedSpreadRadius > maxRadius then
            maxRadius = w.FixedSpreadRadius    
        elseif w.DamageRadius > maxRadius then
            maxRadius = w.DamageRadius
        end
    end

    if maxRadius > 0 then
        return {
            {
                texture = "/textures/ui/common/game/AreaTargetDecal/weapon_icon_small.dds",
                scale = maxRadius * 2
            }
        }
    end

    return false
end

--- Specialised decal function for nukes: draws the inner/outer radii separately.
local function NukeDecalFunc()
    local weapons = GetSelectedWeaponsWithReticules(
        function(w)
            return w.NukeWeapon
        end
)

    local inner = 0
    local outer = 0
    for _, w in weapons do

        if w.NukeOuterRingRadius > outer then
            outer = w.NukeOuterRingRadius
        end

        if w.NukeInnerRingRadius > inner then
            inner = w.NukeInnerRingRadius
        end
    end

    if inner > 0 and outer > 0 then
        local prefix = '/textures/ui/common/game/AreaTargetDecal/nuke_icon_'
        return {
            { texture = prefix .. 'outer.dds', scale = outer * 2 },
            { texture = prefix .. 'inner.dds', scale = inner* 2 }
        }
    end
end

local function TacticalDecalFunc()
    return RadiusDecalFunction(
        function(w)
            return w.WeaponCategory == 'Missile' and w.DamageRadius and not w.NukeWeapon
        end
)
end

local function AttackDecalFunc(mode)
    return RadiusDecalFunction(
        function(w)
            return w.ManualFire == false and w.WeaponCategory ~= 'Teleport' and w.WeaponCategory ~= "Death"
        end
)
end

local function OverchargeDecalFunc()
    return RadiusDecalFunction(
        function(w)
            return w.DamageType == 'Overcharge'
        end
    )
end

DecalFunctions = {
    RULEUCC_Attack = AttackDecalFunc,
    RULEUCC_Nuke = NukeDecalFunc,
    RULEUCC_Tactical = TacticalDecalFunc,
    RULEUCC_Overcharge = OverchargeDecalFunc
}

WorldView = Class(moho.UIWorldView, Control) {

    Cursor = nil,
    bMouseIn = false,
    EventRedirect = nil,
    _pingAnimationThreads = {},
    Decals = {},

    HandleEvent = function(self, event)
        if self.EventRedirect then
            return self.EventRedirect(self,event)
        end
        if event.Type == 'MouseEnter' or event.Type == 'MouseMotion' then
            self.bMouseIn = true
            if self.Cursor then
                if (self.LastCursor == nil) or (self.Cursor[1] != self.LastCursor[1]) then
                    self.LastCursor = self.Cursor
                    GetCursor():SetTexture(unpack(self.Cursor))
                end
            else
                GetCursor():Reset()
            end
        elseif event.Type == 'MouseExit' then
            self.bMouseIn = false
            GetCursor():Reset()
            self.LastCursor = nil
            self:ResetDecals()
        elseif event.Type == 'WheelRotation' then
            self.zoomed = true
        end

        return false
    end,

    ResetDecals = function(self)
        for _, d in self.Decals do
            d:Destroy()
        end
        self.Decals = {}
    end,

    OnUpdateCursor = function(self)
        local oldCursor = self.Cursor
        local command_mode, command_data = unpack(import('/lua/ui/game/commandmode.lua').GetCommandMode())

        if not command_mode then
            local units = GetSelectedUnits()
            local order = self:GetRightMouseButtonOrder()
            if self:HasHighlightCommand() then
                if self:ShowConvertToPatrolCursor() then
                    self.Cursor = {UIUtil.GetCursor("MOVE2PATROLCOMMAND")}
                else
                    self.Cursor = {UIUtil.GetCursor('HOVERCOMMAND')}
                end
            elseif (not order or order == 'RULEUCC_Move') and IsKeyDown(18) and units and table.getn(units) > 0 then
                local availableOrders,_,_ = GetUnitCommandData(units)
                for _, availOrder in availableOrders do
                    if (availOrder == 'RULEUCC_RetaliateToggle' and table.getn(EntityCategoryFilterDown(categories.MOBILE, units)) > 0)
                        or table.getn(EntityCategoryFilterDown(categories.ENGINEER - categories.POD, units)) > 0
                        or table.getn(EntityCategoryFilterDown(categories.FACTORY, units)) > 0 then

                        self.Cursor = {UIUtil.GetCursor('ATTACK_MOVE')}
                        break
                    end
                end
            else
                -- Don't show the move cursor as a right mouse button hightlight state
                if order and order ~= 'RULEUCC_Move' then
                    self.Cursor = {UIUtil.GetCursor(order)}
                else
                    self.Cursor = nil
                end

                -- Catches if there is no order, or if there is no cursor assigned to the order
                if not self.Cursor then
                    GetCursor():Reset()
                end
            end
        elseif command_mode == "order" then
            if self:ShowConvertToPatrolCursor() then
                self.Cursor = {UIUtil.GetCursor("MOVE2PATROLCOMMAND")}
            elseif command_data.name == "RULEUCC_Overcharge" then
                local canKill = OverchargeCanKill()
                if canKill == true then
                    self.Cursor = {UIUtil.GetCursor(command_data.name)}
                elseif canKill == false then
                    self.Cursor = {UIUtil.GetCursor("OVERCHARGE_ORANGE")}
                else
                    self.Cursor = {UIUtil.GetCursor("OVERCHARGE_GREY")}
                end
            else
                if command_data.cursor then
                    self.Cursor = {UIUtil.GetCursor(command_data.cursor)}
                else
                    self.Cursor = {UIUtil.GetCursor(command_data.name)}
                end
            end
        elseif command_mode == "build" then
            self.Cursor = {UIUtil.GetCursor('BUILD')}
        elseif command_mode == "ping" then
            self.Cursor = {UIUtil.GetCursor(command_data.cursor)}
        end

        if CommandDecals[1] and command_mode then
            local valid = GetValidAttackingUnits()
            if not valid then
                self.Cursor = {UIUtil.GetCursor('RULEUCC_Invalid')}
                self:ResetDecals()
            else
                for i, cd in CommandDecals do
                    if not self.Decals[i] then
                        self.Decals[i] = UserDecal()
                    end

                    local cursor_decal = self.Decals[i]
                    if cursor_decal.texture ~= cd.texture then
                        cursor_decal:SetTexture(cd.texture)
                        cursor_decal.texture = cd.texture
                    end

                    if cursor_decal.scale ~= cd.scale then
                        cursor_decal:SetScale(Vector(cd.scale, 1, cd.scale))
                        cursor_decal.scale = cd.scale
                    end

                    cursor_decal:SetPosition(GetMouseWorldPos())
                end
            end
        else
            self:ResetDecals()
        end

        if not (self.Cursor and oldCursor) or self.Cursor[1] ~= oldCursor[1] then
            self:ApplyCursor()
        end
    end,

    OnDestroy = function(self)
        self:ResetDecals()

        for i, v in self._pingAnimationThreads do
            if v then KillThread(v) end
        end
        if self._registered then
            WorldViewMgr.UnregisterWorldView(self)
        end
        Ping.UpdateMarker({Action = 'renew'})
    end,

    OnCommandDragBegin = function(self)
        local dragCommandCursor = {UIUtil.GetCursor("DRAGCOMMAND")}
        if (self.Cursor == nil) or (self.Cursor[1] != dragCommandCursor[1]) then
            self.Cursor = dragCommandCursor
            self:ApplyCursor()
        end
    end,

    OnCommandDragEnd = function(self)
        self:OnUpdateCursor()
    end,

    ApplyCursor = function(self)
        if self.Cursor and self.bMouseIn then
            GetCursor():SetTexture(unpack(self.Cursor))
        end
    end,

    DisplayPing = function(self, pingData)
        -- Flash the scoreboard faction icon for the ping owner to indicate the source.
        if not pingData.Marker and not pingData.Renew then
            -- Zero-based indices FTW...
            local pingOwnerIndex = pingData.Owner + 1

            -- The faction icon for the pingOwner.
            local toFlash

            -- Find the UI element we need to flash.
            local scoreBoardControls = import('/lua/ui/game/score.lua').controls
            for _, line in scoreBoardControls.armyLines or {} do
                if line.armyID == pingOwnerIndex then
                    toFlash = line.faction
                    break
                end
            end

            if toFlash then
                local flashesRemaining = 8
                local flashInterval = 0.4
                ForkThread(function()
                    -- Flash the icon the appropriate number of times.
                    while flashesRemaining > 0 do
                        toFlash:Hide()
                        WaitSeconds(flashInterval)
                        toFlash:Show()
                        WaitSeconds(flashInterval)

                        flashesRemaining = flashesRemaining - 1
                    end
                end)
            end
        end

        if not self:IsHidden() and pingData.Location then
            local coords = self:Project(Vector(pingData.Location[1], pingData.Location[2], pingData.Location[3]))
            if not pingData.Renew then
                local function PingRing(Lifetime)
                    local pingBmp = Bitmap(self, UIUtil.UIFile(pingData.Ring))
                    pingBmp.Left:Set(function() return self.Left() + coords.x - pingBmp.Width() / 2 end)
                    pingBmp.Top:Set(function() return self.Top() + coords.y - pingBmp.Height() / 2 end)
                    pingBmp:SetRenderPass(UIUtil.UIRP_PostGlow)
                    pingBmp:DisableHitTest()
                    pingBmp.Height:Set(0)
                    pingBmp.Width:Set(pingBmp.Height)
                    pingBmp.Time = 0
                    pingBmp.data = pingData
                    pingBmp:SetNeedsFrameUpdate(true)
                    pingBmp.OnFrame = function(ping, deltatime)
                        local camZoomedIn = true
                        if GetCamera(self._cameraName):GetTargetZoom() > ((GetCamera(self._cameraName):GetMaxZoom() - GetCamera(self._cameraName):GetMinZoom()) * .4) then
                            camZoomedIn = false
                        end
                        local coords = self:Project(Vector(ping.data.Location[1], ping.data.Location[2], ping.data.Location[3]))
                        ping.Left:Set(function() return self.Left() + coords.x - ping.Width() / 2 end)
                        ping.Top:Set(function() return self.Top() + coords.y - ping.Height() / 2 end)
                        ping.Height:Set(function() return ((ping.Time / Lifetime) * (self.Height()/4)) end)
                        ping:SetAlpha(math.max((1 - (ping.Time / Lifetime)), 0))
                        if not camZoomedIn then
                            ping.Width:Set(ping.Height)
                            LayoutHelpers.ResetRight(ping)
                            LayoutHelpers.ResetBottom(ping)
                            ping:SetTexture(UIUtil.UIFile(pingData.Ring))
                            ping:Show()
                        else
                            ping:Hide()
                        end
                        ping.Time = ping.Time + deltatime
                        if ping.data.Lifetime and ping.Time > Lifetime then
                            ping:SetNeedsFrameUpdate(false)
                            ping:Destroy()
                        end
                    end
                end
                table.insert(self._pingAnimationThreads, ForkThread(function()
                    local Arrow = false
                    if not self._disableMarkers then
                        Arrow = self:CreateCameraIndicator(self, pingData.Location, pingData.ArrowColor)
                    end
                    for count = 1, pingData.Lifetime do
                        PingRing(1)
                        WaitSeconds(.2)
                        PingRing(1)
                        WaitSeconds(1)
                    end
                    if Arrow then Arrow:Destroy() end
                end))
            end

            --If this ping is a marker, create the edit controls for it.
            if not self._disableMarkers and pingData.Marker then
                if not self.Markers then self.Markers = {} end
                if not self.Markers[pingData.Owner] then self.Markers[pingData.Owner] = {} end
                if self.Markers[pingData.Owner][pingData.ID] then
                    return
                end
                local PingGroup = Group(self, 'ping gruop')
                PingGroup.coords = coords
                PingGroup.data = pingData
                PingGroup.Marker = Bitmap(self, UIUtil.UIFile('/game/ping_marker/ping_marker-01.dds'))
                LayoutHelpers.AtCenterIn(PingGroup.Marker, PingGroup)
                PingGroup.Marker.TeamColor = Bitmap(PingGroup.Marker)
                PingGroup.Marker.TeamColor:SetSolidColor(PingGroup.data.Color)
                PingGroup.Marker.TeamColor.Height:Set(12)
                PingGroup.Marker.TeamColor.Width:Set(12)
                PingGroup.Marker.TeamColor.Depth:Set(function() return PingGroup.Marker.Depth() - 1 end)
                LayoutHelpers.AtCenterIn(PingGroup.Marker.TeamColor, PingGroup.Marker)

                PingGroup.Marker.HandleEvent = function(marker, event)
                    if event.Type == 'ButtonPress' then
                        if event.Modifiers.Right and event.Modifiers.Ctrl then
                            local data = {Action = 'delete', ID = PingGroup.data.ID, Owner = PingGroup.data.Owner}
                            Ping.UpdateMarker(data)
                        elseif event.Modifiers.Left then
                            PingGroup.Marker:DisableHitTest()
                            PingGroup:SetNeedsFrameUpdate(false)
                            marker.drag = Dragger()
                            local moved = false
                            GetCursor():SetTexture(UIUtil.GetCursor('MOVE_WINDOW'))
                            marker.drag.OnMove = function(dragself, x, y)
                                PingGroup.Left:Set(function() return  (x - (PingGroup.Width()/2)) end)
                                PingGroup.Top:Set(function() return  (y - (PingGroup.Marker.Height()/2)) end)
                                moved = true
                                dragself.x = x
                                dragself.y = y
                            end
                            marker.drag.OnRelease = function(dragself)
                                PingGroup:SetNeedsFrameUpdate(true)
                                if moved then
                                    PingGroup.NewPosition = true
                                    ForkThread(function()
                                        WaitSeconds(.1)
                                        local data = {Action = 'move', ID = PingGroup.data.ID, Owner = PingGroup.data.Owner}
                                        data.Location = UnProject(self, Vector2(dragself.x, dragself.y))
                                        for _, v in data.Location do
                                            local var = v
                                            if var != v then
                                                PingGroup.NewPosition = false
                                                return
                                            end
                                        end
                                        Ping.UpdateMarker(data)
                                    end)
                                end
                            end
                            marker.drag.OnCancel = function(dragself)
                                PingGroup:SetNeedsFrameUpdate(true)
                                PingGroup.Marker:EnableHitTest()
                            end
                            PostDragger(self:GetRootFrame(), event.KeyCode, marker.drag)
                            return true
                        end
                    end
                end

                PingGroup.BGMid = Bitmap(PingGroup, UIUtil.UIFile('/game/ping-info-panel/bg-mid.dds'))
                LayoutHelpers.AtCenterIn(PingGroup.BGMid, PingGroup, 17)
                PingGroup.BGMid.Depth:Set(function() return PingGroup.Marker.Depth() - 2 end)

                PingGroup.Name = UIUtil.CreateText(PingGroup, PingGroup.data.Name, 14, UIUtil.bodyFont)
                PingGroup.Name:DisableHitTest()
                PingGroup.Name:SetDropShadow(true)
                PingGroup.Name:SetColor('ff00cc00')
                LayoutHelpers.AtCenterIn(PingGroup.Name, PingGroup.BGMid)

                PingGroup.BGRight = Bitmap(PingGroup, UIUtil.UIFile('/game/ping-info-panel/bg-right.dds'))
                LayoutHelpers.AtVerticalCenterIn(PingGroup.BGRight, PingGroup.BGMid, 1)
                PingGroup.BGRight.Left:Set(function() return math.max(PingGroup.Name.Right(), PingGroup.BGMid.Right()) end)
                PingGroup.BGRight.Depth:Set(PingGroup.BGMid.Depth)

                PingGroup.BGLeft = Bitmap(PingGroup, UIUtil.UIFile('/game/ping-info-panel/bg-left.dds'))
                LayoutHelpers.AtVerticalCenterIn(PingGroup.BGLeft, PingGroup.BGMid, 1)
                PingGroup.BGLeft.Right:Set(function() return math.min(PingGroup.Name.Left(), PingGroup.BGMid.Left()) end)
                PingGroup.BGLeft.Depth:Set(PingGroup.BGMid.Depth)

                if PingGroup.Name.Width() > PingGroup.BGMid.Width() then
                    PingGroup.StretchLeft = Bitmap(PingGroup, UIUtil.UIFile('/game/ping-info-panel/bg-stretch.dds'))
                    LayoutHelpers.AtVerticalCenterIn(PingGroup.StretchLeft, PingGroup.BGMid, 1)
                    PingGroup.StretchLeft.Left:Set(PingGroup.BGLeft.Right)
                    PingGroup.StretchLeft.Right:Set(PingGroup.BGMid.Left)
                    PingGroup.StretchLeft.Depth:Set(function() return PingGroup.BGMid.Depth() - 1 end)

                    PingGroup.StretchRight = Bitmap(PingGroup, UIUtil.UIFile('/game/ping-info-panel/bg-stretch.dds'))
                    LayoutHelpers.AtVerticalCenterIn(PingGroup.StretchRight, PingGroup.BGMid, 1)
                    PingGroup.StretchRight.Left:Set(PingGroup.BGMid.Right)
                    PingGroup.StretchRight.Right:Set(PingGroup.BGRight.Left)
                    PingGroup.StretchRight.Depth:Set(function() return PingGroup.BGMid.Depth() - 1 end)
                end

                PingGroup.Height:Set(5)
                PingGroup.Width:Set(5)
                PingGroup.Left:Set(function() return PingGroup.coords.x - PingGroup.Height() / 2 end)
                PingGroup.Top:Set(function() return PingGroup.coords.y - PingGroup.Width() / 2 end)
                PingGroup:SetNeedsFrameUpdate(true)
                PingGroup.OnFrame = function(pinggrp, deltaTime)
                    pinggrp.coords = self:Project(Vector(PingGroup.data.Location[1], PingGroup.data.Location[2], PingGroup.data.Location[3]))
                    PingGroup.Left:Set(function() return self.Left() + (PingGroup.coords.x - PingGroup.Height() / 2) end)
                    PingGroup.Top:Set(function() return self.Top() + (PingGroup.coords.y - PingGroup.Width() / 2) end)
                    if pinggrp.NewPosition then
                        pinggrp:Hide()
                        pinggrp.Marker:Hide()
                        pinggrp.Name:Hide()
                    else
                        if pinggrp.Top() < self.Top() or pinggrp.Left() < self.Left() or pinggrp.Right() > self.Right() or pinggrp.Bottom() > self.Bottom() then
                            pinggrp:Hide()
                            pinggrp.Name:Hide()
                            pinggrp.Marker:Hide()
                        else
                            if self.PingVis then
                                pinggrp:Show()
                            end
                            pinggrp.Name:Show()
                            pinggrp.Marker:Show()
                        end
                    end
                end
                PingGroup:Hide()
                PingGroup:DisableHitTest()
                PingGroup.Marker:DisableHitTest()
                self.Markers[pingData.Owner][pingData.ID] = PingGroup
            end
        end
    end,

    UpdatePing = function(self, pingData)
        if pingData.Action == 'flush' and self.Markers then
            for ownerID, pingTable in self.Markers do
                for pingID, ping in pingTable do
                    ping.Name:Destroy()
                    ping.Marker:Destroy()
                    ping:Destroy()
                end
            end
            self.Markers = {}
        elseif not self._disableMarkers and self.Markers[pingData.Owner][pingData.ID] then
            if pingData.Action == 'delete' then
                self.Markers[pingData.Owner][pingData.ID].Name:Destroy()
                self.Markers[pingData.Owner][pingData.ID].Marker:Destroy()
                self.Markers[pingData.Owner][pingData.ID]:Destroy()
                self.Markers[pingData.Owner][pingData.ID] = nil
            elseif pingData.Action == 'move' then
                self.Markers[pingData.Owner][pingData.ID].data.Location = pingData.Location
                self.Markers[pingData.Owner][pingData.ID].NewPosition = false
                self.Markers[pingData.Owner][pingData.ID].Marker:EnableHitTest()
            elseif pingData.Action == 'rename' then
                self.Markers[pingData.Owner][pingData.ID].Name:SetText(pingData.Name)
                self.Markers[pingData.Owner][pingData.ID].data.Name = pingData.Name
            end
        end
    end,

    ShowPings = function(self, show)
        self.PingVis = show
        if not self:IsHidden() and self.Markers then
            for index, marks in self.Markers do
                for MarkID, controls in marks do
                    controls:SetHidden(not show)
                    if show then
                        controls.Marker:EnableHitTest()
                    else
                        controls.Marker:DisableHitTest()
                    end
                end
            end
        end
    end,

    CreateCameraIndicator = function(self, parent, location, color, stayOnScreen)
        local Arrow = Button(parent, UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_b_up.dds'),
                UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_b_down.dds'),
                UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_b_over.dds'),
                UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_b_up.dds'))
        Arrow.State = 'b'
        LayoutHelpers.AtCenterIn(Arrow, self)
        Arrow:SetNeedsFrameUpdate(true)
        Arrow.Depth:Set(parent:GetRootFrame():GetTopmostDepth() + 1)
        Arrow.Glow = Bitmap(Arrow, UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_glow.dds'))
        LayoutHelpers.AtCenterIn(Arrow.Glow, Arrow)
        Arrow.Glow:SetNeedsFrameUpdate(true)
        Arrow.Glow:SetAlpha(0)
        Arrow.Glow.time = 0
        Arrow.Glow:DisableHitTest()
        Arrow.Glow.OnFrame = function(glow, delta)
            if delta then
                glow.time = glow.time + math.pi * 0.05
                glow:SetAlpha(MATH_Lerp(math.sin(glow.time), -1.0, 1.0, 0.0, 0.5))
            end
        end
        Arrow.OnClick = function(arrow, modifiers)
            local currentCamSettings = GetCamera('WorldCamera'):SaveSettings()
            currentCamSettings.Focus = location
            GetCamera(self._cameraName):RestoreSettings(currentCamSettings)
        end
        Arrow.OnFrame = function(arrow, deltatime)
            local coords = self:Project(Vector(location[1], location[2], location[3]))
            local horzStr = ''
            local vertStr = ''
            if self.Left() + coords.x < self.Left() then
                horzStr = 'l'
                arrow.Left:Set(self.Left)
                LayoutHelpers.AtLeftIn(arrow.Glow, arrow, -10)
                LayoutHelpers.ResetRight(arrow.Glow)
                LayoutHelpers.ResetRight(arrow)
            elseif coords.x > self.Right() then
                horzStr = 'r'
                arrow.Right:Set(self.Right)
                LayoutHelpers.AtRightIn(arrow.Glow, arrow, -10)
                LayoutHelpers.ResetLeft(arrow.Glow)
                LayoutHelpers.ResetLeft(arrow)
            else
                arrow.Left:Set(function() return coords.x - arrow.Width() / 2 end)
                LayoutHelpers.AtHorizontalCenterIn(arrow.Glow, arrow)
                LayoutHelpers.ResetRight(arrow.Glow)
                LayoutHelpers.ResetRight(arrow)
            end
            if self.Top() + coords.y > self.Bottom() then
                vertStr = 't'
                arrow.Bottom:Set(self.Bottom)
                LayoutHelpers.AtBottomIn(arrow.Glow, arrow, -10)
                LayoutHelpers.ResetTop(arrow.Glow)
                LayoutHelpers.ResetTop(arrow)
            elseif coords.y < self.Top() then
                vertStr = 'b'
                arrow.Top:Set(self.Top)
                LayoutHelpers.AtTopIn(arrow.Glow, arrow, -10)
                LayoutHelpers.ResetBottom(arrow.Glow)
                LayoutHelpers.ResetBottom(arrow)
            else
                arrow.Top:Set(function() return coords.y - arrow.Height() / 2 end)
                LayoutHelpers.AtVerticalCenterIn(arrow.Glow, arrow)
                LayoutHelpers.ResetBottom(arrow.Glow)
                LayoutHelpers.ResetBottom(arrow)
            end
            if horzStr != '' or vertStr != '' then
                if arrow:IsHidden() then
                    arrow:Show()
                end
                if arrow.State != vertStr..horzStr then
                    arrow:SetTexture(UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_'..vertStr..horzStr..'_up.dds'))
                    arrow:SetNewTextures(UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_'..vertStr..horzStr..'_up.dds'),
                    UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_'..vertStr..horzStr..'_down.dds'),
                    UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_'..vertStr..horzStr..'_over.dds'),
                    UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_'..vertStr..horzStr..'_up.dds'))
                    arrow.State = vertStr..horzStr
                end
                if arrow:IsDisabled() then
                    arrow:Enable()
                end
            else
                if stayOnScreen then
                    if arrow.State != 't' then
                        arrow:SetTexture(UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_t_up.dds'))
                        arrow:SetNewTextures(UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_t_up.dds'),
                        UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_t_down.dds'),
                        UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_t_over.dds'),
                        UIUtil.UIFile('/game/ping_edge/ping_edge_'..color..'_t_up.dds'))
                        arrow.State = 't'
                    end
                else
                    if not arrow:IsHidden() then
                        arrow:Hide()
                    end
                end
                if not arrow:IsDisabled() then
                    arrow:Disable()
                end
            end
        end
        return Arrow
    end,

    Register = function(self, cameraName, disableMarkers, displayName, order)
        self._cameraName = cameraName
        self._disableMarkers = disableMarkers
        self._displayName = displayName
        self._order = order or 5
        self._registered = true
        WorldViewMgr.RegisterWorldView(self)
        if Prefs.GetFromCurrentProfile(cameraName.."_cartographic_mode") != nil then
            self:SetCartographic(Prefs.GetFromCurrentProfile(cameraName.."_cartographic_mode"))
        end
        if Prefs.GetFromCurrentProfile(cameraName.."_resource_icons") != nil then
            self:EnableResourceRendering(Prefs.GetFromCurrentProfile(cameraName.."_resource_icons"))
        end
        if GetCamera(self._cameraName) then
            GetCamera(self._cameraName):SetMaxZoomMult(import('/lua/ui/game/gamemain.lua').defaultZoom)
        end
    end,

    OnIconsVisible = function(self, areIconsVisible)
        -- called when strat icons are turned on/off
    end,
}
