---------------------------------------------------------------------
-- File: lua/modules/ui/controls/worldview.lua
-- Summary: World view control
-- Copyright © 2008 Gas Powered Games, Inc.  All rights reserved.
---------------------------------------------------------------------
local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Control = import("/lua/maui/control.lua").Control
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Button = import("/lua/maui/button.lua").Button
local Group = import("/lua/maui/group.lua").Group
local Dragger = import("/lua/maui/dragger.lua").Dragger
local Ping = import("/lua/ui/game/ping.lua")
local UserDecal = import("/lua/user/userdecal.lua").UserDecal
local WorldViewMgr = import("/lua/ui/game/worldview.lua")
local Prefs = import("/lua/user/prefs.lua")
local OverchargeCanKill = import("/lua/ui/game/unitview.lua").OverchargeCanKill
local CommandMode = import("/lua/ui/game/commandmode.lua")



WorldViewParams = {
    ui_SelectTolerance = 7.0,
    ui_DisableCursorFixing = false,
    ui_ExtractSnapTolerance = 4.0,
    ui_MinExtractSnapPixels = 10,
    ui_MaxExtractSnapPixels = 1000,
}

local KeyCodeAlt = 18
local KeyCodeCtrl = 17
local KeyCodeShift = 16

local weaponsCached = { }

---@class WorldViewDecalData
---@field texture string
---@field scale number

-- If all selected units with the SHOWATTACKRETICLE flag set are of the same type, return the weapon
-- table from their blueprint. Otherwise returns null.

--- Returns all weapon blueprints that match the predicate of units with the `SHOWATTACKRETICLE` category set
---@param predicate function<WeaponBlueprint>
---@return WeaponBlueprint[]
local function GetSelectedWeaponsWithReticules(predicate)
    local selectedUnits = GetSelectedUnits()

    -- clear out the cache
    local weapons = weaponsCached
    for k, other in weapons do
        weapons[k] = false
    end

    -- find valid units
    if selectedUnits then
        for i, u in selectedUnits do
            local bp = u:GetBlueprint()
            if bp.CategoriesHash['SHOWATTACKRETICLE'] and (not weapons[bp.BlueprintId]) then
                for k, v in bp.Weapon do
                    if predicate(v) then
                        weapons[bp.BlueprintId] = v
                        break
                    end
                end
            end
        end
    end

    return weapons
end

--- A generic decal texture / size computation function that uses the damage or spread radius
---@param predicate function<WeaponBlueprint>
---@return WorldViewDecalData[]
local function RadiusDecalFunction(predicate)
    local weapons = GetSelectedWeaponsWithReticules(predicate)

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

--- A decal texture / size computation function for `RULEUCC_Nuke`
---@return WorldViewDecalData[]
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

    local decals = { }
    local prefix = '/textures/ui/common/game/AreaTargetDecal/nuke_icon_'
    if inner > 0  then
        table.insert(decals, { texture = prefix .. 'inner.dds', scale = inner * 2 } )
    end

    if outer > 0 then
        table.insert(decals, { texture = prefix .. 'outer.dds', scale = outer * 2 } )
    end

    return decals
end

--- A decal texture / size computation function for `RULEUCC_Tactical`
---@return WorldViewDecalData[]
local function TacticalDecalFunc()
    return RadiusDecalFunction(
        function(w)
            return w.WeaponCategory == 'Missile' and w.DamageRadius and not w.NukeWeapon
        end
)
end

--- A decal texture / size computation function for `RULEUCC_Attack`
---@return WorldViewDecalData[]
local function AttackDecalFunc(mode)
    return RadiusDecalFunction(
        function(w)
            return w.ManualFire == false and w.WeaponCategory ~= 'Teleport' and w.WeaponCategory ~= "Death" and w.WeaponCategory ~= "Anti Air"
        end
)
end

--- A decal texture / size computation function for `RULEUCC_Overcharge`
---@return WorldViewDecalData[]
local function OverchargeDecalFunc()
    return RadiusDecalFunction(
        function(w)
            return w.DamageType == 'Overcharge'
        end
    )
end

--- A dictionary that takes a command name and maps it to the respective callback of the WorldView class
local orderToCursorCallback = {

    -- orders that have use of a cursors
    RULEUCC_Move = 'OnCursorMove',
    RULEUCC_Guard = 'OnCursorGuard',
    RULEUCC_Repair = 'OnCursorRepair',
    RULEUCC_Attack = 'OnCursorAttack',
    RULEUCC_AttackAlt = 'OnCursorAttackAlt',
    RULEUCC_AttackGround = 'OnCursorAttackGround',
    RULEUCC_Patrol = 'OnCursorPatrol',
    RULEUCC_Teleport = 'OnCursorTeleport',
    RULEUCC_Tactical = 'OnCursorTactical',
    RULEUCC_Nuke = 'OnCursorNuke',
    RULEUCC_Reclaim = 'OnCursorReclaim',
    RULEUCC_SpecialAction = 'OnCursorSpecialAction',
    RULEUCC_Overcharge = 'OnCursorOvercharge',
    RULEUCC_Sacrifice = 'OnCursorSacrifice',
    RULEUCC_Capture = 'OnCursorCapture',
    RULEUCC_Transport = 'OnCursorTransport',
    RULEUCC_Ferry = 'OnCursorFerry',
    RULEUCC_Script = 'OnCursorScript',
    RULEUCC_Invalid = 'OnCursorInvalid',
    RULEUCC_CallTransport = 'OnCursorCallTransport',

    -- misc
    CommandHighlight = 'OnCursorCommandHover',
    MESSAGE = 'OnCursorMessage',

    -- orders that are a one-click type of thing
    RULEUCC_Stop = nil,
    RULEUCC_Dive = nil,
    RULEUCC_Dock = nil,
    RULEUCC_Pause = nil,
    RULEUCC_SiloBuildTactical = nil,
    RULEUCC_SiloBuildNuke = nil,
    RULEUCC_RetaliateToggle = nil,
}

---@class WorldView : moho.UIWorldView, Control
---@field Cursor table
---@field CursorTrash TrashBag
---@field CursorLastEvent any
---@field CursorLastIdentifier CommandCap
---@field CursorOverride CommandCap
---@field CursorDecalTrash UserDecal[]
---@field CursorOverWorld boolean
---@field IgnoreMode boolean
---@field Trash TrashBag
WorldView = ClassUI(moho.UIWorldView, Control) {

    PingThreads = {},

    ---@param self WorldView
    ---@param spec any
    __post_init = function(self, spec)

        --- Contains cursor textures
        self.Cursor = { }

        --- Cursor trashbag that is emptied when the cursor is reset
        self.CursorTrash = TrashBag()

        --- Last cursor event
        self.CursorLastEvent = nil

        --- last cursor order name
        self.CursorLastIdentifier = nil

        --- Cursor related decals
        self.CursorDecalTrash = TrashBag()

        --- Flag that indicates whether the cursor is over the world (instead of the UI)
        self.CursorOverWorld = false

        self.CursorOverride = false

        self.Trash = TrashBag()
    end,

    ---@param self WorldView
    ---@param command CommandCap
    OverrideCursor = function(self, command)
        self.CursorOverride = command
    end,

    ---@param self WorldView
    DefaultCursor = function(self)
        self.CursorOverride = false
    end,

    --- Sets the selection tolerance to ignore everything
    ---@param self any
    SetIgnoreSelectTolerance = function(self)
        local tolerance = -1000
        if tolerance != self.SelectionTolerance then
            -- LOG('Tolerance set to: ' .. tolerance)
            ConExecute(string.format("ui_SelectTolerance %i", tolerance))
            self.SelectionTolerance = tolerance
        end
    end,

    --- Reverts the selection tolerance back to the default
    ---@param self any
    SetDefaultSelectTolerance = function(self)
        local tolerance
        if SessionIsReplay() then
            tolerance = Prefs.GetFromCurrentProfile('options.selection_threshold_replay')
        else 
            tolerance = Prefs.GetFromCurrentProfile('options.selection_threshold_regular')
        end

        if tolerance != self.SelectionTolerance then
            -- LOG('Tolerance set to: ' .. tolerance)
            ConExecute(string.format("ui_SelectTolerance %i", tolerance))
            self.SelectionTolerance = tolerance
        end
    end,

    --- Sets the selection tolerance to make it easier to reclaim
    ---@param self any
    SetReclaimSelectTolerance = function(self)
        local tolerance = Prefs.GetFromCurrentProfile('options.selection_threshold_reclaim')

        if tolerance != self.SelectionTolerance then
            -- LOG('Tolerance set to: ' .. tolerance)
            ConExecute(string.format("ui_SelectTolerance %i", tolerance))
            self.SelectionTolerance = tolerance
        end
    end,

    --- Only accept move and attack move commands, ignore everything else
    ---@param self any
    ---@param enabled boolean
    EnableIgnoreMode = function(self, enabled)
        if enabled then
            ConExecute("ui_CommandClickScale 0")
            self:SetIgnoreSelectTolerance()
        else
            ConExecute("ui_CommandClickScale 1")
            self:SetDefaultSelectTolerance()
        end
    end,

    --- Checks and toggles the ignore mode which only processes move and attack move commands
    ---@param self WorldView
    CheckIgnoreMode = function(self)
        return IsKeyDown(KeyCodeCtrl) and (not IsKeyDown(KeyCodeShift)) and Prefs.GetFromCurrentProfile('options.commands_ignore_mode') == 'on' -- shift key
    end,

    --- Returns true if the reclaim command can be applied
    ---@param self WorldView
    ---@return boolean
    CanIssueReclaimOrders = function(self)
        if not self.Camera then
            self.Camera = GetCamera('WorldCamera')
        end

        return self.Camera:GetZoom() < 150
    end,

    --- Called each frame to update the cursor, by the engine. We use it to determine the correct command
    ---@param self any
    OnUpdateCursor = function(self)
        -- gather all information
        local selection = GetSelectedUnits()
        local command_mode, command_data = unpack(CommandMode.GetCommandMode())     -- is set when we issue orders manually, try to build something, etc
        local orderViaMouse = self:GetRightMouseButtonOrder()                       -- is set when our mouse is over a hostile unit, reclaim, etc and not in command mode
        local holdAltToAttackMove = Prefs.GetFromCurrentProfile('options.alt_to_force_attack_move')

        -- process precedence hierarchy
        ---@type CommandCap | 'CommandHighlight'
        local order

        -- special override 
        if self.CursorOverride then
            order = self.CursorOverride

        -- special override
        elseif holdAltToAttackMove == 'On' and IsKeyDown(KeyCodeAlt) and selection then
            order = 'RULEUCC_AttackAlt'

        -- usual order structure
        else
            -- 1. command mode
            if command_mode then
                order = command_data.cursor or command_data.name

                if order == 'RULEUCC_Attack' then
                    order = 'RULEUCC_AttackGround'
                end
            -- 2. then command highlighting
            elseif self:HasHighlightCommand() then
                order = 'CommandHighlight'
            -- 3. then whatever is below the mouse
            elseif orderViaMouse and orderViaMouse != 'RULEUCC_Move' then
                order = orderViaMouse
            -- 4. then if we hold alt, we'll show the attack cursor
            elseif IsKeyDown(KeyCodeAlt) and selection then
                order = 'RULEUCC_Attack'
            end
        end

        -- perform the action accordingly
        self:OnCursor(order, selection, command_data)
    end,

    --- Calls command-specific code to manage the cursor, if available
    ---@param self WorldView
    ---@param identifier CommandCap
    OnCursor = function(self, identifier)

        -- map order to event name
        local event = orderToCursorCallback[identifier]

        -- clean up previous cursor
        if not (self.CursorLastEvent == event) and self[self.CursorLastEvent] then
            self[self.CursorLastEvent](self, self.CursorLastIdentifier, false, false)
        end

        -- attempt to create a new cursor
        if event and self[event] then
            self[event](self, identifier, true, event ~= self.CursorLastEvent)
            -- if (event ~= self.CursorLastEvent) then
            --     LOG(event)
            -- end
        else
            self:OnCursorReset(identifier, true, event ~= self.CursorLastEvent)
        end

        -- keep track of the previous cursor type
        self.CursorLastEvent = event
        self.CursorLastIdentifier = identifier
    end,

    --- Manages the decals of a cursor event
    ---@param self WorldView
    ---@param identifier CommandCap
    ---@param enabled boolean
    ---@param changed boolean
    ---@param getDecalsBasedOnSelection function # See the radial decal functions
    OnCursorDecals = function(self, identifier, enabled, changed, getDecalsBasedOnSelection)
        if enabled then
            if changed then

                -- prepare decals based on the selection
                local data = getDecalsBasedOnSelection()
                if data then
                    -- clear out old decals, if they exist
                    self.CursorDecalTrash:Destroy();
                    for k, instance in data do
                        local decal = UserDecal()
                        decal:SetTexture(instance.texture)
                        decal:SetScale({ instance.scale, 1, instance.scale })
                        self.CursorDecalTrash:Add(decal);
                        self.Trash:Add(decal)
                    end
                end
            end

            -- update their locations
            for k, decal in self.CursorDecalTrash do
                decal:SetPosition(GetMouseWorldPos())
            end
        else
            -- command ended, destroy the current decals to make room for new decals
            self.CursorDecalTrash:Destroy();
        end
    end,

    --- Resets the cursor texture and state
    ---@param self WorldView
    ---@param identifier CommandCap
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorReset = function(self, identifier, enabled, changed)
        if enabled then
            if changed then
                self.Cursor[1] = nil
                self.Cursor[2] = nil
                self.Cursor[3] = nil
                self.Cursor[4] = nil
                self.Cursor[5] = nil

                GetCursor():Reset()
            end
        end
    end,

    --- Called when hovering over a command
    ---@param self WorldView
    ---@param identifier CommandCap
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorCommandHover = function(self, identifier, enabled, changed)
        if self:ShowConvertToPatrolCursor() then
            local cursor = self.Cursor
            cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor("MOVE2PATROLCOMMAND")
        else
            local cursor = self.Cursor
            cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor('HOVERCOMMAND')
        end

        self:ApplyCursor()
    end,

    --- Called when the order `RULEUCC_Move` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Move'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorMove = function(self, identifier, enabled, changed)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()

                self:EnableIgnoreMode(true)
            end
        else
            self:EnableIgnoreMode(false)
        end
    end,

    --- Called when the order `RULEUCC_Guard` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Guard'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorGuard = function(self, identifier, enabled, changed)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `RULEUCC_Repair` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Repair'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorRepair = function(self, identifier, enabled, changed)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `RULEUCC_Attack` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Attack'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorAttack = function(self, identifier, enabled, changed)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end

        -- if via prefs then we always show the splash indicator
        local viaPrefs = Prefs.GetFromCurrentProfile('options.cursor_splash_damage') == 'on'
        if viaPrefs then
            self:OnCursorDecals(identifier, enabled, changed, AttackDecalFunc)

        -- otherwise we only show it if we're in command mode
        else
            local commandData = CommandMode.GetCommandMode()
            local viaCommandMode = commandData[1] and commandData[1] == 'order' and commandData[2].name == 'RULEUCC_Attack'
            if viaCommandMode then
                local commandModeChange = (viaCommandMode != self.ViaCommandModeOld)
                self:OnCursorDecals(identifier, enabled or commandModeChange, changed or commandModeChange, AttackDecalFunc)
            else 
                self:OnCursorDecals(identifier, false, changed, AttackDecalFunc)
            end
            self.ViaCommandModeOld = viaCommandMode
        end
    end,

    --- Called when we hold alt
    ---@param self WorldView
    ---@param identifier 'RULEUCC_AttackAlt'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorAttackAlt = function(self, identifier, enabled, changed)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor('RULEUCC_Attack')
                self:ApplyCursor()

                self:EnableIgnoreMode(true)
                CommandMode.CacheAndClearCommandMode()
            end
        else
            self:EnableIgnoreMode(false)
            CommandMode.RestoreCommandMode()
        end
    end,

    ---@param self WorldView
    ---@param identifier 'RULEUCC_AttackGround'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorAttackGround = function(self, identifier, enabled, changed)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor('RULEUCC_Attack')
                self:ApplyCursor()

                self:EnableIgnoreMode(true)
            end
        else
            self:EnableIgnoreMode(false)
        end

        self:OnCursorDecals(identifier, enabled, changed, AttackDecalFunc)
    end,

    --- Called when the order `RULEUCC_Patrol` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Attack'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorPatrol = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `RULEUCC_Teleport` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Teleport'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorTeleport = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `RULEUCC_Tactical` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Tactical'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorTactical = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()

                self:EnableIgnoreMode(true)
            end
        else
            self:EnableIgnoreMode(false)
        end

        self:OnCursorDecals(identifier, enabled, changed, TacticalDecalFunc)
    end,

    --- Called when the order `RULEUCC_Nuke` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Nuke'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorNuke = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()

                self:EnableIgnoreMode(true)
            end
        else
            self:EnableIgnoreMode(false)
        end

        self:OnCursorDecals(identifier, enabled, changed, NukeDecalFunc)
    end,

    ApplyReclaimCursor = function(self, identifier, canIssueReclaimOrders, viaCommandMode, viaRightMouseButton)
        local reference = identifier
        if not canIssueReclaimOrders then
            reference = reference .. 'Disabled'

        -- this won't trigger because `GetRightMouseButtonOrder` always returns nil once we're in command mode
        -- elseif viaCommandMode and (not viaRightMouseButton) then
        --     reference = reference .. 'Invalid'
        end

        local cursor = self.Cursor
        cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(reference)
        self:ApplyCursor()
    end,

    --- Called when the order `RULEUCC_Reclaim` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Reclaim'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorReclaim = function(self, identifier, enabled, changed)

        -- allows us to make easier distinctions for the status quo, note that this becomes invalid once we change
        local commandData = CommandMode.GetCommandMode()
        local viaCommandMode = commandData[1] and commandData[1] == 'order' and commandData[2].name == 'RULEUCC_Reclaim'
        local viaRightMouseButton = self:GetRightMouseButtonOrder() == 'RULEUCC_Reclaim' -- always returns nil when in command mode
        local canIssueReclaimOrders = self:CanIssueReclaimOrders()

        if enabled then
            if changed then

                if viaCommandMode then
                    self:SetReclaimSelectTolerance()
                end

                self.ViaCommandModeOld = viaCommandMode
                self.CanIssueReclaimOrdersOld = canIssueReclaimOrders
                self.ViaRightMouseButtonOld = viaRightMouseButton
                self:ApplyReclaimCursor(identifier, canIssueReclaimOrders, viaCommandMode, true)
            else
                if (canIssueReclaimOrders ~= self.CanIssueReclaimOrdersOld) or (viaRightMouseButton ~= self.ViaRightMouseButtonOld) then
                    self:ApplyReclaimCursor(identifier, canIssueReclaimOrders, viaCommandMode, true)

                    self.ViaRightMouseButtonOld = viaRightMouseButton
                    self.CanIssueReclaimOrdersOld = canIssueReclaimOrders
                end

                if viaCommandMode ~= self.ViaCommandModeOld then
                    if not viaCommandMode then
                        self:SetDefaultSelectTolerance()
                    else
                        self:SetReclaimSelectTolerance()
                    end

                    self.ViaCommandModeOld = viaCommandMode
                end
            end
        else
            self:SetDefaultSelectTolerance()
        end
    end,

    --- Called when the order `RULEUCC_SpecialAction` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_SpecialAction'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorSpecialAction = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `RULEUCC_Overcharge` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Overcharge'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorOvercharge = function(self, identifier, enabled, changed, commandData)
        if enabled then
            local canKill = OverchargeCanKill()
            if canKill == true then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
            elseif canKill == false then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor("OVERCHARGE_ORANGE")
            else
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor("OVERCHARGE_GREY")
            end

            self:ApplyCursor()
        end

        self:OnCursorDecals(identifier, enabled, changed, OverchargeDecalFunc)
    end,

    --- Called when the order `RULEUCC_Sacrifice` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Sacrifice'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorSacrifice = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `RULEUCC_Capture` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Capture'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorCapture = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `RULEUCC_Transport` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Transport'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorTransport = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `RULEUCC_Ferry` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Ferry'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorFerry = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `MESSAGE` is being applied
    ---@param self WorldView
    ---@param identifier 'MESSAGE'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorMessage = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `RULEUCC_Script` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Script'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorScript = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `RULEUCC_Invalid` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Invalid'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorInvalid = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called when the order `RULEUCC_Transport` is being applied
    ---@param self WorldView
    ---@param identifier 'RULEUCC_Transport'
    ---@param enabled boolean
    ---@param changed boolean
    OnCursorCallTransport = function(self, identifier, enabled, changed, commandData)
        if enabled then
            if changed then
                local cursor = self.Cursor
                cursor[1], cursor[2], cursor[3], cursor[4], cursor[5] = UIUtil.GetCursor(identifier)
                self:ApplyCursor()
            end
        end
    end,

    --- Called whenever the mouse moves and clicks in the world view. If it returns false then the engine further processes the event for orders
    ---@param self WorldView
    ---@param event any
    ---@return boolean
    HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' or event.Type == 'MouseMotion' then
            self.CursorOverWorld = true
            if not table.empty(self.Cursor) then
                if (self.LastCursor == nil) or (self.Cursor[1] != self.LastCursor[1]) then
                    self.LastCursor = self.Cursor
                    GetCursor():SetTexture(unpack(self.Cursor))
                end
            else
                GetCursor():Reset()
            end

        elseif event.Type == 'MouseExit' then
            self.CursorOverWorld = false
            GetCursor():Reset()
            self.LastCursor = nil
        elseif event.Type == 'WheelRotation' then
            self.zoomed = true
        end

        -- template rotation feature that relies on a math trick that allows for rotating 2 dimensional positions at 90 degrees, see also:
        -- - https://en.wikipedia.org/wiki/Rotation_matrix#Common_2D_rotations

        if  event.Type == 'ButtonPress' and
            event.Modifiers.Middle and
            Prefs.GetFromCurrentProfile('options.gui_template_rotator') ~= 0
        then
            local template = GetActiveBuildTemplate()
            if template and not table.empty(template) then
                local temp = template[1]
                template[1] = template[2]
                template[2] = temp
                for i = 3, table.getn(template) do
                    local temp = template[i][3]
                    template[i][3] = -1 * template[i][4]
                    template[i][4] = temp
                end
                SetActiveBuildTemplate(template)
            end
        end

        return false
    end,

    OnDestroy = function(self)

        -- take out the trash
        self.Trash:Destroy()

        -- take out all ping threads
        for i, v in self.PingThreads do
            if v then KillThread(v) end
        end

        -- unregister ourselves
        if self._registered then
            WorldViewMgr.UnregisterWorldView(self)
        end
        Ping.UpdateMarker({Action = 'renew'})
    end,

    OnCommandDragBegin = function(self)
    end,

    OnCommandDragEnd = function(self)
        self:OnUpdateCursor()
    end,

    --- Attempts to apply the current cursor textures
    ---@param self any
    ApplyCursor = function(self)
        if self.Cursor and self.CursorOverWorld then
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
            local scoreBoardControls = import("/lua/ui/game/score.lua").controls
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
                table.insert(self.PingThreads, ForkThread(function()
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
                self.Markers = self.Markers or {}
                self.Markers[pingData.Owner] = self.Markers[pingData.Owner] or {}
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
                    ping.Marker:Destroy()
                    ping:Destroy()
                end
            end
            self.Markers = {}
        elseif not self._disableMarkers and self.Markers[pingData.Owner][pingData.ID] then
            local marker = self.Markers[pingData.Owner][pingData.ID]
            if pingData.Action == 'delete' then
                marker.Marker:Destroy()
                marker:Destroy()
                self.Markers[pingData.Owner][pingData.ID] = nil
            elseif pingData.Action == 'move' then
                marker.data.Location = pingData.Location
                marker.NewPosition = false
                marker.Marker:EnableHitTest()
            elseif pingData.Action == 'rename' then
                marker.Name:SetText(pingData.Name)
                marker.data.Name = pingData.Name
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
            GetCamera(self._cameraName):SetMaxZoomMult(import("/lua/ui/game/gamemain.lua").defaultZoom)
        end
    end,

    OnIconsVisible = function(self, areIconsVisible)
        -- called when strat icons are turned on/off
    end,
}
