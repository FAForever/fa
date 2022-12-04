local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Combo = import("/lua/ui/controls/combo.lua").Combo
local UIUtil = import("/lua/ui/uiutil.lua")
local Edit = import("/lua/maui/edit.lua").Edit
local options = import("/lua/user/prefs.lua").GetFromCurrentProfile('options')

local ssub, gsub, upper, lower, find, slen, format = string.sub, string.gsub, string.upper, string.lower, string.find,
    string.len, string.format
local mmin, mmax, floor = math.min, math.max, math.floor

local dialog, nameDialog, defaultEditField
local EscThread, SpawnThread
local activeFilters, activeFilterTypes, specialFilterControls, filterSet = {}, {}, {}, {}
local UnitList, CreationList = {}, {}

local NumArmies = GetArmiesTable().numArmies
local options = nil

local TableGetN = table.getn

local ChoiceColumns = options.spawn_menu_filter_columns or 5
local TeamColumns = mmin(options.spawn_menu_team_columns or 3, NumArmies)

local function SourceListTabs()
    local NameMaxLengthChars = 12

    local function ShouldGiveTab(mod)
        local dirlen = slen(mod.location)
        for id, bp in __blueprints do
            if mod.location .. '/' == ssub(bp.Source, 1, dirlen + 1) then
                return true
            end
        end
    end

    local function NameIsShortEnough(name) return slen(name) <= NameMaxLengthChars end

    local function ForWordsIn(text, operation) return gsub(text, '[%a\']+', operation) end

    local function Initialise(text) return gsub(text, '[%a\'%&]+%s*', function(s) return upper(ssub(s, 1, 1)) end) end

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
        return words[gsub(word, '\'', '')] or word
    end

    local function titleFit(name)
        local l = NameMaxLengthChars

        --Removes version numbers and any brackets around them. Restrictive to reduce false positives
        name = gsub(name, '[%[%<%{%(%s]+[vV]+%s*%d+[_%.%d]*[%]%>%}%)%s]*', '') --Requires v or V at start
        name = gsub(name, '[%[%<%{%(%s]+%d+[_%.]+[_%.%d]+[%]%>%}%)%s]*', '') --Requres one or more decimal point or _ between numbers

        if NameIsShortEnough(name) then return name end

        -- Remove anything between brackets, and any space before them
        name = gsub(name, '%s*%b()', '')
        name = gsub(name, '%s*%b[]', '')
        name = gsub(name, '%s*%b<>', '')
        name = gsub(name, '%s*%b{}', '')

        if NameIsShortEnough(name) then return name end

        name = ForWordsIn(name, Abreviate)

        if NameIsShortEnough(name) then return name end

        if not find(ssub(name, l), ' ') then --If we wouldn't lose any entire words, cutoff.
            return ssub(name, 1, l)

        else -- If there are words that would be entirely cut off, initialise after the first
            local FirstSpaceIndex = find(name, ' ')
            local name = ssub(name, 1, FirstSpaceIndex) .. Initialise(ssub(name, FirstSpaceIndex + 1))

            if NameIsShortEnough(name) then
                return name

            else --If it still isn't short enough, just initialise the rest as well, and trim the result just in case
                name = Initialise(ssub(name, 1, FirstSpaceIndex)) .. ssub(name, FirstSpaceIndex + 1)
                return ssub(name, 1, mmin(l, slen(name)))
            end
        end
    end

    local listicle

    if options.spawn_menu_split_sources == 1 then
        listicle = {
            {
                title = 'SC',
                key = 'sc1',
                sortFunc = function(unitID, modloc)
                    return ssub(__blueprints[unitID].Source, 1, 8) == "/units/u"
                end,
            },
            {
                title = 'SC-FA',
                key = 'scx1',
                sortFunc = function(unitID, modloc)
                    return ssub(__blueprints[unitID].Source, 1, 8) == "/units/x"
                end,
            },
            {
                title = 'SC Patch',
                key = 'dlc',
                sortFunc = function(unitID, modloc)
                    return ssub(__blueprints[unitID].Source, 1, 7) == "/units/" and ssub(unitID, 1, 1) ~= 'u' and
                        ssub(unitID, 1, 1) ~= 'x' and ssub(unitID, 1, 1) ~= 'o'
                end,
            }
        }
    else
        listicle = {
            {
                title = 'Core Game',
                key = 'vanilla',
                sortFunc = function(unitID, modloc)
                    return ssub(__blueprints[unitID].Source, 1, 7) == "/units/"
                end,
            }
        }
    end

    for i, mod in __active_mods do
        if mod.name then
            if ShouldGiveTab(mod) then
                local key = gsub(lower(mod.name), "%s+", "_")
                specialFilterControls[key] = mod.location
                table.insert(listicle, {
                    title = titleFit(mod.name),
                    key = key,
                    sortFunc = function(unitID, modloc) return modloc .. '/' ==
                        ssub(__blueprints[unitID].Source, 1, slen(modloc) + 1) end,
                })
            end
        end
    end
    return listicle
end

local function HasCat(id, cat)
    return __blueprints[id].CategoriesHash and __blueprints[id].CategoriesHash[cat]
        or __blueprints[id].Categories and table.find(__blueprints[id].Categories, cat)
end

local function FactionListTabs()
    local flisticle = {}
    local allFactionCats = {}

    for i, faction in import("/lua/factions.lua").Factions do
        local key = 'faction' .. faction.Category
        specialFilterControls[key] = faction.Category
        table.insert(allFactionCats, faction.Category)
        table.insert(flisticle, {
            title = faction.DisplayName,
            key = key,
            sortFunc = HasCat
        })
    end

    table.insert(flisticle, {
        title = 'Other',
        key = 'otherfaction',
        sortFunc = function(unitID)
            for i, cat in allFactionCats do
                if HasCat(unitID, cat) then return end
            end
            return true
        end,
    })

    return flisticle
end

local function TypeListTabs()
    if options.spawn_menu_type_filter_mode == 1 then
        return {
            {
                title = 'Land',
                key = 'land',
                sortFunc = function(unitID) return HasCat(unitID, 'LAND') end,
            },
            {
                title = 'Air',
                key = 'air',
                sortFunc = function(unitID) return HasCat(unitID, 'AIR') end,
            },
            {
                title = 'Naval',
                key = 'naval',
                sortFunc = function(unitID) return HasCat(unitID, 'NAVAL') end,
            },
            {
                title = 'Amphibious',
                key = 'amph',
                sortFunc = function(unitID)
                    return HasCat(unitID, 'AMPHIBIOUS') or HasCat(unitID, 'HOVER')
                end,
            },
            {
                title = 'Base',
                key = 'base',
                sortFunc = function(unitID)
                    return __blueprints[unitID].Physics.MotionType == 'RULEUMT_None'
                end,
            },
        }
    else
        local list = {
            {
                title = 'Land',
                key = 'land',
                sortFunc = function(unitID)
                    local MT = __blueprints[unitID].Physics.MotionType
                    return (MT == 'RULEUMT_Amphibious' or MT == 'RULEUMT_Land') and
                        __blueprints[unitID].ScriptClass ~= 'ResearchItem'
                end,
            },
            {
                title = 'Surface',
                key = 'surface',
                sortFunc = function(unitID)
                    local MT = __blueprints[unitID].Physics.MotionType
                    return MT == 'RULEUMT_AmphibiousFloating' or MT == 'RULEUMT_Hover'
                end,
            },
            {
                title = 'Naval',
                key = 'naval',
                sortFunc = function(unitID)
                    local MT = __blueprints[unitID].Physics.MotionType
                    return MT == 'RULEUMT_Water' or MT == 'RULEUMT_SurfacingSub'
                end,
            },
            {
                title = 'Air',
                key = 'air',
                sortFunc = function(unitID)
                    return __blueprints[unitID].Physics.MotionType == 'RULEUMT_Air'
                end,
            },
            {
                title = 'Base',
                key = 'base',
                sortFunc = function(unitID)
                    return __blueprints[unitID].Physics.MotionType == 'RULEUMT_None'
                end,
            },
        }

        for i, mod in __active_mods do
            if mod.showresearch then
                table.insert(list, {
                    title = 'Research',
                    key = 'rnd',
                    sortFunc = function(unitID)
                        return __blueprints[unitID].ScriptClass == 'ResearchItem'
                    end,
                })
                break
            end
        end

        return list
    end
end

local function TechListTabs()
    local list = {
        {
            title = 'T1',
            key = 't1',
            sortFunc = function(unitID)
                return HasCat(unitID, 'TECH1')
            end,
        },
        {
            title = 'T2',
            key = 't2',
            sortFunc = function(unitID)
                return HasCat(unitID, 'TECH2')
            end,
        },
        {
            title = 'T3',
            key = 't3',
            sortFunc = function(unitID)
                return HasCat(unitID, 'TECH3')
            end,
        },
        {
            title = 'Exp.',
            key = 't4',
            sortFunc = function(unitID)
                return HasCat(unitID, 'EXPERIMENTAL')
            end,
        },
    }
    if options.spawn_menu_notech_filter ~= 0 then
        table.insert(list, 1, {
            title = 'No Tech',
            key = 'civ',
            sortFunc = function(unitID)
                return not (HasCat(unitID, 'TECH1') or HasCat(unitID, 'TECH2')
                    or HasCat(unitID, 'TECH3') or HasCat(unitID, 'EXPERIMENTAL'))
            end,
        })
    end
    if options.spawn_menu_paragon_filter == 1 then
        table.insert(list, {
            title = 'ACU+',
            key = 'acu',
            sortFunc = function(unitID)
                return HasCat(unitID, 'COMMAND') -- Show ACU's
                    or find(unitID, 'l0301_Engineer') -- Show SCU's
                    or find(unitID, 'xab1401') -- Show Paragon
            end,
        })
    end
    return list
end

local nameFilters = {
    {
        title = 'Search',
        key = 'custominput',
        sortFunc = function(unitID, text)
            local bp = __blueprints[unitID]
            local desc = lower(LOC(bp.Description or ''))
            local name = lower(LOC(bp.General.UnitName or ''))
            text = lower(text)
            return find(unitID, text) or find(desc, text) or find(name, text)
        end,
    },
    {
        title = 'Faction',
        key = 'faction',
        choices = FactionListTabs(),
    },
    {
        title = 'Source',
        key = 'mod',
        choices = SourceListTabs(),
    },
    {
        title = 'Type',
        key = 'type',
        choices = TypeListTabs(),
    },
    {
        title = 'Tech Level',
        key = 'tech',
        choices = TechListTabs(),
    },
}

if options.spawn_menu_filter_menu_sort ~= 0 then
    table.insert(nameFilters, {
        title = 'Menu Sort',
        key = 'sort',
        choices = {
            {
                title = 'Construction',
                key = 'const',
                sortFunc = function(unitID)
                    return HasCat(unitID, 'SORTCONSTRUCTION')
                end,
            },
            {
                title = 'Economy',
                key = 'eco',
                sortFunc = function(unitID)
                    return HasCat(unitID, 'SORTECONOMY')
                end,
            },
            {
                title = 'Defense',
                key = 'fence',
                sortFunc = function(unitID)
                    return HasCat(unitID, 'SORTDEFENSE')
                end,
            },
            {
                title = 'Strategic',
                key = 'strat',
                sortFunc = function(unitID)
                    return HasCat(unitID, 'SORTSTRATEGIC')
                end,
            },
            {
                title = 'Intel',
                key = 'inside',
                sortFunc = function(unitID)
                    return HasCat(unitID, 'SORTINTEL')
                end,
            },
            {
                title = 'Other',
                key = 'othersort',
                sortFunc = function(unitID)
                    return HasCat(unitID, 'SORTOTHER') or not (
                        HasCat(unitID, 'SORTCONSTRUCTION') or
                            HasCat(unitID, 'SORTECONOMY') or
                            HasCat(unitID, 'SORTDEFENSE') or
                            HasCat(unitID, 'SORTSTRATEGIC') or
                            HasCat(unitID, 'SORTINTEL')
                        )
                end,
            },
        },
    })
end

if categories.UNSPAWNABLE then
    table.insert(nameFilters, 2,
        {
            title = 'Visibility',
            key = 'spawnable',
            choices = {
                {
                    title = '',
                    key = 'spawnable',
                    sortFunc = function(unitID)
                        return not HasCat(unitID, 'UNSPAWNABLE')
                    end,
                },
                {
                    title = '',
                    key = 'unspawnable',
                    sortFunc = function(unitID)
                        return HasCat(unitID, 'UNSPAWNABLE')
                    end,
                },
            }
        }
    )
end

local function getItems() return EntityCategoryGetUnitList(categories.ALLUNITS) end

local function CreateNameFilter(data)
    local group = Group(dialog)
    group.Width:Set(dialog.Width)
    if data.choices and data.choices[1] and TableGetN(data.choices) > ChoiceColumns then
        LayoutHelpers.SetHeight(group, 30 + floor((TableGetN(data.choices) - 1) / ChoiceColumns) * 25)
    else
        LayoutHelpers.SetHeight(group, 30)
    end

    group.check = UIUtil.CreateCheckboxStd(group, '/dialogs/check-box_btn/radio')
    LayoutHelpers.AtLeftIn(group.check, group)
    if data.choices and data.choices[1] and TableGetN(data.choices) > ChoiceColumns then
        LayoutHelpers.AtTopIn(group.check, group, 2)
    else
        LayoutHelpers.AtVerticalCenterIn(group.check, group)
    end

    group.check.key = data.key
    if filterSet[data.key] == nil then
        filterSet[data.key] = { value = data.key == 'spawnable', choices = {} }
    end
    if activeFilters[data.key] == nil then
        activeFilters[data.key] = {}
    end

    group.label = UIUtil.CreateText(group, data.title, 14, UIUtil.bodyFont)
    LayoutHelpers.RightOf(group.label, group.check)
    if data.choices and data.choices[1] and TableGetN(data.choices) > ChoiceColumns then
        LayoutHelpers.AtTopIn(group.label, group, 7)
    else
        LayoutHelpers.AtVerticalCenterIn(group.label, group)
    end

    if data.choices then
        group.items = {}
        for i, v in data.choices do
            local index = i
            group.items[index] = UIUtil.CreateCheckboxStd(group,
                data.key == 'spawnable' and '/dialogs/check-box_btn/radio' or '/dialogs/toggle_btn/toggle')
            if index == 1 then
                LayoutHelpers.AtLeftTopIn(group.items[index], group, 95)
            elseif index < ChoiceColumns + 1 then
                LayoutHelpers.RightOf(group.items[index], group.items[index - 1])
            else
                LayoutHelpers.Below(group.items[index], group.items[index - ChoiceColumns])
            end
            if index < ChoiceColumns + 1 then
                LayoutHelpers.AtTopIn(group.items[index], group)
            end

            group.items[index].label = UIUtil.CreateText(group.items[index], v.title, 10, UIUtil.bodyFont)
            LayoutHelpers.AtCenterIn(group.items[index].label, group.items[index])
            group.items[index].label:DisableHitTest()

            group.items[index].sortFunc = v.sortFunc
            group.items[index].filterKey = v.key
            group.items[index].key = data.key
            group.items[index].OnCheck = function(self, checked)
                filterSet[self.key].choices[self.filterKey] = checked
                self.label:SetColor(UIUtil.fontColor)
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
        end
    else
        group.edit = Edit(group)
        group.edit:SetForegroundColor(UIUtil.fontColor)
        group.edit:SetBackgroundColor('ff333333')
        group.edit:SetHighlightForegroundColor(UIUtil.highlightColor)
        group.edit:SetHighlightBackgroundColor("880085EF")
        LayoutHelpers.SetDimensions(group.edit, (ChoiceColumns - 2) * 82 + 15, 15)
        group.edit:SetText(filterSet[data.key].editText or '')
        group.edit:SetFont(UIUtil.bodyFont, 12)
        group.edit:SetMaxChars(20)
        LayoutHelpers.AtLeftIn(group.edit, group, 95)
        LayoutHelpers.AtVerticalCenterIn(group.edit, group)
        group.edit.filterKey = data.key
        group.edit.key = data.key
        group.edit.sortFunc = data.sortFunc

        group.edit.OnTextChanged = function(self, new, old)
            if new == '' then
                activeFilters[self.key][self.filterKey] = nil
                if group.check:IsChecked() then
                    group.check:SetCheck(false)
                end
            else
                filterSet[self.key].editText = new
                activeFilters[self.key][self.filterKey] = self.sortFunc
                if not group.check:IsChecked() then
                    group.check:SetCheck(true)
                end
            end
            RefreshList()
        end

        defaultEditField = group.edit

        specialFilterControls[data.key] = group.edit
    end

    group.check.OnCheck = function(self, checked)
        activeFilterTypes[self.key] = checked
        filterSet[data.key].value = checked
        local labelColor = 'ff555555'
        if checked then
            labelColor = UIUtil.fontColor
        end
        if group.items then
            for i, v in group.items do
                if not checked then
                    v:SetCheck(false, true)
                end
                v.label:SetColor(labelColor)
            end
        else

        end
        group.label:SetColor(labelColor)
        RefreshList()
    end
    group.check:SetCheck(filterSet[data.key].value)

    return group
end

function CreateDialog(x, y)
    
    if dialog then
        dialog:Destroy()
        dialog = nil
        return
    end

    local currentArmy = GetFocusArmy()

    CreationList = {}

    dialog = Bitmap(GetFrame(0))
    dialog:SetSolidColor('CC000000')

    local NoArmies = math.ceil(NumArmies / TeamColumns)
    local NoMods = floor((table.getn(nameFilters[3].choices) - 1) / ChoiceColumns)

    LayoutHelpers.SetDimensions(dialog,
        90 + 83 * ChoiceColumns, -- Width
        450 + NoArmies * 30 + NoMods * 25-- Height
    )
    dialog.Left:Set(function() return mmax(mmin(x - dialog.Width() / 2, GetFrame(0).Right() - dialog.Width()), 0) end)
    dialog.Top:Set(function() return mmax(mmin(y - 160, GetFrame(0).Bottom() - dialog.Height()), 0) end)
    dialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)

    local cancelBtn = UIUtil.CreateButtonStd(dialog, '/widgets/small', "Cancel", 12)
    LayoutHelpers.AtBottomIn(cancelBtn, dialog)
    LayoutHelpers.AtRightIn(cancelBtn, dialog)
    cancelBtn.OnClick = function(button)
        dialog:Destroy()
        dialog = nil
        if EscThread then KillThread(EscThread) end
    end

    EscThread = ForkThread(function()
        while dialog do
            if IsKeyDown('ESCAPE') then
                cancelBtn.OnClick()
                break
            end
            WaitSeconds(0.05)
        end
    end)

    local function numImputSettings(element, label, startval)
        element.StartVal = startval
        element:SetForegroundColor(UIUtil.fontColor)
        element:SetBackgroundColor('ff333333')
        element:SetHighlightForegroundColor(UIUtil.highlightColor)
        element:SetHighlightBackgroundColor("880085EF")
        element.Width:Set(30)
        element.Height:Set(15)
        element:SetFont(UIUtil.bodyFont, 12)
        element:SetMaxChars(4)
        element:SetText(startval)
        LayoutHelpers.RightOf(element, label, 5)
        element.OnCharPressed = function(self, charcode)
            return (charcode < 48) or (charcode > 57) -- between 0 and 9
        end
        element.OnNonTextKeyPressed = function(self, keycode, modifiers) end
        element.OnKeyboardFocusChange = function(self)
            local text = self:GetText()
            self:SetText(text == '' and self.StartVal or text)
        end
    end

    local countLabel = UIUtil.CreateText(dialog, 'Count:', 12, UIUtil.bodyFont)
    LayoutHelpers.AtBottomIn(countLabel, dialog, 10)
    LayoutHelpers.AtLeftIn(countLabel, dialog, 5)
    local count = Edit(dialog)
    numImputSettings(count, countLabel, '1')

    local veterancyLabel = UIUtil.CreateText(count, 'Vet:', 12, UIUtil.bodyFont)
    LayoutHelpers.RightOf(veterancyLabel, count, 5)
    local veterancyLevel = Edit(dialog)
    numImputSettings(veterancyLevel, veterancyLabel, '0')

    local orientLabel = UIUtil.CreateText(count, 'Yaw:', 12, UIUtil.bodyFont)
    LayoutHelpers.RightOf(orientLabel, veterancyLevel, 5)
    local orientation = Edit(dialog)
    numImputSettings(orientation, orientLabel, '0')

    if SpawnThread then KillThread(SpawnThread) end

    local function spreadSpawn(ids, count, vet)

        if TableGetN(ids) > 0 then

            -- store selection so that units do not go of and try to build the unit we're
            -- cheating in, is reset in EndCommandMode of '/lua/ui/game/commandmode.lua'
            local selection = GetSelectedUnits()
            SelectUnits(nil);

            -- enables command mode for spawning units
            import("/lua/ui/game/commandmode.lua").StartCommandMode(
                "build",
                {
                    -- default information required
                    ids = ids,
                    index = 2,

                    -- inform this is part of a cheat
                    cheat = true,

                    -- information for spawning
                    name = ids[1],
                    bpId = ids[1],
                    count = tonumber(count:GetText()) or 1,
                    vet = tonumber(vet:GetText()) or 0,
                    yaw = (tonumber(orientation:GetText()) or 0) / 57.295779513,
                    army = currentArmy,
                    selection = selection,
                }
            )

            -- options for user to exit the spawn mode
            local function IsCancelKeyDown() return IsKeyDown('ESCAPE') or IsKeyDown(2) end

            WaitSeconds(0.15)

            -- check if user wants to exit
            while not dialog do
                if IsCancelKeyDown() then
                    import("/lua/ui/game/commandmode.lua").EndCommandMode(true)
                    break
                end
                WaitSeconds(0.1)
            end
        end
    end

    local createBtn = UIUtil.CreateButtonStd(dialog, '/widgets/small', "Create", 12)
    LayoutHelpers.AtBottomIn(createBtn, dialog)
    LayoutHelpers.LeftOf(createBtn, cancelBtn, 5)
    createBtn.OnClick = function(button)
        ForkThread(spreadSpawn, table.keys(CreationList), count, veterancyLevel)
        cancelBtn.OnClick()
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
                        if filterTable[key].choices[choiceControl.filterKey] ~= nil and
                            choiceControl:IsChecked() ~= filterTable[key].choices[choiceControl.filterKey] then
                            choiceControl:SetCheck(filterTable[key].choices[choiceControl.filterKey])
                        end
                    end
                else
                    groupControls.edit:SetText(filterTable[key].editText)
                end
            end
        end
        RefreshList()
    end

    local function CreateArmySelectionSlot(parent, index, armyData)
        local group = Bitmap(parent)
        LayoutHelpers.SetHeight(group, 30)
        group.Width:Set(function() return parent.Width() / TeamColumns end)

        local iconBG = Bitmap(group)
        LayoutHelpers.SetDimensions(iconBG, 30, 30)
        iconBG:SetSolidColor(armyData.color)
        LayoutHelpers.AtLeftTopIn(iconBG, group)
        iconBG:DisableHitTest()

        local icon = Bitmap(iconBG)
        if armyData.civilian then
            icon:SetSolidColor('aaaaaaaa')
        else
            icon:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(armyData.faction)))
        end
        LayoutHelpers.FillParent(icon, iconBG)
        icon:DisableHitTest()

        -- Army name
        local name = UIUtil.CreateText(group, armyData.nickname, 12, UIUtil.bodyFont)
        LayoutHelpers.RightOf(name, icon, 2)
        LayoutHelpers.AtTopIn(name, group)
        name:SetColor('ffffffff')
        name:DisableHitTest()

        local army = UIUtil.CreateText(group, armyData.name, 12, UIUtil.bodyFont)
        LayoutHelpers.Below(army, name)
        army:DisableHitTest()

        group.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if currentArmy == index then
                    self:SetSolidColor('cc00cc00')
                else
                    self:SetSolidColor('77007700')
                end
            elseif event.Type == 'MouseExit' then
                if currentArmy == index then
                    self:SetSolidColor('aa00aa00')
                else
                    self:SetSolidColor('00000000')
                end
            elseif event.Type == 'ButtonPress' then
                currentArmy = index
                for i, v in parent.armySlots do
                    if i == index then
                        v:SetSolidColor('aa00aa00')
                    else
                        v:SetSolidColor('00000000')
                    end
                end
            elseif event.Type == 'ButtonDClick' then
                ConExecute('SetFocusArmy ' .. tostring(currentArmy - 1))
            end
        end
        if index == currentArmy then
            group:SetSolidColor('aa00aa00')
        end
        return group
    end

    local armiesGroup = Group(dialog)
    armiesGroup.Width:Set(dialog.Width)
    LayoutHelpers.AtLeftTopIn(armiesGroup, dialog)

    local function IsColumnHead(teamI)
        if TeamColumns <= 1 then return false end
        for i = 1, TeamColumns - 1 do
            if teamI == floor(NumArmies / TeamColumns * i) + 1 then
                return true
            end
        end
    end

    armiesGroup.armySlots = {}
    local lowestControl
    local WorkingColumnHead = 1
    for i, val in GetArmiesTable().armiesTable do
        armiesGroup.armySlots[i] = CreateArmySelectionSlot(armiesGroup, i, val)
        if i == 1 then
            LayoutHelpers.AtLeftTopIn(armiesGroup.armySlots[i], armiesGroup)
            lowestControl = armiesGroup.armySlots[i]
        elseif IsColumnHead(i) then
            LayoutHelpers.RightOf(armiesGroup.armySlots[i], armiesGroup.armySlots[WorkingColumnHead])
            LayoutHelpers.AtTopIn(armiesGroup.armySlots[i], armiesGroup)
            WorkingColumnHead = i
        else
            LayoutHelpers.Below(armiesGroup.armySlots[i], armiesGroup.armySlots[i - 1])
        end
        if armiesGroup.armySlots[i].Bottom() > lowestControl.Bottom() then
            lowestControl = armiesGroup.armySlots[i]
        end
    end

    armiesGroup.Height:Set(function() return lowestControl.Bottom() - armiesGroup.armySlots[1].Top() end)

    local filterSetCombo = Combo(dialog, 14, 10, nil, nil, "UI_Tab_Click_01", "UI_Tab_Rollover_01")
    LayoutHelpers.SetWidth(filterSetCombo, 250)
    LayoutHelpers.Below(filterSetCombo, armiesGroup, 5)
    filterSetCombo.OnClick = function(self, index, text, skipUpdate)
        SetFilters(self.keyMap[index])
    end

    local function RefreshFilterList(defName)
        filterSetCombo:ClearItems()
        filterSetCombo.itemArray = {}
        filterSetCombo.keyMap = {}
        local CurrentFilterSets = GetPreference('CreateUnitFilters')
        if CurrentFilterSets and not table.empty(CurrentFilterSets) then
            local index = 1
            local default = 1
            for filterName, filter in sortedpairs(CurrentFilterSets) do
                if filterName == defName then
                    default = index
                end
                filterSetCombo.itemArray[index] = format('%s', filterName)
                filterSetCombo.keyMap[index] = filter
                index = index + 1
            end
            filterSetCombo:AddItems(filterSetCombo.itemArray, default)
        end
    end

    local function CreateToggleButton(text)
        local btn = UIUtil.CreateButton(dialog,
            '/dialogs/toggle_btn/toggle-d_btn_up.dds',
            '/dialogs/toggle_btn/toggle-d_btn_down.dds',
            '/dialogs/toggle_btn/toggle-d_btn_over.dds',
            '/dialogs/toggle_btn/toggle-d_btn_dis.dds',
            text, 10)
        btn.label:SetFont(UIUtil.bodyFont, 10)
        return btn
    end

    local saveFilterSet = CreateToggleButton 'Save Filter'
    LayoutHelpers.RightOf(saveFilterSet, filterSetCombo)
    LayoutHelpers.AtVerticalCenterIn(saveFilterSet, filterSetCombo)
    saveFilterSet.OnClick = function(self, modifiers)
        NameSet(function(name)
            local newFilterListing = {}
            if GetPreference('CreateUnitFilters') then
                newFilterListing = table.deepcopy(GetPreference('CreateUnitFilters'))
                newFilterListing[name] = filterSet
            else
                newFilterListing[name] = filterSet
            end
            SetPreference('CreateUnitFilters', newFilterListing)
            RefreshFilterList(name)
        end)
    end

    local delFilterSet = CreateToggleButton 'Delete Filter'
    LayoutHelpers.RightOf(delFilterSet, saveFilterSet)
    LayoutHelpers.AtVerticalCenterIn(delFilterSet, filterSetCombo)
    delFilterSet.OnClick = function(self, modifiers)
        local index = filterSetCombo:GetItem()
        if index >= 1 then
            local delName = filterSetCombo.itemArray[index]
            LOG(delName)
            local oldFilterSets = GetPreference('CreateUnitFilters')
            if oldFilterSets[delName] then
                oldFilterSets[delName] = nil
            end
            SetPreference('CreateUnitFilters', oldFilterSets)
            RefreshFilterList()
        end
    end

    local propSwapBtn = CreateToggleButton 'Prop mode'
    LayoutHelpers.Below(propSwapBtn, armiesGroup, 5)
    LayoutHelpers.RightOf(propSwapBtn, delFilterSet, 9)
    propSwapBtn.OnClick = function(button)
        ConExecuteSave('ui_lua import("/lua/ui/dialogs/createprop.lua").CreateDialog(' .. x .. ',' .. y .. ')')
        cancelBtn.OnClick()
    end

    RefreshFilterList()

    filterGroups = {}
    for filtIndex, filter in nameFilters do
        local index = filtIndex
        filterGroups[index] = CreateNameFilter(filter)
        if filtIndex == 1 then
            LayoutHelpers.Below(filterGroups[index], filterSetCombo)
            LayoutHelpers.AtLeftIn(filterGroups[index], dialog)
        elseif categories.UNSPAWNABLE and filtIndex == 2 then
            LayoutHelpers.RightOf(filterGroups[index], filterGroups[1], -150)
        elseif categories.UNSPAWNABLE and filtIndex == 3 then
            LayoutHelpers.Below(filterGroups[index], filterGroups[1])
        else
            LayoutHelpers.Below(filterGroups[index], filterGroups[index - 1])
        end
    end

    dialog.unitList = Group(dialog)
    dialog.unitList.Height:Set(function() return createBtn.Top() - filterGroups[TableGetN(filterGroups)].Bottom() -
        LayoutHelpers.ScaleNumber(5) end)
    dialog.unitList.Width:Set(function() return dialog.Width() - LayoutHelpers.ScaleNumber(40) end)
    LayoutHelpers.Below(dialog.unitList, filterGroups[TableGetN(filterGroups)])
    dialog.unitList.top = 0

    dialog.unitEntries = {}

    UIUtil.CreateVertScrollbarFor(dialog.unitList)

    local LineColors = {
        Up = '00000000', Sel_Up = 'ff447744',
        Over = 'ff444444', Sel_Over = 'ff669966',
    }

    local mouseover = false
    local function CreateElementMouseover(unitData, x, y)
        if mouseover then mouseover:Destroy() end
        mouseover = Bitmap(dialog)
        mouseover:SetSolidColor('dd115511')

        mouseover.img = Bitmap(mouseover)
        LayoutHelpers.SetDimensions(mouseover.img, 40, 40)
        LayoutHelpers.AtLeftTopIn(mouseover.img, mouseover, 2, 2)
        if DiskGetFileInfo(UIUtil.UIFile('/icons/units/' .. unitData .. '_icon.dds', true)) then
            mouseover.img:SetTexture(UIUtil.UIFile('/icons/units/' .. unitData .. '_icon.dds', true))
        else
            mouseover.img:SetTexture(UIUtil.UIFile('/icons/units/default_icon.dds'))
        end

        mouseover.name = UIUtil.CreateText(mouseover, __blueprints[unitData].Description, 14, UIUtil.bodyFont)
        LayoutHelpers.RightOf(mouseover.name, mouseover.img, 2)

        mouseover.desc = UIUtil.CreateText(mouseover, __blueprints[unitData].General.UnitName or unitData, 14,
            UIUtil.bodyFont)
        LayoutHelpers.AtLeftIn(mouseover.desc, mouseover, 44)
        LayoutHelpers.AtBottomIn(mouseover.desc, mouseover, 5)

        mouseover.Left:Set(x + 20)
        mouseover.Top:Set(y + 20)
        mouseover.Height:Set(function() return mouseover.img.Height() + 4 end)
        mouseover.Width:Set(function() return mouseover.img.Width() +
            mmax(mouseover.name.Width(), mouseover.desc.Width()) + 8 end)
        mouseover.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    end

    local function MoveMouseover(x, y)
        if mouseover then
            mouseover.Left:Set(x + 20)
            mouseover.Top:Set(y + 20)
        end
    end

    local function DestroyMouseover()
        if mouseover then
            mouseover:Destroy()
            mouseover = false
        end
    end

    local function CreateUnitElements()
        if dialog.unitEntries then
            for i, v in dialog.unitEntries do
                if v.bg then v.bg:Destroy() end
            end
            dialog.unitEntries = {}
        end

        local function CreateElement(index)
            dialog.unitEntries[index] = Bitmap(dialog.unitList)
            dialog.unitEntries[index].Left:Set(dialog.unitList.Left)
            dialog.unitEntries[index].Right:Set(dialog.unitList.Right)
            LayoutHelpers.SetHeight(dialog.unitEntries[index], 16)
            dialog.unitEntries[index].Checked = false
            dialog.unitEntries[index].HandleEvent = function(self, event)
                if event.Type == 'MouseEnter' then
                    CreateElementMouseover(self.unitID, event.MouseX, event.MouseY)
                    if self.Checked then
                        self:SetSolidColor(LineColors.Sel_Over)
                    else
                        self:SetSolidColor(LineColors.Over)
                    end
                elseif event.Type == 'MouseExit' then
                    DestroyMouseover()
                    if self.Checked then
                        self:SetSolidColor(LineColors.Sel_Up)
                    else
                        self:SetSolidColor(LineColors.Up)
                    end
                elseif event.Type == 'ButtonPress' and event.Modifiers.Left then
                    self.Checked = not self.Checked
                    if CreationList[self.unitID] then
                        CreationList[self.unitID] = nil
                    else
                        CreationList[self.unitID] = true
                        self:SetSolidColor(LineColors.Sel_Up)
                    end
                elseif event.Type == 'ButtonDClick' and event.Modifiers.Left then
                    SpawnThread = ForkThread(spreadSpawn, { self.unitID }, count, veterancyLevel)
                    cancelBtn:OnClick()
                elseif event.Type == 'MouseMotion' then
                    MoveMouseover(event.MouseX, event.MouseY)
                end
            end

            dialog.unitEntries[index].id = UIUtil.CreateText(dialog.unitEntries[index], '', 12, UIUtil.bodyFont)
            LayoutHelpers.AtLeftTopIn(dialog.unitEntries[index].id, dialog.unitEntries[index])
        end

        CreateElement(1)
        LayoutHelpers.AtTopIn(dialog.unitEntries[1], dialog.unitList)

        local index = 2
        while dialog.unitEntries[table.getsize(dialog.unitEntries)].Top() + (2 * dialog.unitEntries[1].Height()) <
            dialog.unitList.Bottom() do
            CreateElement(index)
            LayoutHelpers.Below(dialog.unitEntries[index], dialog.unitEntries[index - 1])
            index = index + 1
        end
    end

    CreateUnitElements()

    local numLines = function() return table.getsize(dialog.unitEntries) end

    local function DataSize()
        return TableGetN(UnitList)
    end

    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    dialog.unitList.GetScrollValues = function(self, axis)
        local size = DataSize()
        return 0, size, self.top, mmin(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    dialog.unitList.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    dialog.unitList.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    dialog.unitList.ScrollSetTop = function(self, axis, top)
        top = floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = mmax(mmin(size - numLines(), top), 0)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    dialog.unitList.IsScrollable = function(self, axis)
        return true
    end
    -- determines what controls should be visible or not
    dialog.unitList.CalcVisible = function(self)
        local function SetTextLine(line, data, lineID)
            line:Show()
            if CreationList[data.id] then
                line.Checked = true
                line:SetSolidColor(LineColors.Sel_Up)
            else
                line.Checked = false
                line:SetSolidColor(LineColors.Up)
            end
            line.unitID = data.id
            line.id:SetText(format('%s %5s %s', data.id, ' ', data.desc))
        end

        for i, v in dialog.unitEntries do
            if UnitList[i + self.top] then
                SetTextLine(v, UnitList[i + self.top], i + self.top)
            else
                v:Hide()
            end
        end
    end

    dialog.unitList.HandleEvent = function(control, event)
        if event.Type == 'WheelRotation' then
            local lines = 3
            if event.WheelRotation > 0 then
                lines = -3
            end
            control:ScrollLines(nil, lines)
        end
    end
    defaultEditField:AcquireFocus()
    RefreshList()
end

function RefreshList()
    if not dialog.unitList then return end
    UnitList = {}
    local totalList = getItems()
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

            table.insert(UnitList,
                { id = v, name = LOC(__blueprints[v].General.UnitName) or '',
                    desc = LOC(__blueprints[v].Description) or '' })
        end
    end
    dialog.unitList.top = 0
    dialog.unitList:CalcVisible()
end

function NameSet(callback)
    -- Dialog already showing? Don't show another one
    if nameDialog then return end

    nameDialog = Bitmap(dialog, UIUtil.SkinnableFile('/dialogs/dialog_02/panel_bmp.dds'), "Marker Name Dialog")
    LayoutHelpers.AtCenterIn(nameDialog, GetFrame(0))
    nameDialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)

    local label = UIUtil.CreateText(nameDialog, "Name your filter set:", 16, UIUtil.buttonFont)
    LayoutHelpers.AtLeftTopIn(label, nameDialog, 35, 30)

    local cancelButton = UIUtil.CreateButtonStd(nameDialog, '/widgets02/small', "<LOC _CANCEL>", 12)
    LayoutHelpers.AtTopIn(cancelButton, nameDialog, 112)
    cancelButton.Left:Set(function() return nameDialog.Left() +
        (((nameDialog.Width() / 4) * 1) - (cancelButton.Width() / 2)) end)
    cancelButton.OnClick = function(self, modifiers)
        nameDialog:Destroy()
        nameDialog = nil
    end

    --TODO this should be in layout
    local nameEdit = Edit(nameDialog)
    LayoutHelpers.AtLeftTopIn(nameEdit, nameDialog, 35, 60)
    LayoutHelpers.SetWidth(nameEdit, 283)
    nameEdit.Height:Set(nameEdit:GetFontHeight())
    nameEdit:ShowBackground(false)
    nameEdit:AcquireFocus()
    UIUtil.SetupEditStd(nameEdit, UIUtil.fontColor, nil, nil, nil, UIUtil.bodyFont, 16, 30)

    local okButton = UIUtil.CreateButtonStd(nameDialog, '/widgets02/small', "<LOC _OK>", 12)
    okButton.Top:Set(function() return nameDialog.Top() + 112 end)
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

-- kept for mod backwards compatibility
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Text = import("/lua/maui/text.lua").Text
local Border = import("/lua/maui/border.lua").Border
local Checkbox = import("/lua/maui/checkbox.lua").Checkbox
local RadioGroup = import("/lua/maui/mauiutil.lua").RadioGroup
local unselectedCheckboxFile = UIUtil.UIFile('/widgets/rad_un.dds')
local selectedCheckboxFile = UIUtil.UIFile('/widgets/rad_sel.dds')
