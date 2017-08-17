
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')
local UnitDescriptions = import('/lua/ui/help/unitdescription.lua').Description

local controls = import('/lua/ui/controls.lua').Get()

View = controls.View or false
MapView = controls.MapView or false
ViewState = "full"

local enhancementSlotNames =
{
    back = "<LOC uvd_0007>Back",
    lch = "<LOC uvd_0008>LCH",
    rch = "<LOC uvd_0009>RCH",
}

function Contract()
    View:Hide()
end

function Expand()
    View:Show()
end

function GetTechLevelString(bp)
    if EntityCategoryContains(categories.TECH1, bp.BlueprintId) then
        return 1
    elseif EntityCategoryContains(categories.TECH2, bp.BlueprintId) then
        return 2
    elseif EntityCategoryContains(categories.TECH3, bp.BlueprintId) then
        return 3
    else
        return false
    end
end

function FormatTime(seconds)
    return string.format("%02d:%02d", math.floor(seconds / 60), math.mod(seconds, 60))
end

function GetAbilityList(bp)
    local abilitiesList = {}

    return abilitiesList
end

function CheckFormat()
    if ViewState ~= Prefs.GetOption('uvd_format') then
        SetLayout()
    end
    if ViewState == "off" then
        return false
    else
        return true
    end
end

function ShowView(showUpKeep, enhancement, showecon, showShield)
    import('/lua/ui/game/unitview.lua').ShowROBox(false, false)
    View:Show()

    View.UpkeepGroup:SetHidden(not showUpKeep)

    View.BuildCostGroup:SetHidden(not showecon)
    View.UpkeepGroup:SetHidden(not showUpKeep)
    View.TimeStat:SetHidden(not showecon)
    View.HealthStat:SetHidden(not showecon)

    View.HealthStat:SetHidden(enhancement)

    View.ShieldStat:SetHidden(not showShield)

    if View.Description then
        View.Description:SetHidden(ViewState == "limited" or View.Description.Value[1]:GetText() == "")
    end
end

function ShowEnhancement(bp, bpID, iconID, iconPrefix, userUnit)
    if not CheckFormat() then
        View:Hide()
        return
    end

    -- Name / Description
    View.UnitImg:SetTexture(UIUtil.UIFile(iconPrefix..'_btn_up.dds'))

    LayoutHelpers.AtTopIn(View.UnitShortDesc, View, 10)
    View.UnitShortDesc:SetFont(UIUtil.bodyFont, 14)

    local slotName = enhancementSlotNames[string.lower(bp.Slot)]
    slotName = slotName or bp.Slot

    if bp.Name ~= nil then
        View.UnitShortDesc:SetText(LOCF("%s: %s", bp.Name, slotName))
    else
        View.UnitShortDesc:SetText(LOC(slotName))
    end
    if View.UnitShortDesc:GetStringAdvance(View.UnitShortDesc:GetText()) > View.UnitShortDesc.Width() then
        LayoutHelpers.AtTopIn(View.UnitShortDesc, View, 14)
        View.UnitShortDesc:SetFont(UIUtil.bodyFont, 10)
    end

    local showecon = true
    local showAbilities = false
    local showUpKeep = false
    local time, energy, mass
    if bp.Icon ~= nil and not string.find(bp.Name, 'Remove') then
        time, energy, mass = import('/lua/game.lua').GetConstructEconomyModel(userUnit, bp)
        time = math.max(time, 1)
        showUpKeep = DisplayResources(bp, time, energy, mass)
        View.TimeStat.Value:SetFont(UIUtil.bodyFont, 14)
        View.TimeStat.Value:SetText(string.format("%s", FormatTime(time)))
        if string.len(View.TimeStat.Value:GetText()) > 5 then
            View.TimeStat.Value:SetFont(UIUtil.bodyFont, 10)
        end
    else
        showecon = false
        if View.Description then
            View.Description:Hide()
            for i, v in View.Description.Value do
                v:SetText("")
            end
        end
    end

    if View.Description then
        -- If SubCommander enhancement, then remove extension. (ual0301_Engineer --> ual0301)
        if string.find(bpID, '0301_') then
            bpID = string.sub(bpID, 1, string.find(bpID, "_[^_]*$")-1)
        end
        local tempDescID = bpID.."-"..iconID
        if UnitDescriptions[tempDescID] and not string.find(bp.Name, 'Remove') then
            local tempDesc = LOC(UnitDescriptions[tempDescID])
            WrapAndPlaceText(nil, nil, nil, nil, tempDesc, View.Description)
        else
            WARN('No description found for unit: ', bpID, ' enhancement: ', iconID)
            View.Description:Hide()
            for i, v in View.Description.Value do
                v:SetText("")
            end
        end
    end

    local showShield = false
    if bp.ShieldMaxHealth then
        showShield = true
        View.ShieldStat.Value:SetText(bp.ShieldMaxHealth)
    end

    ShowView(showUpKeep, true, showecon, showShield)
    if time == 0 and energy == 0 and mass == 0 then
        View.BuildCostGroup:Hide()
        View.TimeStat:Hide()
    end
end

function WrapAndPlaceText(air, physics, weapons, abilities, text, control)
    local ppf = 1
    local dotpulses = 1
    local lines = {}
    -- Used to set the line colour correctly.
    local physics_line = -1
    local weapon_start = -1
    if text then
        lines = import('/lua/maui/text.lua').WrapText(text, control.Value[1].Width(),
                function(text) return control.Value[1]:GetStringAdvance(text) end)
    end
    local abilityLines = 0
    if abilities then
        local i = table.getn(abilities)
        while abilities[i] do
            table.insert(lines, 1, LOC(abilities[i]))
            i = i - 1
        end
        abilityLines = table.getsize(abilities)
    end

    if options.gui_render_armament_detail == 1 then
        weapon_start = table.getsize(lines)
        if weapons then
            if table.getn(weapons) > 0 then
                table.insert(lines, "")
            end
            local lastWeapon = {}

            -- Used to count up duplicate weapons.
            local mflag = 0
            for i, weapon in weapons do
                if weapon.WeaponCategory and weapon.WeaponCategory ~= 'Death' then
                    if weapon.DisplayName == lastWeapon.DisplayName then
                        mflag = mflag + 1
                    else
                        if mflag ~= 0 then
                            table.insert(lines, string.format("%s (%s) x%d",
                                weapon.DisplayName,
                                weapon.WeaponCategory,
                                mflag + 1))
                        else
                            table.insert(lines, string.format("%s (%s)", weapon.DisplayName, weapon.WeaponCategory)
                            )
                        end

                        if weapon.ProjectilesPerOnFire then
                            ppf = weapon.ProjectilesPerOnFire
                        else
                            ppf = 1
                        end

                        if weapon.DoTPulses then
                            dotpulses = weapon.DoTPulses
                        else
                            dotpulses = 1
                        end

                        table.insert(lines, LOCF("<LOC gameui_0001>Damage: %d, Rate: %0.2f (DPS: %d)  Range: %d",
                            weapon.Damage * ppf * dotpulses,
                            1.0 / weapon.RateOfFire,
                            math.floor(weapon.Damage * ppf * dotpulses * weapon.RateOfFire),
                            weapon.MaxRadius))
                        mflag = 0
                    end

                    lastWeapon = weapon
                end
            end
        end

        if air and air.MaxAirspeed and air.MaxAirspeed ~=0 then
            table.insert(lines, "")
            table.insert(lines, LOCF("<LOC gameui_0002>Speed: %0.2f, Turning: %0.2f",
                air.MaxAirspeed,
                air.TurnSpeed))
            physics_line = table.getn(lines)
        elseif physics and physics.MaxSpeed and physics.MaxSpeed ~=0 then
            table.insert(lines, "")
            table.insert(lines, LOCF("<LOC gameui_0003>Speed: %0.2f, Acceleration: %0.2f, Turning: %d",
                physics.MaxSpeed,
                physics.MaxBrake,
                physics.TurnRate))
            physics_line = table.getn(lines)
        end

        weapon_start = weapon_start + 1
    end

    for i, v in lines do
        local index = i
        if control.Value[index] then
            control.Value[index]:SetText(v)
        else
            control.Value[index] = UIUtil.CreateText(control, v, 12, UIUtil.bodyFont)
            LayoutHelpers.Below(control.Value[index], control.Value[index-1])
            control.Value[index].Right:Set(function() return control.Right() - 7 end)
            control.Value[index].Width:Set(function() return control.Right() - control.Left() - 14 end)
            control.Value[index]:SetClipToWidth(true)
            control.Value[index]:DisableHitTest()
        end
        if index <= abilityLines then
            control.Value[index]:SetColor(UIUtil.bodyColor)
        elseif index == physics_line then
            control.Value[index]:SetColor('FFb0ffb0')
        elseif index == weapon_start then
            control.Value[index]:SetColor('ffff9999')
            weapon_start = weapon_start + 2
        else
            control.Value[index]:SetColor(UIUtil.fontColor)
        end
        control.Height:Set(function() return (math.max(table.getsize(lines), 4) * control.Value[1].Height()) + 30 end)
    end
    for i, v in control.Value do
        local index = i
        if index > table.getsize(lines) then
            v:SetText("")
        end
    end
end

function Show(bp, buildingUnit, bpID)
    if not CheckFormat() then
        View:Hide()
        return
    end

    -- Name / Description
    LayoutHelpers.AtTopIn(View.UnitShortDesc, View, 10)
    View.UnitShortDesc:SetFont(UIUtil.bodyFont, 14)
    local description = LOC(bp.Description)
    if GetTechLevelString(bp) then
        description = LOCF('Tech %d %s', GetTechLevelString(bp), description)
    end
    if bp.General.UnitName ~= nil then
        View.UnitShortDesc:SetText(LOCF("%s: %s", bp.General.UnitName, description))
    else
        View.UnitShortDesc:SetText(LOCF("%s", description))
    end
    if View.UnitShortDesc:GetStringAdvance(View.UnitShortDesc:GetText()) > View.UnitShortDesc.Width() then
        LayoutHelpers.AtTopIn(View.UnitShortDesc, View, 14)
        View.UnitShortDesc:SetFont(UIUtil.bodyFont, 10)
    end
    local showecon = true
    local showUpKeep = false
    local showAbilities = false
    if buildingUnit ~= nil then
        -- Differential upgrading. Check to see if building this would be an upgrade
        local targetBp = bp
        local builderBp = buildingUnit:GetBlueprint()

        local performUpgrade = false

        if targetBp.General.UpgradesFrom == builderBp.BlueprintId then
            performUpgrade = true
        elseif targetBp.General.UpgradesFrom == builderBp.General.UpgradesTo then
            performUpgrade = true
        elseif targetBp.General.UpgradesFromBase ~= "none" then
            -- try testing against the base
            if targetBp.General.UpgradesFromBase == builderBp.BlueprintId then
                performUpgrade = true
            elseif targetBp.General.UpgradesFromBase == builderBp.General.UpgradesFromBase then
                performUpgrade = true
            end
        end

        local time, energy, mass

        if performUpgrade then
            time, energy, mass = import('/lua/game.lua').GetConstructEconomyModel(buildingUnit, bp.Economy, builderBp.Economy)
        else
            time, energy, mass = import('/lua/game.lua').GetConstructEconomyModel(buildingUnit, bp.Economy)
        end

        time = math.max(time, 1)
        showUpKeep = DisplayResources(bp, time, energy, mass)
        View.TimeStat.Value:SetFont(UIUtil.bodyFont, 14)
        View.TimeStat.Value:SetText(string.format("%s", FormatTime(time)))
        if string.len(View.TimeStat.Value:GetText()) > 5 then
            View.TimeStat.Value:SetFont(UIUtil.bodyFont, 10)
        end
    else
        showecon = false
    end

    -- Health stat
    View.HealthStat.Value:SetText(string.format("%d", bp.Defense.MaxHealth))

    if View.Description then
        WrapAndPlaceText(bp.Air,
            bp.Physics,
            bp.Weapon,
            bp.Display.Abilities,
            LOC(UnitDescriptions[bpID]),
            View.Description)
    end
    local showShield = false
    if bp.Defense.Shield and bp.Defense.Shield.ShieldMaxHealth then
        showShield = true
        View.ShieldStat.Value:SetText(bp.Defense.Shield.ShieldMaxHealth)
    end

    local iconName = GameCommon.GetCachedUnitIconFileNames(bp)
    View.UnitImg:SetTexture(iconName)
    View.UnitImg.Height:Set(46)
    View.UnitImg.Width:Set(48)

    ShowView(showUpKeep, false, showecon, showShield)
end

function DisplayResources(bp, time, energy, mass)
    -- Cost Group
    if time > 0 then
        local consumeEnergy = -energy / time
        local consumeMass = -mass / time
        View.BuildCostGroup.EnergyValue:SetText(string.format("%d (%d)",-energy,consumeEnergy))
        View.BuildCostGroup.MassValue:SetText(string.format("%d (%d)",-mass,consumeMass))

        View.BuildCostGroup.EnergyValue:SetColor("FFF05050")
        View.BuildCostGroup.MassValue:SetColor("FFF05050")
    end

    -- Upkeep Group
    local upkeepEnergy, upkeepMass = GetUpkeep(bp)
    local showUpkeep = false
    if upkeepEnergy ~= 0 or upkeepMass ~= 0 then
        View.UpkeepGroup.Label:SetText(LOC("<LOC uvd_0002>Yield"))
        View.UpkeepGroup.EnergyValue:SetText(string.format("%d",upkeepEnergy))
        View.UpkeepGroup.MassValue:SetText(string.format("%d",upkeepMass))
        if upkeepEnergy >= 0 then
            View.UpkeepGroup.EnergyValue:SetColor("FF50F050")
        else
            View.UpkeepGroup.EnergyValue:SetColor("FFF05050")
        end

        if upkeepMass >= 0 then
            View.UpkeepGroup.MassValue:SetColor("FF50F050")
        else
            View.UpkeepGroup.MassValue:SetColor("FFF05050")
        end
        showUpkeep = true
    elseif bp.Economy and (bp.Economy.StorageEnergy ~= 0 or bp.Economy.StorageMass ~= 0) then
        View.UpkeepGroup.Label:SetText(LOC("<LOC uvd_0006>Storage"))
        local upkeepEnergy = bp.Economy.StorageEnergy or 0
        local upkeepMass = bp.Economy.StorageMass or 0
        View.UpkeepGroup.EnergyValue:SetText(string.format("%d",upkeepEnergy))
        View.UpkeepGroup.MassValue:SetText(string.format("%d",upkeepMass))
        View.UpkeepGroup.EnergyValue:SetColor("FF50F050")
        View.UpkeepGroup.MassValue:SetColor("FF50F050")
        showUpkeep = true
    end

    return showUpkeep
end

function GetUpkeep(bp)
    local plusEnergyRate = bp.Economy.ProductionPerSecondEnergy or bp.ProductionPerSecondEnergy
    local negEnergyRate = bp.Economy.MaintenanceConsumptionPerSecondEnergy or bp.MaintenanceConsumptionPerSecondEnergy
    local plusMassRate = bp.Economy.ProductionPerSecondMass or bp.ProductionPerSecondMass
    local negMassRate = bp.Economy.MaintenanceConsumptionPerSecondMass or bp.MaintenanceConsumptionPerSecondMass

    local upkeepEnergy = GetYield(negEnergyRate, plusEnergyRate)
    local upkeepMass = GetYield(negMassRate, plusMassRate)

    return upkeepEnergy, upkeepMass
end

function GetYield(consumption, production)
    if consumption then
        return -consumption
    elseif production then
        return production
    else
        return 0
    end
end

function OnNIS()
    if View then
        View:Hide()
    end
end

function Hide()
    View:Hide()
end

function SetLayout()
    import(UIUtil.GetLayoutFilename('unitviewDetail')).SetLayout()
end

function SetupUnitViewLayout(parent)
    if View then
        View:Destroy()
        View = nil
    end
    MapView = parent
    controls.MapView = MapView
    SetLayout()
    controls.View = View
    View:Hide()
    View:DisableHitTest(true)
end
