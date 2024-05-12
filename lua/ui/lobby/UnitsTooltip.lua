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
local PixelScaleFactor = LayoutHelpers.GetPixelScaleFactor()
local Layouter = LayoutHelpers.ReusedLayoutFor

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

    -- This looks like a border for the entire tooltip when the other backgrounds on top fill it in.
    tooltipUI = Layouter(Bitmap(parent)):Color(UIUtil.tooltipBorderColor):Over(parent, 10000):Width(tooltipWidth):Height(tooltipHeight):End()

    -- left text margin; leftwards offset from the tooltip border's left edge
    local left = 7

    local titleString = ''

    if bp.Description then
        titleString = bp.Tech .. ' ' .. LOC(bp.Description)
    elseif bp.Name then
        titleString = LOC(bp.Name)
    end

    local generalUnitName = LOC(bp.General.UnitName)
    if generalUnitName and generalUnitName ~= '' and not bp.CategoriesHash['SUBCOMMANDER'] then
        titleString = titleString .. ' (' .. generalUnitName .. ')'
    end

    -- 2px top/left border, 7px left offset
    local title = Layouter(UIUtil.CreateText(tooltipUI, titleString, fontTextSize, UIUtil.bodyFont)):AtLeftTopIn(tooltipUI, 2 + left, 2):End()
    tooltipUI.title = title

    -- AtBottomIn -2 offset for parantheses to appear centered
    local titleBg = Layouter(Bitmap(tooltipUI)):Color(UIUtil.tooltipTitleColor):Under(title):AtTopIn(title):AtBottomIn(title, -2):AtLeftIn(tooltipUI, 2):AtRightIn(tooltipUI, 2):End()
    tooltipUI.titleBg = titleBg

    local titleHeight = math.max(tooltipUI.title.Height(), 1) + 4 -- 2 border + title height + 2 titleBg bottom negative padding
    local top  = titleHeight

    -- Serves as the black background of the body of the tooltip
    local body = Layouter(Bitmap(tooltipUI)):Color('FF080808'):AtLeftIn(tooltipUI, 2):AtRightIn(tooltipUI, 2):Height(300):AnchorToBottom(titleBg):End()
    tooltipUI.body = body

    top = top + 2 -- + 2 body padding

    -- Reusable string value
    local value = ''

    tooltipHeight = math.max(tooltipUI.title.Height(), 1)

    -- showing bp.Categories because they are more accurate than bp.Display.Abilities
    local categoriesText = TextArea(tooltipUI, tooltipWidth - 2 * left, 30)
    categoriesText:SetText( table.concat(UnitsAnalyzer.GetUnitsCategories(bp, false), ', ') )
    categoriesText:SetFont(fontTextName, fontTextSize - 1)
    categoriesText:SetColors('FFFC9038', nil, nil, nil) -- Only the foreground color will be changed, the rest will remain as defaults
    local textAreaHeight = categoriesText:GetItemCount() * (fontTextSize + PixelScaleFactor) -- +1 px for the text to fit in
    Layouter(categoriesText):Height(textAreaHeight):AtLeftIn(tooltipUI, left):AtTopIn(body, 2):End()
    tooltipUI.Categories = categoriesText

    top = top + tooltipUI.Categories.Height()
    top = top + 8 -- + categories height + 8 padding

    local id = bp.ID
    if bp.Type == "UPGRADE" and bp.Icon and bp.SourceID then
        id = bp.SourceID .. "-" .. bp.Icon
        id = string.lower(id)
    end

    value = LOC(UnitDescriptions[id]) or LOC(bp.Interface.Help.HelpText)

    -- defaulting to description of base units for preset support commanders
    local underscoreIndex = string.find(id, "_")
    if not value and bp.CategoriesHash['SUBCOMMANDER'] and underscoreIndex then
        local baseID = string.sub(id, 1, underscoreIndex - 1)
        value = LOC(UnitDescriptions[baseID])
    end

    local description
    if not value then
        if not bp.Mod then -- show warnings only for not modded units
            WARN('UnitsTooltip cannot find unit description for ' .. bp.ID .. ' blueprint')
        end
    else
        description = TextArea(tooltipUI, tooltipWidth-14, 30)
        description:SetText(value)
        description:SetFont(fontTextName, fontTextSize-1)
        description:SetColors(colorText, nil, nil, nil)
        local textAreaHeight = description:GetItemCount() * (fontTextSize + PixelScaleFactor)
        Layouter(description):Height(textAreaHeight):AtLeftIn(tooltipUI, 7):AnchorToBottom(categoriesText):End()
        tooltipUI.Descr = description

        top  = top + tooltipUI.Descr.Height()
        top  = top + 12 -- + categories height + 12 padding
    end

    -- the columns give the right margin of the text so that the numbers can grow leftwards freely
    local column2 = tooltipWidth - 100 + left -- cost/damage            -- 327  -- 420 - 327 = 93
    local column3 = column2 - 100 -- production/dps                     -- 227  -- 420 - 227 = 193
    local column4 = column3 - 90  -- defense/range                      -- 137  -- 420 - 137 = 283
    local column5 = column4 - 90  -- per mass                           -- 47   -- 420 - 47  = 373

    local costLabel = Layouter(UIUtil.CreateText(tooltipUI, 'BUILD COST ', fontTextSize-2, fontTextName)):Color(colorText)
        :AtRightIn(tooltipUI, column2-iconSize-5):AnchorToBottom(description or categoriesText, 12):End()

    local prodLabel = Layouter(UIUtil.CreateText(tooltipUI, 'PRODUCTION ', fontTextSize-2, fontTextName)):Color(colorText)
        :AtRightIn(tooltipUI, column3-iconSize-5):AnchorToBottom(description or categoriesText, 12):End()

    local defenseLabel = Layouter(UIUtil.CreateText(tooltipUI, 'DEFENSE ', fontTextSize-2, fontTextName)):Color(colorText)
        :AtRightIn(tooltipUI, column4-iconSize-5):AnchorToBottom(description or categoriesText, 12):End()

    local perMassLabel = Layouter(UIUtil.CreateText(tooltipUI, 'PER MASS ', fontTextSize-2, fontTextName)):Color(colorText)
        :AtRightIn(tooltipUI, column5-iconSize-5):AnchorToBottom(description or categoriesText, 12):End()

    top  = top + costLabel.Height()  + 1 -- + row 1 height + 1 padding

    local eco = UnitsAnalyzer.GetEconomyStats(bp)

    value = StringComma(eco.BuildCostMass)
    local MassCostIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/mass.dds'):Width(iconSize):Height(iconSize)
        :AtRightIn(costLabel, 5):AnchorToBottom(costLabel, 2):End()
    local MassCostText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorMass):LeftOf(MassCostIcon, 4):AnchorToBottom(costLabel, 1):End()

    value = eco.YieldMass
    value = StringComma(value > 0 and '+' .. value or value)
    local MassProdIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/mass.dds'):Width(iconSize):Height(iconSize)
        :AtRightIn(prodLabel, 5):AnchorToBottom(prodLabel, 2):End()
    local MassProdText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorMass):LeftOf(MassProdIcon, 4):AnchorToBottom(prodLabel, 1):End()

    local healthValue = init(bp.Defense.Health or bp.NewHealth) -- NewHealth is used by enhancements
    value = StringComma(math.floor(healthValue))
    local HealthIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/defense-health.dds'):Width(iconSize):Height(iconSize)
        :AtRightIn(defenseLabel, 5):AnchorToBottom(defenseLabel, 2):End()
    local HealthText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDefense):LeftOf(HealthIcon, 4):AnchorToBottom(defenseLabel, 1):End()

    value = string.format("%0.2f ", (healthValue / eco.BuildCostMass))
    local HealthPerMassIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/defense-health.dds'):Width(iconSize):Height(iconSize)
        :AtRightIn(perMassLabel, 5):AnchorToBottom(perMassLabel, 2):End()
    local HealthPerMassText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDefense):LeftOf(HealthPerMassIcon, 4):AnchorToBottom(perMassLabel, 1):End()

    top  = top + MassCostText.Height() + 2 -- row 2 text height + 2 padding

    value = StringComma(math.ceil(eco.BuildCostEnergy))
    local EnergyCostIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/energy.dds'):Width(iconSize):Height(iconSize)
        :AtRightIn(MassCostIcon):AnchorToBottom(MassCostText, 3):End()
    local EnergyCostText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorEnergy):LeftOf(EnergyCostIcon, 4):AnchorToBottom(MassCostText, 2):End()

    value = eco.YieldEnergy
    value = StringComma(value > 0 and '+' .. value or value)
    local EnergyProdIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/energy.dds'):Width(iconSize):Height(iconSize)
        :AtRightIn(MassProdIcon):AnchorToBottom(MassProdText, 3):End()
    local EnergyProdText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorEnergy):LeftOf(EnergyProdIcon, 4):AnchorToBottom(MassProdText, 2):End()

    local shieldValue = init(bp.ShieldMaxHealth or bp.Defense.Shield.ShieldMaxHealth)
    value = StringComma(math.floor(shieldValue))
    local ShieldIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/defense-shields.dds'):Width(iconSize):Height(iconSize)
        :AtRightIn(HealthIcon):AnchorToBottom(HealthText, 3):End()
    local ShieldText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDefense):LeftOf(ShieldIcon, 4):AnchorToBottom(HealthText, 2):End()

    value = string.format("%0.2f",(shieldValue / eco.BuildCostMass))
    local ShieldPerMassIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/defense-shields.dds'):Width(iconSize):Height(iconSize)
        :AtRightIn(HealthPerMassIcon):AnchorToBottom(HealthPerMassText, 3):End()
    local ShieldPerMassText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDefense):LeftOf(ShieldPerMassIcon, 4):AnchorToBottom(HealthPerMassText, 2):End()

    top = top + EnergyCostText.Height() + 2 -- row 3 text height + 2 padding

    value = StringComma(math.floor(eco.BuildTime))
    local BuildTimeIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/build-time.dds'):Width(iconSize):Height(iconSize)
        :AtRightIn(EnergyCostIcon):AnchorToBottom(EnergyCostText, 3):End()
    local BuildTimeText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorBuild):LeftOf(BuildTimeIcon, 4):AnchorToBottom(EnergyCostText, 2):End()

    value = StringComma(eco.BuildRate)
    local BuildRateIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/build-rate.dds'):Width(iconSize):Height(iconSize)
        :AtRightIn(EnergyProdIcon):AnchorToBottom(EnergyProdText, 3):End()
    local BuildRateText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorBuild):LeftOf(BuildRateIcon, 4):AnchorToBottom(EnergyProdText, 2):End()

    top  = top + BuildTimeText.Height() + 10 -- row 4 text height + 10 padding

    local furthestDownControl
    local weapons = UnitsAnalyzer.GetWeaponsStats(bp)
    for i, weapon in weapons or {} do
        top = top + 1 -- + 1 padding

        local weaponText = Layouter(UIUtil.CreateText(tooltipUI, weapon.Info, fontTextSize-1, fontTextName)):Color(colorText):AtLeftIn(tooltipUI, left)
        if not furthestDownControl then
            weaponText = weaponText:AnchorToBottom(BuildTimeText, 11):End()
        else
            weaponText = weaponText:AnchorToBottom(furthestDownControl, 1):End()
        end

        top = top + weaponText.Height()  + 1 -- + weapon title text height + 1 padding
        
        value = StringComma(weapon.Damage)
        local dmgIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/damage.dds'):Width(iconSize):Height(iconSize)
            :AtRightIn(EnergyCostIcon):AnchorToBottom(weaponText, 2):End()
        local dmgText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDamage):LeftOf(dmgIcon, 4):AnchorToBottom(weaponText, 1):End()

        furthestDownControl = dmgText

        value = StringComma(weapon.DPS)
        local dpsIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/damage-per-second.dds'):Width(iconSize):Height(iconSize)
            :AtRightIn(EnergyProdIcon):AnchorToBottom(weaponText, 2):End()
        local dpsText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDamage):LeftOf(dpsIcon, 4):AnchorToBottom(weaponText, 1):End()
        
        value = StringComma(weapon.Range)
        local rangeIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/damage-range.dds'):Width(iconSize):Height(iconSize)
            :AtRightIn(ShieldIcon):AnchorToBottom(weaponText, 2):End()
        local rangeText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDamage):LeftOf(rangeIcon, 4):AnchorToBottom(weaponText, 1):End()
        
        value = string.format("%0.2f", weapon.DPM)
        local dpmIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/damage-per-mass.dds'):Width(iconSize):Height(iconSize)
            :AtRightIn(ShieldPerMassIcon):AnchorToBottom(weaponText, 2):End()
        local dpmText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDamage):LeftOf(dpmIcon, 4):AnchorToBottom(weaponText, 1):End()

        top  = top + dmgText.Height() -- + dmgtext Height
    end

    local total = UnitsAnalyzer.GetWeaponsTotal(weapons)
    if total.Count > 1 then
        top  = top + 10 -- + 10 padding (don't forget dmgtext from before)

        local weaponText = Layouter(UIUtil.CreateText(tooltipUI, total.Info, fontTextSize-1, fontTextName)):Color(colorText):AtLeftIn(tooltipUI, left)
            :AnchorToBottom(furthestDownControl, 10):End()

        top  = top + weaponText.Height() + 1 -- all weapons title text + 1 padding

        value = StringComma(total.Damage)
        local dmgIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/damage.dds'):Width(iconSize):Height(iconSize)
            :AtRightIn(EnergyCostIcon):AnchorToBottom(weaponText, 2):End()
        local dmgText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDamage):LeftOf(dmgIcon, 4):AnchorToBottom(weaponText, 1):End()

        furthestDownControl = dmgText

        value = StringComma(total.DPS)
        local dpsIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/damage-per-second.dds'):Width(iconSize):Height(iconSize)
            :AtRightIn(EnergyProdIcon):AnchorToBottom(weaponText, 2):End()
        local dpsText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDamage):LeftOf(dpsIcon, 4):AnchorToBottom(weaponText, 1):End()
        
        value = StringComma(total.Range)
        local rangeIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/damage-range.dds'):Width(iconSize):Height(iconSize)
            :AtRightIn(ShieldIcon):AnchorToBottom(weaponText, 2):End()
        local rangeText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDamage):LeftOf(rangeIcon, 4):AnchorToBottom(weaponText, 1):End()
        
        value = string.format("%0.2f", total.DPM)
        local dpmIcon = Layouter(Bitmap(tooltipUI)):Texture('/textures/ui/common/game/unit-build-over-panel/damage-per-mass.dds'):Width(iconSize):Height(iconSize)
            :AtRightIn(ShieldPerMassIcon):AnchorToBottom(weaponText, 2):End()
        local dpmText = Layouter(UIUtil.CreateText(tooltipUI, value, fontValueSize, fontValueName)):Color(colorDamage):LeftOf(dpmIcon, 4):AnchorToBottom(weaponText, 1):End()

        top  = top + dmgText.Height() -- + dmgtext height
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
    --local column1 = left
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





