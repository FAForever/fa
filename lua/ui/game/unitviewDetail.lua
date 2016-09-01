
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Prefs = import('/lua/user/prefs.lua')
local options = Prefs.GetFromCurrentProfile('options')
local UnitDescriptions = import('/lua/ui/help/unitdescription.lua').Description
local LocalisationUS = {} doscript('/loc/' .. 'us' .. '/strings_db.lua', LocalisationUS)

View = false
ViewState = "full"
MapView = false

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
            control.Value[index] = UIUtil.CreateText( control, v, 12, UIUtil.bodyFont)
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
            CreateDisplayAbilities(bp),
            LOC(UnitDescriptions[bpID]),
            View.Description)
    -- we need to show armament_detail even if we don't have a unit.Description
    elseif options.gui_render_armament_detail == 1 then
        WrapAndPlaceText(bp.Air,
            bp.Physics,
            bp.Weapon,
            CreateDisplayAbilities(bp),
            "no Text1",
            "no Text2",
            bp)
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
        View.BuildCostGroup.EnergyValue:SetText( string.format("%d (%d)",-energy,consumeEnergy) )
        View.BuildCostGroup.MassValue:SetText( string.format("%d (%d)",-mass,consumeMass) )

        View.BuildCostGroup.EnergyValue:SetColor( "FFF05050" )
        View.BuildCostGroup.MassValue:SetColor( "FFF05050" )
    end

    -- Upkeep Group
    local plusEnergyRate = bp.Economy.ProductionPerSecondEnergy or bp.ProductionPerSecondEnergy
    local negEnergyRate = bp.Economy.MaintenanceConsumptionPerSecondEnergy or bp.MaintenanceConsumptionPerSecondEnergy
    local plusMassRate = bp.Economy.ProductionPerSecondMass or bp.ProductionPerSecondMass
    local negMassRate = bp.Economy.MaintenanceConsumptionPerSecondMass or bp.MaintenanceConsumptionPerSecondMass
    local upkeepEnergy = GetYield(negEnergyRate, plusEnergyRate)
    local upkeepMass = GetYield(negMassRate, plusMassRate)
    local showUpkeep = false
    if upkeepEnergy ~= 0 or upkeepMass ~= 0 then
        View.UpkeepGroup.Label:SetText(LOC("<LOC uvd_0002>Yield"))
        View.UpkeepGroup.EnergyValue:SetText( string.format("%d",upkeepEnergy) )
        View.UpkeepGroup.MassValue:SetText( string.format("%d",upkeepMass) )
        if upkeepEnergy >= 0 then
            View.UpkeepGroup.EnergyValue:SetColor( "FF50F050" )
        else
            View.UpkeepGroup.EnergyValue:SetColor( "FFF05050" )
        end

        if upkeepMass >= 0 then
            View.UpkeepGroup.MassValue:SetColor( "FF50F050" )
        else
            View.UpkeepGroup.MassValue:SetColor( "FFF05050" )
        end
        showUpkeep = true
    elseif bp.Economy and (bp.Economy.StorageEnergy ~= 0 or bp.Economy.StorageMass ~= 0) then
        View.UpkeepGroup.Label:SetText(LOC("<LOC uvd_0006>Storage"))
        local upkeepEnergy = bp.Economy.StorageEnergy or 0
        local upkeepMass = bp.Economy.StorageMass or 0
        View.UpkeepGroup.EnergyValue:SetText( string.format("%d",upkeepEnergy) )
        View.UpkeepGroup.MassValue:SetText( string.format("%d",upkeepMass) )
        View.UpkeepGroup.EnergyValue:SetColor( "FF50F050" )
        View.UpkeepGroup.MassValue:SetColor( "FF50F050" )
        showUpkeep = true
    end

    return showUpkeep
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
    SetLayout()
    View:Hide()
    View:DisableHitTest(true)
end

local Abilities = {
    ["ability_radar"] = function (bp)
        return bp.CategoriesHash.OVERLAYRADAR and bp.Intel.RadarRadius > 0
    end,
    ["ability_sonar"] = function (bp)
        return bp.CategoriesHash.OVERLAYSONAR and bp.Intel.SonarRadius > 0
    end,
    ["ability_omni"] = function (bp)
        return bp.CategoriesHash.OVERLAYOMNI and bp.Intel.OmniRadius > 0
    end,
    ["ability_hover"] = function (bp)
        return bp.CategoriesHash.MOBILE and bp.Physics.MotionType == 'RULEUMT_Hover'
    end,
    ["ability_amphibious"] = function (bp)
        local BitArray = DezimalToBinary(bp.Physics.BuildOnLayerCaps)
        return (bp.CategoriesHash.STRUCTURE and not 
                bp.CategoriesHash.FACTORY and 
                BitArray[0] == 1 and  -- LAYER_Land
                BitArray[1] == 1)     -- LAYER_Seabed
            or (bp.CategoriesHash.MOBILE and 
               (bp.Physics.MotionType == 'RULEUMT_Amphibious' or 
                bp.Physics.MotionType == 'RULEUMT_AmphibiousFloating')) 
    end,
    ["ability_aquatic"] = function (bp)
        local BitArray = DezimalToBinary(bp.Physics.BuildOnLayerCaps)
        return bp.CategoriesHash.STRUCTURE and 
                BitArray[0] == 1 and  -- LAYER_Land
                BitArray[3] == 1      -- LAYER_Water
    end,
    ["ability_deathaoe"] = function (bp)
        if bp.Weapon then
            for _,weapon in bp.Weapon do
                if weapon.DisplayName and weapon.DisplayName ~= '' then
                    if (weapon.DisplayName == 'Death Weapon' or 
                        weapon.DisplayName == 'Death Nuke' or
                        weapon.DisplayName == 'Collossus Death' or
                        weapon.DisplayName == 'Megalith Death')
                    or (weapon.DamageType == 'EMP' and weapon.DamageRadius > 1) then
                        return true
                    end
                end
            end
        end
        return false
    end,
    ["ability_sacrifice"] = function (bp)
        return DezimalToBinary(bp.General.CommandCaps)[16] == 1 -- RULEUCC_Sacrifice
    end,
    ["ability_engineeringsuite"] = function (bp)
        if ((bp.CategoriesHash.ENGINEER or bp.CategoriesHash.ENGINEERSTATION) and bp.CategoriesHash.CONSTRUCTION) 
        or (bp.CategoriesHash.ENGINEER and bp.CategoriesHash.POD) then
            return true
        end
        return false
    end,
    ["ability_manuallaunch"] = function (bp)
        if bp.Weapon then
            for _,weapon in bp.Weapon do
                if weapon.ManualFire then
                    return true
                end
            end
        end
        return false
    end,
    ["ability_aa"] = function (bp)
        if bp.Weapon then
            for _,weapon in bp.Weapon do
                if weapon.WeaponCategory ~= 'Kamikaze' then
                    for _,TargetLayer in weapon.FireTargetLayerCapsTable or {} do
                        if (not weapon.TargetRestrictDisallow or not string.find( weapon.TargetRestrictDisallow, 'AIR' )) and
                           (not weapon.TargetRestrictOnlyAllow or not string.find( weapon.TargetRestrictOnlyAllow, 'MISSILE' )) and
                            string.find( TargetLayer, 'Air' ) then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end,
    ["ability_stun"] = function (bp)
        if bp.Weapon then
            for _,weapon in bp.Weapon do
                for arg,Buff in weapon.Buffs or {} do
                    if Buff.BuffType and Buff.BuffType == 'STUN' then
                        return true
                    end
                end
            end
        end
        return false
    end,
    ["ability_carrier"] = function (bp)
        return bp.CategoriesHash.CARRIER and
               DezimalToBinary(bp.General.CommandCaps)[8] == 1 -- RULEUCC_Transport
    end,
    ["ability_factory"] = function (bp)
        return bp.CategoriesHash.MOBILE and
               bp.CategoriesHash.FACTORY and
               bp.CategoriesHash.SHOWQUEUE
    end,
    ["ability_tacmissiledef"] = function (bp)
        if bp.Weapon then
            for _,weapon in bp.Weapon do
                for _,TargetLayer in weapon.FireTargetLayerCapsTable or {} do
                    if string.find( TargetLayer, 'Air' ) then
                        if weapon.TargetRestrictOnlyAllow and 
                           string.find(weapon.TargetRestrictOnlyAllow, 'TACTICAL' ) and 
                           string.find(weapon.TargetRestrictOnlyAllow, 'MISSILE' ) then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end,
    ["ability_stratmissiledef"] = function (bp)
        if bp.Weapon then
            for _,weapon in bp.Weapon do
                for _,TargetLayer in weapon.FireTargetLayerCapsTable or {} do
                    if string.find( TargetLayer, 'Air' ) then
                        if weapon.TargetRestrictOnlyAllow and 
                           string.find( weapon.TargetRestrictOnlyAllow, 'STRATEGIC' ) and 
                           string.find( weapon.TargetRestrictOnlyAllow, 'MISSILE' ) then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end,
    ["ability_torpedo"] = function (bp)
        if bp.Weapon then
            for _,weapon in bp.Weapon do
                for _,TargetLayer in weapon.FireTargetLayerCapsTable or {} do
                    if string.find( TargetLayer, 'Sub' ) then
                        if weapon.TargetRestrictDisallow and string.find( weapon.TargetRestrictDisallow, 'HOVER' ) then
                            if weapon.ProjectileId and not string.find( weapon.ProjectileId, 'depthcharge' ) then
                                return true
                            end
                        end
                    end
                end
            end
        end
        return false
    end,
    ["ability_depthcharge"] = function (bp)
        if bp.Weapon then
            for _,weapon in bp.Weapon do
                for _,TargetLayer in weapon.FireTargetLayerCapsTable or {} do
                    if string.find( TargetLayer, 'Sub' ) then
                        if weapon.ProjectileId and string.find( weapon.ProjectileId, 'depthcharge' ) then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end,
    ["ability_torpedodef"] = function (bp)
        if bp.Weapon then
            for _,weapon in bp.Weapon do
                for _,TargetLayer in weapon.FireTargetLayerCapsTable or {} do
                    if weapon.TargetRestrictOnlyAllow and 
                       weapon.RangeCategory == 'UWRC_Countermeasure' and 
                       string.find( weapon.TargetRestrictOnlyAllow, 'TORPEDO' )  then
                        return true
                    end
                end
            end
        end
        return false
    end,
    ["ability_upgradable"] = function (bp)
        return bp.General.UpgradesTo and bp.General.UpgradesTo ~= ''
    end,
    ["ability_tacticalmissledeflect"] = function (bp)
        return bp.CategoriesHash.ANTIMISSILE and bp.Defense.AntiMissile and type(bp.Defense.AntiMissile) == 'table'
    end,
    ["ability_cloak"] = function (bp)
        return bp.Intel and bp.Intel.Cloak
    end,
    ["ability_transport"] = function (bp)
        return bp.CategoriesHash.TRANSPORTATION and bp.General.Category and bp.Transport.TransportClass > 0
    end,
    ["ability_airstaging"] = function (bp)
        return bp.CategoriesHash.AIRSTAGINGPLATFORM and not bp.CategoriesHash.CARRIER
    end,
    ["ability_submersible"] = function (bp)
        return bp.CategoriesHash.SUBMERSIBLE
    end,
    ["ability_jamming"] = function (bp)
        return bp.Intel.JamRadius and type(bp.Intel.JamRadius) == 'table' and bp.Intel.JamRadius.Max > 0 
    end,
    ["ability_suicideweapon"] = function (bp)
        if bp.Weapon then
            for _,weapon in bp.Weapon do
                if weapon.WeaponCategory and weapon.WeaponCategory == 'Kamikaze' then
                    return true
                end
            end
        end
        return false
    end,
    ["ability_repairs"] = function (bp)
        return not bp.CategoriesHash.ENGINEER and DezimalToBinary(bp.General.CommandCaps)[6] == 1 -- RULEUCC_Repair
    end,
    ["ability_reclaim"] = function (bp)
        return not bp.CategoriesHash.ENGINEER and DezimalToBinary(bp.General.CommandCaps)[20] == 1 -- RULEUCC_Reclaim
    end,
    ["ability_deploys"] = function (bp)
        if bp.CategoriesHash.MOBILE and bp.Weapon then
            for _,weapon in bp.Weapon do
                if weapon.WeaponUnpackLocksMotion == true then
                    return true
                end
            end
        end
        return false
    end,
    ["ability_personalshield"] = function (bp)
        if bp.Defense.Shield.PersonalShield == true
        or bp.Defense.Shield.ShieldSize > 0 and bp.Defense.Shield.ShieldSize <= 3
        or bp.Defense.Shield.PersonalBubble == true then
            return true
        end
        return false
    end,
    ["ability_shielddome"] = function (bp)
        return bp.Defense.Shield.ShieldSize > 3 and bp.Defense.Shield.PersonalShield ~= true 
    end,
    ["ability_personalstealth"] = function (bp)
        return bp.Intel.RadarStealth == true and bp.Intel.RadarStealthField ~= true
    end,
    ["ability_stealthfield"] = function (bp)
        return bp.Intel.RadarStealthField == true or bp.Intel.RadarStealthFieldRadius > 0
    end,
    ["ability_customizable"] = function (bp)
        return table.getsize(bp.Enhancements) > 0
    end,
    ["ability_notcap"] = function (bp)
        return bp.CategoriesHash.SUBCOMMANDER or bp.BlueprintId == 'uaa0310' 
    end,
    ["ability_massive"] = function (bp)
        return bp.Display.MovementEffects.Land.Footfall.Damage.Amount > 0 and
               bp.Display.MovementEffects.Land.Footfall.Damage.Radius > 0
    end,
    ["ability_teleport"] = function (bp)
        return bp.CategoriesHash.TELEPORT and
               DezimalToBinary(bp.General.CommandCaps)[12] == 1 -- RULEUCC_Teleport
    end,
}
local ReserveAbilities = {
    ["Armed"] = function (bp)
        return type(bp.Weapon) == 'table'
    end,
}
function DezimalToBinary(String)
    local number = tonumber(String)
    local BitArray = {}
    local cnt = 0
    while (number > 0) do
        local last = math.mod(number,2)
        if(last == 1) then
            BitArray[cnt] = 1
        else
            BitArray[cnt] = 0
        end
        number = (number-last)/2
        cnt = cnt + 1
    end
    return BitArray
end
function ExtractAbilityFromString(ability)
    local i = string.find(ability,">")
    if i then
        ability = string.sub(ability,6,i-1)
    end
    return ability
end
function ValidateUnitDescriptions(bp)
    local UnitDescriptions = import('/lua/ui/help/unitdescription.lua').Description
    local Description = LOC(UnitDescriptions[bp.BlueprintId]) or LOC(bp.Interface.Help.HelpText)
    if Description then
        return true
    end
    return false
end
function CreateDisplayAbilities(bp)
    -- Without this we have to reload the game to get the new option if the user changed something.
    options = Prefs.GetFromCurrentProfile('options')
    
    -- option Off(1): don't touch the Abilitiy array, option Medium(2): don't create a new array, if we have one inside the blueprint
    if options.gui_show_AutoAbility < 2 or options.gui_show_AutoAbility < 3 and bp.Display.Abilities then
        return bp.Display.Abilities
    end

    -- create the new Abilities array
    local count = 0
    local newAbilities = {}
    for ability, matching in Abilities do
        if matching(bp) then
            count = count + 1
            newAbilities[count] = '<LOC '..ability..'>'..LocalisationUS[ability]
        end
    end
    -- stop here, if AutoAbility options are Off, Medium or Full.
    if options.gui_show_AutoAbility < 4 then return newAbilities end
    
    -- option Advanced(4) merge bp.Abilities to the generated one
    -- We only merge unknown abilities and cross fingers that the mod-author did it right :)
    if type(bp.Display.Abilities) == "table" then
        for _,ability in bp.Display.Abilities do
            if not Abilities[ExtractAbilityFromString(ability)] then
                count = count + 1
                newAbilities[count] = ability
            end
        end
    end
    -- if we don't have an ability and the unit don't has a description, we add a Weapon ability
    -- to display the tooltip for advanced unit-stats.
    if not newAbilities[1] and not ValidateUnitDescriptions(bp) then
        for ability, matching in ReserveAbilities do
            if matching(bp) then
                count = count + 1
                newAbilities[count] = ability
            end
        end
    end
    return newAbilities
end
