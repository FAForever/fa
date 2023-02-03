-- Call these in your scripts where you need them

function GetFactions(AllowedMods)
    -- AllowedMods  -> a table of currently enabled mods, keyed by mod ID. Ignore if not used
    -- returns a list of factions. All 4 of the original factions are included plus all enabled custom factions.
    return GetCustomFactions(OrgFactions(), AllowedMods)
end

function GetNewFactionAINames()
    -- Gets a name for AI players
    local ainames = {}
    for f,_ in NewFactionAiData do
        ainames[f] = NewFactionAiData[f].ainames or { 'nameless', }
    end
    return ainames
end

function GetNewFactionAIPlans(offset)
    -- Gets an AI plan for computer players. Offset is the key with which the table should begin, counting up from
    -- that value + 1.
    if table.empty(NewFactionAiData) then
        local x = import("/lua/factions.lua").Factions  -- to make sure NewFactionAiData contains something
    end
    if not offset then
        offset = 5  -- 5 for the 5 races
    end
    local aiplans = {}
    offset = math.max(0, offset)
    for f,_ in NewFactionAiData do
        offset = offset + 1
        aiplans[ offset ] = NewFactionAiData[f].AIPlansList or { '/lua/AI/aiarchetype-managerloader.lua', }
    end
    return aiplans
end

-- ----------------------------------------------------------------------------------------------------------------
-- Don't touch these!

NewFactionAiData = {}

function GetCustomFactions(FactionsTable, AllowedMods)
    if not FactionsTable or type(FactionsTable) ~= 'table' then
        FactionsTable = {}
    end
    local FactionFiles = DiskFindFiles('/lua/CustomFactions', '*.lua')
    local SelectedMods = GetSelectedMods(AllowedMods)
    for k, file in FactionFiles do

        local FactionFile = import(file)
        if rawget(FactionFile, 'Factions') then
            WARN('File '..repr(file)..' contains a "Factions" variable. Please change it to "FactionList", the old variable is not used.')
        end
        if not rawget(FactionFile, 'FactionList') then
            continue
        end

        for s, t in FactionFile.FactionList do
            if type(t) == 'table' then
                if t.ModsPrerequisite and (type(t.ModsPrerequisite) ~= 'table' or not TableHasKeys(SelectedMods, t.ModsPrerequisite)) then
                    continue
                end
                t['IsCustomFaction'] = true
                table.insert(FactionsTable, t)
                NewFactionAiData[t.Key] = t.AI or {}
            end
        end
    end
    return FactionsTable
end

function GetSelectedMods(AllowedMods)
    -- We need an array with it's keys being mod uids and the values being true. but this function can be called
    -- while loading the game which means /lua/mods.lua.GetSelectedMods() doesn't work. In that case we look in
    -- the global var __active_mods and get the mod uids from that table.
    local mods = {}
    if __modules['/lua/ui/dialogs/modmanager.lua'] or __modules['/lua/ui/campaign/campaignmanager.lua'] then
        -- Detect if we're in the main menu or loading the game
        mods = import("/lua/mods.lua").GetSelectedMods()
    elseif rawget(_G, '__active_mods') and not table.empty(__active_mods) then
        for k, mod in __active_mods do
            mods[mod.uid] = true
        end
    end
    if AllowedMods then  -- AllowedMods -> table of mods keyed by mod id
        local newmods = {}
        for id,_ in mods do
            if AllowedMods[id] then
                newmods[id] = true
            end
        end
        mods = newmods
    end
    return mods
end

function TableHasKeys(tbl, keys)
    for _, k in keys do
        if not tbl[k] then
            return false
        end
    end
    return true
end

function OrgFactions()
    return {
    {
        Key = 'uef',
        Category = 'UEF',
        FactionInUnitBp = 'UEF',
        IsCustomFaction = false,
        DisplayName = "<LOC _UEF>UEF",
        SoundPrefix = 'UEF',
        InitialUnit = 'uel0001',
        CampaignFileDesignator = 'E',
        TransmissionLogColor = 'ff00c1ff',
        Icon = "/widgets/faction-icons-alpha_bmp/uef_ico.dds",
        VeteranIcon = "/game/veteran-logo_bmp/uef-veteran_bmp.dds",
        SmallIcon = "/faction_icon-sm/uef_ico.dds",
        LargeIcon = "/faction_icon-lg/uef_ico.dds",
        TooltipID = 'lob_uef',
        DefaultSkin = 'uef',
        loadingMovie = '/movies/UEF_load.sfd',
        loadingColor = 'FFbadbdb',
        loadingTexture = '/UEF_load.dds',
        IdleEngTextures = {
            T1 = '/icons/units/uel0105_icon.dds',
            T2 = '/icons/units/uel0208_icon.dds',
            T2F = '/icons/units/xel0209_icon.dds',
            T3 = '/icons/units/uel0309_icon.dds',
            SCU = '/icons/units/uel0301_icon.dds',
        },
        IdleFactoryTextures = {
            LAND = {
                '/icons/units/ueb0101_icon.dds',
                '/icons/units/ueb0201_icon.dds',
                '/icons/units/ueb0301_icon.dds',
            },
            AIR = {
                '/icons/units/ueb0102_icon.dds',
                '/icons/units/ueb0202_icon.dds',
                '/icons/units/ueb0302_icon.dds',
            },
            NAVAL = {
                '/icons/units/ueb0103_icon.dds',
                '/icons/units/ueb0203_icon.dds',
                '/icons/units/ueb0303_icon.dds',
            },
        },

        GAZ_UI_Info = {
            BuildingIdPrefixes = {
                'ueb',
                'xeb',
                'deb',
                'zeb',
            },
        },
    },
    {
        Key = 'aeon',
        Category = 'AEON',
        FactionInUnitBp = 'Aeon',
        IsCustomFaction = false,
        DisplayName = "<LOC _Aeon>Aeon",
        SoundPrefix = 'Aeon',
        InitialUnit = 'ual0001',
        CampaignFileDesignator = 'A',
        TransmissionLogColor = 'ffff0000',
        Icon = "/widgets/faction-icons-alpha_bmp/aeon_ico.dds",
        VeteranIcon = "/game/veteran-logo_bmp/aeon-veteran_bmp.dds",
        SmallIcon = "/faction_icon-sm/aeon_ico.dds",
        LargeIcon = "/faction_icon-lg/aeon_ico.dds",
        TooltipID = 'lob_aeon',
        DefaultSkin = 'aeon',
        loadingMovie = '/movies/aeon_load.sfd',
        loadingColor = 'FFc7e98a',
        loadingTexture = '/aeon_load.dds',
        IdleEngTextures = {
            T1 = '/icons/units/ual0105_icon.dds',
            T2 = '/icons/units/ual0208_icon.dds',
            T2F = '/icons/units/xel0209_icon.dds',
            T3 = '/icons/units/ual0309_icon.dds',
            SCU = '/icons/units/ual0301_icon.dds',
        },
        IdleFactoryTextures = {
            LAND = {
                '/icons/units/uab0101_icon.dds',
                '/icons/units/uab0201_icon.dds',
                '/icons/units/uab0301_icon.dds',
            },
            AIR = {
                '/icons/units/uab0102_icon.dds',
                '/icons/units/uab0202_icon.dds',
                '/icons/units/uab0302_icon.dds',
            },
            NAVAL = {
                '/icons/units/uab0103_icon.dds',
                '/icons/units/uab0203_icon.dds',
                '/icons/units/uab0303_icon.dds',
            },
        },

        GAZ_UI_Info = {
            BuildingIdPrefixes = {
                'uab',
                'xab',
                'dab',
                'zab',
            },
        },
    },
    {
        Key = 'cybran',
        Category = 'CYBRAN',
        FactionInUnitBp = 'Cybran',
        IsCustomFaction = false,
        DisplayName = "<LOC _Cybran>Cybran",
        SoundPrefix = 'Cybran',
        InitialUnit = 'url0001',
        CampaignFileDesignator = 'R',
        TransmissionLogColor = 'ff89d300',
        Icon = "/widgets/faction-icons-alpha_bmp/cybran_ico.dds",
        VeteranIcon = "/game/veteran-logo_bmp/cybran-veteran_bmp.dds",
        SmallIcon = "/faction_icon-sm/cybran_ico.dds",
        LargeIcon = "/faction_icon-lg/cybran_ico.dds",
        TooltipID = 'lob_cybran',
        DefaultSkin = 'cybran',
        loadingMovie = '/movies/cybran_load.sfd',
        loadingColor = 'FFe24f2d',
        loadingTexture = '/cybran_load.dds',
        IdleEngTextures = {
            T1 = '/icons/units/url0105_icon.dds',
            T2 = '/icons/units/url0208_icon.dds',
            T2F = '/icons/units/xel0209_icon.dds',
            T3 = '/icons/units/url0309_icon.dds',
            SCU = '/icons/units/url0301_icon.dds',
        },
        IdleFactoryTextures = {
            LAND = {
                '/icons/units/urb0101_icon.dds',
                '/icons/units/urb0201_icon.dds',
                '/icons/units/urb0301_icon.dds',
            },
            AIR = {
                '/icons/units/urb0102_icon.dds',
                '/icons/units/urb0202_icon.dds',
                '/icons/units/urb0302_icon.dds',
            },
            NAVAL = {
                '/icons/units/urb0103_icon.dds',
                '/icons/units/urb0203_icon.dds',
                '/icons/units/urb0303_icon.dds',
            },
        },

        GAZ_UI_Info = {
            BuildingIdPrefixes = {
                'urb',
                'xrb',
                'drb',
                'zrb',
            },
        },
    },
    {
        Key = 'seraphim',
        Category = 'SERAPHIM',
        FactionInUnitBp = 'Seraphim',
        IsCustomFaction = false,
        DisplayName = "<LOC _Seraphim>Seraphim",
        SoundPrefix = 'Seraphim',
        InitialUnit = 'xsl0001',
        CampaignFileDesignator = 'S',
        TransmissionLogColor = 'ff00FF00',
        Icon = "/widgets/faction-icons-alpha_bmp/seraphim_ico.dds",
        VeteranIcon = "/game/veteran-logo_bmp/seraphim-veteran_bmp.dds",
        SmallIcon = "/faction_icon-sm/seraphim_ico.dds",
        LargeIcon = "/faction_icon-lg/seraphim_ico.dds",
        TooltipID = 'lob_seraphim',
        DefaultSkin = 'seraphim',
        loadingMovie = '/movies/seraphim_load.sfd',
        loadingColor = 'FFffd700',
        loadingTexture = '/seraphim_load.dds',
        IdleEngTextures = {
            T1 = '/icons/units/xsl0105_icon.dds',
            T2 = '/icons/units/xsl0208_icon.dds',
            T2F = '/icons/units/xel0209_icon.dds',
            T3 = '/icons/units/xsl0309_icon.dds',
            SCU = '/icons/units/xsl0301_icon.dds',
        },
        IdleFactoryTextures = {
            LAND = {
                '/icons/units/xsb0101_icon.dds',
                '/icons/units/xsb0201_icon.dds',
                '/icons/units/xsb0301_icon.dds',
            },
            AIR = {
                '/icons/units/xsb0102_icon.dds',
                '/icons/units/xsb0202_icon.dds',
                '/icons/units/xsb0302_icon.dds',
            },
            NAVAL = {
                '/icons/units/xsb0103_icon.dds',
                '/icons/units/xsb0203_icon.dds',
                '/icons/units/xsb0303_icon.dds',
            },
        },

        GAZ_UI_Info = {
            BuildingIdPrefixes = {
                'xsb',
                'usb',
                'dsb',
                'zsb',
            },
        },
    },
}
end

-- ----------------------------------------------------------------------------------------------------------------
-- Original faction variables

Factions = GetFactions()

-- Map faction key to index, as this lookup is done frequently
FactionIndexMap = {}

-- File designator to faction key
FactionDesToKey = {}

FactionInUnitBpToKey = {}

for index, value in Factions do
    FactionIndexMap[value.Key] = index
    FactionDesToKey[value.CampaignFileDesignator] = value.Key
    FactionInUnitBpToKey[value.FactionInUnitBp] = index
end
