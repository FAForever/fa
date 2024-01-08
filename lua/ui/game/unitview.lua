--*****************************************************************************
--* File: lua/modules/ui/game/unitview.lua
--* Author: Chris Blackwell
--* Summary: Rollover unit view control
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import("/lua/ui/uiutil.lua")
local DiskGetFileInfo = UIUtil.DiskGetFileInfo
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local GameCommon = import("/lua/ui/game/gamecommon.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local StatusBar = import("/lua/maui/statusbar.lua").StatusBar
local veterancyDefaults = import("/lua/game.lua").VeteranDefault
local Factions = import("/lua/factions.lua")
local Prefs = import("/lua/user/prefs.lua")
local EnhancementCommon = import("/lua/enhancementcommon.lua")
local options = Prefs.GetFromCurrentProfile('options')
local GetUnitRolloverInfo = import("/lua/keymap/selectedinfo.lua").GetUnitRolloverInfo
local unitViewLayout = import(UIUtil.GetLayoutFilename('unitview'))
local unitviewDetail = import("/lua/ui/game/unitviewdetail.lua")
local Grid = import("/lua/maui/grid.lua").Grid
local Construction = import("/lua/ui/game/construction.lua")
local GameMain = import("/lua/ui/game/gamemain.lua")

local selectedUnit = nil
local updateThread = nil
local unitHP = {}
controls = import("/lua/ui/controls.lua").Get()

-- shared between sim and ui
local OverchargeShared = import("/lua/shared/overcharge.lua")

local UpdateWindowShowQueueOfUnit = (categories.SHOWQUEUE * categories.STRUCTURE) + categories.FACTORY

function OverchargeCanKill()
    if unitHP[1] and unitHP.blueprintId then
        local selected = GetSelectedUnits()
        local ACU
        local ACUBp
        local bp

        for _, unit in selected do
            if unit:GetBlueprint().CategoriesHash.COMMAND or
                EntityCategoryContains(categories.SUBCOMMANDER * categories.SERAPHIM, unit) then
                ACU = unit
                break
            end
        end

        if ACU then
            ACUBp = ACU:GetBlueprint()

            if ACUBp.Weapon[2].Overcharge then
                bp = ACUBp.Weapon[2].Overcharge
            elseif ACUBp.Weapon[3].Overcharge then -- cyb ACU
                bp = ACUBp.Weapon[3].Overcharge
                -- First weapon in cyb bp is "torpedo fix". Weapon[1] - torp, [2] - normal gun, [3] - OC. Other ACUs: [1] - normal, [2] - OC.
            end

            if bp then
                local targetCategories = __blueprints[unitHP.blueprintId].CategoriesHash
                local damage = OverchargeShared.EnergyAsDamage(GetEconomyTotals().stored.ENERGY)

                if damage > bp.maxDamage then
                    damage = bp.maxDamage
                end

                if targetCategories.COMMAND then
                    if unitHP[1] < bp.commandDamage then
                        unitHP[1] = nil
                        return true
                    else
                        unitHP[1] = nil
                        return false
                    end
                elseif targetCategories.STRUCTURE then
                    if unitHP[1] < bp.structureDamage then
                        unitHP[1] = nil
                        return true
                    else
                        unitHP[1] = nil
                        return false
                    end
                elseif unitHP[1] < damage then
                    unitHP[1] = nil
                    return true
                else
                    unitHP[1] = nil
                    return false
                end
            end
        end
    end
end

function Contract()
    controls.bg:SetNeedsFrameUpdate(false)
    controls.bg:Hide()
end

function Expand()
    controls.bg:SetNeedsFrameUpdate(true)
    controls.bg:Show()
end

local queueTextures = {
    Move = { texture = UIUtil.UIFile('/game/orders/move_btn_up.dds'), text = '<LOC order_0000>Moving' },
    FormMove = { texture = UIUtil.UIFile('/game/orders/move_btn_up.dds'), text = '<LOC order_0000>Moving' },
    BuildMobile = { texture = UIUtil.UIFile('/game/orders/move_btn_up.dds'), text = '<LOC order_0001>Building' },
    Attack = { texture = UIUtil.UIFile('/game/orders/attack_btn_up.dds'), text = '<LOC order_0002>Attacking' },
    AggressiveMove = { texture = UIUtil.UIFile('/game/orders/attack_btn_up.dds'), text = '<LOC order_0002>Attacking' },
    Upgrade = { texture = UIUtil.UIFile('/game/orders/repair_btn_up.dds'), text = '<LOC order_0003>Upgrading' },
    Guard = { texture = UIUtil.UIFile('/game/orders/guard_btn_up.dds'), text = '<LOC order_0011>' },
    Repair = { texture = UIUtil.UIFile('/game/orders/repair_btn_up.dds'), text = '<LOC order_0005>Repairing' },
    Reclaim = { texture = UIUtil.UIFile('/game/orders/reclaim_btn_up.dds'), text = '<LOC order_0006>Reclaiming' },
    Capture = { texture = UIUtil.UIFile('/game/orders/convert_btn_up.dds'), text = '<LOC order_0007>Capturing' },
    Ferry = { texture = UIUtil.UIFile('/game/orders/ferry_btn_up.dds'), text = '<LOC order_0016>Ferry' },
    Patrol = { texture = UIUtil.UIFile('/game/orders/patrol_btn_up.dds'), text = '<LOC order_0017>Patrol' },
    TransportReverseLoadUnits = { texture = UIUtil.UIFile('/game/orders/load_btn_up.dds'),
        text = '<LOC order_0008>Loading' },
    TransportUnloadUnits = { texture = UIUtil.UIFile('/game/orders/unload_btn_up.dds'),
        text = '<LOC order_0009>Unloading' },
    TransportLoadUnits = { texture = UIUtil.UIFile('/game/orders/load_btn_up.dds'), text = '<LOC order_0010>Loading' },
    AssistCommander = { texture = UIUtil.UIFile('/game/orders/unload02_btn_up.dds'), text = '<LOC order_0011>Assisting' },
    Sacrifice = { texture = UIUtil.UIFile('/game/orders/sacrifice_btn_up.dds'), text = '<LOC order_0012>Sacrificing' },
    Nuke = { texture = UIUtil.UIFile('/game/orders/nuke_btn_up.dds'), text = '<LOC order_0013>Nuking' },
    Tactical = { texture = UIUtil.UIFile('/game/orders/tactical_btn_up.dds'), text = '<LOC order_0014>Launching' },
    OverCharge = { texture = UIUtil.UIFile('/game/orders/overcharge_btn_up.dds'), text = '<LOC order_0015>Overcharging' },
}

local function FormatTime(seconds)
    return string.format("%02d:%02d", math.floor(seconds / 60), math.floor(math.mod(seconds, 60)))
end

local statFuncs = {
    function(info)
        local massUsed = math.max(info.massRequested, info.massConsumed)
        if info.massProduced > 0 or massUsed > 0 then
            return string.format('%+d', math.ceil(info.massProduced - massUsed)),
                UIUtil.UIFile('/game/unit_view_icons/mass.dds'), '00000000'
        elseif info.armyIndex + 1 ~= GetFocusArmy() and info.kills == 0 and info.shieldRatio <= 0 then
            local armyData = GetArmiesTable().armiesTable[info.armyIndex + 1]
            local icon = Factions.Factions[armyData.faction + 1].Icon
            if armyData.showScore and icon then
                return string.sub(armyData.nickname, 1, 12), UIUtil.UIFile(icon), armyData.color
            else
                return false
            end
        else
            return false
        end
    end,
    function(info)
        local energyUsed = math.max(info.energyRequested, info.energyConsumed)
        if info.energyProduced > 0 or energyUsed > 0 then
            return string.format('%+d', math.ceil(info.energyProduced - energyUsed))
        else
            return false
        end
    end,
    function(info)
        if UnitData[info.entityId].xp ~= nil then
            local nextLevel = 0
            local veterancyLevels = __blueprints[info.blueprintId].Veteran or veterancyDefaults
            for index = 1, 5 do
                local i = index
                local vet = veterancyLevels[string.format('Level%d', i)]

                if UnitData[info.entityId].xp < vet then
                    return string.format('%d / %d', UnitData[info.entityId].xp, vet)
                end
            end

            return false
        else
            return false
        end


    end,
    function(info)
        if info.kills > 0 then
            return string.format('%d', info.kills)
        else
            return false
        end
    end,

    function(info)
        if info.tacticalSiloMaxStorageCount > 0 or info.nukeSiloMaxStorageCount > 0 then
            if info.userUnit:IsInCategory('VERIFYMISSILEUI') then
                local curEnh = EnhancementCommon.GetEnhancements(info.userUnit:GetEntityId())
                if curEnh then
                    if curEnh.Back == 'TacticalMissile' or curEnh.Back == 'Missile' then
                        return string.format('%d / %d', info.tacticalSiloStorageCount, info.tacticalSiloMaxStorageCount)
                            , 'tactical'
                    elseif curEnh.Back == 'TacticalNukeMissile' then
                        return string.format('%d / %d', info.nukeSiloStorageCount, info.nukeSiloMaxStorageCount),
                            'strategic'
                    else
                        return false
                    end
                else
                    return false
                end
            end
            if info.nukeSiloMaxStorageCount > 0 then
                return string.format('%d / %d', info.nukeSiloStorageCount, info.nukeSiloMaxStorageCount), 'strategic'
            else
                return string.format('%d / %d', info.tacticalSiloStorageCount, info.tacticalSiloMaxStorageCount),
                    'tactical'
            end
        elseif info.userUnit and not table.empty(GetAttachedUnitsList({ info.userUnit })) then
            return string.format('%d', table.getn(GetAttachedUnitsList({ info.userUnit }))), 'attached'
        else
            return false
        end
    end,
    function(info, bp)
        if info.shieldRatio > 0 then
            return string.format('%d%%', math.floor(info.shieldRatio * 100))
        else
            return false
        end
    end,
    function(info, bp)
        if info.fuelRatio > -1 then
            return FormatTime(bp.Physics.FuelUseTime * info.fuelRatio)
        else
            return false
        end
    end,
    function(info, bp)
        if options.gui_detailed_unitview == 0 then
            return false
        end
        if info.userUnit ~= nil and info.userUnit:GetBuildRate() >= 1 then
            return string.format("%d", math.floor(info.userUnit:GetBuildRate()))
        end
        return false
    end,
}


function CreateQueueGrid(parent)
    controls.queue = Bitmap(parent)
    controls.queue.grid = Bitmap(controls.queue)
    controls.queue.grid.items = {}
    controls.queue.bg = Bitmap(controls.queue)
    controls.queue:DisableHitTest()

    controls.queue.bg.leftBracket = Bitmap(controls.queue.bg)

    controls.queue.bg.rightGlowTop = Bitmap(controls.queue.bg)
    controls.queue.bg.rightGlowMiddle = Bitmap(controls.queue.bg)
    controls.queue.bg.rightGlowBottom = Bitmap(controls.queue.bg)

    controls.queue.bg.leftGlowTop = Bitmap(controls.queue.bg)
    controls.queue.bg.leftGlowMiddle = Bitmap(controls.queue.bg)
    controls.queue.bg.leftGlowBottom = Bitmap(controls.queue.bg)

    local function CreateGridUnitIcon(parent)
        local item = Bitmap(parent)
        item.icon = Bitmap(item)
        item.text = UIUtil.CreateText(item, "", 16, 'Arial Black', true)
        return item
    end

    for id = 1, 7 do
        controls.queue.grid.items[id] = CreateGridUnitIcon(controls.queue.grid)
    end

    controls.queue.grid.UpdateQueue = function(self, queue)
        if not queue then
            controls.queue:Hide()
        else
            controls.queue:Show()
            for id, item in self.items do
                if queue[id] then
                    item:Show()
                    item.icon:SetTexture(UIUtil.UIFile('/icons/units/' .. queue[id].id .. '_icon.dds', true))
                    item.text:SetText(tostring(queue[id].count))
                else
                    item:Hide()
                end
            end
        end
    end
    controls.queue:Hide()
end

function UpdateWindow(info)
    if info.blueprintId == 'unknown' then
        controls.name:SetText(LOC('<LOC rollover_0000>Unknown Unit'))
        controls.icon:SetTexture('/textures/ui/common/game/unit_view_icons/unidentified.dds')
        controls.stratIcon:SetTexture('/textures/ui/common/game/strategicicons/icon_structure_generic_selected.dds')
        for index = 1, table.getn(controls.statGroups) do
            local i = index
            controls.statGroups[i].icon:Hide()
            if controls.statGroups[i].color then
                controls.statGroups[i].color:SetSolidColor('00000000')
            end
            if controls.vetIcons[i] then
                controls.vetIcons[i]:Hide()
            end
        end
        controls.healthBar:Hide()
        controls.shieldBar:Hide()
        controls.fuelBar:Hide()
        controls.vetBar:Hide()
        controls.actionIcon:Hide()
        controls.actionText:Hide()
        controls.abilities:Hide()
        controls.ReclaimGroup:Hide()
    else
        local bp = __blueprints[info.blueprintId]
        local icon = '/icons/units/' .. (bp.BaseBlueprintId or bp.BlueprintId) .. '_icon.dds'
        if DiskGetFileInfo(UIUtil.UIFile(icon, true)) then
            controls.icon:SetTexture(UIUtil.UIFile(icon, true))
        else
            controls.icon:SetTexture('/textures/ui/common/game/unit_view_icons/unidentified.dds')
        end
        if DiskGetFileInfo('/textures/ui/common/game/strategicicons/' .. bp.StrategicIconName .. '_selected.dds') then
            controls.stratIcon:SetTexture('/textures/ui/common/game/strategicicons/' ..
                bp.StrategicIconName .. '_selected.dds')
        else
            controls.stratIcon:SetSolidColor('00000000')
        end
        local techLevel = false
        local levels = { TECH1 = 1, TECH2 = 2, TECH3 = 3 }
        for cat, level in levels do
            if bp.CategoriesHash[cat] then
                techLevel = level
                break
            end
        end
        local description = LOC(bp.Description)
        if techLevel then
            description = LOC('<LOC _Tech>') .. techLevel .. ' ' .. description
        end
        LayoutHelpers.AtTopIn(controls.name, controls.bg, 10)
        controls.name:SetFont(UIUtil.bodyFont, 14)
        local name = ''
        if info.customName then
            name = LOC(info.customName)
        elseif bp.General.UnitName then
            name = LOC(bp.General.UnitName)
        end
        if name ~= '' then
            name = name .. ': '
        end
        controls.name:SetText(name .. description)
        local scale = controls.name.Width() / controls.name.TextAdvance()
        if scale < 1 then
            LayoutHelpers.AtTopIn(controls.name, controls.bg, 10 / scale)
            controls.name:SetFont(UIUtil.bodyFont, 14 * scale)
        end
        for index = 1, table.getn(statFuncs) do
            local i = index
            if statFuncs[i](info, bp) then
                if i == 1 then
                    local value, iconType, color = statFuncs[i](info, bp)
                    controls.statGroups[i].color:SetSolidColor(color)
                    controls.statGroups[i].icon:SetTexture(iconType)
                    controls.statGroups[i].value:SetText(value)
                elseif i == 3 then
                    local value, iconType, color = statFuncs[i](info, bp)
                    controls.statGroups[i].value:SetText(value)
                    controls.statGroups[i].icon:SetTexture(UIUtil.UIFile(Factions.Factions[
                        Factions.FactionIndexMap[string.lower(bp.General.FactionName)] ].VeteranIcon))
                elseif i == 5 then
                    local text, iconType = statFuncs[i](info, bp)
                    controls.statGroups[i].value:SetText(text)
                    if iconType == 'strategic' then
                        controls.statGroups[i].icon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/missiles.dds'))
                    elseif iconType == 'attached' then
                        controls.statGroups[i].icon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/attached.dds'))
                    else
                        controls.statGroups[i].icon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/tactical.dds'))
                    end
                else
                    controls.statGroups[i].value:SetText(statFuncs[i](info, bp))
                end
                controls.statGroups[i].icon:Show()
            else
                controls.statGroups[i].icon:Hide()
                if controls.statGroups[i].color then
                    controls.statGroups[i].color:SetSolidColor('00000000')
                end
            end
        end

        controls.fuelBar:Hide()
        controls.vetBar:Hide()
        controls.ReclaimGroup:Hide()

        if info.shieldRatio > 0 then
            controls.shieldBar:Show()
            controls.shieldBar:SetValue(info.shieldRatio)
        else
            controls.shieldBar:Hide()
        end

        if info.fuelRatio > 0 then
            controls.fuelBar:Show()
            controls.fuelBar:SetValue(info.fuelRatio)
        end

        if info.shieldRatio > 0 and info.fuelRatio > 0 then
            controls.store = 1
        else
            controls.store = 0
        end

        if info.health then
            controls.healthBar:Show()

            -- Removing a MaxHealth buff causes health > maxhealth until a damage event for some reason
            info.health = math.min(info.health, info.maxHealth)

            if not info.userUnit then
                unitHP[1] = info.health
                unitHP.blueprintId = info.blueprintId
            end

            controls.healthBar:SetValue(info.health / info.maxHealth)
            if info.health / info.maxHealth > .75 then
                controls.healthBar._bar:SetTexture(UIUtil.UIFile('/game/unit-build-over-panel/healthbar_green.dds'))
            elseif info.health / info.maxHealth > .25 then
                controls.healthBar._bar:SetTexture(UIUtil.UIFile('/game/unit-build-over-panel/healthbar_yellow.dds'))
            else
                controls.healthBar._bar:SetTexture(UIUtil.UIFile('/game/unit-build-over-panel/healthbar_red.dds'))
            end
            controls.health:SetText(string.format("%d / %d", info.health, info.maxHealth))
        else
            controls.healthBar:Hide()
        end

        -- always hide veterancy stars initially
        for i = 1, 5 do
            controls.vetIcons[i]:Hide()
        end

        -- Control the veterancy stars
        if info.entityId then
            local unit = GetUnitById(info.entityId)
            if unit then
                local blueprint = unit:GetBlueprint()

                if blueprint.VetEnabled then
                    local level = unit:GetStat('VetLevel', 0).Value
                    local experience = unit:GetStat('VetExperience', 0).Value

                    local progress, title
                    local lowerThreshold, upperThreshold
                    if level < 5 then
                        lowerThreshold = blueprint.VetThresholds[level] or 0
                        upperThreshold = blueprint.VetThresholds[level + 1]
                    end

                    -- show stars
                    for i = 1, 5 do
                        if level >= i then
                            controls.vetIcons[i]:Show()
                            controls.vetIcons[i]:SetTexture(UIUtil.UIFile(Factions.Factions[Factions.FactionIndexMap[string.lower(bp.General.FactionName)] ].VeteranIcon))
                        end
                    end

                    -- show veterancy to gain
                    if lowerThreshold then
                        title = 'Veterancy'
                        progress = (experience - lowerThreshold) / (upperThreshold - lowerThreshold)

                        local text = ''
                        if upperThreshold >= 1000000 then
                            text = string.format('%.2fM/%.2fM', experience / 1000000, upperThreshold / 1000000)
                        elseif upperThreshold >= 100000 then
                            text = string.format('%.0fK/%.0fK', experience / 1000, upperThreshold / 1000)
                        elseif upperThreshold >= 10000 then
                            text = string.format('%.1fK/%.1fK', experience / 1000, upperThreshold / 1000)
                        else
                            text = experience .. '/' .. upperThreshold
                        end
                        controls.nextVet:SetText(text)

                    -- show total experience
                    else
                        title = 'Mass killed'
                        progress = 1

                        local text
                        if experience >= 1000000 then
                            text = string.format('%.2fM', experience / 1000000)
                        elseif experience >= 100000 then
                            text = string.format('%.0fK', experience / 1000)
                        elseif experience >= 10000 then
                            text = string.format('%.1fK', experience / 1000)
                        else
                            text = experience
                        end
                        controls.nextVet:SetText(text)
                    end

                    -- always show it, regardless
                    controls.vetBar:Show()
                    controls.vetBar:SetValue(progress)
                    controls.vetTitle:SetText(title)

                -- show reclaim statistics
                else
                    local reclaimedMass, reclaimedEnergy
                    if unit then
                        reclaimedMass = unit:GetStat('ReclaimedMass').Value
                        reclaimedEnergy = unit:GetStat('ReclaimedEnergy').Value
                    end
                    if reclaimedMass or reclaimedEnergy then
                        controls.ReclaimGroup:Show()
                        controls.ReclaimGroup.MassText:SetText(tostring(reclaimedMass or 0))
                        controls.ReclaimGroup.EnergyText:SetText(tostring(reclaimedEnergy or 0))
                    end
                end
            end
        end

        local unitQueue = false
        if info.userUnit then
            unitQueue = info.userUnit:GetCommandQueue()
        end

        -- -- Build queue upon hovering of unit

        local always = Prefs.GetFromCurrentProfile('options.gui_queue_on_hover_02') == 'always'
        local isObserver = GameMain.OriginalFocusArmy == -1 or GetFocusArmy() == -1
        local whenObserving = Prefs.GetFromCurrentProfile('options.gui_queue_on_hover_02') == 'only-obs'

        if always or (whenObserving and isObserver) then
            if (info.userUnit ~= nil) and EntityCategoryContains(UpdateWindowShowQueueOfUnit, info.userUnit) and
                (info.userUnit ~= selectedUnit) then

                -- find the main factory we're using the queue of
                local mainFactory
                local factory = info.userUnit
                while true do
                    mainFactory = factory:GetGuardedEntity()
                    if mainFactory == nil then
                        break
                    end
                    factory = mainFactory
                end

                -- show that queue
                controls.queue.grid:UpdateQueue(PeekCurrentFactoryForQueueDisplay(factory))
            else
                controls.queue:Hide()
            end
        else
            controls.queue:Hide()
        end

        if info.focus then
            if DiskGetFileInfo(UIUtil.UIFile('/icons/units/' .. info.focus.blueprintId .. '_icon.dds', true)) then
                controls.actionIcon:SetTexture(UIUtil.UIFile('/icons/units/' .. info.focus.blueprintId .. '_icon.dds',
                    true))
            else
                controls.actionIcon:SetTexture('/textures/ui/common/game/unit_view_icons/unidentified.dds')
            end
            if info.focus.health and info.focus.maxHealth then
                controls.actionText:SetFont(UIUtil.bodyFont, 14)
                controls.actionText:SetText(string.format('%d%%', (info.focus.health / info.focus.maxHealth) * 100))
            elseif queueTextures[unitQueue[1].type] then
                controls.actionText:SetFont(UIUtil.bodyFont, 10)
                controls.actionText:SetText(LOC(queueTextures[unitQueue[1].type].text))
            else
                controls.actionText:SetText('')
            end
            controls.actionIcon:Show()
            controls.actionText:Show()
        elseif info.focusUpgrade then
            controls.actionIcon:SetTexture(queueTextures.Upgrade.texture)
            controls.actionText:SetFont(UIUtil.bodyFont, 14)
            controls.actionText:SetText(string.format('%d%%', info.workProgress * 100))
            controls.actionIcon:Show()
            controls.actionText:Show()
        elseif info.userUnit and queueTextures[unitQueue[1].type] and not info.userUnit:IsInCategory('FACTORY') then
            controls.actionText:SetFont(UIUtil.bodyFont, 10)
            controls.actionText:SetText(LOC(queueTextures[unitQueue[1].type].text))
            controls.actionIcon:SetTexture(queueTextures[unitQueue[1].type].texture)
            controls.actionIcon:Show()
            controls.actionText:Show()
        elseif info.userUnit and info.userUnit:IsIdle() then
            controls.actionIcon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/idle.dds'))
            controls.actionText:SetFont(UIUtil.bodyFont, 10)
            controls.actionText:SetText(LOC('<LOC _Idle>'))
            controls.actionIcon:Show()
            controls.actionText:Show()
        else
            controls.actionIcon:Hide()
            controls.actionText:Hide()
        end

        local lines = nil
        if Prefs.GetOption('uvd_format') == 'full' then
            lines = {}
            --Get not autodetected abilities
            if bp.Display.Abilities then
                for _, id in bp.Display.Abilities do
                    local ability = unitviewDetail.ExtractAbilityFromString(id)
                    if not unitviewDetail.IsAbilityExist[ability] then
                        table.insert(lines, LOC(id))
                    end
                end
            end
            --Autodetect abilities
            for id, func in unitviewDetail.IsAbilityExist do
                if (id ~= 'ability_building') and (id ~= 'ability_repairs') and
                    (id ~= 'ability_reclaim') and (id ~= 'ability_capture') and func(bp) then
                    table.insert(lines, LOC('<LOC ' .. id .. '>'))
                end
            end
        end
        if lines and (not table.empty(lines)) then
            local i = 1
            local maxWidth = 0
            local index = table.getn(lines)
            while lines[index] do
                if not controls.abilityText[i] then
                    controls.abilityText[i] = UIUtil.CreateText(controls.abilities, lines[index], 12, UIUtil.bodyFont)
                    controls.abilityText[i]:DisableHitTest()
                    if i == 1 then
                        LayoutHelpers.AtLeftIn(controls.abilityText[i], controls.abilities)
                        LayoutHelpers.AtBottomIn(controls.abilityText[i], controls.abilities)
                    else
                        LayoutHelpers.Above(controls.abilityText[i], controls.abilityText[i - 1])
                    end
                else
                    controls.abilityText[i]:SetText(lines[index])
                end
                maxWidth = math.max(maxWidth, controls.abilityText[i].Width())
                index = index - 1
                i = i + 1
            end
            while controls.abilityText[i] do
                controls.abilityText[i]:Destroy()
                controls.abilityText[i] = nil
                i = i + 1
            end
            controls.abilities.Width:Set(maxWidth)
            controls.abilities.Height:Set(function() return controls.abilityText[1].Height() *
                table.getsize(controls.abilityText) end)
            if controls.abilities:IsHidden() then
                controls.abilities:Show()
            end
        elseif not controls.abilities:IsHidden() then
            controls.abilities:Hide()
        end
    end
    if options.gui_enhanced_unitview ~= 0 then
        -- Replace fuel bar with progress bar
        if info.blueprintId ~= 'unknown' then
            controls.fuelBar:Hide()
            if info.workProgress > 0 then
                controls.fuelBar:Show()
                controls.fuelBar:SetValue(info.workProgress)
            end
        end
    end
    if options.gui_detailed_unitview ~= 0 then
        if info.blueprintId ~= 'unknown' then
            controls.shieldText:Hide()

            if info.userUnit ~= nil then
                local regen = info.userUnit:GetStat("HitpointsRegeneration", 0).Value or 0
                controls.health:SetText(string.format("%d / %d +%d/s", info.health, info.maxHealth, regen))
            end

            if info.shieldRatio > 0 then
                local getEnh = import("/lua/enhancementcommon.lua")
                local unitBp = info.userUnit:GetBlueprint()
                local shield = unitBp.Defense.Shield
                if not shield.ShieldMaxHealth then
                    shield = unitBp.Enhancements[getEnh.GetEnhancements(info.entityId).Back]
                end
                local shieldMaxHealth, shieldRegenRate = shield.ShieldMaxHealth or 0, shield.ShieldRegenRate or 0
                if shieldMaxHealth > 0 then
                    local shieldHealth = math.floor(shieldMaxHealth * info.shieldRatio)
                    local shieldText = string.format("%d / %d", shieldHealth, shieldMaxHealth)
                    if shieldRegenRate > 0 then
                        shieldText = shieldText .. string.format("+%d/s", shieldRegenRate)
                    end
                    if shieldMaxHealth > 0 then
                        controls.shieldText:Show()
                        if shieldRegenRate > 0 then
                            controls.shieldText:SetText(string.format("%d / %d +%d/s",
                                math.floor(shieldMaxHealth * info.shieldRatio), shieldMaxHealth, shieldRegenRate))
                        else
                            controls.shieldText:SetText(string.format("%d / %d",
                                math.floor(shieldMaxHealth * info.shieldRatio), shieldMaxHealth))
                        end
                    end
                end
            end
        end
    end

    UpdateEnhancementIcons(info)
end

local GetEnhancementPrefix = import("/lua/ui/game/construction.lua").GetEnhancementPrefix
function UpdateEnhancementIcons(info)
    local unit = info.userUnit
    local existingEnhancements
    if unit then
        existingEnhancements = EnhancementCommon.GetEnhancements(unit:GetEntityId())
    end

    for slot, enhancement in controls.enhancements do
        if unit == nil or
            (not unit:IsInCategory('COMMAND') and not unit:IsInCategory('SUBCOMMANDER')) or
            existingEnhancements == nil or existingEnhancements[slot] == nil then
            enhancement:Hide()
            continue
        end

        local bp = unit:GetBlueprint()
        local bpId = bp.BlueprintId
        local enhancementBp = bp.Enhancements[ existingEnhancements[slot] ]
        local texture = GetEnhancementPrefix(bpId, enhancementBp.Icon) .. '_btn_up.dds'

        enhancement:Show()
        enhancement:SetTexture(UIUtil.UIFile(texture, true))
        LayoutHelpers.SetDimensions(enhancement, 30, 30)
    end
end

function ShowROBox()
end

function SetLayout(layout)
    unitViewLayout.SetLayout()
end

function SetupUnitViewLayout(mapGroup, orderControl)
    controls.parent = mapGroup
    controls.orderPanel = orderControl
    CreateUI()
    SetLayout(UIUtil.currentLayout)
end

function CreateUI()
    controls.bg = Bitmap(controls.parent)
    controls.bracket = Bitmap(controls.bg)
    controls.name = UIUtil.CreateText(controls.bg, '', 14, UIUtil.bodyFont)
    controls.icon = Bitmap(controls.bg)
    controls.stratIcon = Bitmap(controls.bg)
    controls.vetIcons = {}
    for i = 1, 5 do
        controls.vetIcons[i] = Bitmap(controls.bg)
    end
    controls.healthBar = StatusBar(controls.bg, 0, 1, false, false, nil, nil, true)
    controls.shieldBar = StatusBar(controls.bg, 0, 1, false, false, nil, nil, true)
    controls.fuelBar = StatusBar(controls.bg, 0, 1, false, false, nil, nil, true)
    controls.health = UIUtil.CreateText(controls.healthBar, '', 14, UIUtil.bodyFont)
    controls.vetBar = StatusBar(controls.bg, 0, 1, false, false, nil, nil, true)
    controls.nextVet = UIUtil.CreateText(controls.vetBar, '', 10, UIUtil.bodyFont)
    controls.vetTitle = UIUtil.CreateText(controls.vetBar, 'Veterancy', 10, UIUtil.bodyFont)

    controls.ReclaimGroup = Group(controls.bg)
    -- controls.ReclaimGroup.Title = UIUtil.CreateText(controls.ReclaimGroup, 'Reclaimed', 10, UIUtil.bodyFont)
    controls.ReclaimGroup.Debug = Bitmap(controls.ReclaimGroup)
    controls.ReclaimGroup.MassIcon = Bitmap(controls.ReclaimGroup)
    controls.ReclaimGroup.EnergyIcon = Bitmap(controls.ReclaimGroup)
    controls.ReclaimGroup.MassText = UIUtil.CreateText(controls.ReclaimGroup, '0', 10, UIUtil.bodyFont)
    controls.ReclaimGroup.EnergyText = UIUtil.CreateText(controls.ReclaimGroup, '0', 10, UIUtil.bodyFont)
    -- controls.ReclaimGroup.MassReclaimed = UIUtil.CreateText(controls.ReclaimGroup, '0', 10, UIUtil.bodyFont)
    -- controls.ReclaimGroup.MassIcon = Bitmap(controls.ReclaimGroup)
    -- controls.ReclaimGroup.MassReclaimed = UIUtil.CreateText(controls.ReclaimGroup, '0', 10, UIUtil.bodyFont)

    controls.statGroups = {}
    for i = 1, table.getn(statFuncs) do
        controls.statGroups[i] = {}
        controls.statGroups[i].icon = Bitmap(controls.bg)
        controls.statGroups[i].value = UIUtil.CreateText(controls.statGroups[i].icon, '', 12, UIUtil.bodyFont)
        if i == 1 then
            controls.statGroups[i].color = Bitmap(controls.bg)
            LayoutHelpers.FillParent(controls.statGroups[i].color, controls.statGroups[i].icon)
            controls.statGroups[i].color.Depth:Set(function() return controls.statGroups[i].icon.Depth() - 1 end)
        end
    end
    controls.actionIcon = Bitmap(controls.bg)
    controls.actionText = UIUtil.CreateText(controls.bg, '', 14, UIUtil.bodyFont)

    controls.abilities = Group(controls.bg)
    controls.abilityText = {}

    controls.bg:DisableHitTest(true)

    controls.bg:SetNeedsFrameUpdate(true)

    if options.gui_detailed_unitview ~= 0 then
        controls.shieldText = UIUtil.CreateText(controls.bg, '', 13, UIUtil.bodyFont)
    end

    controls.bg.OnFrame = function(self, delta)
        local info = GetRolloverInfo()
        if not info and selectedUnit and options.gui_enhanced_unitview ~= 0 then
            info = GetUnitRolloverInfo(selectedUnit)
        end

        if info and import("/lua/ui/game/unitviewdetail.lua").View:IsHidden() then
            UpdateWindow(info)
            if self:GetAlpha() < 1 then
                self:SetAlpha(1, true)
            end
            unitViewLayout.PositionWindow()
            unitViewLayout.UpdateStatusBars(controls)
        elseif self:GetAlpha() > 0 then
            self:SetAlpha(0, true)
        end
    end

    -- This section is for the small icons showing what active enhancements an ACU has
    controls.enhancements = {}
    controls.enhancements['RCH'] = Bitmap(controls.bg)
    controls.enhancements['Back'] = Bitmap(controls.bg)
    controls.enhancements['LCH'] = Bitmap(controls.bg)

    LayoutHelpers.AtLeftTopIn(controls.enhancements['RCH'], controls.bg, 10, -30)
    LayoutHelpers.AtLeftTopIn(controls.enhancements['Back'], controls.bg, 42, -30)
    LayoutHelpers.AtLeftTopIn(controls.enhancements['LCH'], controls.bg, 74, -30)
    CreateQueueGrid(controls.bg)
end

function OnSelection(units)
    -- set if we have one unit selected, useful for state management for information to show
    if units and table.getn(units) == 1 then
        selectedUnit = units[1]
    else
        selectedUnit = nil
    end
end
