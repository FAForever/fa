local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local UIScale = LayoutHelpers.GetPixelScaleFactor()
local Group = import('/lua/maui/group.lua').Group
local Text = import('/lua/maui/text.lua').Text
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local Tooltip = import("/lua/ui/game/tooltip.lua")
local UIUtil = import('/lua/ui/uiutil.lua')
local Edit = import('/lua/maui/edit.lua').Edit
local getOptions = function() return import('/lua/user/prefs.lua').GetFromCurrentProfile('options') end
local options = getOptions()

-- this module provides most of logic for working with blueprints of units an props
local Logic = import('/lua/ui/dialogs/createunit.logic.lua')

local DummyUnitID = 'ura0001'
local DialogMode = options.spawn_menu_main_mode or 'units' --or 'props' or 'templates'
local currentArmy = GetFocusArmy()

-- combining army tables with an observer to simplify logic for creating army selectors
local ArmiesAndObserver = table.copy(GetArmiesTable().armiesTable)
table.insert(ArmiesAndObserver, {
    name = 'NEUTRAL',
    nickname = '<LOC tooltipui0149>Observer',
    observer = true, civilian = true, color = 'FF727272',
})
local NumArmies = table.getsize(ArmiesAndObserver)

local WindowBorderThickness = 10
local WindowHeaderThickness = 30

-- Helper values, changing these will break stuff, not configure stuff
local FilterWidth = 83 * UIScale
local FilterHeaderWidth = 90 * UIScale

local dialog, nameDialog, windowGroup, debugConfig
local EscThread
local ChosenCreation, FilterColumnCount, TeamColumnCount, TeamRowsCount
local activeFilters, activeFilterTypes, specialFilterControls, filterSet = {}, {}, {}, {}
local UnitList = {}

local searchText = ''

function RefreshUI()
    if dialog then
        dialog:OnClose()
        CreateDialog()
    end
end

function ClearFilters()
    searchText = ''
    activeFilters, activeFilterTypes, specialFilterControls, filterSet = {}, {}, {}, {}
    RefreshUI()
end

function UpdateTeamGridCounts(columns)
    TeamColumnCount = math.min(columns, math.ceil(NumArmies / math.ceil(NumArmies / columns)))
    TeamRowsCount = math.ceil(NumArmies/TeamColumnCount)
end

function StringTrim(str)
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function SourceListTabs()
    local NameMaxLengthChars = 12

    local function ShouldGiveTab(mod)
        local dirlen = (mod.location):len()
        for id, bp in __blueprints do
            if mod.location..'/' == string.sub(bp.Source, 1, dirlen+1) then
                return true
            end
        end
    end

    local function NameIsShortEnough(name) return (name):len() <= NameMaxLengthChars end
    local function ForWordsIn(text, operation) return string.gsub(text, '[%a\']+', operation) end
    local function Initialise(text) return string.gsub(text, '[%a\'%&]+%s*', function(s) return string.upper(string.sub(s,1,1)) end ) end
    local function Abreviate(word)
        local words = {
            Additional = 'Add',
            Advanced = 'Adv',
            Balance = 'Bal',
            BlackOps = 'BO',
            BrewLAN = 'BL',
            Command = 'Com',
            Commander = 'Cdr',
            Commanders = 'Cdrs',
            Experiment = 'Exp',
            Experimental = 'Exp',
            Experimentals = 'Exps',
            Infrastructure = 'Infr',
            Supreme = 'Sup',
            Veterancy = 'Vet',
        }
        return words[string.gsub(word,'\'','')] or word
    end

    local function titleFit(name)
        local l = NameMaxLengthChars

        --Removes version numbers and any brackets around them. Restrictive to reduce false positives
        name = string.gsub(name, '[%[%<%{%(%s]+[vV]+%s*%d+[_%.%d]*[%]%>%}%)%s]*', '') --Requires v or V at start
        name = string.gsub(name, '[%[%<%{%(%s]+%d+[_%.]+[_%.%d]+[%]%>%}%)%s]*', '') --Requres one or more decimal point or _ between numbers

        if NameIsShortEnough(name) then return name end

        -- Remove anything between brackets, and any space before them
        name = string.gsub(name, '%s*%b()', '')
        name = string.gsub(name, '%s*%b[]', '')
        name = string.gsub(name, '%s*%b<>', '')
        name = string.gsub(name, '%s*%b{}', '')

        if NameIsShortEnough(name) then return name end

        name = ForWordsIn(name, Abreviate)

        if NameIsShortEnough(name) then return name end

        if not string.find(string.sub(name, l), ' ') then --If we wouldn't lose any entire words, cutoff.
            return string.sub(name, 1, l)

        else -- If there are words that would be entirely cut off, initialise after the first
            local FirstSpaceIndex = string.find(name, ' ')
            local name = string.sub(name, 1, FirstSpaceIndex) .. Initialise(string.sub(name, FirstSpaceIndex+1))

            if NameIsShortEnough(name) then
                return name

            else --If it still isn't short enough, just initialise the rest as well, and trim the result just in case
                name = Initialise(string.sub(name, 1, FirstSpaceIndex)) .. string.sub(name, FirstSpaceIndex+1)
                return string.sub(name, 1, math.min(l, (name):len() ))
            end
        end
    end

    local list

    if getOptions().spawn_menu_split_sources then
        list = {
            {
                display = '<LOC spawn_filter_sc1>SC',
                tooltip = '<LOC spawn_filter_sc1_tip>Toggle SC orginal units',
                key = 'sc1',
                sortFunc = function(unitID, modloc)
                    return string.sub(__blueprints[unitID].Source, 1, 8) == "/units/u"
                end,
            },
            {
                display = '<LOC spawn_filter_scx1>SC-FA',
                tooltip = '<LOC spawn_filter_scx1_tip>Toggle FA updated units',
                key = 'scx1',
                sortFunc = function(unitID, modloc)
                    return string.sub(__blueprints[unitID].Source, 1, 8) == "/units/x"
                end,
            },
            {
                display = '<LOC spawn_filter_dlc>SC Patch',
                tooltip = '<LOC spawn_filter_dlc_tip>Toggle SC patched units',
                key = 'dlc',
                sortFunc = function(unitID, modloc)
                    return string.sub(__blueprints[unitID].Source, 1, 7) == "/units/" and string.sub(unitID, 1, 1) ~= 'u' and string.sub(unitID, 1, 1) ~= 'x' and string.sub(unitID, 1, 1) ~= 'o'
                end,
            },
        }
    else
        list = {
            {
                display = '<LOC spawn_filter_vanilla>Core Game',
                key = 'vanilla',
                sortFunc = function(unitID, modloc)
                    return string.sub(__blueprints[unitID].Source, 1, 7) == "/units/"
                end,
            }
        }
    end

    for i, mod in __active_mods do
        if mod.name then
            if ShouldGiveTab(mod) then
                local key = string.gsub(string.lower(mod.name),"%s+", "_")
                specialFilterControls[key] = mod.location
                table.insert(list, {
                    title = titleFit(mod.name),
                    key = key,
                    sortFunc = function(unitID, modloc) return modloc..'/' == string.sub(__blueprints[unitID].Source, 1, (modloc):len()+1) end,
                })
            end
        end
    end
    return list
end

function GetUnitFactionFilter(SearchFunc)
    local filter = { key = 'faction' }
    filter.display = '<LOC spawn_filter_faction>Faction'
    filter.choices = {}
    local allFactionCats = {}

    for i, faction in import('/lua/factions.lua').Factions do
        local key = 'faction'..faction.Category
        specialFilterControls[key] = faction.Category
        table.insert(allFactionCats, faction.Category)
        table.insert(filter.choices, {
            key = key,
            display = '<LOC spawn_filter_faction_'.. faction.Category .. '>' .. faction.Category,
            tooltip = '<LOC spawn_filter_faction_'.. faction.Category .. '_tip>Toggle ' .. faction.Category .. ' units',
            sortFunc = SearchFunc or Logic.HasCategory
        })
    end

    table.insert(filter.choices, {
        display = '<LOC spawn_filter_faction_other>Other',
        tooltip = '<LOC spawn_filter_faction_other_tip>Toggle units from other factions',
        key = 'otherfaction',
        sortFunc = function(unitID)
            for i, cat in allFactionCats do
                if SearchFunc then 
                    if SearchFunc(unitID, cat) then return end
                else
                    if Logic.HasCategory(unitID, cat) then return end
                end
            end
            return true
        end,
    })

    return filter
end

function GetUnitTypeFilter()
    local filter = { key = 'type' } 
    if getOptions().spawn_menu_type_filter_mode == 'category' then
        filter.display = '<LOC spawn_filter_type>Type'
        filter.choices = {
            {
                display = '<LOC spawn_filter_category_land>Land',
                tooltip = '<LOC spawn_filter_category_land_tip>Toggle Land units',
                key = 'land',
                sortFunc = Logic.IsLand,
            },
            {
                display = '<LOC spawn_filter_category_air>Air',
                tooltip = '<LOC spawn_filter_category_air_tip>Toggle Air units',
                key = 'air',
                sortFunc = Logic.IsAir,
            },
            {
                display = '<LOC spawn_filter_category_naval>Naval',
                tooltip = '<LOC spawn_filter_category_naval_tip>Toggle Naval units',
                key = 'naval',
                sortFunc = Logic.IsNaval,
            },
            {
                display = '<LOC spawn_filter_category_amph>Amphibious',
                tooltip = '<LOC spawn_filter_category_amph_tip>Toggle Amphibious units',
                key = 'amph',
                sortFunc = Logic.IsAmphibious
            },
            {
                display = '<LOC spawn_filter_category_structure>Base',
                tooltip = '<LOC spawn_filter_category_structure_tip>Toggle base structures',
                key = 'base',
                sortFunc = Logic.IsStructure
            },
        }
    else
        filter.display = '<LOC spawn_filter_type>Type'
        filter.choices = {
            {
                display = '<LOC spawn_filter_move_land>Land',
                tooltip = '<LOC spawn_filter_move_land_tip>Toggleunits that move only on land or seabed',
                key = 'land',
                sortFunc = Logic.IsMotionLand
            },
            {
                display = '<LOC spawn_filter_move_air>Air',
                tooltip = '<LOC spawn_filter_move_air_tip>Toggle units that move only in air',
                key = 'air',
                sortFunc = Logic.IsMotionAir,
            },
            {
                display = '<LOC spawn_filter_move_water>Water',
                tooltip = '<LOC spawn_filter_move_water_tip>Toggle units that move only in water',
                key = 'water',
                sortFunc = Logic.IsMotionWater,
            },
            {
                display = '<LOC spawn_filter_move_hover>Hover',
                tooltip = '<LOC spawn_filter_move_hover_tip>Toggle units that hover on land or water',
                key = 'hover',
                sortFunc = Logic.IsMotionHover
            },
            {
                display = '<LOC spawn_filter_move_stationary>Stationary',
                tooltip = '<LOC spawn_filter_move_stationary_tip>Toggle units that do not move',
                key = 'stationary',
                sortFunc = Logic.IsMotionNone,
            },
        }
    end

    for i, mod in __active_mods do
        if mod.showresearch then
            table.insert(filter.choices, {
                display = '<LOC spawn_filter_rnd>Research',
                key = 'rnd',
                sortFunc = function(unitID)
                    return __blueprints[unitID].ScriptClass == 'ResearchItem'
                end,
            })
            break
        end
    end
    return filter
end

function GetUnitTechFilter()
    local filter = { key = 'tech' }
    filter.display = '<LOC spawn_filter_tech>Tech Level'
    filter.choices = {
        {
            display = '<LOC spawn_filter_t0>No Tech',
            tooltip = '<LOC spawn_filter_t0_tip>Toggle units no Tech Level',
            key = 'civ',
            sortFunc = Logic.IsTech0,
        },
        {
            display = '<LOC CONSTRUCT_0000>T1',
            tooltip = '<LOC spawn_filter_t1_tip>Toggle T1 units',
            key = 't1',
            sortFunc = Logic.IsTech1,
        },
        {
            display = '<LOC CONSTRUCT_0001>T2',
            tooltip = '<LOC spawn_filter_t2_tip>Toggle T2 units',
            key = 't2',
            sortFunc = Logic.IsTech2,
        },
        {
            display = '<LOC CONSTRUCT_0002>T3',
            tooltip = '<LOC spawn_filter_t3_tip>Toggle T3 units',
            key = 't3',
            sortFunc = Logic.IsTech3,
        },
        {
            display = '<LOC CONSTRUCT_0003>Exp.',
            tooltip = '<LOC spawn_filter_t4_tip>Toggle T4 units',
            key = 't4',
            sortFunc = Logic.IsTech4,
        },
    }
    return filter
end

function SearchInUnit(id, text)
    local bp = __blueprints[id]
    local desc = string.lower(LOC(bp.Description or ''))
    local name = string.lower(LOC(bp.General.UnitName or ''))

    text = string.lower(text)
    return string.find(id, text)
        or string.find(desc, text)
        or string.find(name, text)
end

function SearchInProp(id, text)
    local bp = __blueprints[id]
    return (id or ''):find(text)
        or ((bp.Interface.HelpText or ''):lower()):find(text)
        or ((bp.ScriptClass or ''):lower()):find(text)
end

function SearchInputFilter()
    return {
        display = '<LOC spawn_filter_search>Search',
        key = 'custominput',
        sortFunc = function(input, text)
            if DialogMode == 'units' then
                return SearchInUnit(input, text)
            elseif DialogMode == 'props' then
                return SearchInProp(input, text)
            elseif DialogMode == 'templates' then
                if string.find(input.name, text) then return true end
                local td = input.templateData
                for i = 3, table.getn(td) do
                    if SearchInUnit(td[i][1], text) then return true end
                end
            end
        end,
    }
end

function GetPropFolderFilters()
    local list, folders = {}, {}

    for id, bp in __blueprints do
        if 'prop.bp' == string.sub(id, -7) then
            local folder = string.sub(id,string.find(id,'%/[^%/]+%/[^%/]+%/'))
            if not folders[folder] then
                folders[folder] = true
            end
        end
    end

    for folder in folders do
        specialFilterControls[folder] = folder
        table.insert(list, {
            display = string.sub(string.gsub(folder, '%b//', ''),1,-2),
            key = folder,
            sortFunc = function(ID, folder) 
                return folder == string.sub(ID, 1, string.len(folder)) 
            end
        })
    end

    return list
end

function GetPropsTypeFilters()
    local list, propTypes = {}, {}

    for id, bp in __blueprints do
        if 'prop.bp' == string.sub(id, -7) then
            local propType = Logic.GetPropType(id)
            propTypes[propType] = true
        end
    end

    for propType in propTypes do
        specialFilterControls[propType] = propType
        table.insert(list, {
            display = propType, tooltip = 'Toggle ' .. propType .. ' props',
            key = propType,
            sortFunc = function(id, propType)
                return propType == Logic.GetPropType(id)
            end
        })
    end

    return list
end

GetNameFilters = {
    units = function()
        local filters = {
            SearchInputFilter(),
            GetUnitFactionFilter(),
            GetUnitTypeFilter(),
            GetUnitTechFilter(),
        }
        if getOptions().spawn_menu_filter_build_menu ~= false then
            table.insert(filters, {
                display = '<LOC spawn_filter_build_menu>Build Menu',
                key = 'sort',
                choices = {
                    {
                        key = 'const',
                        display = '<LOC spawn_filter_build_const>Construction',
                        tooltip = '<LOC spawn_filter_build_const_tip>Toggle construction units',
                        sortFunc = Logic.IsConstruction,
                    },
                    {
                        key = 'eco',
                        display = '<LOC spawn_filter_build_eco>Economy',
                        tooltip = '<LOC spawn_filter_build_eco>_tipToggle Economy units',
                        sortFunc = Logic.IsEconomy,
                    },
                    {
                        key = 'defence',
                        display = '<LOC spawn_filter_build_defence>Defense',
                        tooltip = '<LOC spawn_filter_build_defence_tip>Toggle Defense units',
                        sortFunc = Logic.IsDefense,
                    },
                    {
                        key = 'strat',
                        display = '<LOC spawn_filter_build_strat>Strategic',
                        tooltip = '<LOC spawn_filter_build_strat_tip>Toggle Strategic units',
                        sortFunc = Logic.IsStrategic,
                    },
                    {
                        key = 'intel',
                        display = '<LOC spawn_filter_build_intel>Intel',
                        tooltip = '<LOC spawn_filter_build_intel_tip>Toggle Intel units',
                        sortFunc = Logic.IsIntel,
                    },
                },
            })
        end

        if getOptions().spawn_menu_filter_visibility ~= false then
            table.insert(filters,
                {
                    display = '<LOC spawn_filter_vis>Visibility',
                    key = 'spawnable',
                    choices = {
                        {
                            key = 'spawnable',
                            display = '<LOC spawn_filter_vis_spawnable>Spawnable',
                            tooltip = '<LOC spawn_filter_vis_spawnable_tip>Toggle spawnable units',
                            sortFunc = Logic.IsSpawnable,
                        },
                        {
                            key = 'unspawnable',
                            display = '<LOC spawn_filter_vis_dummy>Dummy',
                            tooltip = '<LOC spawn_filter_vis_dummy_tip>Toggle dummy units',
                            sortFunc = Logic.IsDummy,
                        },
                        {
                            key = 'civilian',
                            display = '<LOC spawn_filter_vis_civilian>civilian',
                            tooltip = '<LOC spawn_filter_vis_civilian_tip>Toggle civilian units',
                            sortFunc = Logic.IsCivilian,
                        },
                        {
                            key = 'playable',
                            display = '<LOC spawn_filter_vis_playable>Playable',
                            tooltip = '<LOC spawn_filter_vis_playable_tip>Toggle units playable in the game',
                            sortFunc = Logic.IsUnitPlayable,
                        },
                        {
                            key = 'testing',
                            display = '<LOC spawn_filter_vis_playable>Testing',
                            tooltip = '<LOC spawn_filter_vis_playable_tip>Toggle units for testing: ACU, SCU, Paragon',
                            sortFunc = Logic.IsUnitTesting,
                        }
                    }
                }
            )
        end

        if getOptions().spawn_menu_filter_source ~= false then
            table.insert(filters,
            {
                display = '<LOC spawn_filter_source>Source',
                key = 'mod',
                choices = SourceListTabs(),
            })
        end
        return filters
    end,
    props = function()
        return {
            SearchInputFilter(),
            {
                display = 'Type',
                key = 'propType',
                choices = GetPropsTypeFilters(),
            },
            {
                display = 'Folder',
                key = 'sourcefolder',
                choices = GetPropFolderFilters(),
            },
        }
    end,
    templates = function()
        return {
            SearchInputFilter(),
            GetUnitFactionFilter(function(template, cat)
                local td = template.templateData
                for i = 3, table.getn(td) do
                    if not Logic.HasCategory(td[i][1], cat) then return --[[true]] end
                end
                return true
            end),
            {
                display = '<LOC spawn_filter_layer>Build layer',
                key = 'layer',
                choices = {
                    {
                        key = 'bland',
                        display = '<LOC spawn_filter_layer_land>Land',
                        tooltip = '<LOC spawn_filter_layer_land_tip>Toggle Land templates',
                        sortFunc = function(template)
                            local td = template.templateData
                            for i = 3, table.getn(td) do
                                local id = td[i][1]
                                if Logic.GetLayerGroup(id) == 'sea' then
                                    return
                                end
                            end
                            return true
                        end,
                    },
                    {
                        key = 'bsea',
                        display = '<LOC spawn_filter_layer_naval>Naval',
                        tooltip = '<LOC spawn_filter_layer_naval_tip>Toggle Naval templates',
                        sortFunc = function(template)
                            local td = template.templateData
                            for i = 3, table.getn(td) do
                                local id = td[i][1]
                                if Logic.GetLayerGroup(id) == 'land' then
                                    return
                                end
                            end
                            return true
                        end,
                    },
                    {
                        key = 'bboth',
                        display = '<LOC spawn_filter_layer_both>Both',
                        tooltip = '<LOC spawn_filter_layer_both_tip>Toggle land and sea templates',
                        sortFunc = function(template)
                            local td = template.templateData
                            for i = 3, table.getn(td) do
                                local id = td[i][1]
                                if Logic.GetLayerGroup(id) == 'land' or Logic.GetLayerGroup(id) == 'sea' then
                                    return
                                end
                            end
                            return true
                        end,
                    }
                }
            }
        }
    end,
}

function SetUnitFactionIcon(id, bitmap, background)
    local faction = Logic.GetUnitFactionInfo(id)
    if bitmap and faction.icon and faction.color then
        bitmap:SetTexture(faction.icon)
        background:SetSolidColor(faction.color)
        background:SetAlpha(1, true)
    else
        background:SetAlpha(0, true)
    end
end

function CreateNameFilter(data)
    local group = Group(windowGroup)
    group.Width:Set(dialog.Width)
    if data.choices and data.choices[1] and table.getn(data.choices) > FilterColumnCount then
        LayoutHelpers.SetHeight(group, 30 + math.floor((table.getn(data.choices)-1)/FilterColumnCount) * 25)
    else
        LayoutHelpers.SetHeight(group, 30)
    end

    group.check = UIUtil.CreateCheckboxStd(group, '/dialogs/check-box_btn/radio')
    LayoutHelpers.AtLeftIn(group.check, group)
    if data.choices and data.choices[1] and table.getn(data.choices) > FilterColumnCount then
        LayoutHelpers.AtTopIn(group.check, group, 2)
    else
        LayoutHelpers.AtVerticalCenterIn(group.check, group)
    end

    group.check.key = data.key
    if filterSet[data.key] == nil then
        filterSet[data.key] = {value = data.key == 'spawnable', choices = {}}
    end
    if activeFilters[data.key] == nil then
        activeFilters[data.key] = {}
    end

    group.label = UIUtil.CreateText(group, data.display, 14, UIUtil.bodyFont)
    LayoutHelpers.RightOf(group.label, group.check)
    if data.choices and data.choices[1] and table.getn(data.choices) > FilterColumnCount then
        LayoutHelpers.AtTopIn(group.label, group, 7)
    else
        LayoutHelpers.AtVerticalCenterIn(group.label, group)
    end

    if data.choices then
        group.items = {}
        for i, v in data.choices do
            local index = i
            group.items[index] = UIUtil.CreateCheckboxStd(group, '/dialogs/toggle_btn/toggle')

            if index == 1 then
                LayoutHelpers.AtLeftTopIn(group.items[index], group, 95)
            elseif index < FilterColumnCount+1 then
                LayoutHelpers.RightOf(group.items[index], group.items[index-1])
            else
                LayoutHelpers.Below(group.items[index], group.items[index-FilterColumnCount])
            end
            if index < FilterColumnCount+1 then
                LayoutHelpers.AtTopIn(group.items[index], group)
            end

            group.items[index].label = UIUtil.CreateText(group.items[index], v.display, 10, UIUtil.bodyFont)
            LayoutHelpers.AtCenterIn(group.items[index].label, group.items[index])
            group.items[index].label:DisableHitTest()

            group.items[index].sortFunc = v.sortFunc
            group.items[index].filterKey = v.key
            group.items[index].key = data.key
            group.items[index].OnCheck = function(self, checked)
                filterSet[self.key].choices[self.filterKey] = checked
                if checked then
                    if not group.check:IsChecked() then
                        group.check:SetCheck(true)
                    end
                    activeFilters[self.key][self.filterKey] = self.sortFunc
                elseif activeFilters[self.key][self.filterKey] then
                    local otherChecked
                    for _, control in group.items do
                        if control ~= self then
                            if control:IsChecked() then
                                otherChecked = true
                                break
                            end
                        end
                    end
                    if not otherChecked then
                        group.check:SetCheck(false)
                    end
                    activeFilters[self.key][self.filterKey] = nil
                end
                RefreshList()
            end
            if filterSet[data.key].choices[v.key] == nil then
                filterSet[data.key].choices[v.key] = data.key == 'spawnable' and v.key == 'spawnable'
            end
            group.items[index]:SetCheck(filterSet[data.key].choices[v.key])
            if activeFilters[data.key] == nil then activeFilters[data.key] = {} end

            group.items[index].label:SetColor(UIUtil.fontColor)
            if v.tooltip then
                Tooltip.AddControlTooltip(group.items[index], { text = ' '.. LOC(v.tooltip) .. ' ' })
            end
        end
    else -- search box filter
        group.edit = Edit(group)
        group.edit:AbandonFocus()
        group.edit:SetForegroundColor(UIUtil.fontColor)
        group.edit:SetBackgroundColor('ff333333')
        group.edit:SetHighlightForegroundColor(UIUtil.highlightColor)
        group.edit:SetHighlightBackgroundColor("880085EF")
        group.edit.Width:Set(windowGroup.Width() - FilterHeaderWidth - (20 * UIScale) )
        LayoutHelpers.SetHeight(group.edit, 20)
        group.edit:SetText(filterSet[data.key].editText or searchText)
        group.edit:SetFont(UIUtil.bodyFont, 15)
        group.edit:SetMaxChars(20)
        LayoutHelpers.AtLeftIn(group.edit, group, 95)
        LayoutHelpers.AtVerticalCenterIn(group.edit, group)
        group.edit.filterKey = data.key
        group.edit.key = data.key
        group.edit.sortFunc = data.sortFunc

        group.hint = UIUtil.CreateText(group.edit, '', 12, UIUtil.bodyFont)
        group.hint:SetColor('FF7C7C7C')
        LayoutHelpers.AtCenterIn(group.hint, group.edit)
        group.hint:DisableHitTest()

        if DialogMode == 'units' then
            group.hint:SetText(string.upper(LOC("<LOC spawn_search_hint_units>type unit ID or name")))
        elseif DialogMode == 'templates' then
            group.hint:SetText(string.upper(LOC("<LOC spawn_search_hint_templates>type name or type of templates")))
        elseif DialogMode == 'props' then
            group.hint:SetText(string.upper(LOC("<LOC spawn_search_hint_props>type name of props")))
        end

        group.edit.OnTextChanged = function(self, new, old)
            -- initialize search box to previus search term when it was not intialized to prevent keymapping messing with it
            if not group.edit.isInitialized then
                group.edit.isInitialized = true
                group.edit:SetText(new)
            end

            searchText = new
            filterSet[self.key].editText = new

            if new == '' then
                group.hint:SetAlpha(1, false)
                activeFilters[self.key][self.filterKey] = nil
                if group.check:IsChecked() then
                    group.check:SetCheck(false)
                end
            else
                group.hint:SetAlpha(0, false)
                activeFilters[self.key][self.filterKey] = self.sortFunc
                if not group.check:IsChecked() then
                    group.check:SetCheck(true)
                end
            end

            
            RefreshList()
        end

        dialog.searchBox = group.edit
        Tooltip.AddControlTooltip(dialog.searchBox._fg, { text = '<LOC spawn_filter_search>Search units by name, category, or weapon name'})

        specialFilterControls[data.key] = group.edit
    end

    group.check.OnCheck = function(self, checked)
        activeFilterTypes[self.key] = checked
        filterSet[data.key].value = checked
        if group.items then
            for i, v in group.items do
                if not checked then
                    v:SetCheck(false, true)
                end
            end
        end
        RefreshList()
    end
    group.check:SetCheck(filterSet[data.key].value)

    return group
end

function CreateWindowContentGroup(parent)
    local windowGroup = Group(parent:GetClientGroup())
    windowGroup.Bottom:Set(function() return parent.Bottom()-WindowBorderThickness * UIScale end)
    windowGroup.Right:Set(function() return parent.Right()-WindowBorderThickness * UIScale end)
    windowGroup.Left:Set(function() return parent.Left()+WindowBorderThickness * UIScale end)
    windowGroup.Top:Set(function() return parent.Top()+WindowHeaderThickness * UIScale end)
    return windowGroup
end

function CreateDialog()
    if dialog.OnClose then
        dialog:OnClose()
        return
    end

    -- Configurable values
    local TeamGridCellMinWidth = getOptions().spawn_menu_team_column_min_width or 145
    local DefaultHeight = 450
    local DefaultWidth = FilterHeaderWidth + FilterWidth * 5
    local MinWidth = FilterHeaderWidth + FilterWidth * 2

    local DefaultWindowLocation = {
        Top = 50,
        Left = 50,
        Right = 50 + DefaultWidth + WindowBorderThickness + WindowBorderThickness,
        Bottom = 50 + DefaultHeight + WindowHeaderThickness
    }
    dialog = import('/lua/maui/window.lua').Window(
        GetFrame(0), --Parent
        'Debug Spawn and Army Focus', --title
        nil, -- icon --[==["/textures/ui/common/lobby/uef_ico.dds"]==]
        nil, -- pin button
        true, -- config button
        nil, --locked size
        nil, --lock position
        'spawn_window', -- pref ID
        DefaultWindowLocation,
        nil
    )
    dialog:SetWindowAlpha((options.spawn_menu_alpha or 80)/100)
    dialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    dialog:SetMinimumResize(MinWidth+WindowBorderThickness+WindowBorderThickness, DefaultHeight+WindowHeaderThickness+WindowBorderThickness)
    dialog.isPopulated = false -- tracking status of dialog populated by UI elements

    dialog.OnClose = function(self)
        dialog:Destroy()
        dialog = nil
        windowGroup:Destroy()
        windowGroup = nil
        if EscThread then KillThread(EscThread) end
    end

    dialog.OnResizeSet = function(control)
        RefreshUI()
    end

    dialog.OnConfigClick = function(control)
        CreateDebugConfig()
    end

    windowGroup = CreateWindowContentGroup(dialog)

    FilterColumnCount = math.floor((windowGroup.Width()-FilterHeaderWidth)/FilterWidth)

    UpdateTeamGridCounts(math.floor((windowGroup.Width())/TeamGridCellMinWidth))

    EscThread = ForkThread(function()
        while dialog or debugConfig do
            if IsKeyDown('ESCAPE') then
                if debugConfig then
                    debugConfig:OnClose()
                    while IsKeyDown('ESCAPE') do
                        --Wait for it to be released so we don't instantly close both
                        WaitSeconds(0.05)
                    end
                else
                    dialog:OnClose()
                    break
                end
            end
            WaitSeconds(0.05)
        end
    end)

    local function numImputSettings(element, label, data)
        element.StartVal = data.default
        element.CheckFun = data.check
        element:SetForegroundColor(UIUtil.fontColor)
        element:SetBackgroundColor('ff333333')
        element:SetHighlightForegroundColor(UIUtil.highlightColor)
        element:SetHighlightBackgroundColor("880085EF")
        LayoutHelpers.SetWidth(element, 30)
        LayoutHelpers.SetHeight(element, 15)
        element:SetFont(UIUtil.bodyFont, 12)
        element:SetMaxChars(4)
        element:SetText(data.default)
        LayoutHelpers.RightOf(element, label, 5)

        local function validate(self, val)
            local start = self.StartVal
            val = tonumber(val or self:GetText()) --tonumber filters out anything like '1-1'
            return val and (self.CheckFun and self.CheckFun(val, start) or val) or self.StartVal
        end

        local function setTextValid(self, text)
            local valid = validate(self, text)
            self:SetText(valid)
            return valid
        end

        element.OnCharPressed = function(self, c) --"active low"
            return not ((c >= 48) and (c <= 57) or c == 45) -- 0-9, -
        end

        element.OnNonTextKeyPressed = function(self, keycode, modifiers)
            local num = tonumber(self:GetText())--tonumber filters out anything like '1-1'
            if num and keycode == 38 then
                self:SetText(num+1)
            elseif num and keycode == 40 then
                self:SetText(num-1)
            end
        end

        element.OnEnterPressed = setTextValid
        element.OnKeyboardFocusChange = setTextValid

        element.GetValue = function(self)
            return tonumber(self:GetText())
        end

        return element
    end

    local NumberInputFields = {
        units = {
            -- creating input fields for count, vet, and rotation
            {label='Count', name = 'Count',     default=1,   check=math.max},
            {label='Vet',   name = 'Veterancy', default=0,   check=math.max, max=5},
            {label='Yaw',   name = 'Rotation',  default=360, check=math.mod},
        },
        props = {
            {label='Count', name = 'Count',    default=1,   check=math.max},
            {label='Yaw',   name = 'Rotation', default=360, check=math.mod},
            {label='Rand',  name = 'Scatter',  default=0,   check=math.max},
        },
    }

    local footerGroup = Group(windowGroup)
    footerGroup.Width:Set(windowGroup.Width)
    LayoutHelpers.AtBottomIn(footerGroup, windowGroup)
    LayoutHelpers.SetWidth(footerGroup, windowGroup.Width)
    LayoutHelpers.AtLeftIn(footerGroup, windowGroup)
    footerGroup.Top:Set(footerGroup.Bottom)

    local function SetFooterHeighest(obj)
        if footerGroup.Top() > obj.Top() then
            footerGroup.Top:Set(obj.Top)
        end
    end

    if NumberInputFields[DialogMode] then
        for i, inputdata in NumberInputFields[DialogMode] do
            local textlabel = UIUtil.CreateText(footerGroup, inputdata.name..':', 12, UIUtil.bodyFont)
            local inputfield
            if options.spawn_menu_footer_text_input then
                inputfield = numImputSettings(Edit(footerGroup), textlabel, inputdata)
                if i == 1 then
                    LayoutHelpers.AtBottomIn(textlabel, footerGroup, 10)
                    LayoutHelpers.AtLeftIn(textlabel, footerGroup, 5)
                else
                    local previousInput = footerGroup['input'..NumberInputFields[DialogMode][i-1].label]
                    LayoutHelpers.RightOf(textlabel, previousInput, 25)
                end
            else--if inputdata.type == 'slider' then
                inputfield = Group(footerGroup)
                LayoutHelpers.SetHeight(inputfield, 30)
                local slider = IntegerSlider(inputfield, false,
                    inputdata.default==1 and 1 or 0, math.max(inputdata.max or 10, inputdata.default), inputdata.default==360 and 15 or 1,
                    UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
                    UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
                    UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
                    '/textures/ui/common/dialogs/spawn_menu/slider-back_bmp.dds'
                )

                slider._currentValue:Set(inputdata.default)
                local value = UIUtil.CreateText(inputfield, slider:GetValue(), 12, "Arial")
                LayoutHelpers.RightOf(inputfield, textlabel)
                LayoutHelpers.Below(slider, textlabel, 5)
                LayoutHelpers.RightOf(value, textlabel, 10)
                LayoutHelpers.SetWidth(inputfield, slider.Width()+30)
                slider.OnValueChanged = function(self, newValue)
                    value:SetText(newValue)
                end
                inputfield.GetValue = function() return slider:GetValue() end

                if i == 1 then
                    LayoutHelpers.AtBottomIn(textlabel, footerGroup, 30)
                    LayoutHelpers.AtLeftIn(textlabel, footerGroup, 5)
                    LayoutHelpers.AtLeftIn(inputfield, footerGroup, 5)
                else
                    local previousInput = footerGroup['input'..NumberInputFields[DialogMode][i-1].label]
                    LayoutHelpers.RightOf(textlabel, previousInput, 5)
                    LayoutHelpers.RightOf(inputfield, previousInput, 5)
                end
            end

            SetFooterHeighest(textlabel)
            footerGroup['input'..inputdata.label] = inputfield
        end
    end

    if DialogMode == 'templates' then
        local createBtn = UIUtil.CreateButtonStd(footerGroup, '/widgets/small', "Create template", 12)
        LayoutHelpers.AtBottomIn(createBtn, footerGroup)
        LayoutHelpers.AtRightIn(createBtn, footerGroup, 5)
        createBtn.OnClick = function(button)
            import("/lua/ui/game/build_templates.lua").CreateBuildTemplate()
            CreateDialog()
            CreateDialog()
        end
        SetFooterHeighest(createBtn)
    end

    local function SendToCommandMode(id, dialogData)
        if not id then return end

        -- Reset selections if it's already running
        -- Prevents issues with selection storage and chain-selecting new orders.
        import("/lua/ui/game/commandmode.lua").EndCommandMode(true)

        -- store selection so that units do not go of and try to build the unit we're
        -- cheating in, is reset in EndCommandMode of '/lua/ui/game/commandmode.lua'
        local selection = GetSelectedUnits()
        SelectUnits(nil);

        local commandModeData  = {
            cheat = true,
            name = id,
            army = currentArmy,
            -- using user provided count of units or defaulting to creating 1 unit
            count = dialogData.inputCount and dialogData.inputCount:GetValue() or 1,
            vet = dialogData.inputVet and dialogData.inputVet:GetValue() or 0,
            yaw = (dialogData.inputYaw and dialogData.inputYaw:GetValue() or 0) / 57.295779513,
            rand = dialogData.inputRand and dialogData.inputRand:GetValue() or 0,
            CreateTarmac = options.spawn_menu_tarmacs_enabled,
            MeshOnly = options.spawn_menu_mesh_only,
            ShowRaisedPlatforms = options.spawn_menu_show_raised_platforms,
            UnitIconCameraMode = options.spawn_menu_unit_icon_camera,

            selection = selection,
        }

        if DialogMode == 'templates' then
            commandModeData.name = id.templateData[3][1]
            ClearBuildTemplates()
        end

        if DialogMode == 'props' then
            commandModeData.name = DummyUnitID
            commandModeData.prop = id
            commandModeData.yaw = dialogData.inputYaw and dialogData.inputYaw:GetValue() or 0
        end

        local function HasBadMesh(id) return __blueprints[__blueprints[id].Display.MeshBlueprint].LODs[1].MeshName == '' end

        local meshlessUnit = DialogMode == 'units' and HasBadMesh(id)

        if DialogMode == 'units' and (meshlessUnit or options.spawn_menu_force_dummy_spawn) then
            if options.spawn_menu_mesh_only and meshlessUnit then
                return _ALERT(id, "has no mesh. Spawn mode set to meshes only. Aborting.")
            end
            if meshlessUnit then
                _ALERT(id, "has no mesh. Replacing mesh with dummy so Command Mode doesn't hard crash the game.")
            end

            --The SpawnDummyMesh could be bad if it's an aircraft, so lets just check just in case. If DummyUnitID is bad we're fucked.
            commandModeData.name = HasBadMesh(__blueprints[id].SpawnDummyId) and DummyUnitID or __blueprints[id].SpawnDummyId
            commandModeData.unit = id
        end

        -- enables command mode for spawning units
        if commandModeData then
            import("/lua/ui/game/commandmode.lua").StartCommandMode( "build", commandModeData )
            if DialogMode == 'templates' then
                SetActiveBuildTemplate(id.templateData)
            end
        end
    end

    local function SetFilters(filterTable)
        for filterGroup, groupControls in filterGroups do
            local key = groupControls.check.key
            if filterTable[key] ~= nil then
                if groupControls.check:IsChecked() ~= filterTable[key].value then
                    groupControls.check:SetCheck(filterTable[key].value)
                end
                if groupControls.items then
                    for choiceIndex, choiceControl in groupControls.items do
                        if filterTable[key].choices[choiceControl.filterKey] ~= nil and choiceControl:IsChecked() ~= filterTable[key].choices[choiceControl.filterKey] then
                            choiceControl:SetCheck(filterTable[key].choices[choiceControl.filterKey])
                        end
                    end
                elseif filterTable[key].editText ~= nil then
                    groupControls.edit:SetText(filterTable[key].editText)
                end
            end
        end
        RefreshList()
    end

    local function CompressArmyName(name, width)
        if name:sub(1,4) == 'ARMY' then
            if width >= 55 then
                return name
            elseif width >= 12 then
                return name:sub(6)
            else
                return ''
            end
        elseif name == 'NEUTRAL_CIVILIAN' then
            if width >= 110 then
                return name
            elseif width >= 60 then
                return 'NEUTRAL'
            elseif width >= 10 then
                return 'N'
            else
                return ''
            end
        end
        return name
    end

    local function CompressNickname(name, width)
        local charLimitEst = width/(88/17)
        if charLimitEst < 1 then
            return ''
        end
        if name:len() <= charLimitEst then
            return name
        end
        name = name:gsub('%s*%b()', '')
        if name:len() <= charLimitEst then
            return name
        end
        return name:sub(1, math.floor(charLimitEst))
    end

    local function CreateArmySelectionSlot(parent, armyData)
        local group = Bitmap(parent)
        group.Height:Set(armyData.height or (30 * UIScale))
        group.Width:Set(armyData.width or function() return parent.Width() / TeamColumnCount end)
        group:SetSolidColor('FF000000')

        local iconBG = Bitmap(group)
        LayoutHelpers.SetWidth(iconBG, 30)
        LayoutHelpers.SetHeight(iconBG, 30)
        iconBG:SetSolidColor(armyData.color)
        LayoutHelpers.AtLeftTopIn(iconBG, group)
        iconBG:DisableHitTest()

        local icon = Bitmap(iconBG)
        local armyLabel = ''
        local armyName = ''
        if armyData.observer then
            icon:SetTexture(UIUtil.UIFile('/widgets/faction-icons-alpha_bmp/observer_ico.dds'))
            armyName = LOC('<LOC lobui_0295>Neutral')
            armyLabel = LOC('<LOC score_0003>Observer')
        elseif armyData.civilian then
            icon:SetSolidColor('aaaaaaaa')
            armyLabel = StringCapitalize(armyData.nickname)
            armyName = armyData.name == 'NEUTRAL_CIVILIAN' and LOC('<LOC lobui_0295>Neutral') or armyData.name
        else -- human or AI army
            armyLabel = CompressNickname(armyData.nickname, group.Width()-50)
            armyName = CompressArmyName(armyData.name, group.Width()-50)
            icon:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(armyData.faction)))
        end
        LayoutHelpers.FillParent(icon, iconBG)
        icon:DisableHitTest()

        -- Army identifier
        local name = UIUtil.CreateText(group, armyLabel, 12, UIUtil.bodyFont)
        LayoutHelpers.RightOf(name, icon, 2)
        LayoutHelpers.AtTopIn(name, group)
        name:SetColor('ffffffff')
        name:DisableHitTest()

        -- Army index or army type, e.g. civilian
        local army = UIUtil.CreateText(group, string.upper(armyName), 12, UIUtil.bodyFont)
        LayoutHelpers.Below(army, name)
        army:DisableHitTest()

        group.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if currentArmy == armyData.index then
                    self:SetSolidColor('cc00cc00')
                else
                    self:SetSolidColor('77007700')
                end
            elseif event.Type == 'MouseExit' then
                if currentArmy == armyData.index then
                    self:SetSolidColor('aa00aa00')
                else
                    self:SetSolidColor('FF000000')
                end
            elseif event.Type == 'ButtonPress' then
                currentArmy = armyData.index
                for i, v in parent.armySlots do
                    if i == armyData.index then
                        v:SetSolidColor('aa00aa00')
                    else
                        v:SetSolidColor('FF000000')
                    end
                end
            elseif event.Type == 'ButtonDClick' then
                ConExecute('SetFocusArmy '..tostring(currentArmy-1))
            end
        end
        if armyData.index == currentArmy then
            group:SetSolidColor('aa00aa00')
        end
        return group
    end

    local armiesGroup = Group(windowGroup)
    armiesGroup.Width:Set(function() return windowGroup.Width() end)
    LayoutHelpers.AtLeftTopIn(armiesGroup, windowGroup)

    local function IsColumnHead(teamI)
        if TeamColumnCount <= 1 then return false end
        for i = 1, TeamColumnCount-1 do
            if teamI == math.floor(NumArmies / TeamColumnCount * i) + 1 then
                return true
            end
        end
    end

    armiesGroup.armySlots = {}
    local lowestControl
    local WorkingColumnHead = 1

    for i, army in ArmiesAndObserver do
        army.index = army.observer and 0 or i -- army index or 0 for observer
        armiesGroup.armySlots[i] = CreateArmySelectionSlot(armiesGroup, army)
        if i == 1 then
            LayoutHelpers.AtLeftTopIn(armiesGroup.armySlots[i],armiesGroup)
            lowestControl = armiesGroup.armySlots[i]
        elseif IsColumnHead(i) then
            LayoutHelpers.RightOf(armiesGroup.armySlots[i],armiesGroup.armySlots[WorkingColumnHead])
            LayoutHelpers.AtTopIn(armiesGroup.armySlots[i],armiesGroup)
            WorkingColumnHead = i
        else
            LayoutHelpers.Below(armiesGroup.armySlots[i],armiesGroup.armySlots[i-1])
        end
        if armiesGroup.armySlots[i].Bottom() > lowestControl.Bottom() then
            lowestControl = armiesGroup.armySlots[i]
        end
    end

    armiesGroup.Height:Set(function() return lowestControl.Bottom() - armiesGroup.armySlots[1].Top() end)

    local filterPresetLabel = UIUtil.CreateText(windowGroup, 'Filter Preset', 14, UIUtil.bodyFont)
    LayoutHelpers.Below(filterPresetLabel, armiesGroup, 5)
    LayoutHelpers.AtLeftIn(filterPresetLabel, windowGroup, 5)
    filterPresetLabel.Width:Set(function() return FilterHeaderWidth end)

    local filterPresetCombo = import('/lua/ui/controls/combo.lua').Combo(windowGroup, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
    LayoutHelpers.Below(filterPresetCombo, armiesGroup, 10)
    LayoutHelpers.RightOf(filterPresetCombo, filterPresetLabel, 10)
    filterPresetCombo.Width:Set(function() return 2 * FilterWidth - (20 * UIScale) end)
    filterPresetCombo.OnClick = function(self, index, text, skipUpdate)
        SetFilters(self.keyMap[index])
    end

    local function RefreshFilterList(defName)
        filterPresetCombo:ClearItems()
        filterPresetCombo.itemArray = {}
        filterPresetCombo.keyMap = {}
        local CurrentFilterSets = GetPreference('CreateUnitFilters')
        if CurrentFilterSets and not table.empty(CurrentFilterSets) then
            local index = 1
            local default = 1
            for filterName, filter in sortedpairs(CurrentFilterSets) do
                if filterName == defName then
                    default = index
                end
                filterPresetCombo.itemArray[index] = ('%s'):format(filterName)
                filterPresetCombo.keyMap[index] = filter
                index = index + 1
            end
            filterPresetCombo:AddItems(filterPresetCombo.itemArray, default)
        end
    end

    local function CreatePressButton(text)
        local btn = UIUtil.CreateButton(windowGroup,
            '/dialogs/toggle_btn/toggle-d_btn_up.dds',
            '/dialogs/toggle_btn/toggle-d_btn_down.dds',
            '/dialogs/toggle_btn/toggle-d_btn_over.dds',
            '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
            text, 10)
        btn.label:SetFont(UIUtil.bodyFont, 10)
        return btn
    end

    local filterSaveButton = CreatePressButton 'Save'
    LayoutHelpers.Below(filterSaveButton, armiesGroup)
    LayoutHelpers.RightOf(filterSaveButton, filterPresetCombo, 10)
    LayoutHelpers.AtVerticalCenterIn(filterSaveButton, filterPresetCombo)
    Tooltip.AddControlTooltip(filterSaveButton, { text = ' Save current filter as preset ' })
    filterSaveButton.OnClick = function(self, modifiers)
        NameSet(function(name)
            local newFilterListing = {}
            if GetPreference('CreateUnitFilters') then
                newFilterListing = table.deepcopy(GetPreference('CreateUnitFilters'))
                newFilterListing[name] = filterSet
            else
                newFilterListing[name] = filterSet
            end
            SetPreference('CreateUnitFilters',newFilterListing)
            RefreshFilterList(name)
        end)
    end

    local filterDeleteButton = CreatePressButton 'Delete'
    LayoutHelpers.Below(filterDeleteButton, armiesGroup)
    LayoutHelpers.RightOf(filterDeleteButton, filterSaveButton)
    LayoutHelpers.AtVerticalCenterIn(filterDeleteButton, filterPresetCombo)
    Tooltip.AddControlTooltip(filterDeleteButton, { text = ' Delete current filter preset ' })
    filterDeleteButton.OnClick = function(self, modifiers)
        local index = filterPresetCombo:GetItem()
        if index >= 1 then
            local delName = filterPresetCombo.itemArray[index]
            local oldFilterSets = GetPreference('CreateUnitFilters')
            if oldFilterSets[delName] then
                oldFilterSets[delName] = nil
            end
            SetPreference('CreateUnitFilters',oldFilterSets)
            RefreshFilterList()
       end
    end

    local filterClearButton = CreatePressButton('Clear All')
    LayoutHelpers.Below(filterClearButton, armiesGroup)
    LayoutHelpers.RightOf(filterClearButton, filterDeleteButton)
    LayoutHelpers.AtVerticalCenterIn(filterClearButton, filterPresetCombo)
    Tooltip.AddControlTooltip(filterClearButton, { text = ' Clear all filters' })
    filterClearButton.OnClick = ClearFilters

    RefreshFilterList()

    filterGroups = {}
    local nameFilters = GetNameFilters[DialogMode]()
    for filtIndex, filter in nameFilters do
        local index = filtIndex
        filterGroups[index] = CreateNameFilter(filter)
        if filtIndex == 1 then
            LayoutHelpers.Below(filterGroups[index], filterPresetCombo)
            LayoutHelpers.AtLeftIn(filterGroups[index], windowGroup)
        -- elseif categories.UNSPAWNABLE and filter.key == 'spawnable' then
        --     LayoutHelpers.RightOf(filterGroups[index], filterGroups[1], -170)
        -- elseif categories.UNSPAWNABLE and nameFilters[filtIndex-1].key == 'spawnable' then
        --     LayoutHelpers.Below(filterGroups[index], filterGroups[1])
        else
            LayoutHelpers.Below(filterGroups[index], filterGroups[index-1])
        end
    end

    -- UNIT LIST
    windowGroup.unitList = Group(windowGroup)
    windowGroup.unitList.Height:Set(function() return footerGroup.Top() - filterGroups[table.getn(filterGroups)].Bottom() end)
    windowGroup.unitList.Width:Set(function() return windowGroup.Width() - 40 * UIScale end)
    LayoutHelpers.Below(windowGroup.unitList, filterGroups[table.getn(filterGroups)])
    LayoutHelpers.AtHorizontalCenterIn(windowGroup.unitList, windowGroup, -15)

    windowGroup.unitEntries = {}

    -- using verical scrollbar that matches theme or rest of window
    UIUtil.CreateLobbyVertScrollbar(windowGroup.unitList, 15, 1, 1)

    local LineColors = {
        Up = '00000000', Sel_Up = 'ff447744',
        Over = 'ff444444', Sel_Over = 'ff669966',
    }

    local mouseover = false
    local function SetUnitImage(bitmap, id, smol)
        local icon = __blueprints[id].Source and (__blueprints[id].Source):gsub('/units/.*', '')..'/textures/ui/common/icons/units/'..id..'_icon.dds'
        local lods = __blueprints[id].Display.Mesh.LODs
        local albedo = lods[smol and lods and table.getn(lods) or 1].AlbedoName

        bitmap:SetTexture(
            icon and DiskGetFileInfo(icon) and icon or
            albedo and DiskGetFileInfo(albedo) and albedo or
            UIUtil.UIFile('/game/unit_view_icons/unidentified.dds')
        )
    end
    local function SetBackgroundImage(bitmap, id)
        local textures = {
            land = '/textures/ui/common/icons/units/land_up.dds',
            sea = '/textures/ui/common/icons/units/sea_up.dds',
            amph = '/textures/ui/common/icons/units/amph_up.dds',
            air = '/textures/ui/common/icons/units/air_up.dds',
        }
        bitmap:SetTexture(textures[Logic.GetLayerGroup(id)])
        bitmap:SetAlpha(1, false)
    end
    local function GetUnitSkirtSizes(id)
        local bp = __blueprints[id]
        return bp.Physics.SkirtSizeX or bp.Footprint.SizeX or bp.SizeX or 1, bp.Physics.SkirtSizeZ or bp.Footprint.SizeZ or bp.SizeZ or 1
    end
    local function GetSkirtCentreOffset(id)
        local bp = __blueprints[id]
        local w, h = bp.Footprint.SizeX or bp.SizeX or 1, bp.Footprint.SizeZ or bp.SizeZ or 1
        local sW, sH = GetUnitSkirtSizes(id)
        local XSkirtO, ZSkirtO = bp.Physics.SkirtOffsetX, bp.Physics.SkirtOffsetZ
        return ((XSkirtO+((sW+XSkirtO)-w)))/2, ((ZSkirtO+((sH+ZSkirtO)-h)))/2
    end
    local function CreateTemplateElementMouseover(template, x, y)
        if mouseover then mouseover:Destroy() end
        mouseover = Bitmap(windowGroup)
        mouseover:SetSolidColor('dd115511')

        local td = template.templateData
        local gridscale = 10
        local tXgridSize = td[1]
        local tZgridSize = td[2]
        local tScale = 300/(math.max(tXgridSize, tZgridSize)*gridscale)
        local scale = gridscale * tScale

        local xOffset, zOffset = {0,0}, {0,0}

        for i = 3, table.getn(td) do
            local id = td[i][1]
            local w, h = GetUnitSkirtSizes(id)
            local posX, posZ = td[i][3], td[i][4]
            local cOffX, cOffZ = GetSkirtCentreOffset(id)
            xOffset[1] = math.min(xOffset[1], (posX-w/2)+cOffX)
            xOffset[2] = math.max(xOffset[2], (posX+w/2)+cOffX)
            zOffset[1] = math.min(zOffset[1], (posZ-h/2)+cOffZ)
            zOffset[2] = math.max(zOffset[2], (posZ+h/2)+cOffZ)
        end

        xOffset, zOffset = (xOffset[1]+xOffset[2])/2, (zOffset[1]+zOffset[2])/2

        for m = 1, 2 do
            for i = 3, math.min(1000, table.getn(td)) do
                local id = td[i][1]
                mouseover[i..'img'..m] = Bitmap(mouseover)
                local img = mouseover[i..'img'..m]
                local w, h = GetUnitSkirtSizes(id)
                local xCenOff, zCenOff = GetSkirtCentreOffset(id)

                img.Width:Set(m==1 and w*scale or math.min(w*scale, h*scale))
                img.Height:Set(m==1 and h*scale or math.min(w*scale, h*scale))

                LayoutHelpers.AtCenterIn(img, mouseover, (td[i][4]-zOffset+zCenOff)*scale, (td[i][3]-xOffset+xCenOff)*scale)
                if m == 1 then
                    SetBackgroundImage(img, id)
                else
                    SetUnitImage(img, id)
                end
                img:DisableHitTest()
            end
        end

        mouseover.Left:Set(x+20  * UIScale)
        mouseover.Top:Set(y+20 * UIScale)
        LayoutHelpers.SetDimensions(mouseover.img, 300, 300)
        mouseover.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    end
    local function CreateElementMouseover(unitData,x,y)
        if mouseover then mouseover:Destroy() end

        local faction = Logic.GetUnitFactionInfo(unitData)
        mouseover = Bitmap(windowGroup)
        mouseover:SetSolidColor('DD111111')
        
        mouseover.fill = Bitmap(mouseover)
        mouseover.fill:SetSolidColor(faction.color or 'DD232323')
        mouseover.fill:SetAlpha(0.15, false)

        local iconSize = 45
        mouseover.bg = Bitmap(mouseover.fill)
        LayoutHelpers.SetDimensions(mouseover.bg, iconSize, iconSize)
        LayoutHelpers.AtLeftTopIn(mouseover.bg, mouseover, 6, 2)
        LayoutHelpers.AtVerticalCenterIn(mouseover.bg, mouseover)

        mouseover.img = Bitmap(mouseover.bg)
        LayoutHelpers.SetDimensions(mouseover.img, iconSize, iconSize)
        LayoutHelpers.AtLeftTopIn(mouseover.img, mouseover, 6, 2)
        LayoutHelpers.AtVerticalCenterIn(mouseover.img, mouseover)

        SetUnitImage(mouseover.img, unitData)
        SetBackgroundImage(mouseover.bg, unitData)

        local bp = __blueprints[unitData]
        local info = ''
        if DialogMode == 'units' then
            info = StringTrim(Logic.GetUnitDescription(unitData))
        else
            info = bp.Interface and bp.Interface.HelpText
        end

        mouseover.name = UIUtil.CreateText(mouseover.fill, info, 14, UIUtil.bodyFont)
        mouseover.name:SetColor(faction.color or 'DDD8D8D8')
        mouseover.name:SetAlpha(0.85, false)
        LayoutHelpers.RightOf(mouseover.name, mouseover.img, 4)
        LayoutHelpers.AtTopIn(mouseover.name, mouseover, 8)

        mouseover.desc = UIUtil.CreateText(mouseover.fill, Logic.GetUnitIdentifier(unitData, false), 14, UIUtil.bodyFont)
        mouseover.desc:SetColor(faction.color or 'DDD8D8D8')
        mouseover.desc:SetAlpha(0.85, false)
        LayoutHelpers.RightOf(mouseover.desc, mouseover.img, 4)
        LayoutHelpers.Below(mouseover.desc, mouseover.name, 6)

        mouseover.Left:Set(x+20 * UIScale)
        mouseover.Top:Set(y+20 * UIScale)
        mouseover.Height:Set(function() return mouseover.img.Height() + 10 * UIScale end)
        mouseover.Width:Set(function() return mouseover.img.Width() + math.max(mouseover.name.Width(), mouseover.desc.Width()) + 15 * UIScale end)
        mouseover.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)

        LayoutHelpers.FillParent(mouseover.fill, mouseover)
    end
    local MouseOverElement = {
        units = CreateElementMouseover,
        props = CreateElementMouseover,
        templates = CreateTemplateElementMouseover,
    }
    local function MoveMouseover(x,y)
        if mouseover then
            mouseover.Left:Set(x+20 * UIScale)
            mouseover.Top:Set(y+20 * UIScale)
        end
    end
    local function DestroyMouseover()
        if mouseover then
            mouseover:Destroy()
            mouseover = false
        end
    end

    local function CreateUnitElements()
        if windowGroup.unitEntries then
            for i, v in windowGroup.unitEntries do
                if v.bg then v.bg:Destroy() end
            end
            windowGroup.unitEntries = {}
        end

        local function ClearContextMenus(self) -- if self is provided, it doesn't clear that one
            for _, otherBtn in windowGroup.unitEntries do
                if self ~= otherBtn and otherBtn.OptionMenu then
                    otherBtn.OptionMenu:Destroy()
                    otherBtn.OptionMenu = nil
                end
            end
        end

        local function CreateElement(index)
            local unitSelector = Bitmap(windowGroup.unitList)
            unitSelector.Left:Set(windowGroup.unitList.Left)
            unitSelector.Right:Set(windowGroup.unitList.Right)
            unitSelector.Height:Set(16 * UIScale)
            unitSelector.HandleEvent = function(self, event)
                if event.Type == 'MouseEnter' then
                    if MouseOverElement[DialogMode] then
                        MouseOverElement[DialogMode](self.unitID, event.MouseX, event.MouseY)
                    end
                    if ChosenCreation == self.unitID then
                        self:SetSolidColor(LineColors.Sel_Over)
                    else
                        self:SetSolidColor(LineColors.Over)
                    end
                elseif event.Type == 'MouseExit' then
                    DestroyMouseover()
                    if ChosenCreation == self.unitID then
                        self:SetSolidColor(LineColors.Sel_Up)
                    else
                        self:SetSolidColor(LineColors.Up)
                    end
                elseif event.Type == 'ButtonPress' and event.Modifiers.Left then
                    for i, v in windowGroup.unitEntries do
                        v:SetSolidColor(LineColors.Up)
                    end
                    self:SetSolidColor(LineColors.Sel_Over)
                    ChosenCreation = self.unitID
                    SendToCommandMode(self.unitID, footerGroup)
                    ClearContextMenus()
                elseif event.Type == 'ButtonPress' and event.Modifiers.Right and DialogMode == 'templates' then

                    if self.OptionMenu then
                        self.OptionMenu:Destroy()
                        self.OptionMenu = nil
                    else
                        self.Data = { template = self.unitID } -- So the default menu will work with this.
                        self.OptionMenu = CreateTemplateOptionsMenu(self)
                    end
                    ClearContextMenus(self)
                elseif event.Type == 'MouseMotion' then
                    MoveMouseover(event.MouseX,event.MouseY)
                end
            end

            unitSelector.id = UIUtil.CreateText(unitSelector, '', 12, 'Arial')
            LayoutHelpers.AtLeftTopIn(unitSelector.id, unitSelector, options.spawn_menu_show_icons and 25 or 5)
            unitSelector.desc = UIUtil.CreateText(unitSelector, '', 12, UIUtil.bodyFont)
            LayoutHelpers.AtLeftTopIn(unitSelector.desc, unitSelector, (DialogMode == 'templates' and 50 or 120) + (options.spawn_menu_show_icons and 36 or 18))
            if options.spawn_menu_show_icons then
                unitSelector.imageBG = Bitmap(unitSelector)
                unitSelector.imageBG.Height:Set(16 * UIScale)
                unitSelector.imageBG.Width:Set(16 * UIScale)
                LayoutHelpers.AtLeftTopIn(unitSelector.imageBG, unitSelector, 2)

                unitSelector.img = Bitmap(unitSelector.imageBG)
                unitSelector.img.Height:Set(16 * UIScale)
                unitSelector.img.Width:Set(16 * UIScale)
                LayoutHelpers.AtLeftTopIn(unitSelector.img, unitSelector, 2)
            end

            unitSelector.factionBG = Bitmap(unitSelector)
            unitSelector.factionBG.Height:Set(16 * UIScale)
            unitSelector.factionBG.Width:Set(16 * UIScale)
            unitSelector.factionBG:SetSolidColor('red')
            LayoutHelpers.LeftOf(unitSelector.factionBG, unitSelector.desc, 2)

            unitSelector.factionIcon = Bitmap(unitSelector.factionBG)
            unitSelector.factionIcon.Height:Set(16 * UIScale)
            unitSelector.factionIcon.Width:Set(16 * UIScale)
            LayoutHelpers.LeftOf(unitSelector.factionIcon, unitSelector.desc, 2)
            -- storing the unit selector for access in rest of UI
            windowGroup.unitEntries[index] = unitSelector
        end

        CreateElement(1)
        LayoutHelpers.AtTopIn(windowGroup.unitEntries[1], windowGroup.unitList)

        local index = 2
        while windowGroup.unitEntries[table.getsize(windowGroup.unitEntries)].Top() + (2 * windowGroup.unitEntries[1].Height()) < windowGroup.unitList.Bottom() do
            CreateElement(index)
            LayoutHelpers.Below(windowGroup.unitEntries[index], windowGroup.unitEntries[index-1])
            index = index + 1
        end
    end
    CreateUnitElements()

    local numLines = function() return table.getsize(windowGroup.unitEntries) end

    local function DataSize()
        return table.getn(UnitList)
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    windowGroup.unitList.GetScrollValues = function(self, axis)
        local size = DataSize()
        return 0, size, self.top, math.min(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    windowGroup.unitList.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    windowGroup.unitList.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    windowGroup.unitList.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines() , top), 0)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    windowGroup.unitList.IsScrollable = function(self, axis)
        return true
    end
    -- determines what controls should be visible or not
    windowGroup.unitList.CalcVisible = function(self)
        local function SetTextLine(line, data, lineID)
            line:Show()
            if ChosenCreation == data.id then
                line:SetSolidColor(LineColors.Sel_Up)
            else
                line:SetSolidColor(LineColors.Up)
            end
            line.unitID = data.id

            if DialogMode == 'templates' then
                local td = data.id.templateData
                local str = LOC(data.id.name)
                local structs = {}
                for i = 3, table.getn(td) do
                    structs[ td[i][1] ] = (structs[ td[i][1] ] or 0)+1
                end
                for id, no in structs do
                    str=str..' - '..id..' ×'..no
                end

                line.id:SetText(td[1]..'×'..td[2])
                line.desc:SetText(str)
                if options.spawn_menu_show_icons then
                    SetUnitImage(line.img, data.id.icon, true)
                end
                if line.factionBG then line.factionBG:SetAlpha(0, true) end
                if line.imageBG then line.imageBG:SetAlpha(0, false) end

            elseif DialogMode == 'units' then
                line.id:SetText(Logic.GetUnitIdentifier(data.id, true))
                line.desc:SetText(Logic.GetUnitDescription(data.id))
                if options.spawn_menu_show_icons then
                    SetUnitImage(line.img, data.id, true)
                    SetBackgroundImage(line.imageBG, data.id)
                end
                SetUnitFactionIcon(data.id, line.factionIcon, line.factionBG)
            elseif DialogMode == 'props' then
                line.id:SetText(Logic.GetPropIdentifier(data.id))
                line.desc:SetText(Logic.GetPropDescription(data.id))
                if options.spawn_menu_show_icons then
                    SetUnitImage(line.img, data.id, true)
                end
                if line.factionBG then line.factionBG:SetAlpha(0, true) end
                if line.imageBG then line.imageBG:SetAlpha(0, false) end
            end
        end
        for i, v in windowGroup.unitEntries do
            if UnitList[i + self.top] then
                SetTextLine(v, UnitList[i + self.top], i + self.top)
            else
                v:Hide()
            end
        end
    end

    windowGroup.unitList.HandleEvent = function(control, event)
        if event.Type == 'WheelRotation' then
            control:ScrollLines(nil, event.WheelRotation > 0 and -3 or 3)
        end
    end

    RefreshList()

    dialog.searchBox:AcquireFocus()
    dialog.isPopulated = true -- populated by all UI elements
end

function RefreshList()
    if not windowGroup.unitList then return end
    UnitList = {}
    local totalList = Logic.GetBlueprintsFor(DialogMode)
    for i, v in totalList do
        local allValid = true
        for filterType, filters in activeFilters do

            if activeFilterTypes[filterType] then
                local valid = false
                for filterIndex, filter in filters do
                    local specialText = ''
                    if specialFilterControls[filterIndex] then
                        if type(specialFilterControls[filterIndex]) == "string" then
                            specialText = specialFilterControls[filterIndex]
                        else
                            specialText = specialFilterControls[filterIndex]:GetText()
                        end
                    end
                    if filter(v, specialText) then
                        valid = true
                        break
                    end
                end
                allValid = valid and allValid
            end
        end
        if allValid then
            table.insert(UnitList, {id = v, name = LOC(__blueprints[v].General.UnitName) or '', desc = LOC(__blueprints[v].Description) or ''})
        end
    end
    windowGroup.unitList.top = 0
    windowGroup.unitList:CalcVisible()
end

function NameSet(callback)
    -- Dialog already showing? Don't show another one
    if nameDialog then return end

    nameDialog = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp.dds'), "Marker Name Dialog")
    LayoutHelpers.AtCenterIn(nameDialog, GetFrame(0))
    nameDialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)

    local label = UIUtil.CreateText(nameDialog, "Name your filter set:", 16, UIUtil.buttonFont)
    label.Left:Set(function() return nameDialog.Left() + 35 * UIScale end)
    label.Top:Set(function() return nameDialog.Top() + 30 * UIScale end)

    local cancelButton = UIUtil.CreateButtonStd(nameDialog, '/widgets02/small', "<LOC _CANCEL>", 12)
    cancelButton.Top:Set(function() return nameDialog.Top() + 112 * UIScale end)
    cancelButton.Left:Set(function() return nameDialog.Left() + (((nameDialog.Width() / 4) * 1) - (cancelButton.Width() / 2)) end)
    cancelButton.OnClick = function(self, modifiers)
        nameDialog:Destroy()
        nameDialog = nil
    end

    --TODO this should be in layout
    local nameEdit = Edit(nameDialog)
    LayoutHelpers.AtLeftTopIn(nameEdit, nameDialog, 35, 60)
    nameEdit.Width:Set(283 * UIScale)
    nameEdit.Height:Set(nameEdit:GetFontHeight())
    nameEdit:ShowBackground(false)
    nameEdit:AcquireFocus()
    UIUtil.SetupEditStd(nameEdit, UIUtil.fontColor, nil, nil, nil, UIUtil.bodyFont, 16, 30)

    local okButton = UIUtil.CreateButtonStd(nameDialog, '/widgets02/small', "<LOC _OK>", 12)
    okButton.Top:Set(function() return nameDialog.Top() + 112 * UIScale end)
    okButton.Left:Set(function() return nameDialog.Left() + (((nameDialog.Width() / 4) * 3) - (okButton.Width() / 2)) end)
    okButton.OnClick = function(self, modifiers)
        local newName = nameEdit:GetText()
        callback(newName)
        nameDialog:Destroy()
        nameDialog = nil
    end

    nameEdit.OnEnterPressed = function(self, text)
        okButton.OnClick()
    end
end

function CreateToggleButton(parent, text, flag, onClick)

    local check = UIUtil.CreateCheckboxStd(parent, '/dialogs/check-box_btn/radio')
    local label = UIUtil.CreateText(parent, text, 12, UIUtil.bodyFont)
    check:SetCheck(flag, true)
    LayoutHelpers.CenteredRightOf(label, check, 5)
    check.OnCheck = onClick

    return check
end

function SetOptionsConfigValue(key, val)
    if key then
        options[key] = val
        import('/lua/user/prefs.lua').SetToCurrentProfile('options', options)
    end
end

function CreateDebugConfig()
    if debugConfig then debugConfig:OnClose() end

    debugConfig = import('/lua/maui/window.lua').Window(
        GetFrame(0), --Parent
        'Debug Options', --title
        nil, -- icon --[==["/textures/ui/common/lobby/uef_ico.dds"]==]
        nil, -- pin button
        nil, -- config button
        true, --locked size
        false, --lock position
        'spawn_config_window', -- pref ID
        { Top = 50, Left = 50, Right = 350, Bottom = 100 }, --Default position
        nil
    )
    debugConfig:SetWindowAlpha((options.spawn_menu_alpha or 80)/100)
    debugConfig.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    debugConfig.Width:Set(300 * UIScale)

    debugConfig.OnClose = function(self)
        debugConfig:Destroy()
        debugConfig = false
    end

    local wrap = CreateWindowContentGroup(debugConfig)

    local configOptions = {
        {style = 'title',  name = 'Spawn menu mode:' },
        {style = 'toggle', name = 'Unit spawn',     prefid = 'spawn_menu_main_mode', check = function() return DialogMode == 'units' end,     activate = function() DialogMode = 'units' ClearFilters() return DialogMode end },
        {style = 'toggle', name = 'Template spawn', prefid = 'spawn_menu_main_mode', check = function() return DialogMode == 'templates' end, activate = function() DialogMode = 'templates' ClearFilters() return DialogMode end },
        {style = 'toggle', name = 'Prop spawn',     prefid = 'spawn_menu_main_mode', check = function() return DialogMode == 'props' end,     activate = function() DialogMode = 'props' ClearFilters() return DialogMode end },

        {style = 'title',        name = 'Unit spawn settings:' },
        {style = 'configtoggle', name = 'Spawn structure tarmacs',                    prefid = 'spawn_menu_tarmacs_enabled', },
        {style = 'configtoggle', name = 'Spawn mesh entites instead of units',        prefid = 'spawn_menu_mesh_only', },
        {style = 'toggle',       name = 'Clear spawned entity meshes', activate = function() SimCallback{Func = 'ClearSpawnedMeshes'} end },
        {style = 'configtoggle', name = 'Position camera for build icon on spawn',    prefid = 'spawn_menu_unit_icon_camera' },
        {style = 'configtoggle', name = 'Ignore terrain blocking (disables preview)', prefid = 'spawn_menu_force_dummy_spawn'},
        {style = 'configtoggle', name = 'Show raised platforms',                      prefid = 'spawn_menu_show_raised_platforms', },

        {style = 'title',        name = 'Unit spawn filter settings:' },
        {style = 'configtoggle', name = 'Include build-menu filters',     refresh = true, prefid = 'spawn_menu_filter_build_menu', check = function() return options.spawn_menu_filter_build_menu ~= false end },
        {style = 'configtoggle', name = 'Include visibility filters',     refresh = true, prefid = 'spawn_menu_filter_visibility', check = function() return options.spawn_menu_filter_visibility ~= false end },
        {style = 'configtoggle', name = 'Include source filters',         refresh = true, prefid = 'spawn_menu_filter_source', check = function() return options.spawn_menu_filter_source ~= false end },
        {style = 'configtoggle', name = 'Split core game source filter',  refresh = true, prefid = 'spawn_menu_split_sources', check = function() return options.spawn_menu_split_sources ~= false end },
        -- {style = 'configtoggle', name = 'Include no-tech filter',        refresh = true, prefid = 'spawn_menu_notech_filter', },
        --{style = 'configtoggle', name = 'Include ACU/Paragon filter',    refresh = true, prefid = 'spawn_menu_paragon_filter', },
        {style = 'toggle',       name = 'Filter Type by motion type',    refresh = true, prefid = 'spawn_menu_type_filter_mode', check = function() return options.spawn_menu_type_filter_mode == 'motion' end,   activate = function() return 'motion'   end },
        {style = 'toggle',       name = 'Filter Type by category',       refresh = true, prefid = 'spawn_menu_type_filter_mode', check = function() return options.spawn_menu_type_filter_mode == 'category' end, activate = function() return 'category' end },

        {style = 'title',        name = 'Display settings:'},
        {style = 'configtoggle', name = 'Show item icons',                    refresh = true, prefid = 'spawn_menu_show_icons' },
        {style = 'slider',       name = 'Army focus cell minimum width:',     refresh = true, prefid = 'spawn_menu_team_column_min_width', min = 30, max = 300, inc = 5, default = 145 },
        {style = 'slider',       name = 'Dialogue transparency:',             refresh = true, prefid = 'spawn_menu_alpha',                 min = 0,  max = 100, inc = 5, default = 80  },
        {style = 'configtoggle', name = 'Show text input instead of sliders', refresh = true, prefid = 'spawn_menu_footer_text_input' },
    }
    local sectFuncs = {
        title = function(data, parent)
            data.obj = UIUtil.CreateText(wrap, data.name, 14, "Arial Bold")
            if parent == wrap then
                LayoutHelpers.AtLeftTopIn(data.obj, parent, 5, 5)
            else
                LayoutHelpers.Below(data.obj, parent, 10)
                LayoutHelpers.AtLeftIn(data.obj, wrap, 5)
            end
            return data.obj
        end,
        toggle = function(data, parent)
            data.obj = CreateToggleButton(wrap, data.name, data.check and data.check(), function()
                SetOptionsConfigValue(data.prefid, data.activate())
                if data.refresh then
                    RefreshUI()
                end
                CreateDebugConfig()
            end)
            LayoutHelpers.Below(data.obj, parent, 5)
            LayoutHelpers.AtLeftIn(data.obj, wrap, 5)
            return data.obj
        end,
        configtoggle = function(data, parent)
            data.obj = CreateToggleButton(wrap, data.name, options[data.prefid], function()
                SetOptionsConfigValue(data.prefid, not options[data.prefid])
                if data.refresh then
                    RefreshUI()
                end
                CreateDebugConfig()
                return options[data.prefid]
            end)
            LayoutHelpers.Below(data.obj, parent, 5)
            LayoutHelpers.AtLeftIn(data.obj, wrap, 5)
            return data.obj
        end,
        slider = function(data, parent)
            data.obj = UIUtil.CreateText(wrap, data.name, 12, UIUtil.bodyFont)
            data.slider = IntegerSlider(wrap, false,
                data.min, data.max, data.inc,
                UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'),
                UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'),
                UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'),
                UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds'))
            data.slider._currentValue:Set(options[data.prefid] or data.default or data.min)
            data.value = UIUtil.CreateText(wrap, data.slider:GetValue(), 12, "Arial")
            LayoutHelpers.Below(data.obj, parent, 5)
            LayoutHelpers.AtLeftIn(data.obj, wrap, 36)
            LayoutHelpers.Below(data.slider, data.obj, 5)
            LayoutHelpers.AtHorizontalCenterIn(data.slider, wrap)
            LayoutHelpers.RightOf(data.value, data.slider)
            data.slider.OnValueChanged = function(self, newValue)
                data.value:SetText(newValue)--string.format('%3d', newValue))
            end
            data.slider.OnValueSet = function(self, newValue)
                SetOptionsConfigValue(data.prefid, newValue)
                if data.refresh then
                    RefreshUI()
                end
                CreateDebugConfig()
            end
            return data.slider
        end,
    }
    local previous = wrap
    for i, v in configOptions do
        previous = sectFuncs[v.style](v, previous)
    end

    debugConfig.Bottom:Set(function() return previous.Bottom()+20 end)
end

--[[
    NOTE: This CreateTemplateOptionsMenu copied text-for-text verbatim from lua\ui\game\construction.lua
    This is so that it uses the local RefreshUI from above, and not the global one.
]]
local Templates = import('/lua/ui/game/build_templates.lua')
local CreateSubMenu = import('/lua/ui/game/construction.lua').CreateSubMenu
local ProcessKeybinding = import('/lua/ui/game/construction.lua').ProcessKeybinding
local BuildMode = import('/lua/ui/game/buildmode.lua')

function CreateTemplateOptionsMenu(button)
    local group = Group(button)
    group.Depth:Set(button:GetRootFrame():GetTopmostDepth() + 1)
    local title = Edit(group)
    local items = {
        {label = '<LOC _Rename>Rename',
        action = function()
            title:AcquireFocus()
        end,},
        {label = '<LOC _Change_Icon>Change Icon',
        action = function()
            local contents = {}
            local controls = {}
            for _, entry in button.Data.template.templateData do
                if type(entry) != 'table' then continue end
                if not contents[entry[1]] then
                    contents[entry[1]] = true
                end
            end
            for iconType, _ in contents do
                local bmp = Bitmap(group, '/textures/ui/common/icons/units/'..iconType..'_icon.dds')
                bmp.Height:Set(30 * UIScale)
                bmp.Width:Set(30 * UIScale)
                bmp.ID = iconType
                table.insert(controls, bmp)
            end
            group.SubMenu = CreateSubMenu(group, controls, function(id)
                Templates.SetTemplateIcon(button.Data.template.templateID, id)
                RefreshUI()
            end)
        end,
        arrow = true},
        {label = '<LOC _Change_Keybinding>Change Keybinding',
        action = function()
            local text = UIUtil.CreateText(group, "<LOC CONSTRUCT_0008>Press a key to bind", 12, UIUtil.bodyFont)
            if not BuildMode.IsInBuildMode() then
                text:AcquireKeyboardFocus(false)
                text.HandleEvent = function(self, event)
                    if event.Type == 'KeyDown' then
                        ProcessKeybinding(event.KeyCode, button.Data.template.templateID)
                    end
                    return true
                end
                local oldTextOnDestroy = text.OnDestroy
                text.OnDestroy = function(self)
                    text:AbandonKeyboardFocus()
                    oldTextOnDestroy(self)
                end
            else
                capturingKeys = button.Data.template.templateID
            end
            warningtext = text
            group.SubMenu = CreateSubMenu(group, {text}, function(id)
                Templates.SetTemplateKey(button.Data.template.templateID, id)
                RefreshUI()
            end, false)
        end,},
        {label = '<LOC _Send_to>Send to',
        action = function()
            local armies = GetArmiesTable().armiesTable
            local entries = {}
            for i, armyData in armies do
                if i != GetFocusArmy() and armyData.human then
                    local entry = UIUtil.CreateText(group, armyData.nickname, 12, UIUtil.bodyFont)
                    entry.ID = i
                    table.insert(entries, entry)
                end
            end
            if table.getsize(entries) > 0 then
                group.SubMenu = CreateSubMenu(group, entries, function(id)
                    Templates.SendTemplate(button.Data.template.templateID, id)
                    RefreshUI()
                end)
            end
        end,
        disabledFunc = function()
            if table.getsize(GetSessionClients()) > 1 then
                return false
            else
                return true
            end
        end,
        arrow = true},
        {label = '<LOC _Delete>Delete',
        action = function()
            Templates.RemoveTemplate(button.Data.template.templateID)
            RefreshUI()
        end,},
    }
    local function CreateItem(data)
        local bg = Bitmap(group)
        bg:SetSolidColor('00000000')
        bg.label = UIUtil.CreateText(bg, LOC(data.label), 12, UIUtil.bodyFont)
        bg.label:DisableHitTest()
        LayoutHelpers.AtLeftTopIn(bg.label, bg, 2)
        bg.Height:Set(function() return bg.label.Height() + 2 end)
        bg.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                self:SetSolidColor('ff777777')
            elseif event.Type == 'MouseExit' then
                self:SetSolidColor('00000000')
            elseif event.Type == 'ButtonPress' then
                if group.SubMenu then
                    group.SubMenu:Destroy()
                    group.SubMenu = false
                end
                data.action()
            end
            return true
        end

        if data.disabledFunc and data.disabledFunc() then
            bg:Disable()
        end

        return bg
    end
    local totHeight = 0
    local maxWidth = 0
    title.Height:Set(function() return title:GetFontHeight() end)
    title.Width:Set(function() return title:GetStringAdvance(LOC(button.Data.template.name)) end)
    UIUtil.SetupEditStd(title, "ffffffff", nil, "ffaaffaa", UIUtil.highlightColor, UIUtil.bodyFont, 14, 200)
    title:SetDropShadow(true)
    title:ShowBackground(true)
    title:SetText(LOC(button.Data.template.name))
    LayoutHelpers.AtLeftTopIn(title, group)
    totHeight = totHeight + title.Height()
    maxWidth = math.max(maxWidth, title.Width())
    local itemControls = {}
    local prevControl = false
    for index, actionData in items do
        local i = index
        itemControls[i] = CreateItem(actionData)
        if prevControl then
            LayoutHelpers.Below(itemControls[i], prevControl)
        else
            LayoutHelpers.Below(itemControls[i], title)
        end
        totHeight = totHeight + itemControls[i].Height()
        maxWidth = math.max(maxWidth, itemControls[i].label.Width()+4)
        prevControl = itemControls[i]
    end
    for _, control in itemControls do
        control.Width:Set(maxWidth)
    end
    title.Width:Set(maxWidth)
    group.Height:Set(totHeight)
    group.Width:Set(maxWidth)
    LayoutHelpers.Above(group, button, 10)

    title.HandleEvent = function(self, event)
        Edit.HandleEvent(self, event)
        return true
    end
    title.OnEnterPressed = function(self, text)
        Templates.RenameTemplate(button.Data.template.templateID, text)
        RefreshUI()
    end

    group.HandleEvent = function(self, event)
        return true
    end

    return group
end
