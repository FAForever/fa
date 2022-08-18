local GameCommon = import('/lua/ui/game/gamecommon.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Prefs = import('/lua/user/prefs.lua')
local UIUtil = import('/lua/ui/uiutil.lua')

local ArmorDefinition = import('/lua/armordefinition.lua').armordefinition
local Options = Prefs.GetFromCurrentProfile('options')
local UnitDescriptions = import('/lua/ui/help/unitdescription.lua').Description
local WrapText = import('/lua/maui/text.lua').WrapText
local SelectBit = import('/lua/utilities.lua').SelectBitBool
local GetBits = import('/lua/utilities.lua').GetBits

local EntityCategoryContains = EntityCategoryContains


local controls = import('/lua/ui/controls.lua').Get()

View = controls.View or false
MapView = controls.MapView or false
ViewState = "full"

local enhancementSlotNames = {
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
    return ViewState ~= "off"
end

function ShowView(showUpKeep, enhancement, showecon, showShield)
    local View = View
    import('/lua/ui/game/unitview.lua').ShowROBox(false, false)
    View:Show()

    View.UpkeepGroup:SetHidden(not showUpKeep)

    View.BuildCostGroup:SetHidden(not showecon)
    View.UpkeepGroup:SetHidden(not showUpKeep)
    View.TimeStat:SetHidden(not showecon)

    View.HealthStat:SetHidden(enhancement)

    View.ShieldStat:SetHidden(not showShield)

    local desc = View.Description
    if desc then
        desc:SetHidden(ViewState == "limited" or desc.Value[1]:GetText() == "")
    end
end

function ShowEnhancement(bp, bpID, iconID, iconPrefix, userUnit)
    local View = View
    if not CheckFormat() then
        View:Hide()
        return
    end

    -- Name / Description
    View.UnitImg:SetTexture(UIUtil.UIFile(iconPrefix..'_btn_up.dds'))

    local shortDesc = View.UnitShortDesc
    LayoutHelpers.AtTopIn(shortDesc, View, 10)
    shortDesc:SetFont(UIUtil.bodyFont, 14)

    local slotName = enhancementSlotNames[string.lower(bp.Slot)]
    slotName = slotName or bp.Slot

    local bpName = bp.Name
    if bpName ~= nil then
        shortDesc:SetText(LOCF("%s: %s", bpName, slotName))
    else
        shortDesc:SetText(LOC(slotName))
    end
    if shortDesc:GetStringAdvance(shortDesc:GetText()) > shortDesc.Width() then
        LayoutHelpers.AtTopIn(shortDesc, View, 14)
        shortDesc:SetFont(UIUtil.bodyFont, 10)
    end

    local showecon = true
    local showUpKeep = false
    local time, energy, mass
    local desc = View.Description
    if bp.Icon ~= nil and not bp.Name:find('Remove') then
        time, energy, mass = import('/lua/game.lua').GetConstructEconomyModel(userUnit, bp)
        time = math.max(time, 1)
        showUpKeep = DisplayResources(bp, time, energy, mass)
        local timeVal = View.TimeStat
        timeVal:SetFont(UIUtil.bodyFont, 14)
        timeVal:SetText(string.format("%s", FormatTime(time)))
        if timeVal:GetText():len() > 5 then
            timeVal:SetFont(UIUtil.bodyFont, 10)
        end
    else
        showecon = false
        if desc then
            desc:Hide()
            for _, v in desc.Value do
                v:SetText("")
            end
        end
    end

    if desc then
        -- If enhancement of preset, then remove extension. (ual0301_Engineer -> ual0301)
        if bpID:find('_') then
            bpID = bpID:sub(1, bpID:finf("_[^_]*$") - 1)
        end
        WrapAndPlaceText(nil, nil, bpID .. "-" .. iconID, desc)
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

function CreateLines(control, blocks)
    local i = 0
    local controlValue = control.Value
    local prevText = controlValue[1]
    for _, block in blocks do
        for _, line in block.lines do
            i = i + 1
            local text = controlValue[i]
            if text then
                text:SetText(line)
            else
                text = UIUtil.CreateText(control, line, 12, UIUtil.bodyFont)
                LayoutHelpers.Below(text, prevText)
                text.Width:Set(prevText.Width)
                text:DisableHitTest()
                controlValue[i] = text
            end
            text:SetColor(block.color)
            prevText = text
        end
    end
    if i > 0 then
        control.Height:Set(prevText.Bottom() - controlValue[1].Top() + LayoutHelpers.ScaleNumber(30))
    else
        control.Height:Set(LayoutHelpers.ScaleNumber(30))
    end
    for _, val in controlValue do
        val:SetText('')
    end
end

function ExtractAbilityFromString(ability)
    local i = ability:find('>')
    if i then
        return ability:sub(6, i - 1)
    end
    return ability
end

function LOCStr(str)
    local id = str:lower()
    id = id:gsub(' ', '_')
    return LOC('<LOC ls_' .. id .. '>' .. str)
end

function GetShortDesc(bp)
    local desc = ''
    local name = bp.General.UnitName
    if name then
        desc = LOC(name)
        if desc ~= '' then
            desc = desc .. ': '
        end
    end
    if GetTechLevelString(bp) then
        desc = desc .. LOC('<LOC _Tech>') .. GetTechLevelString(bp) .. ' '
    end
    return desc .. LOC(bp.Description)
end

local engineeringAbilities = {
    abilily_engineeringsuite = true,
    ability_building = true,
    ability_repairs = true,
    ability_reclaim = true,
    ability_capture = true,
}
IsAbilityExist = {
    ability_radar = function(bp)
        return bp.Intel.RadarRadius > 0
    end,
    ability_sonar = function(bp)
        return bp.Intel.SonarRadius > 0
    end,
    ability_omni = function(bp)
        return bp.Intel.OmniRadius > 0
    end,
    ability_flying = function(bp)
        return bp.Air.CanFly
    end,
    ability_hover = function(bp)
        return bp.Physics.MotionType == 'RULEUMT_Hover'
    end,
    ability_amphibious = function(bp)
        local bpPhysics = bp.Physics
        local bits = GetBits(tonumber(bpPhysics.BuildOnLayerCaps))
        return (bits[0] == 1 and bits[1] == 1) -- LAYER_Land and LAYER_Seabed
            or bpPhysics.MotionType == 'RULEUMT_Amphibious'
    end,
    ability_aquatic = function(bp)
        local bpPhysics = bp.Physics
        local bits = GetBits(tonumber(bpPhysics.BuildOnLayerCaps))
        return (bits[0] == 1 and bits[3] == 1) -- LAYER_Land and LAYER_Water
            or bpPhysics.MotionType == 'RULEUMT_AmphibiousFloating'
    end,
    ability_sacrifice = function(bp)
        return SelectBit(bp.General.CommandCaps, 16) -- RULEUCC_Sacrifice
    end,
    ability_engineeringsuite = function(bp)
        local bpCategoriesHash = bp.CategoriesHash
        return (bpCategoriesHash.ENGINEER or bpCategoriesHash.ENGINEERSTATION or bpCategoriesHash.REPAIR)
           and bp.Economy.BuildRate > 0
    end,
    ability_carrier = function(bp)
        return bp.Transport.StorageSlots > 0
           and SelectBit(tonumber(bp.General.CommandCaps), 8) -- RULEUCC_Transport
    end,
    ability_factory = function(bp)
        local bpCategoriesHash = bp.CategoriesHash
        return bpCategoriesHash.FACTORY and bpCategoriesHash.SHOWQUEUE
    end,
    ability_upgradable = function(bp)
        local bpGeneral = bp.General
        return bpGeneral.UpgradesTo and bpGeneral.UpgradesTo ~= ''
    end,
    ability_tacticalmissledeflect = function(bp)
        local bpDefenseAntiMissile = bp.Defense.AntiMissile
        return bpDefenseAntiMissile.Radius > 0 and bpDefenseAntiMissile.RedirectRateOfFire > 0
    end,
    ability_cloak = function(bp)
        return bp.Intel.Cloak
    end,
    ability_transportable = function(bp)
        return SelectBit(tonumber(bp.General.CommandCaps), 9) -- RULEUCC_CallTransport
    end,
    ability_transport = function(bp)
        return bp.CategoriesHash.TRANSPORTATION
           and SelectBit(tonumber(bp.General.CommandCaps), 8) -- RULEUCC_Transport
    end,
    ability_airstaging = function(bp)
        return bp.CategoriesHash.AIRSTAGINGPLATFORM
    end,
    ability_submersible = function(bp)
        return SelectBit(tonumber(bp.General.CommandCaps), 19) -- RULEUCC_Dive
    end,
    ability_jamming = function(bp)
        local bpIntel = bp.Intel
        return bpIntel.JammerBlips > 0 and bpIntel.JamRadius.Max > 0
    end,
    ability_building = function(bp)
        return bp.General.BuildBones and bp.CategoriesHash.CONSTRUCTION
    end,
    ability_repairs = function(bp)
        return SelectBit(tonumber(bp.General.CommandCaps), 6) -- RULEUCC_Repair
    end,
    ability_reclaim = function(bp)
        return SelectBit(tonumber(bp.General.CommandCaps), 20) -- RULEUCC_Reclaim
    end,
    ability_capture = function(bp)
        return SelectBit(tonumber(bp.General.CommandCaps), 7) -- RULEUCC_Capture
    end,
    ability_personalshield = function(bp)
        local bpDefenseShield = bp.Defense.Shield
        return bpDefenseShield.PersonalShield or bpDefenseShield.PersonalBubble
    end,
    ability_shielddome = function(bp)
        local bpDefenseShield = bp.Defense.Shield
        return not (bpDefenseShield.PersonalShield or bpDefenseShield.PersonalBubble or bpDefenseShield.ShieldSize <= 0)
    end,
    ability_personalstealth = function(bp)
        local bpIntel = bp.Intel
        return bpIntel.RadarStealth and bpIntel.RadarStealthFieldRadius <= 0
    end,
    ability_stealthfield = function(bp)
        return bp.Intel.RadarStealthFieldRadius > 0
    end,
    ability_stealth_sonar = function(bp)
        local bpIntel = bp.Intel
        return bpIntel.SonarStealth and bpIntel.SonarStealthFieldRadius <= 0
    end,
    ability_stealth_sonarfield = function(bp)
        return bp.Intel.SonarStealthFieldRadius > 0
    end,
    ability_customizable = function(bp)
        return not table.empty(bp.Enhancements)
    end,
    ability_notcap = function(bp)
        local bpCategoriesHash = bp.CategoriesHash
        return bpCategoriesHash.COMMAND or bpCategoriesHash.SUBCOMMANDER or bp.BlueprintId == 'uaa0310'
    end,
    ability_massive = function(bp)
        local stepDamage = bp.Display.MovementEffects.Land.Footfall.Damage
        return stepDamage.Amount > 0 and stepDamage.Radius > 0
    end,
    ability_personal_teleporter = function(bp)
        return SelectBit(tonumber(bp.General.CommandCaps), 12) -- RULEUCC_Teleport
    end
}

GetAbilityDesc = {
    ability_radar = function(bp)
        return LOC('<LOC uvd_Radius>Radius: %d'):format(bp.Intel.RadarRadius)
    end,
    ability_sonar = function(bp)
        return LOC('<LOC uvd_Radius>Radius: %d'):format(bp.Intel.SonarRadius)
    end,
    ability_omni = function(bp)
        return LOC('<LOC uvd_Radius>Radius: %d'):format(bp.Intel.OmniRadius)
    end,
    ability_flying = function(bp)
        local bpAir = bp.Air
        return LOC("<LOC uvd_0011>Speed: %0.1f, Turning: %0.1f"):format(bpAir.MaxAirspeed, bpAir.TurnSpeed)
    end,
    ability_carrier = function(bp)
        return LOCF('<LOC uvd_StorageSlots>Storage Slots: %d', bp.Transport.StorageSlots)
    end,
    ability_factory = function(bp)
        return LOC('<LOC uvd_BuildRate>Build Rate: %0.1f'):format(bp.Economy.BuildRate)
    end,
    ability_upgradable = function(bp)
        return GetShortDesc(__blueprints[bp.General.UpgradesTo])
    end,
    ability_tacticalmissledeflect = function(bp)
        local bpDefenseAntiMissile = bp.Defense.AntiMissile
        return LOC('<LOC uvd_Radius>Radius: %d'):format(bpDefenseAntiMissile.Radius) .. ', '
             ..LOC('<LOC uvd_FireRate>Fire Rate: %0.1f'):format(1 / bpDefenseAntiMissile.RedirectRateOfFire)
    end,
    --[[ability_transportable = function(bp)
        return LOCF('<LOC uvd_UnitSize>', bp.Transport.TransportClass)
    end,]]
    ability_transport = function(bp)
        local text = LOC('<LOC uvd_Capacity>Capacity: ')
        local bpTransport = bp.Transport
        local bpCategoriesHash = bp.CategoriesHash
        return bpTransport and bpTransport.Class1Capacity and text .. bpTransport.Class1Capacity
            or bpCategoriesHash.TECH1 and text .. '≈6'
            or bpCategoriesHash.TECH2 and text .. '≈12'
            or bpCategoriesHash.TECH3 and text .. '≈28'
            or ''
    end,
    ability_airstaging = function(bp)
        local bpTransport = bp.Transport
        return LOC('<LOC uvd_RepairRate>Repair Rate: %0.1f'):format(bpTransport.RepairRate) .. ', '
            .. LOC('<LOC uvd_DockingSlots>Docking Slots: %d'):format(bpTransport.DockingSlots)
    end,
    ability_jamming = function(bp)
        local bpIntel = bp.Intel
        return LOC('<LOC uvd_Radius>Radius: %d'):format(bpIntel.JamRadius.Max) .. ', '
            .. LOC('<LOC uvd_Blips>Blips: %d'):format(bpIntel.JammerBlips)
    end,
    ability_personalshield = function(bp)
        return LOC('<LOC uvd_RegenRate>Regen Rate: %d'):format(bp.Defense.Shield.ShieldRegenRate)
    end,
    ability_shielddome = function(bp)
        local bpDefenseShield = bp.Defense.Shield
        return LOC('<LOC uvd_Radius>Radius: %d'):format(bpDefenseShield.ShieldSize) .. ', '
            .. LOC('<LOC uvd_RegenRate>Regen Rate: %d'):format(bpDefenseShield.ShieldRegenRate)
    end,
    ability_stealthfield = function(bp)
        return LOC('<LOC uvd_Radius>Radius: %d'):format(bp.Intel.RadarStealthFieldRadius)
    end,
    ability_stealth_sonarfield = function(bp)
        return LOC('<LOC uvd_Radius>Radius: %d'):format(bp.Intel.SonarStealthFieldRadius)
    end,
    ability_customizable = function(bp)
        local cnt = 0
        for _, v in bp.Enhancements do
            if v.RemoveEnhancements or (not v.Slot) then continue end
            cnt = cnt + 1
        end
        return cnt
    end,
    ability_massive = function(bp)
        local stepDamage = bp.Display.MovementEffects.Land.Footfall.Damage
        return LOC('<LOC uvd_0010>Damage: %d, Splash: %d'):format(stepDamage.Amount, stepDamage.Radius)
    end,
    ability_personal_teleporter = function(bp)
        local teleDelay = bp.General.TeleportDelay
        if not teleDelay then return '' end
        return LOC('<LOC uvd_Delay>%0.1f'):format(teleDelay)
    end
}

function WrapAndPlaceText(bp, builder, descID, control)
    local lines = {}
    local lineCount = 0
    local blocks = {}
    local blockCount = 0
    -- Unit description
    local text = LOC(UnitDescriptions[descID])
    if text and text ~= '' then
        local firstControlVal = control.Value[1]
        blocks[1] = {
            color = UIUtil.fontColor,
            lines = WrapText(text, firstControlVal.Width(), function(text)
                return firstControlVal:GetStringAdvance(text)
            end),
        }
        blocks[2] = {color = UIUtil.bodyColor, lines = {''}}
        blockCount = 2
    end

    local bpEnhancementPresetAssigned = bp.EnhancementPresetAssigned
    if builder and bpEnhancementPresetAssigned then
        lines[1] = LOC('<LOC uvd_upgrades>Upgrades') .. ':'
        lineCount = 1
        local bpEnhancements = bp.Enhancements
        for _, v in bpEnhancementPresetAssigned.Enhancements do
            lineCount = lineCount + 1
            lines[lineCount] = '    ' .. LOC(bpEnhancements[v].Name)
        end
        blockCount = blockCount + 1
        blocks[blockCount] = {color = 'FFB0FFB0', lines = lines}
    elseif bp then
        -- Get non-autodetected abilities
        local abilities = bp.Display.Abilities
        if abilities then
            for _, id in abilities do
                local ability = ExtractAbilityFromString(id)
                if not IsAbilityExist[ability] then
                    lineCount = lineCount + 1
                    lines[lineCount] = LOC(id)
                end
            end
        end
        -- Autodetect abilities exclude engineering
        for id, func in IsAbilityExist do
            if not engineeringAbilities[id] and func(bp) then
                local ability = LOC('<LOC ' .. id .. '>')
                if GetAbilityDesc[id] then
                    local desc = GetAbilityDesc[id](bp)
                    if desc ~= '' then
                        ability = ability..' - '..desc
                    end
                end
                lineCount = lineCount + 1
                lines[lineCount] = ability
            end
        end
        if lines[1] then -- add spacer
            lineCount = lineCount + 1
            lines[lineCount] = ""
        end
        blockCount = blockCount + 1
        blocks[blockCount] = {color = 'FF7FCFCF', lines = lines}

        -- Autodetect engineering abilities
        if IsAbilityExist.ability_engineeringsuite(bp) then
            local enginerringValues = 
                LOC('<LOC ' .. 'ability_engineeringsuite' .. '>')
                .. ' - ' .. LOC('<LOC uvd_BuildRate>Build Rate: %d'):format(bp.Economy.BuildRate)
                .. ', ' .. LOC('<LOC uvd_Radius>Radius %d:'):format(bp.Economy.MaxBuildDistance)

            local orders = LOC('<LOC order_0011>')
            if IsAbilityExist.ability_building(bp) then
                orders = orders .. ', ' .. LOC('<LOC order_0001>Building')
            end
            if IsAbilityExist.ability_repairs(bp) then
                orders = orders .. ', ' .. LOC('<LOC order_0005>Repairing')
            end
            if IsAbilityExist.ability_reclaim(bp) then
                orders = orders .. ', ' .. LOC('<LOC order_0006>Reclaiming')
            end
            if IsAbilityExist.ability_capture(bp) then
                orders = orders .. ', ' .. LOC('<LOC order_0007>Capturing')
            end

            lines = {
                enginerringValues,
                orders,
                "",
            }
            blockCount = blockCount + 1
            blocks[blockCount] = {color = 'FFFFFFB0', lines = lines}
        end

        if Options.gui_render_armament_detail == 1 then
            --Armor values
            lines = {}
            lineCount = 0
            local armorType = bp.Defense.ArmorType
            if armorType and armorType ~= '' then
                local firstControlVal = control.Value[1]
                local spaceWidth = firstControlVal:GetStringAdvance(' ')
                function AppendTabbedText(leftText, rightText)
                    local spaceCount = (195 - firstControlVal:GetStringAdvance(leftText)) / spaceWidth
                    return leftText .. string.rep(' ', spaceCount) .. rightText
                end

                -- Setup armor type header
                local amrType = LOC('<LOC uvd_ArmorType>Armor Type:') .. LOC('<LOC at_' .. armorType .. '>')
                local dmgTaken = LOC('<LOC uvd_DamageTaken>(% of damage taken)')
                lines[1] = AppendTabbedText(amrType, dmgTaken)
                lineCount = 1

                local formatter = "%s - %0.1f"
                for _, armor in ArmorDefinition do
                    if armor[1] == armorType then
                        local elemCount = table.getn(armor)
                        if elemCount > 1 then
                            local armorDetails
                            local col = 0

                            for i = 2, elemCount do
                                armorDef = armor[i]
                                splitPos = armorDef:find(' ')
                                armorName = armorDef:sub(1, splitPos - 1)
                                armorVal = tonumber(armorDef:sub(splitPos + 1)) * 100
                                local amrDet = formatter:format(LOC('<LOC an_' .. armorName .. '>'), armorVal)

                                if col == 0 then
                                    armorDetails = amrDet
                                    col = 1
                                else
                                    armorDetails = AppendTabbedText(armorDetails, amrDet)

                                    lineCount = lineCount + 1
                                    lines[lineCount] = armorDetails
                                    armorDetails = ""
                                end
                            end
                        end
                    end
                end
                lineCount = lineCount + 1
                lines[lineCount] = ""
                blockCount = blockCount + 1
                blocks[blockCount] = {color = 'FF7FCFCF', lines = lines}
            end

            -- Weapons
            local bpWeapon = bp.Weapon
            if not table.empty(bpWeapon) then
                local __blueprints = __blueprints
                local weapons = {upgrades = {normal = {}, death = {}},
                                    basic = {normal = {}, death = {}}}
                for _, weapon in bpWeapon do
                    if not weapon.WeaponCategory then continue end
                    local dest = weapons.basic
                    if weapon.EnabledByEnhancement then
                        dest = weapons.upgrades
                    end
                    if weapon.FireOnDeath or (weapon.WeaponCategory == 'Death') then
                        dest = dest.death
                    else
                        dest = dest.normal
                    end
                    local dispName = weapon.DisplayName
                    local destCount = dest[dispName]
                    if destCount then
                        dest[dispName].count = destCount.count + 1
                    else
                        dest[dispName] = {info = weapon, count = 1}
                    end
                end
                for k, weaponGroup in weapons do
                    local weaponNormal = weaponGroup.normal
                    local weaponDeath = weaponGroup.death
                    if weaponNormal[1] or weaponDeath[1] then
                        blockCount = blockCount + 1
                        blocks[blockCount] = {
                            color = UIUtil.fontColor,
                            lines = {LOC('<LOC uvd_' .. k .. '>') .. ':'}
                        }
                    end
                    for name, weapon in weaponNormal do
                        local info = weapon.info
                        local weaponDetails1 = LOCStr(name) .. ' (' .. LOCStr(info.WeaponCategory) .. ') '
                        if info.ManualFire then
                            weaponDetails1 = weaponDetails1 .. LOC('<LOC uvd_ManualFire>(Manual Fire)')
                        end
                        local weaponDetails2 = LOC('<LOC uvd_0014>Damage: %d - %d, Splash: %d - %d') .. ', ' .. LOC('<LOC uvd_Range>Range: %d - %d')
                        if info.NukeInnerRingDamage then
                            weaponDetails2 = weaponDetails2:format(
                                info.NukeInnerRingDamage + info.NukeOuterRingDamage, info.NukeOuterRingDamage,
                                info.NukeInnerRingRadius, info.NukeOuterRingRadius, info.MinRadius, info.MaxRadius
                            )
                        else
                            local MuzzleBones = 0
                            if info.MuzzleSalvoDelay > 0 then
                                MuzzleBones = info.MuzzleSalvoSize
                            elseif info.RackBones then
                                for _, rack in info.RackBones do
                                    MuzzleBones = MuzzleBones + table.getsize(rack.MuzzleBones)
                                end
                                if not info.RackFireTogether then
                                    MuzzleBones = MuzzleBones / table.getsize(info.RackBones)
                                end
                            else
                                MuzzleBones = 1
                            end

                            local damage = info.Damage
                            if info.DamageToShields then
                                damage = math.max(damage, info.DamageToShields)
                            end
                            damage = damage * (info.DoTPulses or 1)
                            local projPhysics = __blueprints[info.ProjectileId].Physics
                            while projPhysics do
                                damage = damage * (projPhysics.Fragments or 1)
                                projPhysics = __blueprints[(projPhysics.FragmentId or ''):lower()].Physics
                            end

                            local ReloadTime = math.max((info.RackSalvoChargeTime or 0) + (info.RackSalvoReloadTime or 0) +
                                (info.MuzzleSalvoDelay or 0) * (info.MuzzleSalvoSize or 1), 1 / info.RateOfFire)

                            if not info.ManualFire and info.WeaponCategory ~= 'Kamikaze' then
                                local DPS = damage * MuzzleBones
                                if info.BeamLifetime > 0 then
                                    DPS = DPS * info.BeamLifetime * 10
                                end
                                DPS = DPS / ReloadTime + (info.InitialDamage or 0)
                                weaponDetails1 = weaponDetails1 .. LOC('<LOC uvd_DPS>(DPS: %d)'):format(DPS)
                            end

                            weaponDetails2 = weaponDetails2 .. ', ' .. LOC('<LOC uvd_Reload>Reload: %0.1f')
                            weaponDetails2 = weaponDetails2:format(damage, info.DamageRadius,
                                info.MinRadius, info.MaxRadius, ReloadTime)
                        end
                        if weapon.count > 1 then
                            weaponDetails1 = weaponDetails1 .. ' x' .. weapon.count
                        end
                        blockCount = blockCount + 2
                        blocks[blockCount - 1] = {color = UIUtil.fontColor, lines = {weaponDetails1}}
                        blocks[blockCount] = {color = 'FFFFB0B0', lines = {weaponDetails2}}
                    end
                    lines = {}
                    lineCount = 0
                    for name, weapon in weaponDeath do
                        local info = weapon.info
                        local weaponDetails = LOCStr(name) .. ' (' .. LOCStr(info.WeaponCategory) .. ') '
                        if info.NukeInnerRingDamage then
                            weaponDetails = weaponDetails .. LOC('<LOC uvd_0014>Damage: %d - %d, Splash: %d - %d'):format(
                                info.NukeInnerRingDamage + info.NukeOuterRingDamage, info.NukeOuterRingDamage,
                                info.NukeInnerRingRadius, info.NukeOuterRingRadius)
                        else
                            weaponDetails = weaponDetails .. LOC('<LOC uvd_0010>Damage: %d, Splash: %d'):format(
                                info.Damage, info.DamageRadius)
                        end
                        if weapon.count > 1 then
                            weaponDetails = weaponDetails .. ' x' .. weapon.count
                        end
                        lineCount = lineCount + 1
                        lines[lineCount] = weaponDetails
                    end
                    if weaponNormal[1] or weaponDeath[1] then
                        lineCount = lineCount + 1
                        lines[lineCount] = ""
                    end
                    blockCount = blockCount + 1
                    blocks[blockCount] = {color = 'FFFF0000', lines = lines}
                end
            end
        end

        -- Other parameters
        local bpIntel = bp.Intel
        local bpPhysics = bp.Physics
        local motionType = bpPhysics.MotionType
        lines = {
            LOC("<LOC uvd_0013>Vision: %d, Underwater Vision: %d, Regen: %0.1f, Cap Cost: %0.1f"):format(
            bpIntel.VisionRadius, bpIntel.WaterVisionRadius, bp.Defense.RegenRate, bp.General.CapCost)
        }

        if (motionType ~= 'RULEUMT_Air' and motionType ~= 'RULEUMT_None')
        or (bpPhysics.AltMotionType ~= 'RULEUMT_Air' and bpPhysics.AltMotionType ~= 'RULEUMT_None') then
            lines[2] = LOC("<LOC uvd_0012>Speed: %0.1f, Reverse: %0.1f, Acceleration: %0.1f, Turning: %d")
                :format(bpPhysics.MaxSpeed, bpPhysics.MaxSpeedReverse, bpPhysics.MaxAcceleration, bpPhysics.TurnRate)
        end

        blockCount = blockCount + 1
        blocks[blockCount] = {color = 'FFB0FFB0', lines = lines}
    end
    CreateLines(control, blocks)
end

function Show(bp, builderUnit, bpID)
    local View = View
    if not CheckFormat() then
        View:Hide()
        return
    end

    -- Name / Description
    local shortDesc = View.UnitShortDesc
    LayoutHelpers.AtTopIn(shortDesc, View, 10)
    shortDesc:SetFont(UIUtil.bodyFont, 14)

    shortDesc:SetText(GetShortDesc(bp))

    local scale = shortDesc.Width() / shortDesc.TextAdvance()
    if scale < 1 then
        LayoutHelpers.AtTopIn(shortDesc, View, 10 / scale)
        shortDesc:SetFont(UIUtil.bodyFont, 14 * scale)
    end
    local showecon = true
    local showUpKeep = false
    if builderUnit ~= nil then
        -- Differential upgrading. Check to see if building this would be an upgrade
        local targetBp = bp
        local targetBpGeneral = targetBp.General
        local upgradesFrom = targetBpGeneral.UpgradesFrom
        local builderBp = builderUnit:GetBlueprint()
        local builderBlueprintId = builderBp.BlueprintId

        local performUpgrade = false

        if upgradesFrom == builderBlueprintId then
            performUpgrade = true
        else
            local builderBpGeneral = builderBp.General
            if upgradesFrom == builderBpGeneral.UpgradesTo then
                performUpgrade = true
            else
                local upgradesFrombase = targetBpGeneral.UpgradesFromBase
                if upgradesFrombase ~= "none" then
                    -- try testing against the base
                    if upgradesFrombase == builderBlueprintId then
                        performUpgrade = true
                    elseif upgradesFrombase == builderBpGeneral.UpgradesFromBase then
                        performUpgrade = true
                    end
                end
            end
        end

        local time, energy, mass

        if performUpgrade then
            time, energy, mass = import('/lua/game.lua').GetConstructEconomyModel(builderUnit, bp.Economy, builderBp.Economy)
        else
            time, energy, mass = import('/lua/game.lua').GetConstructEconomyModel(builderUnit, bp.Economy)
        end

        time = math.max(time, 1)
        showUpKeep = DisplayResources(bp, time, energy, mass)
        local timeValue = View.TimeStat.Value
        timeValue:SetText(FormatTime(time))
        if timeValue:GetText():len() > 5 then
            timeValue:SetFont(UIUtil.bodyFont, 10)
        else
            timeValue:SetFont(UIUtil.bodyFont, 14)
        end
    else
        showecon = false
    end

    local bpDefense = bp.Defense

    -- Health stat
    View.HealthStat.Value:SetText(string.format("%d", bpDefense.MaxHealth))

    local desc = View.Description
    if desc then
        WrapAndPlaceText(bp, builderUnit, bpID, desc)
    end

    local showShield = false
    local shieldMaxHealth = bpDefense.Shield.ShieldMaxHealth
    if shieldMaxHealth then
        showShield = true
        View.ShieldStat.Value:SetText(shieldMaxHealth)
    end

    local iconName = GameCommon.GetCachedUnitIconFileNames(bp)
    local unitImg = View.UnitImg
    unitImg:SetTexture(iconName)
    LayoutHelpers.SetDimensions(unitImg, 46, 46)

    ShowView(showUpKeep, false, showecon, showShield)
end

function DisplayResources(bp, time, energy, mass)
    local View = View
    -- Cost Group
    if time > 0 then
        energy =- energy
        mass =- mass
        local consumeEnergy = energy / time
        local consumeMass = mass / time
        local buildCostGroup = View.BuildCostGroup
        local energyValue = buildCostGroup.EnergyValue
        local massValue = buildCostGroup.MassValue
        local formatter = "%d (%d)"
        energyValue:SetText(formatter:format(energy, consumeEnergy))
        massValue:SetText(formatter:format(mass, consumeMass))

        energyValue:SetColor("FFF05050")
        massValue:SetColor("FFF05050")
    end

    -- Upkeep Group
    local upkeepEnergy, upkeepMass = GetUpkeep(bp)
    local upkeepGroup = View.upkeepGroup
    if upkeepEnergy ~= 0 or upkeepMass ~= 0 then
        upkeepGroup.Label:SetText(LOC("<LOC uvd_0002>Yield"))
    else
        local bpEconomy = bp.Economy
        if bpEconomy then
            local storageEnergy = bpEconomy.StorageEnergy
            local storageMass = bpEconomy.StorageMass
            if storageEnergy ~= 0 or storageMass ~= 0 then
                upkeepGroup.Label:SetText(LOC("<LOC uvd_0006>Storage"))
                upkeepEnergy = storageEnergy or 0
                upkeepMass = storageMass or 0
            end
        end
    end
    if upkeepEnergy ~= 0 or upkeepMass ~= 0 then
        local energyValue = upkeepGroup.EnergyValue
        local massValue = upkeepGroup.MassValue
        local formatter = "%d"
        energyValue:SetText(formatter:format(upkeepEnergy))
        massValue:SetText(formatter:format(upkeepMass))
        if upkeepEnergy >= 0 then
            energyValue:SetColor("FF50F050")
        else
            energyValue:SetColor("FFF05050")
        end

        if upkeepMass >= 0 then
            massValue:SetColor("FF50F050")
        else
            massValue:SetColor("FFF05050")
        end
        return true
    end
    return false
end

function GetUpkeep(bp)
    local bpEconomy = bp.Economy
    local upkeepEnergy = (bpEconomy.ProductionPerSecondEnergy or 0) - (bpEconomy.MaintenanceConsumptionPerSecondEnergy or 0)
    local upkeepMass = (bpEconomy.ProductionPerSecondMass or 0) - (bpEconomy.MaintenanceConsumptionPerSecondMass or 0)
    upkeepEnergy = upkeepEnergy + (bp.ProductionPerSecondEnergy or 0) - (bp.MaintenanceConsumptionPerSecondEnergy or 0)
    upkeepMass = upkeepMass + (bp.ProductionPerSecondMass or 0) - (bp.MaintenanceConsumptionPerSecondMass or 0)

    local bpEnhancementPresetAssigned = bp.EnhancementPresetAssigned
    if bpEnhancementPresetAssigned then
        local bpEnhancements = bp.Enhancements
        for _, v in bpEnhancementPresetAssigned.Enhancements do
            local enh = bpEnhancements[v]
            upkeepEnergy = upkeepEnergy + (enh.ProductionPerSecondEnergy or 0) - (enh.MaintenanceConsumptionPerSecondEnergy or 0)
            upkeepMass = upkeepMass + (enh.ProductionPerSecondMass or 0) - (enh.MaintenanceConsumptionPerSecondMass or 0)
        end
    end

    return upkeepEnergy, upkeepMass
end

function OnNIS()
    local View = View
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
    local upView = View
    if upView then
        upView:Destroy()
        View = nil
    end
    MapView = parent
    controls.MapView = MapView
    SetLayout()

    upView = View -- reset upvalue
    controls.View = upView
    upView:Hide()
    upView:DisableHitTest(true)
end
