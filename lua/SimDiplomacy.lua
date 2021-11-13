
local OkayToMessWithArmy = OkayToMessWithArmy
local GetFocusArmy = GetFocusArmy
local tableFind = table.find
local tableRemove = table.remove
local IsAlly = IsAlly
local SetAlliance = SetAlliance
local tableInsert = table.insert

local ignoredList = {}
local offers = {}

function DiplomacyHandler(action)
    if action.Action == 'offer' then
        if not offers[action.From] then offers[action.From] = {} end
        if tableFind(offers[action.From], action.To) then
            return
        else
            tableInsert(offers[action.From], action.To)
        end
    elseif action.Action == 'accept' then
        if tableFind(offers[action.To], action.From) then
            SetAlliance(action.To, action.From, 'Ally')
            tableRemove(offers[action.To], tableFind(offers[action.To], action.From))
        end
    elseif action.Action == 'reject' then
        if offers[action.To] then
            tableRemove(offers[action.To], tableFind(offers[action.To], action.From))
        end
    elseif action.Action == 'break' then
        if IsAlly(action.To, action.From) then
            if OkayToMessWithArmy(action.From) then
                SetAlliance(action.To, action.From, 'Enemy')
            end
        end
    elseif action.Action == 'never' then
        if not ignoredList[action.From] then ignoredList[action.From] = {} end
        if not tableFind(ignoredList[action.From], action.To) then
            tableInsert(ignoredList[action.From], action.To)
        end
    end
    
    if GetFocusArmy() == action.To then
        if action == 'offer' and tableFind(ignoredList[action.To], action.From) then
            return
        end
        SyncAction(action)
    elseif GetFocusArmy() != action.From then
        if action.Action == 'accept' or action.Action == 'break' then
            SyncAnnouncement(action)
        end
    end
end

function SyncAction(action)
    if not Sync.DiplomacyAction then Sync.DiplomacyAction = {} end
    tableInsert(Sync.DiplomacyAction, action)
end

function SyncAnnouncement(announcement)
    if not Sync.DiplomacyAnnouncement then Sync.DiplomacyAnnouncement = {} end
    tableInsert(Sync.DiplomacyAnnouncement, announcement)
end