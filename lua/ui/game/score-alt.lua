
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

---@type Scoreboard
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

        if not table.empty(sync.Score) then
            ArmyStatistics = sync.Score
        end

        instance:ProcessArmyStatistics(ArmyStatistics)
    end
end

-- # classes

---@class ArmyEntry
local ArmyEntry = Class(Group) {

    MassGiftPercentage = 0.2,
    EnergyGiftPercentage = 0.2,

    EntryAlpha = 0.1,
    EntryHighlightAlpha = 0.2,

    StatisticsAlpha = 0.0,
    StatisticsHighlightAlpha = 0.4,

    --- 
    ---@param self ArmyEntry
    ---@param scoreboard Scoreboard
    ---@param debug boolean
    ---@param data ArmiesTableEntry
    ---@param index number
    __init = function(self, scoreboard, debug, data, index) 
        Group.__init(self, scoreboard, "scoreboard-army-" .. index)

        -- # prepare lazy values

        local entry = self
        entry.Rating = LazyVar(0)
        entry.Name = LazyVar("")
        entry.Color = LazyVar("")
        entry.Faction = LazyVar(0)
        entry.Points = LazyVar(0)
        entry.Defeated = LazyVar(false)
        entry.Score = LazyVar(-1)

        entry.IncomeData = LazyVar({
            IncomeMass = false,
            IncomeEnergy = false,
            StorageMass = false,
            StorageEnergy = false,
        })

        -- # store information

        entry.Data = data 
        entry.Debug = debug
        entry.Index = index

        -- # player faction, color, rating and name

        ---@type ArmyEntry
        local entry = LayoutHelpers.LayoutFor(entry)
            :Left(scoreboard.Left)
            :Right(scoreboard.Right)
            :Top(20) -- dummy value
            :Height(20)
            :Over(scoreboard, 10)
            :End()

        entry.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then 
                entry.Highlight:SetAlpha(entry.EntryHighlightAlpha)
            elseif event.Type == 'MouseExit' then 
                entry:DetermineBackgroundColor()
            end
        end

        entry.Highlight = LayoutHelpers.LayoutFor(Bitmap(entry))
            :Fill(entry)
            :Color('44ffffff')
            :Over(scoreboard, 5)
            :End()

        local debugEntry = LayoutHelpers.LayoutFor(Bitmap(debug))
            :Fill(entry)
            :Color('44ffffff')
            :End()

        local faction = LayoutHelpers.LayoutFor(Bitmap(entry))
            :Texture(UIUtil.UIFile(UIUtil.GetFactionIcon(data.faction)))
            :AtLeftIn(entry, 2)
            :AtTopIn(entry, 2)
            :Width(16)
            :Height(16)
            :Over(entry, 10)
            :End()

        entry.Faction.OnDirty = function()
            faction:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(entry.Faction())))
        end

        local factionBackground = LayoutHelpers.LayoutFor(Bitmap(entry))
            :Fill(faction)
            :Under(faction, 1)
            :Color('00ffffff')
            :End()

        entry.Color.OnDirty = function()
            factionBackground:SetSolidColor(entry.Color())
        end

        local rating = faction
        if showRating then 
            rating = LayoutHelpers.LayoutFor(UIUtil.CreateText(scoreboard, "",  12, UIUtil.bodyFont))
                :RightOf(faction, 2)
                :Top(faction.Top)
                :Over(scoreboard, 10)
                :End()

            entry.Rating.OnDirty = function()
                rating:SetText("(" .. math.floor(entry.Rating()+0.5) .. ")")
            end
        end 

        local name = LayoutHelpers.LayoutFor(UIUtil.CreateText(scoreboard, "",  12, UIUtil.bodyFont))
            :RightOf(rating, 2)
            :Top(rating.Top)
            :Over(scoreboard, 10)
            :End()

        entry.Name.OnDirty = function()
            name:SetText(tostring(entry.Name()))
        end

        -- # economy

        local army = LayoutHelpers.LayoutFor(Bitmap(entry))
            :Color('ffffff')
            :AtTopIn(entry, 2)
            :AtRightIn(scoreboard, 2)
            :Width(16)
            :Height(16)
            :Alpha(entry.StatisticsAlpha)
            :Over(scoreboard, 20)
            :End()

        army.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then 
                self:SetAlpha(entry.StatisticsHighlightAlpha)
            elseif event.Type == 'MouseExit' then 
                self:SetAlpha(entry.StatisticsAlpha)
            end
        end

        local armyIcon = LayoutHelpers.LayoutFor(Bitmap(entry))
            :Texture(UIUtil.UIFile('/textures/ui/icons_strategic/commander_generic.dds'))
            :Fill(army)
            :Over(scoreboard, 10)
            :End()

        local energy = LayoutHelpers.LayoutFor(Bitmap(entry))
            :Color('ffffff')
            :LeftOf(army, 2)
            :Top(armyIcon.Top)
            :Width(50)
            :Height(16)
            :Alpha(entry.StatisticsAlpha)
            :Over(scoreboard, 20)
            :End()

        energy.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then 
                self:SetAlpha(entry.StatisticsHighlightAlpha)
            elseif event.Type == 'MouseExit' then 
                self:SetAlpha(entry.StatisticsAlpha)
            end

            entry:EnergyEventBehavior(event)
        end

        local energyIcon = LayoutHelpers.LayoutFor(Bitmap(entry))
            :Texture(UIUtil.UIFile('/game/build-ui/icon-energy_bmp.dds'))
            :AtLeftIn(energy, 2)
            :Top(energy.Top)
            :Width(16)
            :Height(16)
            :Over(scoreboard, 10)
            :Hide()
            :End()

        local energyText = LayoutHelpers.LayoutFor(UIUtil.CreateText(entry, "0",  12, UIUtil.bodyFont))
            :RightOf(energyIcon, 2)
            :Top(energy.Top)
            :Over(scoreboard, 10)
            :Hide()
            :End()

        local mass = LayoutHelpers.LayoutFor(Bitmap(entry))
            :Color('ffffff')
            :LeftOf(energy, 2)
            :Top(energy.Top)
            :Width(50)
            :Height(16)
            :Alpha(entry.StatisticsAlpha)
            :Over(scoreboard, 20)
            :End()

        mass.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then 
                self:SetAlpha(entry.StatisticsHighlightAlpha)
            elseif event.Type == 'MouseExit' then 
                self:SetAlpha(entry.StatisticsAlpha)
            end

            entry:MassEventBehavior(event)
        end

        local massIcon = LayoutHelpers.LayoutFor(Bitmap(entry))
            :Texture(UIUtil.UIFile('/game/build-ui/icon-mass_bmp.dds'))
            :AtLeftIn(mass, 2)
            :Top(mass.Top)
            :Width(16)
            :Height(16)
            :Over(scoreboard, 10)
            :Hide()
            :End()

        local massText = LayoutHelpers.LayoutFor(UIUtil.CreateText(entry, "0",  12, UIUtil.bodyFont))
            :RightOf(massIcon, 2)
            :Top(mass.Top)
            :Over(scoreboard, 10)
            :Hide()
            :End()

        entry.IncomeData.OnDirty = function()
            local incomeData = entry.IncomeData()

            -- show storage
            if IsKeyDown('Shift') then
                if incomeData.StorageMass then 
                    massText:SetText(self:SanitizeNumber(incomeData.StorageMass))
                    massText:Show()
                    massIcon:Show()
                else 
                    massText:SetText("")
                    massIcon:Hide()
                end

                if incomeData.StorageEnergy then 
                    energyText:SetText(self:SanitizeNumber(incomeData.StorageEnergy))
                    energyIcon:Show()
                else 
                    energyText:SetText("")
                    energyText:Show()
                    energyIcon:Hide()
                end

            -- show income
            else
                if incomeData.IncomeMass then 
                    massText:SetText(self:SanitizeNumber(incomeData.IncomeMass))
                    massText:Show()
                    massIcon:Show()
                else 
                    massText:SetText("")
                    massIcon:Hide()
                end

                if incomeData.IncomeEnergy then 
                    energyText:SetText(self:SanitizeNumber(incomeData.IncomeEnergy))
                    energyText:Show()
                    energyIcon:Show()
                else 
                    energyText:SetText("")
                    energyIcon:Hide()
                end
            end
        end

        local score = LayoutHelpers.LayoutFor(Bitmap(entry))
            :Color('ffffff')
            :LeftOf(mass, 2)
            :Top(mass.Top)
            :Width(50)
            :Height(16)
            :Alpha(entry.StatisticsAlpha)
            :Over(scoreboard, 20)
            :End()

        score.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then 
                self:SetAlpha(entry.StatisticsHighlightAlpha)
            elseif event.Type == 'MouseExit' then 
                self:SetAlpha(entry.StatisticsAlpha)
            end

            entry:ScoreEventBehavior(event)
        end

        local scoreIcon = LayoutHelpers.LayoutFor(Bitmap(score))
            :Texture(UIUtil.UIFile('/game/beacons/beacon-quantum-gate_btn_up.dds'))
            :AtLeftIn(score, 2)
            :Top(score.Top)
            :Width(16)
            :Height(16)
            :Over(scoreboard, 10)
            :Hide()
            :End()

        local scoreText = LayoutHelpers.LayoutFor(UIUtil.CreateText(score, "0",  12, UIUtil.bodyFont))
            :RightOf(scoreIcon, 2)
            :Top(score.Top)
            :Over(scoreboard, 10)
            :Hide()
            :End()

        self.Score.OnDirty = function()
            local data = self.Score() 
            if data > 0 then 
                score:Show()
                scoreText:SetText(self:SanitizeNumber(data))
            else 
                score:Hide()
            end
        end

        -- # initial (sane) values

        entry.Faction:Set(data.faction)
        entry.Name:Set(data.nickname)
        entry.Rating:Set(scenario.Options.Ratings[data.nickname] or 0)
        entry.Color:Set(data.iconColor)
        entry.IncomeData:Set(entry.IncomeData())
        entry.Score:Set(entry.Score())

        entry:ComputeBackgroundColor()
    end,

    ---comment
    ---@param self any
    OnDestroy = function(self)
        Group.OnDestroy(self)
        RemoveOnSyncCallback(self:GetName())
    end,

    ---comment
    ---@param self any
    ComputeBackgroundColor = function(self)
        local focus = GetFocusArmy()
        if focus > 0 and self.Index > 0 then 
            if IsAlly(focus, self.Index) then 
                self.Highlight:SetSolidColor('99ff99')
            else 
                self.Highlight:SetSolidColor('9999ff')
            end
        else 
            self.Highlight:SetSolidColor('ffffff')
        end
        
        self:DetermineBackgroundColor()
    end,

    ---comment
    ---@param self any
    DetermineBackgroundColor = function(self)
        local focus = GetFocusArmy()
        if focus > 0 and self.Index > 0 and IsAlly(focus, self.Index) then 
            self.Highlight:SetAlpha(self.EntryAlpha)
        else 
            self.Highlight:SetAlpha(0.0)
        end
    end,

    --- comment
    ---@param self any
    ---@param number any
    ---@return string
    SanitizeNumber = function(self, number)

        if not number then
            return ""
        end

        if number < 1000 then 
            return string.format("%4d", number)
        else
            return string.format("%4dk", 0.1 * math.floor(0.01* number))
        end
    end,

    --- Updates the economy 
    ---@param incomeMass number
    ---@param incomeEnergy number
    ---@param storageMass number
    ---@param storageEnergy number
    UpdateEconomy = function(self, incomeMass, incomeEnergy, storageMass, storageEnergy)
        local incomeData = self.IncomeData()
        incomeData.IncomeMass = incomeMass
        incomeData.IncomeEnergy = incomeEnergy
        incomeData.StorageMass = storageMass
        incomeData.StorageEnergy = storageEnergy
        self.IncomeData:Set(incomeData)
    end,

    UpdateScore = function(self, score)
        self.Score:Set(score)
    end,

    ---
    ---@param self any
    ---@param from number
    ---@param to number
    ---@return string
    NotToSelfMessage = function(self, from, to)
        return "You can't send resources to yourself!"
    end,

    ---comment
    ---@param self any
    ---@param from number
    ---@param to number
    ---@return string
    MassGiftMessage = function(self, from, to)
        return "Sent %d mass to %s"
    end,

    ---comment
    ---@param self any
    ---@param from number
    ---@param to number
    ---@return string
    MassDumpMessage = function(self, from, to)
        return "Dropped %d mass to %s"
    end,

    ---comment
    ---@param self any
    ---@param from number
    ---@param to number
    ---@return string
    MassAskMessage = function(self, from, to)
        return "Could %s gift me mass?"
    end,

    ---comment
    ---@param self any
    ---@return string
    MassEmptyMessage = function(self)
        return "Your mass storage is empty"
    end,

    ---comment
    ---@param self any
    ---@return string
    MassFullMessage = function(self)
        return "Their mass storage is full"
    end,

    ---comment
    ---@param self any
    ---@param event any
    MassEventBehavior = function(self, event)
        local focusArmyIndex = GetFocusArmy()
        if event.Type == 'ButtonPress' and event.Modifiers.Left then

            -- check if we're self
            if focusArmyIndex == self.Index then 
                SessionSendChatMessage(
                    FindClients(),
                    {
                        from = ArmyStatistics[focusArmyIndex].name,
                        to = ArmyStatistics[focusArmyIndex].name,
                        Chat = true,
                        text = string.format(self:NotToSelfMessage())
                    }
                )

                return
            end

            -- check if we're allies
            if IsAlly(focusArmyIndex, self.Index) then

                -- ask for resources
                if event.Modifiers.Shift then

                    SessionSendChatMessage(
                        FindClients(),
                        {
                            from = ArmyStatistics[focusArmyIndex].name,
                            to = 'allies',
                            Chat = true,
                            text = string.format(self:MassAskMessage(focusArmyIndex, self.Index), ArmyStatistics[self.Index].name)
                        }
                    )

                -- give resources
                else
                    local percentage = self.MassGiftPercentage
                    if event.Modifiers.Ctrl then
                        percentage = 1.0
                    end

                    local stored = ArmyStatistics[focusArmyIndex].resources.storage.storedMass
                    local missing = ArmyStatistics[self.Index].resources.storage.maxMass - ArmyStatistics[self.Index].resources.storage.storedMass
                    local amount = math.min(percentage * stored, missing)
                    local percentile = amount / stored

                    if amount > 1 then

                        local message = self:MassGiftMessage(focusArmyIndex, self.Index)
                        if event.Modifiers.Ctrl then
                            message = self:MassDumpMessage(focusArmyIndex, self.Index)
                        end

                        SimCallback(
                            {
                                Func = "GiveResourcesToPlayer",
                                Args = { 
                                    From = focusArmyIndex,
                                    To = self.Index,
                                    Mass = percentile,
                                    Energy = 0,
                                }
                            }
                        )

                        SessionSendChatMessage(
                            FindClients(),
                            {
                                from = ArmyStatistics[focusArmyIndex].name,
                                to = 'allies',
                                Chat = true,
                                text = string.format(message, amount, ArmyStatistics[self.Index].name)
                            }
                        )

                    else 

                        if stored <= 1 then 
                            SessionSendChatMessage(
                                FindClients(),
                                {
                                    from = ArmyStatistics[focusArmyIndex].name,
                                    to = ArmyStatistics[focusArmyIndex].name,
                                    Chat = true,
                                    text = string.format(self:MassEmptyMessage())
                                }
                            )
                        else 
                            SessionSendChatMessage(
                                FindClients(),
                                {
                                    from = ArmyStatistics[focusArmyIndex].name,
                                    to = ArmyStatistics[focusArmyIndex].name,
                                    Chat = true,
                                    text = string.format(self:MassFullMessage())
                                }
                            )
                        end
                    end
                end
            end
        end
    end,

    EnergyEventBehavior = function(self, event)
        local focusArmy = GetFocusArmy()
    end,

    ScoreEventBehavior = function(self, event)
        
    end,

    ArmyEventBehavior = function(self, event)
        
    end,
}

---@class Scoreboard
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

        self.ArmyEntries = { }
        local last = header 
        for k, army in armies do 
            if not army.civilian then 
                local entry = LayoutHelpers.LayoutFor(ArmyEntry(scoreboard, debug, army, k))
                    :Below(last, 2)
                    :End()

                self.ArmyEntries[k] = entry
                last = entry
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

    --- Processes the army statistics to make them visible on the scoreboard
    ---@param self Scoreboard
    ---@param armyStatistics table      # Army statistics as passed over the sync
    ProcessArmyStatistics = function(self, armyStatistics)
        for k, statistics in armyStatistics do 
            self.ArmyEntries[k]:UpdateEconomy(
                statistics.resources.massin.rate and (math.floor(10 * statistics.resources.massin.rate + 0.5)),
                statistics.resources.energyin.rate and (math.floor(10 * statistics.resources.energyin.rate + 0.5)),
                statistics.resources.storage.storedMass,
                statistics.resources.storage.storedEnergy
            )

            self.ArmyEntries[k]:UpdateScore(
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