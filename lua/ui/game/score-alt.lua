
-- # imports


local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Text = import('/lua/maui/text.lua').Text
local Grid = import('/lua/maui/Grid.lua').Grid
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')

local LazyVar = import('/lua/Lazyvar.lua').Create

local Prefs = import('/lua/user/prefs.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local FindClients = import('/lua/ui/game/chat.lua').FindClients

-- # locals

local instance = false
local scenario = SessionGetScenarioInfo()
local armies = GetArmiesTable().armiesTable

local showDebugLayout = true
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

local function SyncCallback(sync)
    if instance then 
        local focus = GetFocusArmy()
        local score = sync.Score[focus]

        instance.Time:Set(GetGameTime())

        if score.general.currentunits and score.general.currentcap then 
            instance.UnitData:Set({ Count = score.general.currentunits , Cap = score.general.currentcap })
        end

        if sync.NewPlayableArea then 
            local width = sync.NewPlayableArea[3] - sync.NewPlayableArea[1]
            local height = sync.NewPlayableArea[4] - sync.NewPlayableArea[2]

            -- update existing data
            local mapData = instance.MapData()
            mapData.Width = width
            mapData.Height = height
            instance.MapData:Set(mapData)
        end
    end
end

-- # classes

local ArmyEntry = Class(Group) {

    Rating = LazyVar(0),
    Name = LazyVar(""),
    Faction = LazyVar(0),
    Points = LazyVar(0),
    Defeated = LazyVar(false),

    IncomeData = LazyVar({
        IncomeMass = 0,
        IncomeEnergy = 0,
        BalanceMass = 0,
        BalanceEnergy = 0,
        StorageMass = 0,
        StorageEnergy = 0,
    }),

    __init = function(self, scoreboard, debug, army) 
        Group.__init(self, scoreboard, "scoreboard-army")

        LOG("Hello!")
        reprsl(army)

        -- # do not use self reference as that can be confusing
        local entry = LayoutHelpers.LayoutFor(self)
            :Left(scoreboard.Left)
            :Right(scoreboard.Right)
            :Top(20)                -- dummy value
            :Height(20)
            :Over(scoreboard, 10)
            :End()

        local debugEntry = LayoutHelpers.LayoutFor(Bitmap(debug))
            :Fill(entry)
            :Color('44ffffff')
            :End()

        local faction = LayoutHelpers.LayoutFor(Bitmap(entry))
            :Texture(UIUtil.UIFile(UIUtil.GetFactionIcon(army.faction)))
            :AtLeftIn(entry, 2)
            :AtTopIn(entry, 2)
            :Width(16)
            :Height(16)
            :Over(entry, 10)
            :End()
        
        self.Faction.OnDirty = function()
            faction:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(self.Faction())))
        end

        local rating = faction
        if showRating then 
            rating = LayoutHelpers.LayoutFor(UIUtil.CreateText(scoreboard, "",  12, UIUtil.bodyFont))
                :RightOf(faction, 2)
                :Top(faction.Top)
                :Over(scoreboard, 10)
                :End()

            self.Rating.OnDirty = function()
                
                rating:SetText("(" .. math.floor(self.Rating()+0.5) .. ")")
            end
        end 

        local name = LayoutHelpers.LayoutFor(UIUtil.CreateText(scoreboard, "",  12, UIUtil.bodyFont))
            :RightOf(rating, 2)
            :Top(rating.Top)
            :Over(scoreboard, 10)
            :End()

        self.Name.OnDirty = function()
            name:SetText(tostring(self.Name()))
        end





        -- # initial (sane) values

        self.Faction:Set(army.faction)
        self.Name:Set(army.nickname)
        self.Rating:Set(scenario.Options.Ratings[army.nickname] or 0)
    end,
}

---@class Scoreboard : Group
local Scoreboard = Class(Group) {

    Time = LazyVar(0),

    SimSpeed = LazyVar(0),
    SimSpeedDesired = LazyVar(0),

    UnitData = LazyVar({
        Count = 0, 
        Cap = 0,
    }),

    GameType = LazyVar({
        Name = "",
        Description = "",
    }),

    MapData = LazyVar({
         Name = "", 
         Description = "",
         Width = 0, 
         Height = 0, 
         Version = 0,
         ReplayID = 0
    }),

    Ranked = LazyVar(true),

    __init = function(self, parent)
        Group.__init(self, parent, "scoreboard")

        -- # do not use self reference as that can be confusing
        local scoreboard = LayoutHelpers.LayoutFor(self)
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

        local header = LayoutHelpers.LayoutFor(Bitmap(scoreboard))
            :Left(scoreboard.Left)
            :Right(scoreboard.Right)
            :Top(scoreboard.Top)
            :Bottom(function() return scoreboard.Top() + LayoutHelpers.ScaleNumber(20) end)
            :End()

        LayoutHelpers.LayoutFor(Bitmap(debug))
            :Fill(header)
            :Color('44ff0000')
            :End()

        local body = LayoutHelpers.LayoutFor(Bitmap(scoreboard))
            :Left(scoreboard.Left)
            :Right(scoreboard.Right)
            :Top(header.Bottom)
            :Bottom(function() return header.Bottom() + 200 end)        -- some dummy value to start with
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

        -- # Populate header

        local timeIcon = LayoutHelpers.LayoutFor(Bitmap(scoreboard))
            :Texture(UIUtil.UIFile('/game/unit_view_icons/time.dds'))
            :AtLeftIn(header, 2)
            :AtTopIn(header, 2)
            :Width(14)                  -- match font size
            :Height(14)                 -- match font size
            :Over(scoreboard, 10)
            :End()

        local time = LayoutHelpers.LayoutFor(UIUtil.CreateText(scoreboard, "",  12, UIUtil.bodyFont))
            :RightOf(timeIcon, 2)
            :AtTopIn(header, 2)
            :Color('ff00dbff')
            :Over(scoreboard, 10)
            :End()

        scoreboard.Time.OnDirty = function()
            time:SetText(self.Time())
        end

        local unitIcon = LayoutHelpers.LayoutFor(Bitmap(scoreboard))
            :Texture(UIUtil.UIFile('/dialogs/score-overlay/tank_bmp.dds'))
            :AtRightIn(header, 2)
            :AtTopIn(header, 2)
            :Width(28)
            :Height(14)
            :Over(scoreboard, 10)
            :End()

        local unit = LayoutHelpers.LayoutFor(UIUtil.CreateText(scoreboard, "",  12, UIUtil.bodyFont))
            :LeftOf(unitIcon, 2)
            :AtTopIn(header, 2)
            :Color('ff00dbff')
            :Over(scoreboard, 10)
            :End()

        self.UnitData.OnDirty = function()
            local data = self.UnitData()
            unit:SetText(string.format("%d/%d", data.Count or 0, data.Cap or 0))
        end

        -- # populate footer

        local gametype = LayoutHelpers.LayoutFor(UIUtil.CreateText(scoreboard, "",  12, UIUtil.bodyFont))
            :AtLeftIn(footer, 2)
            :AtTopIn(footer, 2)
            :Over(scoreboard, 10)
            :End()

        self.GameType.OnDirty = function()
            local data = self.GameType()
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

        self.MapData.OnDirty = function()
            local data = self.MapData()

            local name = LOC(tostring(data.Name))
            local description = LOC(tostring(data.Description)) .. "\r\n\r\n" .. LOC("<LOC map_version>Map version") .. ": " .. tostring(data.Version)
            local width = math.ceil(data.Width / 51.2 - 0.5) 
            local height = math.ceil(data.Height / 51.2 - 0.5)
            local size = "(" .. tostring(width) .. "x" .. tostring(height) .. ")"

            map:SetText(size .. " " .. name)
            Tooltip.AddForcedControlTooltipManual(map, name, description)

            local replayID = LOC("<LOC replay_id>Replay ID") .. ": " .. tostring(data.ReplayID)
            replay:SetText(replayID)
        end

        -- # Populate body

        local last = header 

        local entries = { }
        for k, army in armies do 
            if not army.civilian then 
                local entry = LayoutHelpers.LayoutFor(ArmyEntry(scoreboard, debug, army))
                    :Below(last, 2)
                    :End()

                table.insert(entries, entry)

                last = entries[k]
            end
        end

        
        -- # initial (sane) values

        self.Time:Set(GetGameTime())
        self.SimSpeed:Set(0)
        self.SimSpeedDesired:Set(0)
        self.UnitData:Set({
            Count = 0,
            Cap = scenario.Options.UnitCap,
        })

        self.GameType:Set({
            Name = ShareNameLookup[scenario.Options.Share],
            Description = ShareDescriptionLookup[scenario.Options.Share]
        })

        self.MapData:Set({
            Name = scenario.name,
            Description = scenario.description or "No description set by the author.",
            Width = scenario.size[1],
            Height = scenario.size[2],
            Version = scenario.map_version or 0,
            ReplayID = UIUtil.GetReplayId() or 0
        })

        self.Ranked:Set(scenario.Options.Ranked or false)

        -- # other 

        if not showDebugLayout then 
            debug:Hide()
        end
    end,


    --- Allows you to expand / contract the scoreboard accordingly
    --- @param self Scoreboard 
    SetCollapsed = function(self, state)

    end,

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