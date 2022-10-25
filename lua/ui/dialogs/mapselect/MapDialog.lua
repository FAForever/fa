
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local UIUtil = import('/lua/ui/uiutil.lua')

local Group = import('/lua/maui/group.lua').Group
local EventEmitter = import('/lua/ui/common/EventEmitter.lua').EventEmitter
local UIBorder = import('/lua/ui/common/Border.lua').UIBorder

---@type MapDialog
local Root = nil
local DebugInterface = false

---@alias UIMapMetaType 'skirmish' | 'campaign_coop'

---@class UIMapMetaSize
---@field [1] number    # horizontal size
---@field [2] number    # vertical size

---@class UIMapMetaReclaim
---@field [1] number    # mass value
---@field [2] number    # energy value

---@class UIMapMetaScenario
---@field name string
---@field description string 
---@field preview FileName 
---@field map_version number
---@field type UIMapMetaType
---@field starts boolean 
---@field size UIMapMetaSize
---@field reclaim UIMapMetaReclaim
---@field map FileName
---@field save FileName 
---@field script FileName
---@field Configurations table

---@class UIMapMeta
---@field version number
---@field file FileName
---@field ScenarioInfo UIMapMetaScenario
---@field error? string

---@alias MapDialogEvents 'EventLoadingMaps' | 'EventMapsLoaded'

---@type EventEmitter
local MapDialogEventEmitter = EventEmitter()

---@class MapList : Group
MapList = Class(Group) {

    ---@param self MapList
    __init = function(self, parent)
        Group.__init(self, parent)

        -- register for events
        MapDialogEventEmitter:OnEvent(self, 'EventLoadingMaps')
        MapDialogEventEmitter:OnEvent(self, 'EventMapsLoaded')
    end,

    EventLoadingMaps = function(self)
        LOG("EventLoadingMaps")
    end,

    EventMapsLoaded = function(self, data)
        LOG("EventMapsLoaded")
    end,
}

---@class MapDialog : Group, EventEmitter, UIBorder
---@field Maps UIMapMeta[]
---@field InvalidMaps UIMapMeta[]
MapDialog = Class(Group, UIBorder) {

    ---@param self MapDialog
    ---@param parent Control
    __init = function(self, parent)
        Group.__init(self, parent, 'MapDialog')
        UIBorder.__init(self)

        -- setup state

        self.Maps = { }
        self.InvalidMaps = { }

        -- give ourself some dimensions
        self.Left:Set(200)
        self.Right:Set(1000)
        self.Top:Set(200)
        self.Bottom:Set(1000)
        self.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)



        local debug = Bitmap(self)
        LayoutHelpers.FillParent(debug, self)
        debug:SetSolidColor('ffffff')
    end,

    Setup = function (self)
        self.MapList = MapList(self)
    end,

    ---@param self MapDialog
    ---@param file FileName
    ---@return UIMapMeta
    LoadMapMetaData = function(self, file)
        -- attempt to load in the scenario file
        local scenario = {}
        doscript('/lua/dataInit.lua', scenario)
        doscript(file, scenario)

        scenario.file = file
        return scenario
    end,

    ---@param self MapDialog
    ---@param meta UIMapMeta
    ---@return boolean
    ---@return string?
    CheckMapMetaData = function(self, meta)

        if not DiskGetFileInfo(meta.ScenarioInfo.save) then
            return false, 'Missing save file'
        end

        if not DiskGetFileInfo(meta.ScenarioInfo.script) then
            return false, 'Missing script file'
        end

        if not DiskGetFileInfo(meta.ScenarioInfo.map) then
            return false, 'Missing scmap file'
        end

        return true
    end,

    ---@param self MapDialog
    LoadMaps = function(self)
        ForkThread(self.LoadMapsThread, self)
    end,

    LoadMap = function(self, file)
        local meta = self:LoadMapMetaData(file)
        local ok, msg = self:CheckMapMetaData(meta)
        if ok then 
            table.insert(self.Maps, meta)
        else 
            meta.error = msg
            table.insert(self.InvalidMaps, meta)
        end
    end,

    ---@param self MapDialog
    LoadMapsThread = function(self)
        MapDialogEventEmitter:EmitEvent('EventLoadingMaps')

        self.Maps = { }
        self.InvalidMaps = { }
        local files = DiskFindFiles('/maps', '*_scenario.lua')
        for k, file in files do
            local ok, msg = pcall(self.LoadMap, self, file)
            if not ok then 
                WARN(msg)
            end
            WaitFrames(1)
        end

        MapDialogEventEmitter:EmitEvent('EventMapsLoaded', {
            Maps = self.Maps,
            InvalidMaps = self.InvalidMaps
        })
    end,
}

---@param parent Control
---@param callbackOk function<string, table<string, string>, any>   -- called when ok                       -> acquires focus back to lobby text box, updates the lobby
---@param callbackCancel function()                                 -- called when cancelled                -> acquires focus back to lobby text box
---@param callbackModsChanged function()                            -- called when mods have been changed   -> informs all other players that mods have been adjusted
---@param singlePlayer boolean                                      -- whether we are in single player or not
---@param defaultScenarioName string                                -- name of the selected scenario
---@param curOptions table<string, string>                          -- for each option, the key / value pair
---@param availableMods table<number, table<string, boolean>>       -- for each player, list of mod identifiers that are available
function OpenWindow(parent, callbackOk, callbackCancel, callbackModsChanged, singlePlayer, defaultScenarioName, curOptions, availableMods)
    if not Root then 
        Root = MapDialog(GetFrame(0))
    end
    
    Root:Setup()
    Root:LoadMaps()
end

function CloseWindow()

end

--- Called by the module manager when this module is dirty due to a disk change
function __moduleinfo.OnDirty()
    if Root then
        Root:Destroy()
    end
end