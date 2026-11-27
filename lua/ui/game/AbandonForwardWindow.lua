--******************************************************************************************************
--** When a player leaves without choosing who receives their army, every ally that received part of
--** it gets this window to keep it or pass it on (`ForwardAbandonedArmy`). It opens without being
--** asked for, so it doesn't block the screen: by default it sits under the score board, left of the
--** avatars, and players can move and resize it (saved in the preferences).
--******************************************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Layouter = LayoutHelpers.ReusedLayoutFor
local Group = import("/lua/maui/group.lua").Group
local Window = import("/lua/maui/window.lua").Window
local ChatFactionBadge = import("/lua/ui/game/chat/ChatFactionBadge.lua").ChatFactionBadge
local ArmyListModule = import("/lua/ui/game/abandonarmylist.lua")

-- Seconds before "Pass on" can be clicked, so that a click meant for something else doesn't pass
-- the army on. Selecting a player ends the wait.
local PassOnDelay = 1.5

-- Rows shown by default before the list scrolls
local DefaultRows = 5

local Width = 320

---@class AbandonForwardState
---@field Window Window
---@field List AbandonArmyList
---@field PassOn Button
---@field Forwarders table<number, boolean>
---@field Waiting boolean   # a pass on request is on its way to the sim
---@field Armed boolean     # the delay before "Pass on" is over

---@type table<number, AbandonForwardState>
local Open = {}

--- Entries of the list: allies that can receive the army first, the ones that already passed it on
--- last.
---@param from number
---@param forwarders table<number, boolean>
---@return AbandonArmyListEntry[]
local function GetEntries(from, forwarders)
    local entries = {}
    local excluded = {}
    for _, entry in ArmyListModule.GetAllies(from) do
        if forwarders[entry.Army] then
            entry.Excluded = true
            table.insert(excluded, entry)
        else
            table.insert(entries, entry)
        end
    end
    for _, entry in excluded do
        table.insert(entries, entry)
    end
    return entries
end

--- Whether any entry can be selected.
---@param entries AbandonArmyListEntry[]
---@return boolean
local function HasRecipients(entries)
    return entries[1] ~= nil and not entries[1].Excluded
end

--- Default place: under the score board, left of the avatars.
---@param rows number
---@return table
local function GetDefaultPosition(rows)
    local score = import("/lua/ui/game/score.lua").controls
    local avatars = import("/lua/ui/game/avatars.lua").controls
    local frame = GetFrame(0)

    local function Right()
        -- left of the avatar icons, which stick out of their background; their group spans the
        -- whole width
        local left = avatars.bgTop and avatars.bgTop.Left()
        for _, avatar in avatars.avatars or {} do
            if avatar.Left and (not left or avatar.Left() < left) then
                left = avatar.Left()
            end
        end
        if left then
            return left - LayoutHelpers.ScaleNumber(6)
        end
        return frame.Right() - LayoutHelpers.ScaleNumber(70)
    end
    local function Top()
        if score.bg then
            return score.bg.Bottom() + LayoutHelpers.ScaleNumber(6)
        end
        return frame.Top() + LayoutHelpers.ScaleNumber(160)
    end

    -- title bar, header, rows, buttons and the spacing between them
    local height = LayoutHelpers.ScaleNumber(30 + 26 + 10 + 14 + 30 + 20) + ArmyListModule.HeightForRows(rows)
    return {
        Left = function() return Right() - LayoutHelpers.ScaleNumber(Width) end,
        Top = Top,
        Right = Right,
        Bottom = function() return Top() + height end,
    }
end

---@param state AbandonForwardState
local function UpdatePassOn(state)
    if state.Waiting or not state.Armed or not state.List.Selected then
        state.PassOn:Disable()
    else
        state.PassOn:Enable()
    end
end

---@param from number
local function Close(from)
    local state = Open[from]
    if state then
        Open[from] = nil
        state.Window:Destroy()
    end
end

--- Opens the window for an army received from `from`, or refreshes it when it is already open.
---@param from number
---@param forwarders number[]
function OpenForwardWindow(from, forwarders)
    local forwarderSet = {}
    for _, army in forwarders do
        forwarderSet[army] = true
    end

    local entries = GetEntries(from, forwarderSet)
    if not HasRecipients(entries) then
        Close(from)
        return
    end

    local existing = Open[from]
    if existing then
        existing.Forwarders = forwarderSet
        existing.List:SetEntries(entries)
        UpdatePassOn(existing)
        return
    end

    local armies = GetArmiesTable().armiesTable
    local window = Window(GetFrame(0), LOC("<LOC abandon_forward_window>Received Army"), nil, false, false, false, false,
        "abandon_forward_window", GetDefaultPosition(math.min(DefaultRows, table.getn(entries))))
    window.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    window:SetMinimumResize(LayoutHelpers.ScaleNumber(240), LayoutHelpers.ScaleNumber(160))
    local client = window:GetClientGroup()

    -- the army: faction badge in its color and the name of the player who left
    local badge = ChatFactionBadge(client, armies[from].faction, armies[from].color)
    Layouter(badge):AtLeftIn(client, 10):AtTopIn(client, 6):Width(18):Height(18):End()
    local name = UIUtil.CreateText(client, LOCF("<LOC abandon_forward_army>%s's army", armies[from].nickname), 14, UIUtil.bodyFont)
    Layouter(name):RightOf(badge, 6):AtVerticalCenterIn(badge):End()

    local passOn = UIUtil.CreateButtonStd(client, "/widgets02/small", LOC("<LOC abandon_forward_send>Pass on"), 14)
    local keep = UIUtil.CreateButtonStd(client, "/widgets02/small", LOC("<LOC abandon_forward_keep>Keep"), 14)
    Layouter(passOn):AtBottomIn(client, 8)
        :Left(function() return client.Left() + client.Width() * 0.27 - passOn.Width() * 0.5 end):End()
    Layouter(keep):AtBottomIn(client, 8)
        :Left(function() return client.Left() + client.Width() * 0.73 - keep.Width() * 0.5 end):End()

    local list = ArmyListModule.AbandonArmyList(client, entries, entries[1].Army)
    Layouter(list):Below(badge, 10):AtLeftIn(client, 10):AtRightIn(client, 10)
        :Bottom(function() return passOn.Top() - LayoutHelpers.ScaleNumber(10) end):End()
    list:Refresh()

    ---@type AbandonForwardState
    local state = {
        Window = window,
        List = list,
        PassOn = passOn,
        Forwarders = forwarderSet,
        Waiting = false,
        Armed = false,
    }
    Open[from] = state

    window.OnResize = function(self, x, y, firstFrame)
        list:Refresh()
    end
    window.OnResizeSet = function(self)
        list:Refresh()
    end
    window.OnClose = function(self)
        Close(from)
    end

    -- selecting a player shows the choice is deliberate: no need to wait
    list.OnSelect = function(self, army)
        state.Armed = true
        passOn.label:SetText(LOC("<LOC abandon_forward_send>Pass on"))
        UpdatePassOn(state)
    end

    keep.OnClick = function()
        Close(from)
    end

    passOn.OnClick = function()
        if not list.Selected or state.Waiting then
            return
        end
        state.Waiting = true
        UpdatePassOn(state)
        SimCallback({ Func = "ForwardAbandonedArmy", Args = { From = from, To = list.Selected } })
    end

    UpdatePassOn(state)

    ForkThread(function()
        -- count down before "Pass on" can be clicked
        local start = GetSystemTimeSeconds()
        while Open[from] == state and not state.Armed do
            local left = PassOnDelay - (GetSystemTimeSeconds() - start)
            if left <= 0 then
                state.Armed = true
                passOn.label:SetText(LOC("<LOC abandon_forward_send>Pass on"))
                UpdatePassOn(state)
                break
            end
            passOn.label:SetText(LOCF("<LOC abandon_forward_send_wait>Pass on (%d)", math.ceil(left)))
            WaitSeconds(0.1)
        end

        -- allies that are defeated leave the list
        while Open[from] == state do
            WaitSeconds(1)
            if Open[from] ~= state then
                break
            end
            local current = GetEntries(from, state.Forwarders)
            if not HasRecipients(current) then
                Close(from)
                break
            end
            if table.getn(current) ~= table.getn(list.Entries) then
                list:SetEntries(current)
                UpdatePassOn(state)
            end
        end
    end)
end

--- Called from `UserSync.lua` when an army received units of an abandoned army whose player didn't
--- choose who receives them.
---@param data { From: number, To: number, Forwarders: number[] }[]
function OnAbandonedArmyReceived(data)
    if SessionIsReplay() then
        return
    end
    for _, received in data do
        if received.To == GetFocusArmy() then
            OpenForwardWindow(received.From, received.Forwarders)
        end
    end
end

--- Called from `UserSync.lua` with the sim's answer to `ForwardAbandonedArmy`: closes the window
--- when the army moved, or lets the player choose again.
---@param results { From: number, Army: number, To: number, Accepted: boolean }[]
function OnForwardResults(results)
    for _, result in results do
        local state = Open[result.From]
        if state and result.Army == GetFocusArmy() then
            if result.Accepted then
                Close(result.From)
            else
                state.Waiting = false
                local entries = GetEntries(result.From, state.Forwarders)
                if HasRecipients(entries) then
                    state.List:SetEntries(entries)
                    UpdatePassOn(state)
                else
                    Close(result.From)
                end
            end
        end
    end
end
