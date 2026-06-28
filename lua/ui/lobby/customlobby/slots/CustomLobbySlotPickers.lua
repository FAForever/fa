--******************************************************************************************************
--** Copyright (c) 2026 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

-- The three small floating pickers a player opens by clicking a card's editable element: the **faction
-- multi-toggle** (tick a subset of factions — more than one means random among them), the **colour
-- grid** (taken colours greyed; colours are scarce), and the **team list**. Each is a framed panel
-- anchored at a screen point, dismissed on click-outside / Esc — the same singleton + full-screen-cover
-- pattern as CustomLobbyContextMenu, lifted above the slot rows' raised hit area.
--
-- A picker only proposes a change: it calls the matching host-authoritative controller intent
-- (`RequestSetFactions` / `RequestSetColor` / `RequestSetTeam`, keyed by slot) and the seat re-renders
-- from the synced model. It never writes a model itself. The faction picker applies live on each toggle
-- (and stays open); the colour / team pickers apply and close (a single choice).

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local EscapeHandler = import("/lua/ui/dialogs/eschandler.lua")

local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local GameColors = import("/lua/gamecolors.lua").GameColors
local Factions = import("/lua/factions.lua").Factions
local CustomLobbyController = import("/lua/ui/lobby/customlobby/customlobbycontroller.lua")
local CustomLobbyLaunchModel = import("/lua/ui/lobby/customlobby/models/customlobbylaunchmodel.lua")

local Layouter = LayoutHelpers.ReusedLayoutFor
local scaled = LayoutHelpers.ScaleNumber

local Pad = 6
local RowHeight = 24
local LabelPadX = 8
local RowWidth = 150         -- faction / team rows
local Swatch = 22            -- colour grid cell
local SwatchGap = 4
local SwatchesPerRow = 8

local BorderColor = 'ff415055'
local FillColor = 'f0101418'
local HoverColor = '22ffffff'
local CheckOn = 'ff7ad97a'
local CheckOff = '00000000'
local CheckBorder = 'ff5a6470'
local MaxTeams = 8           -- "No team" + Team 1..MaxTeams

-------------------------------------------------------------------------------
--#region Singleton + framing (mirrors CustomLobbyContextMenu)

local ModuleTrash = TrashBag()
---@type Group | false
local Instance = false
---@type Bitmap | false
local Cover = false

--- Closes the open picker (if any). Idempotent.
function Hide()
    if not Instance then
        return
    end
    EscapeHandler.PopEscapeHandler()
    Instance:Destroy()
    Instance = false
    if Cover then
        Cover:Destroy()
        Cover = false
    end
end

--- A full-screen invisible catcher: a click off the panel dismisses it.
---@return Bitmap
local function CreateCover()
    local cover = Bitmap(GetFrame(0))
    cover:SetSolidColor('00000000')
    cover.HandleEvent = function(control, event)
        if event.Type == 'ButtonPress' then
            Hide()
            return true
        end
        return false
    end
    Layouter(cover):Fill(GetFrame(0)):End()
    return cover
end

--- Builds an empty framed panel (border + dark fill) of the given unscaled size, parented to the
--- frame. Children anchor into it; the caller positions it via `Mount`.
---@param width number
---@param height number
---@return Group
local function CreatePanel(width, height)
    local panel = Group(GetFrame(0), "CustomLobbySlotPicker")
    panel.Width:Set(scaled(width))
    panel.Height:Set(scaled(height))

    local border = Bitmap(panel)
    border:SetSolidColor(BorderColor)
    border:DisableHitTest()
    local fill = Bitmap(panel)
    fill:SetSolidColor(FillColor)
    fill:DisableHitTest()
    Layouter(border):Fill(panel):End()
    Layouter(fill):AtLeftIn(panel, 1):AtRightIn(panel, 1):AtTopIn(panel, 1):AtBottomIn(panel, 1):End()
    return panel
end

--- Shows `panel` at the screen point, kept on-screen, above the slot rows' raised hit area, with the
--- click-outside cover and an Esc handler. Replaces any picker already open.
---@param panel Group
---@param x number
---@param y number
local function Mount(panel, x, y)
    local frame = GetFrame(0)
    local baseDepth = frame:GetTopmostDepth()

    Cover = CreateCover()
    Cover.Depth:Set(baseDepth + 10)

    panel.Depth:Set(baseDepth + 20)
    ModuleTrash:Add(panel)
    Instance = panel

    local left = math.min(x, frame.Right() - panel.Width())
    local top = math.min(y, frame.Bottom() - panel.Height())
    panel.Left:Set(math.max(0, left))
    panel.Top:Set(math.max(0, top))

    EscapeHandler.PushEscapeHandler(function() Hide() end)
end

--#endregion

-------------------------------------------------------------------------------
--#region Faction multi-toggle

--- The sorted list of ticked faction indices in `selected`.
---@param selected table<number, boolean>
---@return number[]
local function SelectedFactions(selected)
    local out = {}
    for index = 1, CustomLobbyLaunchModel.RealFactionCount do
        if selected[index] then
            table.insert(out, index)
        end
    end
    return out
end

--- Opens the faction multi-toggle for `slot`'s player at the screen point. Each row is a faction with a
--- tick box; clicking toggles it and applies live (more than one ticked = random among them). The last
--- ticked faction can't be un-ticked, so a player always has at least one allowed faction.
---@param slot number
---@param player UICustomLobbyPlayer
---@param x number
---@param y number
function ShowFactionPicker(slot, player, x, y)
    Hide()
    local count = CustomLobbyLaunchModel.RealFactionCount

    local selected = {}
    for _, index in (player.Factions or { player.Faction }) do
        if type(index) == 'number' and index >= 1 and index <= count then
            selected[index] = true
        end
    end

    local panel = CreatePanel(RowWidth, Pad * 2 + count * RowHeight)

    for i = 1, count do
        local faction = Factions[i]
        local top = Pad + (i - 1) * RowHeight

        local row = Group(panel)
        local surface = Bitmap(row)
        surface:SetSolidColor(HoverColor)
        surface:SetAlpha(0.0)

        -- the frame first (behind), then the fill on top so the tick shows over it
        local checkBorder = Bitmap(row)
        checkBorder:SetSolidColor(CheckBorder)
        checkBorder:DisableHitTest()
        local check = Bitmap(row)
        check:DisableHitTest()
        check:SetSolidColor(selected[i] and CheckOn or CheckOff)

        local icon = Bitmap(row)
        icon:DisableHitTest()
        if faction.SmallIcon then
            icon:SetTexture(UIUtil.UIFile(faction.SmallIcon))
        end

        local label = UIUtil.CreateText(row, faction.DisplayName or faction.Key or tostring(i), 13, UIUtil.bodyFont)
        label:DisableHitTest()

        surface.HandleEvent = function(control, event)
            if event.Type == 'MouseEnter' then
                control:SetAlpha(1.0)
                return true
            elseif event.Type == 'MouseExit' then
                control:SetAlpha(0.0)
                return true
            elseif event.Type == 'ButtonPress' then
                -- toggle, but never empty the set (the last allowed faction stays ticked)
                if selected[i] and table.getn(SelectedFactions(selected)) <= 1 then
                    return true
                end
                selected[i] = not selected[i]
                check:SetSolidColor(selected[i] and CheckOn or CheckOff)
                CustomLobbyController.RequestSetFactions(slot, SelectedFactions(selected))
                return true
            end
            return false
        end

        Layouter(row):AtLeftIn(panel, Pad):AtRightIn(panel, Pad):Height(RowHeight)
            :Top(function() return panel.Top() + scaled(top) end):End()
        Layouter(surface):Fill(row):End()
        Layouter(checkBorder):AtLeftIn(row):AtVerticalCenterIn(row):Width(14):Height(14):End()
        Layouter(check):AtLeftIn(checkBorder, 1):AtTopIn(checkBorder, 1):AtRightIn(checkBorder, 1):AtBottomIn(checkBorder, 1):End()
        Layouter(icon):AnchorToRight(checkBorder, LabelPadX):AtVerticalCenterIn(row):Width(14):Height(14):End()
        Layouter(label):AnchorToRight(icon, 6):AtVerticalCenterIn(row):End()
    end

    Mount(panel, x, y)
end

--#endregion

-------------------------------------------------------------------------------
--#region Colour grid

--- The set of PlayerColor indices already used by a seated player other than `exceptSlot` (greyed in
--- the grid — colours are scarce). Mirrors the host-side scarcity check, for UX.
---@param exceptSlot number
---@return table<number, boolean>
local function TakenColors(exceptSlot)
    local launch = CustomLobbyLaunchModel.GetSingleton()
    local taken = {}
    for slot = 1, CustomLobbyLaunchModel.MaxSlots do
        if slot ~= exceptSlot then
            local player = launch.Players[slot]()
            if player and player.PlayerColor then
                taken[player.PlayerColor] = true
            end
        end
    end
    return taken
end

--- Opens the colour grid for `slot`'s player. Free colours are pickable (click applies + closes);
--- colours taken by another seated player are greyed and inert; the player's current colour is framed.
---@param slot number
---@param player UICustomLobbyPlayer
---@param x number
---@param y number
function ShowColorPicker(slot, player, x, y)
    Hide()
    local colors = GameColors.PlayerColors
    local total = table.getn(colors)
    local rows = math.ceil(total / SwatchesPerRow)
    local taken = TakenColors(slot)

    local width = Pad * 2 + SwatchesPerRow * Swatch + (SwatchesPerRow - 1) * SwatchGap
    local height = Pad * 2 + rows * Swatch + (rows - 1) * SwatchGap
    local panel = CreatePanel(width, height)

    for i = 1, total do
        local col = math.mod(i - 1, SwatchesPerRow)
        local rowIdx = math.floor((i - 1) / SwatchesPerRow)
        local left = Pad + col * (Swatch + SwatchGap)
        local top = Pad + rowIdx * (Swatch + SwatchGap)
        local isTaken = taken[i]
        local isCurrent = player.PlayerColor == i

        -- a white frame behind the current colour's swatch
        if isCurrent then
            local frame = Bitmap(panel)
            frame:SetSolidColor('ffffffff')
            frame:DisableHitTest()
            Layouter(frame):Width(Swatch + 4):Height(Swatch + 4)
                :Left(function() return panel.Left() + scaled(left - 2) end)
                :Top(function() return panel.Top() + scaled(top - 2) end):End()
        end

        local swatch = Bitmap(panel)
        swatch:SetSolidColor(colors[i])
        swatch:SetAlpha(isTaken and 0.25 or 1.0)
        if not isTaken and not isCurrent then
            swatch.HandleEvent = function(control, event)
                if event.Type == 'MouseEnter' then
                    control:SetAlpha(0.7)
                    return true
                elseif event.Type == 'MouseExit' then
                    control:SetAlpha(1.0)
                    return true
                elseif event.Type == 'ButtonPress' then
                    Hide()
                    CustomLobbyController.RequestSetColor(slot, i)
                    return true
                end
                return false
            end
        else
            swatch:DisableHitTest()
        end

        Layouter(swatch):Width(Swatch):Height(Swatch)
            :Left(function() return panel.Left() + scaled(left) end)
            :Top(function() return panel.Top() + scaled(top) end):End()
    end

    Mount(panel, x, y)
end

--#endregion

-------------------------------------------------------------------------------
--#region Team list

--- Opens the team list for `slot`'s player: "No team" + Team 1..MaxTeams (backend numbering 1, 2..9).
--- Clicking applies + closes. The current team is highlighted.
---@param slot number
---@param player UICustomLobbyPlayer
---@param x number
---@param y number
function ShowTeamPicker(slot, player, x, y)
    Hide()
    local entries = {}
    table.insert(entries, { label = "No team", team = 1 })
    for t = 1, MaxTeams do
        table.insert(entries, { label = "Team " .. tostring(t), team = t + 1 })
    end
    local count = table.getn(entries)

    local panel = CreatePanel(RowWidth, Pad * 2 + count * RowHeight)

    for i = 1, count do
        local entry = entries[i]
        local top = Pad + (i - 1) * RowHeight
        local isCurrent = (player.Team or 1) == entry.team

        local row = Group(panel)
        local surface = Bitmap(row)
        surface:SetSolidColor(HoverColor)
        surface:SetAlpha(isCurrent and 0.12 or 0.0)

        local label = UIUtil.CreateText(row, entry.label, 13, UIUtil.bodyFont)
        label:SetColor(isCurrent and CheckOn or 'ffffffff')
        label:DisableHitTest()

        surface.HandleEvent = function(control, event)
            if event.Type == 'MouseEnter' then
                control:SetAlpha(0.12)
                return true
            elseif event.Type == 'MouseExit' then
                control:SetAlpha(isCurrent and 0.12 or 0.0)
                return true
            elseif event.Type == 'ButtonPress' then
                Hide()
                CustomLobbyController.RequestSetTeam(slot, entry.team)
                return true
            end
            return false
        end

        Layouter(row):AtLeftIn(panel, Pad):AtRightIn(panel, Pad):Height(RowHeight)
            :Top(function() return panel.Top() + scaled(top) end):End()
        Layouter(surface):Fill(row):End()
        Layouter(label):AtLeftIn(row, LabelPadX):AtVerticalCenterIn(row):End()
    end

    Mount(panel, x, y)
end

--#endregion

-------------------------------------------------------------------------------
--#region Debugging

function __moduleinfo.OnDirty()
    Hide()
    ModuleTrash:Destroy()
end

--#endregion
