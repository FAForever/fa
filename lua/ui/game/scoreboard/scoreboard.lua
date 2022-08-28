
-- # imports


local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local LazyVar = import('/lua/Lazyvar.lua').Create

local Prefs = import('/lua/user/prefs.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local FindClients = import('/lua/ui/game/chat.lua').FindClients

-- # locals

---@type Scoreboard | boolean
local instance = false
local scenario = SessionGetScenarioInfo()
local armies = GetArmiesTable().armiesTable
local ScoreData = { }

local showDebugLayout = false
local showRating = true 

-- table to convert key to LOC value
local ShareNameLookup = { }
ShareNameLookup["FullShare"] = "<LOC lobui_0742>"
ShareNameLookup["ShareUntilDeath"] = "<LOC lobui_0744>"
ShareNameLookup["TransferToKiller"] = "<LOC lobui_0762>"
ShareNameLookup["Defectors"] = "<LOC lobui_0766>"
ShareNameLookup["CivilianDeserter"] = "<LOC lobui_0764>"

local ShareDescriptionLookup = { }
ShareDescriptionLookup["FullShare"] = "<LOC lobui_0743>"
ShareDescriptionLookup["ShareUntilDeath"] = "<LOC lobui_0745>"
ShareDescriptionLookup["TransferToKiller"] = "<LOC lobui_0763>"
ShareDescriptionLookup["Defectors"] = "<LOC lobui_0767>"
ShareDescriptionLookup["CivilianDeserter"] = "<LOC lobui_0765>"

local ArmyStatistics = { }
local function SyncCallback(sync)
    if instance then 
        local focus = GetFocusArmy()
        local score = sync.Score[focus]

        instance:UpdateTime(GetGameTime())

        if score.general.currentunits and score.general.currentcap then 
            instance:UpdateUnitData(score.general.currentunits, score.general.currentcap)
        end

        if sync.NewPlayableArea then 
            local width = sync.NewPlayableArea[3] - sync.NewPlayableArea[1]
            local height = sync.NewPlayableArea[4] - sync.NewPlayableArea[2]

            -- update existing data
            local mapData = instance.mapData()
            mapData.Width = width
            mapData.Height = height
            instance.mapData:Set(mapData)
        end

        if not table.empty(sync.Score) then
            ArmyStatistics = sync.Score
        end

        instance:ProcessArmyStatistics(ArmyStatistics)
    end
end

---@class Scoreboard
local Scoreboard = Class(Group) {

    __init = function(scoreboard, parent)
        Group.__init(scoreboard, parent, "scoreboard")

        
        
        -- # prepare lazy values
    
        scoreboard.gameType = LazyVar({
            Name = "",
            Description = "",
        })
    
        scoreboard.mapData = LazyVar({
             Name = "", 
             Description = "",
             Width = 0, 
             Height = 0, 
             Version = 0,
             ReplayID = 0
        })
    
        scoreboard.ranked = LazyVar(true)


        LayoutHelpers.LayoutFor(scoreboard)
            :Over(parent, 10)
            :AtCenterIn(parent)
            :Width(400)
            :Height(400)
            :End()

        local debug = LayoutHelpers.LayoutFor(Group(scoreboard))
            :Fill(scoreboard)
            :End()
            
        LayoutHelpers.LayoutFor(Bitmap(debug))
            :Fill(scoreboard)
            :Color('ff000000')
            :End()

        scoreboard.header = ScoreboardHeader(scoreboard, debug)
        scoreboard.header.Top:Set(scoreboard.Top)

        -- # Debug tooling

        local checker = LayoutHelpers.LayoutFor(Checkbox(scoreboard))
            :AtLeftTopIn(scoreboard, -30, -30)
            :End() 

        checker:SetTexture(UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_up.dds'))
        checker:SetNewTextures(
            UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_up.dds'),
            UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_up.dds'),
            UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_over.dds'),
            UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_over.dds'),
            UIUtil.UIFile('/game/tab-r-btn/tab-close_btn_dis.dds'),
            UIUtil.UIFile('/game/tab-r-btn/tab-open_btn_dis.dds')
        )
        checker.OnCheck = function(self, checked) 
            RemoveOnSyncCallback(scoreboard:GetName())
            scoreboard:Destroy() 
            instance = false
        end

        -- # Construction of UI areas

        local body = LayoutHelpers.LayoutFor(Bitmap(scoreboard))
            :Left(scoreboard.Left)
            :Right(scoreboard.Right)
            :Top(scoreboard.header.Bottom)
            :Bottom(function() return scoreboard.header.Bottom() + 200 end)        -- some dummy value to start with
            :End()

        LayoutHelpers.LayoutFor(Bitmap(debug))
            :Fill(body)
            :Color('440000ff')
            :End()

        local footer = LayoutHelpers.LayoutFor(Bitmap(scoreboard))
            :Left(scoreboard.Left)
            :Right(scoreboard.Right)
            :Top(body.Bottom)
            :Bottom(function() return body.Bottom() + LayoutHelpers.ScaleNumber(40) end)
            :End()

        LayoutHelpers.LayoutFor(Bitmap(debug))
            :Fill(footer)
            :Color('4400ff00')
            :End()

        LayoutHelpers.LayoutFor(scoreboard)
            :Bottom(footer.Bottom)

        -- # populate footer

        local gametype = LayoutHelpers.LayoutFor(UIUtil.CreateText(scoreboard, "",  12, UIUtil.bodyFont))
            :AtLeftIn(footer, 2)
            :AtTopIn(footer, 2)
            :Over(scoreboard, 10)
            :End()

        scoreboard.gameType.OnDirty = function(self)
            local data = self()
            local name = LOC(tostring(data.Name))
            local description = LOC(tostring(data.Description)) .. "\r\n\r\n" .. LOC("<LOC info_game_settings_dialog>Other game settings can be found in the map information dialog (F12).")

            gametype:SetText(name)
            Tooltip.AddForcedControlTooltipManual(gametype, name, description)
        end

        local dash = LayoutHelpers.LayoutFor(UIUtil.CreateText(scoreboard, " / ",  12, UIUtil.bodyFont))
            :AtVerticalCenterIn(gametype, 2)
            :RightOf(gametype, 2)
            :Over(scoreboard, 10)
            :End()

        local map = LayoutHelpers.LayoutFor(UIUtil.CreateText(scoreboard, "",  12, UIUtil.bodyFont))
            :AtVerticalCenterIn(dash, 2)
            :RightOf(dash, 2)
            :Over(scoreboard, 10)
            :End()

        local replay = LayoutHelpers.LayoutFor(UIUtil.CreateText(scoreboard, "",  12, UIUtil.bodyFont))
            :AtLeftIn(footer, 2)
            :Below(gametype, 2)
            :Over(scoreboard, 10)
            :End()

        scoreboard.mapData.OnDirty = function(self)
            local data = self()

            local name = LOC(tostring(data.Name))
            local description = string.format("%s\r\n\r\n%s: %s", LOC(tostring(data.Description)), LOC("<LOC map_version>Map version"), tostring(data.Version))
            local width = math.ceil(data.Width / 51.2 - 0.5) 
            local height = math.ceil(data.Height / 51.2 - 0.5)
            local size = string.format("(%d, %d)", width, height)

            map:SetText(size .. " " .. name)
            Tooltip.AddForcedControlTooltipManual(map, name, description)

            local replayID = LOC("<LOC replay_id>Replay ID") .. ": " .. tostring(data.ReplayID)
            replay:SetText(replayID)
        end

        -- # Populate body

        scoreboard.armyEntries = { }
        local last = scoreboard.header 
        for k, army in armies do 
            if not army.civilian then 
                local armyLine = LayoutHelpers.LayoutFor(ScoreboardArmyLine(scoreboard, debug, army, k))
                    :Below(last, 2)
                    :End()

                scoreboard.armyEntries[k] = armyLine
                last = armyLine
            end
        end

        body.Bottom:Set(last.Bottom)

        -- # initial (sane) values

        scoreboard.gameType:Set({
            Name = ShareNameLookup[scenario.Options.Share],
            Description = ShareDescriptionLookup[scenario.Options.Share]
        })

        scoreboard.mapData:Set({
            Name = scenario.name,
            Description = scenario.description or "No description set by the author.",
            Width = scenario.size[1],
            Height = scenario.size[2],
            Version = scenario.map_version or 0,
            ReplayID = UIUtil.GetReplayId() or 0
        })

        scoreboard.ranked:Set(scenario.Options.Ranked or false)

        -- # other 

        if not showDebugLayout then 
            debug:Hide()
        end
    end,

    UpdateTime = function(scoreboard, value)
        scoreboard.header:UpdateTime(value)
    end,

    UpdateUnitData = function(scoreboard, count, cap)
        scoreboard.header:UpdateUnitData(count, cap)
    end,


    --- Allows you to expand / contract the scoreboard accordingly
    --- @param scoreboard Scoreboard 
    SetCollapsed = function(scoreboard, state)

    end,

    --- Processes the army statistics to make them visible on the scoreboard
    ---@param scoreboard Scoreboard
    ---@param armyStatistics table      # Army statistics as passed over the sync
    ProcessArmyStatistics = function(scoreboard, armyStatistics)
        for k, statistics in armyStatistics do 
            scoreboard.armyEntries[k]:UpdateEconomy(
                statistics.resources.massin.rate and (math.floor(10 * statistics.resources.massin.rate + 0.5)),
                statistics.resources.energyin.rate and (math.floor(10 * statistics.resources.energyin.rate + 0.5)),
                statistics.resources.storage.storedMass,
                statistics.resources.storage.storedEnergy
            )

            scoreboard.armyEntries[k]:UpdateScore(
                statistics.general.score
            )
        end
    end
}

-- # old public interface

function CreateScoreUI()
    if not instance then 
        instance = Scoreboard(GetFrame(0))
        AddOnSyncCallback(instance:GetName(), SyncCallback)
    end
end

function ToggleScoreControl()
    if instance then

    end
end

function Expand()
    if instance then 

    end
end

function Contract()
    if instance then 

    end
end

function NoteGameSpeedChanged(value)
    if instance then 

    end
end

function ArmyAnnounce(army, text)
    if instance then 

    end
end

function SetLayout()
    if instance then 

    end
end

function InitialAnimation()
    if instance then 

    end
end