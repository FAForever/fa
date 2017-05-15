-- A set of mod uids we don't approve of, and explanations for why we don't like them.

local INCOMPATIBLE = "<LOC uimod_0021>Incompatible with current FAF"
local UPGRADE = "<LOC uimod_0022>Please update to newest version"
local INTEGRATED = "<LOC uimod_0023>Integrated with FAF"
local BROKEN = "<LOC uimod_0024>Broken"
local OBSOLETE = "<LOC uimod_0025>Obsolete"
local HARMFUL = "<LOC uimod_0026>Considered harmful"

Blacklist = {
-- Harmful --
    ['C707618F-D9B3-43CE-A181-1AC80D582078'] = HARMFUL, -- PWN Desync
    ['EF3ADDB4-9D34-437F-B1C8-440DAF896802'] = HARMFUL, -- UI Mass Fab Manager FA by Goom (Causes UI lag because it uses polling rather than interrupts)
    ['b2cde810-15d0-4bfa-af66-ec2d6ecd561d'] = HARMFUL, -- UI Idle Engineers by camelCase (Causes UI lag because it uses polling rather than interrupts)

    -- Auto-adjust netlag (causes desyncs due to interesting race conditions).
    ['9033139e-2701-4ac1-b330-ec984ebc23f9'] = HARMFUL,
    ['xxxx-NetFag-Experimental-v2'] = HARMFUL,
    ['xxxx-NetLag-Experimental-v1'] = HARMFUL,
    ['xxxx-NetLag-Experimental-v2'] = HARMFUL,
    ['xxxx-NetLag-Experimental-v3'] = HARMFUL,

-- Broken --
    ['ce6f9860-d2d2-11e0-9572-0800200c9a66'] = BROKEN, -- Experimental Wars

-- Obselete --

    -- XINNONY TRY FIX CORRECT DISCONNECT
    ['9B308860-AFD9-11E3-A5E2-0800200C9A66'] = OBSOLETE,
    ['9B308860-AFD9-11E3-A5E2-0800200C9A67'] = OBSOLETE,
    ['FF84A3CA-AD2B-4CA8-98D9-ED0581467152'] = OBSOLETE,
    ['56EF9738-2F96-4941-90B9-DDDDFAC50D05'] = OBSOLETE,
    ['56EF9738-2F96-4941-90B9-DDDDFAC50D06'] = OBSOLETE,

 -- Integrated --
    -- UI Lagfix (everything interesting from it is merged)
    ['9cef4ff7-eccd-4d2d-bee7-cbc7bce0de38'] = INTEGRATED,
    ['2a022e6d-1ceb-4353-a8c5-4cd65709bc33'] = INTEGRATED,

    -- Hotbuild (already merged)
    ['f8785b7a-9e9e-4863-abb3-46aaf1caef80'] = INTEGRATED,
    ['98785b7a-9e9e-4863-abb3-46aaf1caef80'] = INTEGRATED,

    -- GAZ_UI (already merged)
    ['4f8b5ac3-346c-4d25-ac34-7b8ccc14eb0a'] = INTEGRATED,
    ['CC5A5288-18E3-11DD-BF33-005055D89593'] = INTEGRATED,
    ['e9bb4b11-2952-4b19-bf4e-11fb6e5fcbe9'] = INTEGRATED,
    ['CC5A5288-18E3-11DD-BF33-005055D89593'] = INTEGRATED,
    ['e9bb4b11-2952-4b19-bf4e-11fe6e5fcbe9'] = INTEGRATED,
    ['CC5A5288-18E3-11DD-BF33-005055D89593'] = INTEGRATED,
    ['e9bb4b11-2952-4b19-bf4e-11fb6e5fcbe9'] = INTEGRATED,

    -- MoreUnitInfo
    ['CC51528A-1823-113D-BF33-044655D89593'] = INTEGRATED,
    ['9B5F858A-163C-4AF1-B846-A884572E61A4'] = INTEGRATED,

    -- Enhanced chat legibility (we merged it)
    ['11c903ef-f42f-49fe-933a-425de3944d20'] = INTEGRATED,
    ['9aa24bb2-1f63-4f77-8292-4aaf5414cdb2'] = INTEGRATED,

    -- AZUI (Merged)
    ['8c5dc7d0-4fa4-11dd-ae16-0800200c9a66'] = INTEGRATED,

    -- Selection Sort
    ['cfe9131e-9324-4753-a9ca-46972127fe8c'] = INTEGRATED,
    ['cfe9131e-9324-4753-a9ca-46972127fe8b'] = INTEGRATED,

    -- Hotkey Labels
    ['e338e34e-58da-11e6-8b77-86f30ca893d3'] = INTEGRATED,

    -- INTEGRATED mods due to added preset restrictions in Units Manager:
    -- No TML v1.0
    ['63472293-f7d7-4b77-ba7b-d04ad09f63de'] = INTEGRATED,
    -- No Tactical Missile Launchers v1.0
    ['922b87a0-31b9-12dd-bd11-0800200c9a66'] = INTEGRATED,
    -- No Mobile Missile Launchers v1.0
    ['dcdbdbcb-b5f1-4828-9298-dca2f4f17a9a'] = INTEGRATED,
    -- No MML v1.0
    ['bcd271f7-92a4-4b8b-b0c3-ec20189f7663'] = INTEGRATED,
    -- No Heavy Art v1.0
    ['ffeca075-c0cd-4355-861b-0bb29c75af10'] = INTEGRATED,
    -- No T3 Mobile Anti-Air units v5.0
    ['ba3d087d-ceb7-495a-b606-3e1593750a5d'] = INTEGRATED,
    -- No Strategic Missile Launchers v1.0
    ['9-22b87a0-31c9-12dd-bd11-4583459c9a66'] = INTEGRATED,
    -- No Mexes
    ['58a524e0-8143-479a-b38f-4e4513b84cd8'] = INTEGRATED,

 -- Upgrade --
    -- Ally overflow (old, broken versions)
    ['ecbf6277-24e3-437a-b968-AllyOverflow-v1'] = UPGRADE,
    ['ecbf6277-24e3-437a-b968-AllyOverflow-v2'] = UPGRADE,
    ['ecbf6277-24e3-437a-b968-AllyOverflow-v3'] = UPGRADE,
    ['ecbf6277-24e3-437a-b968-AllyOverflow-v4'] = UPGRADE,
    ['ecbf6277-24e3-437a-b968-AllyOverflow-v5'] = UPGRADE,
    ['ecbf6277-24e3-437a-b968-AllyOverflow-v6'] = UPGRADE,

    -- Ecomanager (old, broken versions thereof)
    ['e6d78791-dac8-4f5a-bf86-87e1f91f6122'] = UPGRADE,
    ['ecbf6277-24e3-437a-b968-75e7e7c67db9'] = UPGRADE,
    ['b2cde810-15d0-4bfa-af66-ec2d6ecd561b'] = UPGRADE,
    ['ecbf6277-24e3-437a-b968-EcoManager-v4'] = UPGRADE,
    ['ecbf6277-24e3-437a-b968-EcoManager-v5'] = UPGRADE,
    ['ecbf6277-24e3-437a-b968-EcoManager-v6'] = UPGRADE,
    ['ecbf6277-24e3-437a-b968-EcoManager-v7'] = UPGRADE,

    -- Nofity (Old broken ones)
    ['3d098ad8-adb1-4c5d-8daa-a42418274de2'] = UPGRADE,
    ['aa5655fa-7ea0-4e3e-81b7-75695c2df6c9'] = UPGRADE,
    ['92f87e13-813c-4585-80d3-f8adbc4a00be'] = UPGRADE,
    ['b943ea7c-cdbd-40ef-9f9a-9d04b3cb122d'] = UPGRADE,
    ['65283e07-a667-4163-9b2c-cc46ad28d5e6'] = UPGRADE,
    ['20cc4f02-e4ec-4399-8ab8-35e7f40f1f77'] = UPGRADE,
    ['7e6da3ed-8399-45ea-b50a-01a2e5f7483c'] = UPGRADE,
    ['b83ac057-cf56-40d7-b5e4-376dd45422b6'] = UPGRADE,
    ['96333e77-7a0c-4627-a802-d2e9692843bb'] = UPGRADE,
    ['4767b4d5-e74e-489a-8542-3e993dd452b3'] = UPGRADE,
    ['3501ac36-6f32-4299-9bdb-e323f37a55a2'] = UPGRADE,

    -- Supreme economy (old ones)
    ['f8d8c95a-71e7-4978-921e-8765beb328e8'] = UPGRADE,
    ['89BF1572-9EA8-11DC-1313-635F56D89591'] = UPGRADE,

    -- rks explosions
    ['7749EEA3-DE86-5CC2-39AC-35672BDE74DD'] = UPGRADE,
    ['7749EEA3-DE86-5CC2-39AC-35672BDE74DF'] = UPGRADE,
    ['7749EEA3-DE86-5CC2-39AC-35672BDE74DG'] = UPGRADE,
    ['7749EEA3-DE86-5CC2-39AC-35672BDE76DG'] = UPGRADE,
    ['7749EEA5-DE86-5CC2-39AC-35672BDE76DG'] = UPGRADE,
    ['7749EEN4-DE86-5CC2-39AC-35672BDE76DG'] = UPGRADE,
    ['7749EEN4-DE86-5CC2-39AC-35692BDE76XF'] = UPGRADE,
    ['1749EEN4-DE86-5CC2-39AC-35692BDE76XF'] = UPGRADE,
    ['EEFFA8C6-96D9-11E4-9DA1-460D1D5D46B0'] = UPGRADE,
    
    -- OneClickWonder
    ['c5cc7241-d9f8-4b46-8662-ad130e426a4a'] = UPGRADE,
    
    ['12345678-3343-4bf6-9236-451244fa9999'] = BROKEN,
    ['4f8b5ac3-346c-4d25-ac34-7b8ccc14eb0a'] = OBSOLETE,
    
    ['D49b27d4-7252-42b8-b39e-ac04cc195adb'] = INCOMPATIBLE,
    ['728e8d44-98e9-11e5-8994-feff819cdc9f'] = INCOMPATIBLE,
    ['55394440-5DC8-11E3-91ED-66546288709B'] = INCOMPATIBLE,
    ['5048d937-4872-4e86-9f09-dd1806a0629c'] = INCOMPATIBLE,
    ['2bc59538-fc2c-4a18-964b-85322e9562a2'] = INCOMPATIBLE,
    ['022E3DB4-9C00-4ED7-9876-4866D316E009'] = INCOMPATIBLE,
}
