
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local GameCommon = import('/lua/ui/game/gamecommon.lua')
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local Prefs = import('/lua/user/prefs.lua')
local UnitDescriptions = import('/lua/ui/help/unitdescription.lua').Description

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
    View:SetNeedsFrameUpdate(false)
    View:SetAlpha(0)
end

function Expand()
    View:SetNeedsFrameUpdate(true)
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
    local tempSeconds = math.floor(seconds)
    local tempMinutes = 00

    tempMinutes = math.floor(tempSeconds / 60)
    tempSeconds = tempSeconds - (tempMinutes * 60)
    if(tempMinutes < 10) then
        tempMinutes = "0" .. tostring(tempMinutes)
    end
    if(tempSeconds < 10) then
        tempSeconds = "0" .. tostring(tempSeconds)
    end
    local tempTime = tostring(tempMinutes) .. ":" .. tostring(tempSeconds)
    return tempTime
end

function GetAbilityList(bp)
    local abilitiesList = {}

    return abilitiesList
end
    
function CheckFormat()
    if ViewState != Prefs.GetOption('uvd_format') then
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
    View.Hiding = false
    
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
    if CheckFormat() then
        # Name / Description
        View.UnitImg:SetTexture(UIUtil.UIFile(iconPrefix..'_btn_up.dds'))
        
        LayoutHelpers.AtTopIn(View.UnitShortDesc, View, 10)
        View.UnitShortDesc:SetFont(UIUtil.bodyFont, 14)

        local slotName = enhancementSlotNames[string.lower(bp.Slot)]
        slotName = slotName or bp.Slot

        if bp.Name != nil then
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
        if bp.Icon != nil and not string.find(bp.Name, 'Remove') then
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
                WrapAndPlaceText(nil, tempDesc, View.Description)
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
    else
        Hide()
    end
end
    
function WrapAndPlaceText(abilities, text, control)
    local lines = {}
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
    if CheckFormat() then
        # Name / Description
        if false then
            local foo, iconName = GameCommon.GetCachedUnitIconFileNames(bp)
            if iconName then
                View.UnitIcon:SetTexture(iconName)
            else
                View.UnitIcon:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))    
            end
        end
        LayoutHelpers.AtTopIn(View.UnitShortDesc, View, 10)
        View.UnitShortDesc:SetFont(UIUtil.bodyFont, 14)
        local description = LOC(bp.Description)
        if GetTechLevelString(bp) then
            description = LOCF('Tech %d %s', GetTechLevelString(bp), description)
        end
        if bp.General.UnitName != nil then
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
        if buildingUnit != nil then
	   
	   -- Differential upgrading. Check to see if building this would be an upgrade
	   local targetBp = bp
	   local builderBp = buildingUnit:GetBlueprint()
	   
	   local performUpgrade = false
	   
	   if targetBp.General.UpgradesFrom == builderBp.BlueprintId then
	      performUpgrade = true
	   elseif targetBp.General.UpgradesFrom == builderBp.General.UpgradesTo then
	      performUpgrade = true
	   elseif targetBp.General.UpgradesFromBase != "none" then
	      # try testing against the base
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
            
        # Health stat
        View.HealthStat.Value:SetText(string.format("%d", bp.Defense.MaxHealth))
    
        if View.Description then
            WrapAndPlaceText(bp.Display.Abilities, LOC(UnitDescriptions[bpID]), View.Description)
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
    else
        Hide()
    end
end

function DisplayResources(bp, time, energy, mass)
    # Cost Group
    if time > 0 then
        local consumeEnergy = -energy / time
        local consumeMass = -mass / time
        View.BuildCostGroup.EnergyValue:SetText( string.format("%d (%d)",-energy,consumeEnergy) )
        View.BuildCostGroup.MassValue:SetText( string.format("%d (%d)",-mass,consumeMass) )
        
        View.BuildCostGroup.EnergyValue:SetColor( "FFF05050" )
        View.BuildCostGroup.MassValue:SetColor( "FFF05050" )
    end

    # Upkeep Group
    local plusEnergyRate = bp.Economy.ProductionPerSecondEnergy or bp.ProductionPerSecondEnergy
    local negEnergyRate = bp.Economy.MaintenanceConsumptionPerSecondEnergy or bp.MaintenanceConsumptionPerSecondEnergy
    local plusMassRate = bp.Economy.ProductionPerSecondMass or bp.ProductionPerSecondMass
    local negMassRate = bp.Economy.MaintenanceConsumptionPerSecondMass or bp.MaintenanceConsumptionPerSecondMass
    local upkeepEnergy = GetYield(negEnergyRate, plusEnergyRate)
    local upkeepMass = GetYield(negMassRate, plusMassRate)
    local showUpkeep = false
    if upkeepEnergy != 0 or upkeepMass != 0 then
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
    elseif bp.Economy and (bp.Economy.StorageEnergy != 0 or bp.Economy.StorageMass != 0) then
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
        View:SetAlpha(0, true)
        View:SetNeedsFrameUpdate(false)
    end
end

function Hide()
    View.Time = 0
    View.Hiding = true
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
    View:SetAlpha(0, true)
    View:SetNeedsFrameUpdate(true)
    View.Hiding = true
    View:DisableHitTest(true)
    View.OnFrame = function(self, delta)
        if self.Hiding then
            local newAlpha = self:GetAlpha() - (delta * 3)
            if newAlpha < 0 then
                newAlpha = 0
                self.Hiding = true
            end
            self:SetAlpha(newAlpha, true)
        elseif self:GetAlpha() < 1 then
            local newAlpha = math.min(self:GetAlpha() + (delta * 9), 1)
            self:SetAlpha(newAlpha, true)
        end
    end
end
