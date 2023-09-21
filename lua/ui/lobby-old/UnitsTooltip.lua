-- ==========================================================================================
-- * File       : lua/modules/ui/lobby/UnitsTooltips.lua
-- * Authors    : FAF Community, HUSSAR
-- * Summary    : Provides logic on UI/lobby side for creating tooltips of units and
--                enhancements with detailed info about build cost, production power,
--                weapons, and other stats such as DPS, DPM, etc.
-- ==========================================================================================

local Prefs    = import("/lua/user/prefs.lua")
local UIUtil   = import("/lua/ui/uiutil.lua")
local Utils    = import("/lua/system/utils.lua")
local Group    = import("/lua/maui/group.lua").Group
local Bitmap   = import("/lua/maui/bitmap.lua").Bitmap
local Text     = import("/lua/maui/text.lua")
local TextArea = import("/lua/ui/controls/textarea.lua").TextArea

local LayoutHelpers = import("/lua/maui/layouthelpers.lua")

local UnitsAnalyzer   = import("/lua/ui/lobby/unitsanalyzer.lua")
local UnitDescriptions = import("/lua/ui/help/unitdescription.lua").Description

local tooltipUI = false

local fontMono      = "Courier New" -- 'Butterbelly'
local fontDigital   = "Zeroes Three"
local fontBold      = 'Arial Bold'

local fontTextSize = 14
local fontTextName = UIUtil.bodyFont
local fontValueName = UIUtil.bodyFont
local fontValueSize = 15

local iconSize = 16

local tooltipWidth = 420
local tooltipHeight = 20 -- initial tooltip height

local colorMass    = 'FF79c400' -- --FF79c400
local colorEnergy  = 'FFFCCB10' -- --FFFCCB10
local colorDamage  = 'FFF70B0B' -- --FFF70B0B
local colorText    = 'FFE1E1E1' -- --FFE1E1E1
local colorBuild   = 'FFE1E1E1' -- --FFE1E1E1
local colorDefense = 'FF0090ff' -- --FF0090ff
local colorMod     = 'FFCB59F7' -- --FFCB59F7

local debugging = false

-- convert time in ticks to a string with MM:SS format
local function stringTime(time)
    time = time / 60
    local timeMM =  math.floor(time / 60)
    local timeSS =  math.floor(math.mod(time, 60))
    return string.format("%02d:%02d", timeMM, timeSS)
end

-- initializes value to zero if it is nil
local function init(value)
    return value > 1 and value or 0
end

function Destroy()
    if tooltipUI then
       tooltipUI:Destroy()
       tooltipUI = false
    end
end
-- creates custom tooltip with detailed information about game units or modded units
function Create(parent, bp)

    Destroy()

    local title = ''

    if bp.Description then
        title = ' ' .. bp.Tech .. ' ' .. LOCF(bp.Description)
    elseif bp.Name  then
        title = ' ' .. LOCF(bp.Name)
    end
    if bp.General.UnitName and not bp.CategoriesHash['SUBCOMMANDER'] then
        title = title .. ' (' .. LOCF(bp.General.UnitName) .. ')'
    end

    tooltipUI = Bitmap(parent)
    tooltipUI:SetSolidColor(UIUtil.tooltipBorderColor)
    tooltipUI.Depth:Set(function() return parent.Depth() + 10000 end)
    LayoutHelpers.SetDimensions(tooltipUI, tooltipWidth, tooltipHeight)

    tooltipUI.title = UIUtil.CreateText(tooltipUI, title, fontTextSize, UIUtil.bodyFont)
    LayoutHelpers.AtLeftTopIn(tooltipUI.title, tooltipUI, 2, 2)

    tooltipUI.titleBg = Bitmap(tooltipUI)
    tooltipUI.titleBg:SetSolidColor(UIUtil.tooltipTitleColor)
    tooltipUI.titleBg.Depth:Set(function() return tooltipUI.title.Depth() - 1 end)
    tooltipUI.titleBg.Top:Set(tooltipUI.title.Top)
    LayoutHelpers.AtBottomIn(tooltipUI.titleBg, tooltipUI.title, -2)

    tooltipUI.titleBg.Left:Set(function() return tooltipUI.title.Left() end)
    LayoutHelpers.AnchorToLeft(tooltipUI.titleBg, tooltipUI.title, - tooltipWidth + 4)

    local titleHeight = math.max(tooltipUI.title.Height(), 1) + 4
    local top  = titleHeight
    local left = 7

    tooltipUI.body = Bitmap(tooltipUI)
    tooltipUI.body:SetSolidColor('FF080808') ----FF080808
    LayoutHelpers.SetDimensions(tooltipUI.body, tooltipWidth-4, 300)
    LayoutHelpers.AtLeftTopIn(tooltipUI.body, tooltipUI, 2, top)

    top = top + 2

    local column1 = left
    local column2 = tooltipWidth - 100 + left -- damage
    local column3 = column2 - 100 -- dps
    local column4 = column3 - 90  -- dpm
    local column5 = column4 - 90  -- range
    local column6 = column5 - 10

    local text = nil
    local value = ''

    tooltipHeight = math.max(tooltipUI.title.Height(), 1)

    -- showing bp.Categories because they are more accurate than bp.Display.Abilities
    local cats = UnitsAnalyzer.GetUnitsCategories(bp, false)
    value = table.concat(cats, ', ')
    --table.print(bp.Display.Abilities, 'Abilities')
    tooltipUI.Categories = TextArea(tooltipUI, LayoutHelpers.ScaleNumber(tooltipWidth), 30)
    tooltipUI.Categories:SetText(value)
    tooltipUI.Categories:SetFont(fontTextName, fontTextSize-1)
    tooltipUI.Categories:SetColors('FFFC9038', '00000000', UIUtil.fontColor, '00000000') ----FFFC9038
    local wrapped = Text.WrapText(value, LayoutHelpers.ScaleNumber(tooltipWidth-10), function(value) return tooltipUI.Categories:GetStringAdvance(value) end)
    local wrappedHeight = (table.getsize(wrapped) or 1) * tooltipHeight
    tooltipUI.Categories.Height:Set(wrappedHeight)
    LayoutHelpers.AtLeftTopIn(tooltipUI.Categories, tooltipUI, left, top)

    top = top + tooltipUI.Categories.Height()
    top = top + 8

    local id = bp.ID
    if bp.Type == "UPGRADE" and bp.Icon and bp.SourceID then
        id = bp.SourceID .. "-" .. bp.Icon
        id = string.lower(id)
    end

    value = LOC(UnitDescriptions[id]) or LOC(bp.Interface.Help.HelpText)

    -- defaulting to description of base units for preset support commanders
    if not value and bp.CategoriesHash['SUBCOMMANDER'] and string.find(id, "_") then
        local baseID = StringSplit(id, '_')[1]
        value = LOC(UnitDescriptions[baseID])
    end

    if not value then
        if not bp.Mod then -- show warnings only for not modded units
            WARN('UnitsTooltip cannot find unit description for ' .. bp.ID .. ' blueprint')
        end
    else
        tooltipUI.Descr = TextArea(tooltipUI, LayoutHelpers.ScaleNumber(tooltipWidth-10), 30)
        tooltipUI.Descr:SetText(value)
        tooltipUI.Descr:SetFont(fontTextName, fontTextSize-1)
        tooltipUI.Descr:SetColors(colorText, '00000000', UIUtil.fontColor, '00000000')
        local wrapped = Text.WrapText(value, LayoutHelpers.ScaleNumber(tooltipWidth-10), function(value) return tooltipUI.Descr:GetStringAdvance(value) end)
        local wrappedHeight = (table.getsize(wrapped) or 1) * tooltipHeight
        tooltipUI.Descr.Height:Set(wrappedHeight)
        LayoutHelpers.AtLeftTopIn(tooltipUI.Descr, tooltipUI, left, top)

        top  = top + tooltipUI.Descr.Height()
        top  = top + 12
    end

    local perMassLabel = UIUtil.CreateText(tooltipUI, 'PER MASS ', fontTextSize-2, fontTextName)
    perMassLabel:SetColor(colorText)
    LayoutHelpers.AtRightTopIn(perMassLabel, tooltipUI, column5-iconSize-5, top)

    local defenseLabel = UIUtil.CreateText(tooltipUI, 'DEFENSE ', fontTextSize-2, fontTextName)
    defenseLabel:SetColor(colorText)
    LayoutHelpers.AtRightTopIn(defenseLabel, tooltipUI, column4-iconSize-5, top)

    local prodLabel = UIUtil.CreateText(tooltipUI, 'PRODUCTION ', fontTextSize-2, fontTextName)
    prodLabel:SetColor(colorText)
    LayoutHelpers.AtRightTopIn(prodLabel, tooltipUI, column3-iconSize-5, top)

    local costLabel = UIUtil.CreateText(tooltipUI, 'BUILD COST ', fontTextSize-2, fontTextName)
    costLabel:SetColor(colorText)
    LayoutHelpers.AtRightTopIn(costLabel, tooltipUI, column2-iconSize-5, top)

    top  = top + costLabel.Height()  + 1

    local eco = UnitsAnalyzer.GetEconomyStats(bp)

    local healthValue = init(bp.NewHealth or bp.Defense.Health)
    local healthString = StringComma(math.floor(healthValue)) .. ' '
    HealthText = UIUtil.CreateText(tooltipUI, healthString, fontValueSize, fontValueName)
    HealthText:SetColor(colorDefense) ----FF0BACF7
    LayoutHelpers.AtRightTopIn(HealthText, tooltipUI, column4, top)
    HealthIcon = Bitmap(tooltipUI)
    HealthIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/defense-health.dds')
    LayoutHelpers.SetDimensions(HealthIcon, iconSize, iconSize)
    LayoutHelpers.AtLeftTopIn(HealthIcon, tooltipUI, tooltipWidth-column4, top+2)

    local healthValue = (healthValue / eco.BuildCostMass)
    local healthString = string.format("%0.2f ",healthValue)
    HealthPerMassText = UIUtil.CreateText(tooltipUI, healthString, fontValueSize, fontValueName)
    HealthPerMassText:SetColor(colorDefense) ----FF0BACF7
    LayoutHelpers.AtRightTopIn(HealthPerMassText, tooltipUI, column5, top)
    HealthPerMassIcon = Bitmap(tooltipUI)
    HealthPerMassIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/defense-health.dds')
    LayoutHelpers.SetDimensions(HealthPerMassIcon, iconSize, iconSize)
    LayoutHelpers.AtLeftTopIn(HealthPerMassIcon, tooltipUI, tooltipWidth-column5, top+2)

    value = eco.YieldMass
    value = value > 0 and '+' .. value or value
    value = StringComma(value) .. ' '
    MassProdText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
    MassProdText:SetColor(colorMass)  -- --FF2DEC28
    LayoutHelpers.AtRightTopIn(MassProdText, tooltipUI, column3, top)
    MassProdIcon = Bitmap(tooltipUI)
    MassProdIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/mass.dds')
    LayoutHelpers.SetDimensions(MassProdIcon, iconSize, iconSize)
    LayoutHelpers.AtLeftTopIn(MassProdIcon, tooltipUI, tooltipWidth-column3, top+2)

    value = StringComma(eco.BuildCostMass) .. ' '
    MassCostText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
    MassCostText:SetColor(colorMass) -- --FF2DEC28
    LayoutHelpers.AtRightTopIn(MassCostText, tooltipUI, column2, top)
    MassCostIcon = Bitmap(tooltipUI)
    MassCostIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/mass.dds')
    LayoutHelpers.SetDimensions(MassCostIcon, iconSize, iconSize)
    LayoutHelpers.AtLeftTopIn(MassCostIcon, tooltipUI, tooltipWidth-column2, top+2)

    top  = top + MassCostText.Height() + 2

    local shieldValue = init(bp.ShieldMaxHealth or bp.Defense.Shield.ShieldMaxHealth)
    local shieldString = StringComma(math.floor(shieldValue)) .. ' '
    ShieldText = UIUtil.CreateText(tooltipUI, shieldString, fontValueSize, fontValueName)
    ShieldText:SetColor(colorDefense) ----FF0BACF7
    LayoutHelpers.AtRightTopIn(ShieldText, tooltipUI, column4, top)
    ShieldIcon = Bitmap(tooltipUI)
    ShieldIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/defense-shields.dds')
    LayoutHelpers.SetDimensions(ShieldIcon, iconSize, iconSize)
    LayoutHelpers.AtLeftTopIn(ShieldIcon, tooltipUI, tooltipWidth-column4, top+2)

    local shieldValue = (shieldValue / eco.BuildCostMass)
    local shieldString = string.format("%0.2f",shieldValue) .. ' '
    ShieldPerMassText = UIUtil.CreateText(tooltipUI, shieldString, fontValueSize, fontValueName)
    ShieldPerMassText:SetColor(colorDefense) ----FF0BACF7
    LayoutHelpers.AtRightTopIn(ShieldPerMassText, tooltipUI, column5, top)
    ShieldPerMassIcon = Bitmap(tooltipUI)
    ShieldPerMassIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/defense-shields.dds')
    LayoutHelpers.SetDimensions(ShieldPerMassIcon, iconSize, iconSize)
    LayoutHelpers.AtLeftTopIn(ShieldPerMassIcon, tooltipUI, tooltipWidth-column5, top+2)

    value = eco.YieldEnergy
    value = value > 0 and '+' .. value or value
    value = StringComma(value) .. ' '
    EnergyProdText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
    EnergyProdText:SetColor(colorEnergy) ----FFF7B00B
    LayoutHelpers.AtRightTopIn(EnergyProdText, tooltipUI, column3, top)
    EnergyProdIcon = Bitmap(tooltipUI)
    EnergyProdIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/energy.dds')
    LayoutHelpers.SetDimensions(EnergyProdIcon, iconSize, iconSize)
    LayoutHelpers.AtLeftTopIn(EnergyProdIcon, tooltipUI, tooltipWidth-column3, top+2)

    value = StringComma(math.ceil(eco.BuildCostEnergy)) .. ' '
    EnergyCostText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
    EnergyCostText:SetColor(colorEnergy) ----FFF7B00B
    LayoutHelpers.AtRightTopIn(EnergyCostText, tooltipUI, column2, top)
    EnergyCostIcon = Bitmap(tooltipUI)
    EnergyCostIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/energy.dds')
    LayoutHelpers.SetDimensions(EnergyCostIcon, iconSize, iconSize)
    LayoutHelpers.AtLeftTopIn(EnergyCostIcon, tooltipUI, tooltipWidth-column2, top+2)

    top = top + EnergyCostText.Height() + 2

    value = stringTime(math.floor(eco.BuildTime)) .. ' '
    BuildTimeText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
    BuildTimeText:SetColor(colorBuild) ----FFD9D9D9
    LayoutHelpers.AtRightTopIn(BuildTimeText, tooltipUI, column2, top)
    BuildTimeIcon = Bitmap(tooltipUI)
    BuildTimeIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/build-time.dds')
    LayoutHelpers.SetDimensions(BuildTimeIcon, iconSize, iconSize)
    LayoutHelpers.AtLeftTopIn(BuildTimeIcon, tooltipUI, tooltipWidth-column2, top+2)

    value = StringComma(eco.BuildRate).. ' '
    BuildRateText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
    BuildRateText:SetColor(colorBuild) ----FFD9D9D9
    LayoutHelpers.AtRightTopIn(BuildRateText, tooltipUI, column3, top)
    BuildRateIcon = Bitmap(tooltipUI)
    BuildRateIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/build-rate.dds')
    LayoutHelpers.SetDimensions(BuildRateIcon, iconSize, iconSize)
    LayoutHelpers.AtLeftTopIn(BuildRateIcon, tooltipUI, tooltipWidth-column3, top+2)

    top  = top + BuildTimeText.Height() + 10

    local weapons = UnitsAnalyzer.GetWeaponsStats(bp)
    for i, weapon in weapons or {} do
        top  = top + 1
        local weaponText = UIUtil.CreateText(tooltipUI, weapon.Info, fontTextSize-1, fontTextName)
        weaponText:SetColor('FFE1DFDF') ----FFE1DFDF
        LayoutHelpers.AtLeftTopIn(weaponText, tooltipUI, left, top)
        top  = top + weaponText.Height()  + 1

        value = StringComma(weapon.Range) .. ' ' --RANGE
        local rangeText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
        rangeText:SetColor('FFF70B0B') ----FFF70B0B
        LayoutHelpers.AtRightTopIn(rangeText, tooltipUI, column4, top)
        local rangeIcon = Bitmap(tooltipUI)
        rangeIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/damage-range.dds')
        LayoutHelpers.SetDimensions(rangeIcon, iconSize, iconSize)
        LayoutHelpers.AtLeftTopIn(rangeIcon, tooltipUI, tooltipWidth-column4, top+1)

        value = string.format("%0.2f",weapon.DPM) .. ' '
        local dpmText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
        dpmText:SetColor('FFF70B0B') ----FFF70B0B
        LayoutHelpers.AtRightTopIn(dpmText, tooltipUI, column5, top)
        local dpmIcon = Bitmap(tooltipUI)
        dpmIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/damage-per-mass.dds')
        LayoutHelpers.SetDimensions(dpmIcon, iconSize, iconSize)
        LayoutHelpers.AtLeftTopIn(dpmIcon, tooltipUI, tooltipWidth-column5, top+1)

        value = StringComma(weapon.DPS) .. ' '
        local dpsText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
        dpsText:SetColor('FFF70B0B') ----FFF70B0B
        LayoutHelpers.AtRightTopIn(dpsText, tooltipUI, column3, top)
        local dpsIcon = Bitmap(tooltipUI)
        dpsIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/damage-per-second.dds')
        LayoutHelpers.SetDimensions(dpsIcon, iconSize, iconSize)
        LayoutHelpers.AtLeftTopIn(dpsIcon, tooltipUI, tooltipWidth-column3, top+1)

        value = StringComma(weapon.Damage) .. ' '
        local dmgText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
        dmgText:SetColor('FFF70B0B') ----FFF70B0B
        LayoutHelpers.AtRightTopIn(dmgText, tooltipUI, column2, top)
        local dmgIcon = Bitmap(tooltipUI)
        dmgIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/damage.dds')
        LayoutHelpers.SetDimensions(dmgIcon, iconSize, iconSize)
        LayoutHelpers.AtLeftTopIn(dmgIcon, tooltipUI, tooltipWidth-column2, top+1)

        top  = top + dmgText.Height()
    end

    local total = UnitsAnalyzer.GetWeaponsTotal(weapons)
    if total.Count > 1 then
        top  = top + 10

        local weaponText = UIUtil.CreateText(tooltipUI, total.Info, fontTextSize, fontTextName)
        weaponText:SetColor('FFE1DFDF') ----FFE1DFDF
        LayoutHelpers.AtLeftTopIn(weaponText, tooltipUI, left, top)
        top  = top + weaponText.Height() + 1

        value = StringComma(total.Range) .. ' ' --RANGE
        local rangeText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
        rangeText:SetColor('FFF70B0B') ----FFF70B0B
        LayoutHelpers.AtRightTopIn(rangeText, tooltipUI, column4, top)
        local rangeIcon = Bitmap(tooltipUI)
        rangeIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/damage-range.dds')
        LayoutHelpers.SetDimensions(rangeIcon, iconSize, iconSize)
        LayoutHelpers.AtLeftTopIn(rangeIcon, tooltipUI, tooltipWidth-column4, top+1)

        value = string.format("%0.2f",total.DPM) .. ' '
        local dpmText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
        dpmText:SetColor('FFF70B0B') ----FFF70B0B
        LayoutHelpers.AtRightTopIn(dpmText, tooltipUI, column5, top)
        local dpmIcon = Bitmap(tooltipUI)
        dpmIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/damage-per-mass.dds')
        LayoutHelpers.SetDimensions(dpmIcon, iconSize, iconSize)
        LayoutHelpers.AtLeftTopIn(dpmIcon, tooltipUI, tooltipWidth-column5, top+1)

        value = StringComma(total.DPS) .. ' '
        local dpsText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
        dpsText:SetColor('FFF70B0B') ----FFF70B0B
        LayoutHelpers.AtRightTopIn(dpsText, tooltipUI, column3, top)
        local dpsIcon = Bitmap(tooltipUI)
        dpsIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/damage-per-second.dds')
        LayoutHelpers.SetDimensions(dpsIcon, iconSize, iconSize)
        LayoutHelpers.AtLeftTopIn(dpsIcon, tooltipUI, tooltipWidth-column3, top+1)

        value = StringComma(total.Damage) .. ' '
        local dmgText = UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)
        dmgText:SetColor('FFF70B0B') ----FFF70B0B
        LayoutHelpers.AtRightTopIn(dmgText, tooltipUI, column2, top)
        local dmgIcon = Bitmap(tooltipUI)
        dmgIcon:SetTexture('/textures/ui/common/game/unit-build-over-panel/damage.dds')
        LayoutHelpers.SetDimensions(dmgIcon, iconSize, iconSize)
        LayoutHelpers.AtLeftTopIn(dmgIcon, tooltipUI, tooltipWidth-column2, top+1)

        top  = top + dmgText.Height()
    end

    if bp.Mod then
        top  = top + 10
        value = 'MOD: ' .. bp.Mod.name
        local mod = UIUtil.CreateText(tooltipUI, value, fontTextSize, fontTextName)
        mod:SetColor(colorMod) ----FFC905DC
        LayoutHelpers.AtLeftTopIn(mod, tooltipUI, left, top)
        top  = top + mod.Height()
        if debugging and bp.Source then
            value = '' .. bp.Source
            local source = UIUtil.CreateText(tooltipUI, value, fontTextSize, fontTextName)
            source:SetColor(colorMod) ----FFC905DC
            LayoutHelpers.AtLeftTopIn(source, tooltipUI, left, top)
            top  = top + source.Height()
        end
    end

    --NOTE UI for debugging
    --BlueprintText = UIUtil.CreateText(tooltipUI, bp.Source or '', fontValueSize, fontValueName)
    --BlueprintText:SetColor('FFE4BF0C') ----FFE4BF0C
    --LayoutHelpers.AtRightTopIn(BlueprintText, tooltipUI, column1, top)

    LayoutHelpers.SetHeight(tooltipUI.body, top)

    local tooltipHeight = titleHeight
    tooltipHeight = tooltipHeight + math.max(top, 1) + 2
    LayoutHelpers.SetDimensions(tooltipUI, tooltipWidth, tooltipHeight)
    tooltipUI:DisableHitTest(true)

    local frame = GetFrame(0)
    if parent.Top() - tooltipUI.Height() < 0 then
        tooltipUI.Top:Set(function() return parent.Bottom() end)
    else
        tooltipUI.Bottom:Set(parent.Top)
    end

    if parent.Left() - tooltipUI.Width() < 0 then
        tooltipUI.Left:Set(function() return parent.Right() end)
    else
        tooltipUI.Right:Set(parent.Left)
    end

    -- NOTE keep this code in case of adding tooltip animation
    --if not Prefs.GetOption('tooltips') then return end
    --local createDelay = 0.01
    --if delay and Prefs.GetOption('tooltip_delay') then
    --    createDelay = math.max(delay, Prefs.GetOption('tooltip_delay'))
    --else
    --    createDelay = Prefs.GetOption('tooltip_delay') or 0
    --end
    --local alpha = 0.0
    --local totalTime = 0
    --tooltipUI:SetAlpha(alpha, true)
    --tooltipUI:SetNeedsFrameUpdate(true)
    --tooltipUI.OnFrame = function(self, deltaTime)
    --    if totalTime > createDelay then
    --        if parent then
    --            if alpha < 1 then
    --                tooltipUI:SetAlpha(alpha, true)
    --                alpha = alpha + (deltaTime * 4)
    --            else
    --                tooltipUI:SetAlpha(1, true)
    --                tooltipUI:SetNeedsFrameUpdate(false)
    --            end
    --        else
    --            WARN("NO PARENT SPECIFIED FOR TOOLTIP")
    --        end
    --    end
    --    totalTime = totalTime + deltaTime
    --end
end





