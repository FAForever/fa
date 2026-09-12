--******************************************************************************************************
--** Cybran SACU loadout combos
--**
--** Generates a hidden EnhancementPreset for every valid URL0301 slot combination
--** that is not already a named factory preset. IDs are stable: enhancement names
--** are sorted before the suffix is built, so clients cannot disagree on the string.
--**
--** Existing role presets (RAS, Engineer, Combat, ...) are left untouched and stay
--** on the Quantum Gateway construct grid.
--******************************************************************************************************

local TableInsert = table.insert
local TableGetn = table.getn
local StringLower = string.lower

local ComboFactionBaseIds = {
    url0301 = true,
}

local SlotOrder = { 'LCH', 'RCH', 'Back' }

local function IsRemoveEnhancement(name)
    return string.sub(name, -6) == 'Remove'
end

local function SortedKeys(hashtable)
    local keys = {}
    for key in hashtable do
        TableInsert(keys, key)
    end
    table.sort(keys)
    return keys
end

local function EnhancementChain(enhName, slotDefs)
    local chain = { enhName }
    local current = enhName
    local guard = 0
    while slotDefs[current] and slotDefs[current].Prerequisite and guard < 8 do
        local pre = slotDefs[current].Prerequisite
        if not slotDefs[pre] then
            break
        end
        TableInsert(chain, 1, pre)
        current = pre
        guard = guard + 1
    end
    return chain
end

local function SlotChoices(slotDefs)
    local choices = { {} }
    local names = SortedKeys(slotDefs)
    for _, name in names do
        TableInsert(choices, EnhancementChain(name, slotDefs))
    end
    return choices
end

local function GroupBySlot(enhancements)
    local bySlot = {}
    for name, def in enhancements do
        if def.Slot and not IsRemoveEnhancement(name) then
            bySlot[def.Slot] = bySlot[def.Slot] or {}
            bySlot[def.Slot][name] = def
        end
    end
    return bySlot
end

function EnhancementSetKey(list)
    local copy = {}
    for _, name in list do
        TableInsert(copy, name)
    end
    table.sort(copy)
    return string.lower(table.concat(copy, '|'))
end

local function ExistingPresetKeys(namedPresets)
    local keys = {}
    for presetName, preset in namedPresets do
        if preset.Enhancements then
            keys[EnhancementSetKey(preset.Enhancements)] = presetName
        end
    end
    return keys
end

local function AllCombinations(slotChoices)
    local combos = { {} }
    for _, slot in SlotOrder do
        local choices = slotChoices[slot]
        if choices then
            local nextCombos = {}
            for _, prefix in combos do
                for _, choice in choices do
                    local merged = {}
                    for _, name in prefix do
                        TableInsert(merged, name)
                    end
                    for _, name in choice do
                        TableInsert(merged, name)
                    end
                    TableInsert(nextCombos, merged)
                end
            end
            combos = nextCombos
        end
    end
    return combos
end

local function ComboPresetName(enhancements)
    local copy = {}
    for _, name in enhancements do
        TableInsert(copy, StringLower(name))
    end
    table.sort(copy)
    return 'combo_' .. table.concat(copy, '_')
end

local function CleanLabel(name, def)
    local label = name
    if def and def.Name then
        label = string.gsub(def.Name, '^<LOC [^>]+>', '')
    end
    return label
end

local function ComboUnitName(enhancements, bp)
    local labels = {}
    for _, name in enhancements do
        TableInsert(labels, CleanLabel(name, bp.Enhancements[name]))
    end
    return 'SACU (' .. table.concat(labels, ' / ') .. ')'
end

function InjectSacuLoadoutPresets(all_bps)
    if not all_bps or not all_bps.Unit then
        return
    end

    local generated = 0
    local skippedNamed = 0

    for id, bp in all_bps.Unit do
        if ComboFactionBaseIds[id] and bp.Enhancements and bp.EnhancementPresets then
            local bySlot = GroupBySlot(bp.Enhancements)
            local slotChoices = {}
            for _, slot in SlotOrder do
                if bySlot[slot] then
                    slotChoices[slot] = SlotChoices(bySlot[slot])
                end
            end

            local namedKeys = ExistingPresetKeys(bp.EnhancementPresets)
            local combos = AllCombinations(slotChoices)

            for _, enhList in combos do
                if TableGetn(enhList) > 0 then
                    local setKey = EnhancementSetKey(enhList)
                    if namedKeys[setKey] then
                        skippedNamed = skippedNamed + 1
                    else
                        local presetName = ComboPresetName(enhList)
                        if not bp.EnhancementPresets[presetName] then
                            local pretty = ComboUnitName(enhList, bp)
                            bp.EnhancementPresets[presetName] = {
                                Description = pretty,
                                BuildIconSortPriority = 90,
                                Enhancements = enhList,
                                HelpText = pretty,
                                SelectionPriority = 1,
                                SortCategory = 'SORTOTHER',
                                UnitName = pretty,
                                HiddenInBuildMenu = true,
                            }
                            generated = generated + 1
                        end
                    end
                end
            end
        end
    end

    SPEW(string.format('SACU loadout: generated %d hidden Cybran combos, reused %d named presets', generated, skippedNamed))
end

function MarkHiddenSacuLoadoutPresets(all_bps)
    if not all_bps or not all_bps.Unit then
        return
    end

    for id, bp in all_bps.Unit do
        local assigned = bp.EnhancementPresetAssigned
        if assigned and assigned.Name and string.sub(assigned.Name, 1, 6) == 'combo_' then
            local baseId = assigned.BaseBlueprintId
            if ComboFactionBaseIds[baseId] then
                bp.CategoriesHash = bp.CategoriesHash or {}
                bp.CategoriesHash['SACULOADOUTCOMBO'] = true
                bp.Categories = table.unhash(bp.CategoriesHash)
            end
        end
    end
end
