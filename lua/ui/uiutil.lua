 --*****************************************************************************
--* File: lua/modules/ui/uiutil.lua
--* Author: Chris Blackwell
--* Summary: Various utility functions to make UI scripts easier and more consistent
--*
--* Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local LazyVar = import("/lua/lazyvar.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Text = import("/lua/maui/text.lua").Text
local MultiLineText = import("/lua/maui/multilinetext.lua").MultiLineText
local Button = import("/lua/maui/button.lua").Button
local Edit = import("/lua/maui/edit.lua").Edit
local Checkbox = import("/lua/ui/controls/checkbox.lua").Checkbox
local RadioButtons = import("/lua/maui/radiobuttons.lua").RadioButtons
local Scrollbar = import("/lua/maui/scrollbar.lua").Scrollbar
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local Cursor = import("/lua/maui/cursor.lua").Cursor
local Prefs = import("/lua/user/prefs.lua")
local Border = import("/lua/ui/controls/border.lua").Border
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Layouts = import("/lua/skins/layouts.lua")
local Popup = import("/lua/ui/controls/popups/popup.lua").Popup
local NinePatch = import("/lua/ui/controls/ninepatch.lua").NinePatch
local InputDialog = import("/lua/ui/controls/popups/inputdialog.lua").InputDialog
local skins = import("/lua/skins/skins.lua").skins

local Layouter = LayoutHelpers.LayoutFor


--* Handy global variables to assist skinning
buttonFont = LazyVar.Create()            -- default font used for button faces
factionFont = LazyVar.Create()      -- default font used for dialog button faces
dialogButtonFont = LazyVar.Create()      -- default font used for dialog button faces
bodyFont = LazyVar.Create()              -- font used for all other text
fixedFont = LazyVar.Create()             -- font used for fixed width characters
titleFont = LazyVar.Create()             -- font used for titles and labels
fontColor = LazyVar.Create()             -- common font color
fontOverColor = LazyVar.Create()             -- common font color
fontDownColor = LazyVar.Create()             -- common font color
tooltipTitleColor = LazyVar.Create()             -- common font color
tooltipBorderColor = LazyVar.Create()             -- common font color
bodyColor = LazyVar.Create()             -- common color for dialog body text
dialogCaptionColor = LazyVar.Create()    -- common color for dialog titles
dialogColumnColor = LazyVar.Create()     -- common color for column headers in a dialog
dialogButtonColor = LazyVar.Create()     -- common color for buttons in a dialog
highlightColor = LazyVar.Create()        -- text highlight color
disabledColor = LazyVar.Create()         -- text disabled color
panelColor = LazyVar.Create()            -- default color when drawing a panel
transparentPanelColor = LazyVar.Create() -- default color when drawing a transparent panel
consoleBGColor = LazyVar.Create()        -- console background color
consoleFGColor = LazyVar.Create()        -- console foreground color (text)
consoleTextBGColor = LazyVar.Create()    -- console text background color
menuFontSize = LazyVar.Create()          -- font size used on main in game escape menu
factionTextColor = LazyVar.Create()      -- faction color for text foreground
factionBackColor = LazyVar.Create()      -- faction color for text background

-- table of layouts supported by this skin, not a lazy var as we don't need updates
layouts = nil

--* other handy variables!
consoleDepth = false  -- in order to get the console to always be on top, assign this number and never go over

networkBool = LazyVar.Create()    -- boolean whether the game is local or networked

-- Default scenario for skirmishes / MP Lobby
defaultScenario = '/maps/scmp_039/scmp_039_scenario.lua'
requiredType = 'skirmish'

--* These values MUST NOT CHANGE! They syncronize with values in UIManager.h and are used to
--* specify a render pass
-- render before the world is rendered
UIRP_UnderWorld     = 1
-- reserved for world views
UIRP_World          = 2
-- render with glow (note, won't render when world isn't visible)
UIRP_Glow           = 4
-- render without glow
UIRP_PostGlow       = 8

--* useful key codes, weirdly inconsistent, some are MSW vk codes, some are wxW codes :(
VK_BACKSPACE = 8
VK_TAB = 9
VK_ENTER = 13
VK_ESCAPE = 27
VK_SPACE = 32
VK_PRIOR = 33
VK_NEXT = 34
VK_UP = 38
VK_DOWN = 40
VK_PAUSE = 310

local currentSkin = LazyVar.Create()

currentLayout = false
changeLayoutFunction = false    -- set this function to get called with the new layout name when layout changes

local UIFileCache = {}
-- The files below are missing from the game and are used to leave UIFile early
local UIFileBlacklist = {
    ['/icons/units/opc1001_icon.dds'] = true,
    ['/icons/units/opc1002_icon.dds'] = true,
    ['/icons/units/opc2001_icon.dds'] = true,
    ['/icons/units/opc5007_icon.dds'] = true,
    ['/icons/units/opc5008_icon.dds'] = true,
    ['/icons/units/ope2001_icon.dds'] = true,
    ['/icons/units/ope2002_icon.dds'] = true,
    ['/icons/units/ope6002_icon.dds'] = true,
    ['/icons/units/ope6004_icon.dds'] = true,
    ['/icons/units/ope6005_icon.dds'] = true,
    ['/icons/units/ope6006_icon.dds'] = true,
    ['/icons/units/uab5204_icon.dds'] = true,
    ['/icons/units/uac1902_icon.dds'] = true,
    ['/icons/units/xsc9011_icon.dds'] = true,
    ['/icons/units/xsc9010_icon.dds'] = true,
    ['/icons/units/xsc8020_icon.dds'] = true,
    ['/icons/units/xsc8019_icon.dds'] = true,
    ['/icons/units/xsc8018_icon.dds'] = true,
    ['/icons/units/xsc8017_icon.dds'] = true,
    ['/icons/units/xsc8016_icon.dds'] = true,
    ['/icons/units/xsc8015_icon.dds'] = true,
    ['/icons/units/xsc8014_icon.dds'] = true,
    ['/icons/units/xsc8013_icon.dds'] = true,
    ['/icons/units/xsc1601_icon.dds'] = true,
    ['/icons/units/xsc1701_icon.dds'] = true,
    ['/icons/units/xro4001_icon.dds'] = true,
    ['/icons/units/xrc2401_icon.dds'] = true,
    ['/icons/units/xrc2301_icon.dds'] = true,
    ['/icons/units/xrc2101_icon.dds'] = true,
    ['/icons/units/xec9011_icon.dds'] = true,
    ['/icons/units/xec9010_icon.dds'] = true,
    ['/icons/units/xec9009_icon.dds'] = true,
    ['/icons/units/xec9008_icon.dds'] = true,
    ['/icons/units/xec9007_icon.dds'] = true,
    ['/icons/units/xec9006_icon.dds'] = true,
    ['/icons/units/xec9005_icon.dds'] = true,
    ['/icons/units/xec9002_icon.dds'] = true,
    ['/icons/units/xec9001_icon.dds'] = true,
    ['/icons/units/xec9003_icon.dds'] = true,
    ['/icons/units/xec1909_icon.dds'] = true,
    ['/icons/units/xec1908_icon.dds'] = true,
    ['/icons/units/xec9004_icon.dds'] = true,
    ['/icons/units/xac8103_icon.dds'] = true,
    ['/icons/units/xac8102_icon.dds'] = true,
    ['/icons/units/xac8101_icon.dds'] = true,
    ['/icons/units/xac8003_icon.dds'] = true,
    ['/icons/units/xac8002_icon.dds'] = true,
    ['/icons/units/xac2301_icon.dds'] = true,
    ['/icons/units/xac8001_icon.dds'] = true,
    ['/icons/units/uxl0021_icon.dds'] = true,
    ['/icons/units/urb5206_icon.dds'] = true,
    ['/icons/units/urb5204_icon.dds'] = true,
    ['/icons/units/urb3103_icon.dds'] = true,
    ['/icons/units/hel0001_icon.dds'] = true,
    ['/icons/units/ueb5204_icon.dds'] = true,
    ['/icons/units/ueb5208_icon.dds'] = true
}

--- Layout control, sets current layout preference
---@param layout string
function SetCurrentLayout(layout)
    if not layout then return end
    -- make sure this skin contains the layout, otherwise do nothing
    local foundLayout = false
    for index, complayout in layouts do
        if layout == complayout then
            foundLayout = true
            break
        end
    end
    if not foundLayout then return end

    currentLayout = layout
    Prefs.SetToCurrentProfile("layout", layout)
    SelectUnits(nil)
    if changeLayoutFunction then changeLayoutFunction(layout) end
end

---@return boolean network
---@return boolean session
function GetNetworkBool()
    local sessionClientsTable = GetSessionClients()
    local networkBool = false
    local sessionBool = true
    if sessionClientsTable ~= nil then
        networkBool = SessionIsMultiplayer()
    else
        sessionBool = false
    end
    return networkBool, sessionBool
end

---@return true
function GetAnimationPrefs()
    return true
end

---@param key string
---@return FileName | false
function GetLayoutFilename(key)
    if Layouts[currentLayout][key] then
        return Layouts[currentLayout][key]
    else
        WARN('No layout file for \'', key, '\' in the current layout. Expect layout errors.')
        return false
    end
end

---@param skin Skin
---@param isOn? boolean defaults to user preference `"world_border"`
function UpdateWorldBorderState(skin, isOn)
    if skin == nil then
        skin = currentSkin()
    end

    if SessionIsActive() then
        if isOn == nil then
            isOn = Prefs.GetOption('world_border')
        end
        if isOn then
            local skins = import("/lua/skins/skins.lua").skins
            if skins[skin].imagerMesh then
                MapBorderClear()
                --Set the world mesh to the skins world mesh
                local size = SessionGetScenarioInfo().size
                local mapWidth = size[1]
                local mapHeight = size[2]

                -- The meshes used here are, due to limitations of native code, only capable of
                -- scaling preserving aspect ratio.
                -- GPG forgot to include one for tall-thin maps, but here we make optimal use of the
                -- two they did give us :/
                if mapWidth == mapHeight * 2 then
                    -- Wide maps
                    MapBorderAdd(skins[skin].imagerMeshHorz)
                    if skins[skin].imagerMeshDetailsHorz then
                        MapBorderAdd(skins[skin].imagerMeshDetailsHorz)
                    end
                elseif mapWidth == mapHeight then
                    -- Squares
                    MapBorderAdd(skins[skin].imagerMesh)
                    if skins[skin].imagerMeshDetails then
                        MapBorderAdd(skins[skin].imagerMeshDetails)
                    end
                elseif mapHeight == mapWidth * 2 then
                   -- TODO: Someone please make a mesh for this case.
                end
            end
        else
            MapBorderClear()
        end
    end
end

---@alias Skin "random" | "uef" | "cybran" | "aeon" | "seraphim"

local currentSkinName = "random"
--- Gets name of current skin that changes when calling SetCurrentSkin()
---@return Skin
function GetCurrentSkinName()
    return currentSkinName
end

--- Sets the current skin table
---@param skin Skin
---@param overrideTable table
function SetCurrentSkin(skin, overrideTable)
    local skinTable = skins[skin]
    if not skinTable then
        if skin == "random" then
            local randomSkin = {}
            local count = 0
            for skinName in skins do
                count = count + 1
                randomSkin[count] = skinName
            end
            skin = randomSkin[Random(1, count)]
        else
            skin = "uef"
        end
        skinTable = skins[skin]
    end

    currentSkinName = skin -- updating name of current skin
    currentSkin:Set(skin)

    tooltipTitleColor:Set(skinTable.tooltipTitleColor)
    tooltipBorderColor:Set(skinTable.tooltipBorderColor)
    buttonFont:Set(skinTable.buttonFont)
    factionFont:Set(skinTable.factionFont)
    dialogButtonFont:Set(skinTable.dialogButtonFont)
    bodyFont:Set(skinTable.bodyFont)
    fixedFont:Set(skinTable.fixedFont)
    titleFont:Set(skinTable.titleFont)
    bodyColor:Set(skinTable.bodyColor)
    factionTextColor:Set(skinTable.factionTextColor)
    factionBackColor:Set(skinTable.factionBackColor)
    if (overrideTable.faction_font_color == nil and Prefs.GetOption('faction_font_color')) or overrideTable.faction_font_color then
        fontColor:Set(skinTable.fontColor)
    else
        fontColor:Set(skins["default"].fontColor)
    end
    fontOverColor:Set(skinTable.fontOverColor)
    fontDownColor:Set(skinTable.fontDownColor)
    dialogCaptionColor:Set(skinTable.dialogCaptionColor)
    dialogColumnColor:Set(skinTable.dialogColumnColor)
    dialogButtonColor:Set(skinTable.dialogButtonColor)
    highlightColor:Set(skinTable.highlightColor)
    disabledColor:Set(skinTable.disabledColor)
    panelColor:Set(skinTable.panelColor)
    transparentPanelColor:Set(skinTable.transparentPanelColor)
    consoleBGColor:Set(skinTable.consoleBGColor)
    consoleFGColor:Set(skinTable.consoleFGColor)
    consoleTextBGColor:Set(skinTable.consoleTextBGColor)
    menuFontSize:Set(skinTable.menuFontSize)
    layouts = skinTable.layouts

    UpdateWorldBorderState(skin)

    local curLayout = Prefs.GetFromCurrentProfile("layout")

    if not curLayout then
        SetCurrentLayout(layouts[1])
    else
        local validLayout = false
        for i, layoutName in layouts do
            if layoutName == curLayout then
                validLayout = true
                break
            end
        end
        if validLayout then
            SetCurrentLayout(curLayout)
        else
            SetCurrentLayout(layouts[1])
        end
    end

    Prefs.SetToCurrentProfile("skin", skin)
end

function UpdateCurrentSkin(overrideTable)
    SetCurrentSkin(currentSkin(), overrideTable)
end

--- Cycles through all available skins
---@param direction? "+" | "-"
function RotateSkin(direction)
    if not SessionIsActive() or import("/lua/ui/game/gamemain.lua").IsNISMode() then
        return
    end

    local skins = import("/lua/skins/skins.lua").skins

    -- build an array of skin names
    local skinNames = {}
    for skin in skins do
        table.insert(skinNames, skin)
    end

    local dir
    if direction == '+' then
        dir = 1
    else
        dir = -1
    end

    -- Find the next skin from our current skin, skipping default/randomfaction: they're not really
    -- skins note that if the skin table is updated while running, the order of the table might change
    -- so your cycle may be different. No big deal, just be aware it's a side effect.
    local numSkins = table.getn(skinNames)
    for index, skinName in skinNames do
        if skinName == currentSkin() then
            local nextSkinIndex = index + dir
            if nextSkinIndex > numSkins then nextSkinIndex = 1 end
            if nextSkinIndex < 1 then nextSkinIndex = numSkins end
            if skinNames[nextSkinIndex] == 'default' or skinNames[nextSkinIndex] == 'random'  then   -- skip default entry as it's not really a skin
                nextSkinIndex = nextSkinIndex + dir
                if nextSkinIndex > numSkins then nextSkinIndex = 1 end
                if nextSkinIndex < 1 then nextSkinIndex = numSkins end
            end
            LOG('attempting to set skin to: ', skinNames[nextSkinIndex])
            SetCurrentSkin(skinNames[nextSkinIndex])
            break
        end
    end
end

--- Cycles through all available layouts
---@param direction? "+" | "-"
function RotateLayout(direction)
    -- disable when in Screen Capture mode
    if import("/lua/ui/game/gamemain.lua").gameUIHidden then
        return
    end

    local dir
    if direction == '+' then
        dir = 1
    else
        dir = -1
    end

    local numLayouts = table.getn(layouts)
    for index, layoutName in layouts do
        if layoutName == currentLayout then
            local nextLayoutIndex = index + dir
            if nextLayoutIndex > numLayouts then nextLayoutIndex = 1 end
            if nextLayoutIndex < 1 then nextLayoutIndex = numLayouts end
            SetCurrentLayout(layouts[nextLayoutIndex])
            break
        end
    end
end

--- Given a path and name relative to the skin path, returns the full path based on the current skin
---@param filespec FileName
---@param checkMods? boolean
---@return FileName
function UIFile(filespec, checkMods)
    if UIFileBlacklist[filespec] then return filespec end
    local skins = import("/lua/skins/skins.lua").skins
    local useSkin = currentSkin()
    local currentPath = skins[useSkin].texturesPath
    local origPath = currentPath

    if useSkin == nil or currentPath == nil then
        return nil
    end

    if not UIFileCache[currentPath .. filespec] then
        ---@type FileName | false
        local found = false

        if useSkin == 'default' then
            found = currentPath .. filespec
        else
            while not found and useSkin do
                found = currentPath .. filespec
                
                if not DiskGetFileInfo(found) then
                    -- Check mods
                    local inmod = false
                    if checkMods then
                        if __active_mods then
                            for id, mod in __active_mods do
                                -- Unit Icons
                                if DiskGetFileInfo(mod.location .. filespec) then
                                    found = mod.location .. filespec
                                    inmod = true
                                    break
                                -- ACU Enhancements
                                elseif DiskGetFileInfo(mod.location .. currentPath .. filespec) then
                                    found = mod.location .. currentPath .. filespec
                                    inmod = true
                                    break
                                end
                            end
                        end
                    end

                    if not inmod then
                        found = false
                        useSkin = skins[useSkin].default
                        if useSkin then
                            currentPath = skins[useSkin].texturesPath
                        end
                    end
                end
            end
        end

        if not found then
            -- don't print error message if "filespec" is a valid path
            if not DiskGetFileInfo(filespec) then
                SPEW('[uiutil.lua, function UIFile()] - Unable to find file:'.. origPath .. filespec)
            end
            found = filespec
        end

        UIFileCache[origPath .. filespec] = found
    end
    return UIFileCache[origPath .. filespec]
end

--- Returns the filename as a lazy var function to allow triggering of `OnDirty()`
---@param filespec FileName
---@param checkMods? boolean
---@return fun(): FileName
function SkinnableFile(filespec, checkMods)
    return function()
        return UIFile(filespec, checkMods)
    end
end

--- Each UI screen needs something to be responsible for parenting all its controls so
--- placement and destruction can occur. This creates a group which fills the screen.
---@param root Control
---@param debugName? string defaults to `"screenGroup"`
---@return Group
function CreateScreenGroup(root, debugName)
    if not root then return end
    local screenGroup = Group(root, debugName or "screenGroup")
    LayoutHelpers.FillParent(screenGroup, root)
    return screenGroup
end

--- Gets cursor information for a given cursor ID
---@param id CursorType
---@return FileName texture
---@return number hotspotx
---@return number hotspoty
---@return number? numFrames
---@return number? fps
function GetCursor(id)
    local skins = import("/lua/skins/skins.lua").skins
    ---@type CursorDefinition[]
    local cursors = skins[currentSkin()].cursors or skins['default'].cursors
    local cursor = cursors[id]
    if not cursor then
        LOG("Requested cursor not found: " .. id)
    end
    return cursor[1], cursor[2], cursor[3], cursor[4], cursor[5]
end

--- Creates the one cursor used by the game
---@return Cursor
function CreateCursor()
    return Cursor(GetCursor("DEFAULT"))
end

--- Returns a text object with the appropriate font set
---@param parent Control
---@param label? UnlocalizedString
---@param pointSize? number
---@param font? LazyVarString
---@param dropshadow? boolean
---@return Text
function CreateText(parent, label, pointSize, font, dropshadow)
    label = LOC(label) or LOC("<LOC uiutil_0000>[no text]")
    font = font or buttonFont
    local text = Text(parent, "Text: " .. label)
    text:SetFont(font, pointSize)
    text:SetColor(fontColor)
    text:SetText(label)

    if dropshadow then
        text:SetDropShadow(true)
    end
    return text
end

---@param parent Control
---@param filename FileName
---@param border? number
---@return Bitmap
function CreateBitmap(parent, filename, border)
    local bitmap = Bitmap(parent)
    bitmap:SetTexture(UIFile(filename), border)
    return bitmap
end

---@param parent Control
---@param filename FileName
---@param border? number
---@return Bitmap
function CreateBitmapStd(parent, filename, border)
    return CreateBitmap(parent, filename .. "_bmp.dds", border)
end

---@param parent Control
---@param color LazyVarColor
---@return Bitmap
function CreateBitmapColor(parent, color)
    local bitmap = Bitmap(parent)
    bitmap:SetSolidColor(color)
    return bitmap
end

---@param parent Control
---@param filename FileName
---@param border? number
---@return Bitmap
function CreateSkinnableBitmap(parent, filename, border)
    local bitmap = Bitmap(parent)
    bitmap:SetTexture(SkinnableFile(filename), border)
    return bitmap
end

---@param parent Control
---@param filename FileName
---@param border? number
---@return Bitmap
function CreateSkinnableBitmapStd(parent, filename, border)
    return CreateSkinnableBitmap(parent, filename .. "_bmp.dds", border)
end


---@param control Edit
---@param foreColor? LazyVarColor
---@param backColor? LazyVarColor
---@param highlightFore? LazyVarColor
---@param highlightBack? LazyVarColor
---@param fontFace? LazyVarString
---@param fontSize? number
---@param charLimit? number
function SetupEditStd(control, foreColor, backColor, highlightFore, highlightBack, fontFace, fontSize, charLimit)
    if charLimit then
        control:SetMaxChars(charLimit)
    end
    if foreColor then
        control:SetForegroundColor(foreColor)
    end
    if backColor then
        control:SetBackgroundColor(backColor)
    end
    if highlightFore then
        control:SetHighlightForegroundColor(highlightFore)
    end
    if highlightBack then
        control:SetHighlightBackgroundColor(highlightBack)
    end
    if fontFace and fontSize then
        control:SetFont(fontFace, fontSize)
    end

    control.OnCharPressed = function(self, charcode)
        if charcode == VK_TAB then
            return true
        end
        local charLim = self:GetMaxChars()
        if STR_Utf8Len(self:GetText()) >= charLim then
            local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
            PlaySound(sound)
        end
    end
end

--- Returns a button set up with a text overlay and a click sound
---@param parent Control
---@param up FileName
---@param down FileName
---@param over FileName
---@param disabled FileName
---@param label? UnlocalizedString
---@param pointSize? number
---@param textOffsetVert? number
---@param textOffsetHorz? number
---@param clickCue? string defaults to `"UI_Menu_MouseDown_Sml"`; use `"NO_SOUND"` to not have one
---@param rolloverCue? string default to `"UI_Menu_Rollover_Sml"`; use `"NO_SOUND"` to not have one
---@param dropshadow? boolean
---@return Button
function CreateButton(parent, up, down, over, disabled, label, pointSize, textOffsetVert, textOffsetHorz, clickCue, rolloverCue, dropshadow)
    textOffsetVert = textOffsetVert or 0
    textOffsetHorz = textOffsetHorz or 0
    if clickCue == "NO_SOUND" then
        clickCue = nil
    else
        clickCue = clickCue or "UI_Menu_MouseDown_Sml"
    end
    if rolloverCue == "NO_SOUND" then
        rolloverCue = nil
    else
        rolloverCue = rolloverCue or "UI_Menu_Rollover_Sml"
    end
    if type(up) == 'string' then
        up = SkinnableFile(up)
    end
    if type(down) == 'string' then
        down = SkinnableFile(down)
    end
    if type(over) == 'string' then
        over = SkinnableFile(over)
    end
    if type(disabled) == 'string' then
        disabled = SkinnableFile(disabled)
    end

    local button = Button(parent, up, down, over, disabled, clickCue, rolloverCue)
    button:UseAlphaHitTest(false)

    if label and pointSize then
        button.label = CreateText(button, label, pointSize, buttonFont, dropshadow)
        LayoutHelpers.AtCenterIn(button.label, button, textOffsetVert, textOffsetHorz)
        button.label:DisableHitTest()

        -- if text exists, set up to grey it out
        button.OnDisable = function(self)
            Button.OnDisable(self)
            button.label:SetColor(disabledColor)
        end

        button.OnEnable = function(self)
            Button.OnEnable(self)
            button.label:SetColor(fontColor)
        end
        button.OnRolloverEvent = function(self, event)
            if event == 'enter' then
                button.label:SetColor(fontOverColor)
            elseif event == 'exit' then
                button.label:SetColor(fontColor)
            elseif event == 'down' then
                button.label:SetColor(fontDownColor)
            end
        end
    end

    return button
end

--- Creates a button with standardized texture names. 
--- Given a path and button name prefix, generates the four button asset file names:
---   * *\<filename>* `_btn_up.dds`
---   * *\<filename>* `_btn_down.dds`
---   * *\<filename>* `_btn_over.dds`
---   * *\<filename>* `_btn_dis.dds`
---@param parent Control
---@param filename FileName
---@param label? UnlocalizedString
---@param pointSize? number
---@param textOffsetVert? number
---@param textOffsetHorz? number
---@param clickCue? string defaults to `"UI_Menu_MouseDown_Sml"`; use `"NO_SOUND"` to not have one
---@param rolloverCue? string default to `"UI_Menu_Rollover_Sml"`; use `"NO_SOUND"` to not have one
---@return Button
function CreateButtonStd(parent, filename, label, pointSize, textOffsetVert, textOffsetHorz, clickCue, rolloverCue)
    return CreateButton(parent,
        filename .. "_btn_up.dds",
        filename .. "_btn_down.dds",
        filename .. "_btn_over.dds",
        filename .. "_btn_dis.dds",
        label, pointSize,
        textOffsetVert, textOffsetHorz,
        clickCue, rolloverCue
    )
end

--- Creates a button with standardized texture names and a drop shadow with text size 11.
--- Given a path and button name prefix, generates the four button asset file names:
---   * *\<filename>* `_btn_up.dds`
---   * *\<filename>* `_btn_down.dds`
---   * *\<filename>* `_btn_over.dds`
---   * *\<filename>* `_btn_dis.dds`
---@param parent Control
---@param filename FileName
---@param label? UnlocalizedString
---@param textOffsetVert? number
---@param textOffsetHorz? number
---@param clickCue? string defaults to `"UI_Menu_MouseDown_Sml"`; use `"NO_SOUND"` to not have one
---@param rolloverCue? string default to `"UI_Menu_Rollover_Sml"`; use `"NO_SOUND"` to not have one
function CreateButtonWithDropshadow(parent, filename, label, textOffsetVert, textOffsetHorz, clickCue, rolloverCue)
    return CreateButton(parent,
        filename .. "_btn_up.dds",
        filename .. "_btn_down.dds",
        filename .. "_btn_over.dds",
        filename .. "_btn_dis.dds",
        label, 11,
        textOffsetVert, textOffsetHorz,
        clickCue, rolloverCue,
        true
    )
end

--- Create a ninepatch using a texture path and the long-name convention,
--- instead of explicitly with 9 images. These are:
--- `center.dds`, `topLeft.dds`, `topRight.dds`, `bottomLeft.dds`, `bottomRight.dds`, `left.dds`,
--- `right.dds`, `top.dds` and `bottom.dds`
---@param parent Control
---@param texturePath FileName
---@return NinePatch
function CreateNinePatchStd(parent, texturePath)
    return NinePatch(parent,
        SkinnableFile(texturePath .. 'center.dds'),
        SkinnableFile(texturePath .. 'topLeft.dds'),
        SkinnableFile(texturePath .. 'topRight.dds'),
        SkinnableFile(texturePath .. 'bottomLeft.dds'),
        SkinnableFile(texturePath .. 'bottomRight.dds'),
        SkinnableFile(texturePath .. 'left.dds'),
        SkinnableFile(texturePath .. 'right.dds'),
        SkinnableFile(texturePath .. 'top.dds'),
        SkinnableFile(texturePath .. 'bottom.dds')
)
end

--- Surrounds a control with a nine-patch border
---@param parent Control
---@param texturePath FileName
---@param fudgeX? number defaults to `62`
---@param fudgeY? number defaults to `62`
function SurroundWithNinePatch(parent, texturePath, fudgeX, fudgeY)
    local patch = CreateNinePatchStd(parent, texturePath)

    patch:Surround(parent, fudgeX or 62, fudgeY or 62)
    LayoutHelpers.DepthUnderParent(patch, parent, 2)
end

--- Surrounds the given control with an eight-patch dynamically-scaling Border constructed using
--- the standard long-name convention from the given texture path. These are:
--- `topLeft.dds`, `topRight.dds`, `bottomLeft.dds`, `bottomRight.dds`, `left.dds`, `right.dds`,
--- `top.dds` and `bottom.dds`
---@see Border for an explanation of how the textures are arranged.
---@param control Control
---@param texturePath FileName
---@param fudgeX? number The amount of overlap in the X direction the border textures shall have with the control. The default fudgefactors are suitable for use with the widely-used "laser box" borders (which is `62`).
---@param fudgeY? number As fudgeX, but in the Y direction.
function SurroundWithBorder(control, texturePath, fudgeX, fudgeY)
    local border = Border(control,
        SkinnableFile(texturePath .. 'topLeft.dds'),
        SkinnableFile(texturePath .. 'topRight.dds'),
        SkinnableFile(texturePath .. 'bottomLeft.dds'),
        SkinnableFile(texturePath .. 'bottomRight.dds'),
        SkinnableFile(texturePath .. 'left.dds'),
        SkinnableFile(texturePath .. 'right.dds'),
        SkinnableFile(texturePath .. 'top.dds'),
        SkinnableFile(texturePath .. 'bottom.dds')
    )

    border:Surround(control, fudgeX or 62, fudgeY or 62)
    LayoutHelpers.DepthOverParent(border, control, 2)
end

--- Creates a checkbox using the default checkbox texture. Kept as its own entry point for the
--- benefit of code that uses "radiobtn" for its checkboxs' texture names. These are:
--- `-d_btn_up.dds`, `-s_btn_up.dds`, `-d_btn_over.dds`, `-s_btn_over.dds`,
--- `-d_btn_dis.dds`, and `-s_btn_dis.dds`
function CreateCheckboxStd(parent, texturePath)
    return Checkbox(parent,
        SkinnableFile(texturePath .. '-d_btn_up.dds'),
        SkinnableFile(texturePath .. '-s_btn_up.dds'),
        SkinnableFile(texturePath .. '-d_btn_over.dds'),
        SkinnableFile(texturePath .. '-s_btn_over.dds'),
        SkinnableFile(texturePath .. '-d_btn_dis.dds'),
        SkinnableFile(texturePath .. '-s_btn_dis.dds')
    )
end

--- Creates a checkbox using the standard naming convention. This is:
--- `d_up.dds`, `s_up.dds`, `d_over.dds`, `s_over.dds`, `d_dis.dds`, and `s_dis.dds`
---@param parent Control
---@param texturePath FileName
---@param label UnlocalizedString
---@param labelRight any
---@param labelSize any
---@param clickCue any
---@param rollCue any
---@return unknown
function CreateCheckbox(parent, texturePath, label, labelRight, labelSize, clickCue, rollCue)
    return Checkbox(parent,
        SkinnableFile(texturePath .. 'd_up.dds'),
        SkinnableFile(texturePath .. 's_up.dds'),
        SkinnableFile(texturePath .. 'd_over.dds'),
        SkinnableFile(texturePath .. 's_over.dds'),
        SkinnableFile(texturePath .. 'd_dis.dds'),
        SkinnableFile(texturePath .. 's_dis.dds'),
        label, labelRight, labelSize, clickCue, rollCue
    )
end

--- Creates a collapse arrow in one of the directions (note that the bottom is not supported).
--- Note that the control passed in should be the parent of the control you want to have collapsed
--- (so that the collapse arrow isn't hidden with it).
---@param parent Control
---@param position 'l' | 't' | 'r'
---@return Checkbox
function CreateCollapseArrow(parent, position)
    -- make sure the filename will be well-formed (also, someone's going to think that `position`
    -- is optional, so let's disillusion them of that idea)
    if position ~= 't' and position ~= 'r' and position ~= 'l' then
        error("Collapse arrow position must be one of: 'l', 't', 'r'", 2)
    end
    local prefix = "/game/tab-" .. position .. "-btn/tab-"
    return Checkbox(parent,
        SkinnableFile(prefix .. "close_btn_up.dds"),
        SkinnableFile(prefix .. "open_btn_up.dds"),
        SkinnableFile(prefix .. "close_btn_over.dds"),
        SkinnableFile(prefix .. "open_btn_over.dds"),
        SkinnableFile(prefix .. "close_btn_dis.dds"),
        SkinnableFile(prefix .. "open_btn_dis.dds")
    )
end

--- Creates a radio button with the standard naming convention. This is:
--- `d_up.dds`, `s_up.dds`, `d_over.dds`, `s_over.dds`, `d_dis.dds`, and `s_dis.dds`
---@param parent Control
---@param texturePath FileName
---@param title LocalizedString
---@param buttons any
---@param default any
---@return unknown
function CreateRadioButtonsStd(parent, texturePath, title, buttons, default)
    local radioButton = RadioButtons(parent, title, buttons, default, "Arial", 14, fontColor,
        SkinnableFile(texturePath .. 'd_up.dds'),
        SkinnableFile(texturePath .. 's_up.dds'),
        SkinnableFile(texturePath .. 'd_over.dds'),
        SkinnableFile(texturePath .. 's_over.dds'),
        SkinnableFile(texturePath .. 'd_dis.dds'),
        SkinnableFile(texturePath .. 's_dis.dds'),
        "")
    return radioButton
end

--- Creates a dialog button
---@param parent Control
---@param filename FileName
---@param label? UnlocalizedString
---@param pointSize? number
---@param textOffsetVert? number
---@param textOffsetHorz? number
---@param clickCue? string defaults to `"UI_Menu_MouseDown_Sml"`; use `"NO_SOUND"` to not have one
---@param rolloverCue? string default to `"UI_Menu_Rollover_Sml"`; use `"NO_SOUND"` to not have one
---@return Button
function CreateDialogButtonStd(parent, filename, label, pointSize, textOffsetVert, textOffsetHorz, clickCue, rolloverCue)
    local button = CreateButtonStd(parent,filename,label,pointSize,textOffsetVert,textOffsetHorz, clickCue, rolloverCue)
    button.label:SetFont(dialogButtonFont, pointSize)
    button.label:SetColor(dialogButtonColor)
    return button
end

--* return the standard scrollbar
function CreateVertScrollbarFor(attachto, offset_right, filename, offset_bottom, offset_top)
    offset_right = offset_right or 0
    offset_bottom = offset_bottom or 0
    offset_top = offset_top or 0
    local textureName = filename or '/small-vert_scroll/'
    local scrollbg = textureName..'back_scr_mid.dds'
    local scrollbarmid = textureName..'bar-mid_scr_over.dds'
    local scrollbartop = textureName..'bar-top_scr_up.dds'
    local scrollbarbot = textureName..'bar-bot_scr_up.dds'
    if filename then
        scrollbg = textureName..'back_scr_mid.dds'
        scrollbarmid = textureName..'bar-mid_scr_up.dds'
        scrollbartop = textureName..'bar-top_scr_up.dds'
        scrollbarbot = textureName..'bar-bot_scr_up.dds'
    end
    local scrollbar = Scrollbar(attachto, import("/lua/maui/scrollbar.lua").ScrollAxis.Vert)
    scrollbar:SetTextures(   SkinnableFile(scrollbg)
                            ,SkinnableFile(scrollbarmid)
                            ,SkinnableFile(scrollbartop)
                            ,SkinnableFile(scrollbarbot))

    local scrollUpButton = Button(    scrollbar
                                    , SkinnableFile(textureName..'arrow-up_scr_up.dds')
                                    , SkinnableFile(textureName..'arrow-up_scr_down.dds')
                                    , SkinnableFile(textureName..'arrow-up_scr_over.dds')
                                    , SkinnableFile(textureName..'arrow-up_scr_dis.dds')
                                    , "UI_Arrow_Click")

    local scrollDownButton = Button(  scrollbar
                                    , SkinnableFile(textureName..'arrow-down_scr_up.dds')
                                    , SkinnableFile(textureName..'arrow-down_scr_down.dds')
                                    , SkinnableFile(textureName..'arrow-down_scr_over.dds')
                                    , SkinnableFile(textureName..'arrow-down_scr_dis.dds')
                                    , "UI_Arrow_Click")

    LayoutHelpers.AnchorToRight(scrollbar, attachto, offset_right)
    scrollbar.Top:Set(scrollUpButton.Bottom)
    scrollbar.Bottom:Set(scrollDownButton.Top)

    scrollUpButton.Left:Set(scrollbar.Left)
    LayoutHelpers.AtTopIn(scrollUpButton, attachto, offset_top)

    scrollDownButton.Left:Set(scrollbar.Left)
    LayoutHelpers.AtBottomIn(scrollDownButton, attachto, offset_bottom)

    scrollbar.Right:Set(scrollUpButton.Right)

    scrollbar:AddButtons(scrollUpButton, scrollDownButton)
    scrollbar:SetScrollable(attachto)

    return scrollbar
end

function CreateLobbyVertScrollbar(attachto, offset_right, offset_bottom, offset_top)
    return CreateVertScrollbarFor(attachto, offset_right, "/SCROLLBAR_VERT/", offset_bottom, offset_top)
end

-- cause a dialog to get input focus, optional functions to perform when the user hits enter or escape
-- functions signature is: function()
function MakeInputModal(control, onEnterFunc, onEscFunc)
    AddInputCapture(control)

    local oldOnDestroy = control.OnDestroy
    control.OnDestroy = function(self)
        RemoveInputCapture(control)
        oldOnDestroy(self)
    end

    if onEnterFunc or onEscFunc then
        control.oldHandleEvent = control.HandleEvent
        control.HandleEvent = function(self, event)
            if event.Type == 'KeyDown' then
                if event.KeyCode == VK_ESCAPE then
                    if onEscFunc then
                        onEscFunc()
                        return true
                    end
                elseif event.KeyCode == VK_ENTER then
                    if onEnterFunc then
                        onEnterFunc()
                        return true
                    end
                end
            end
            if control.oldHandleEvent then
                return control.oldHandleEvent(self, event)
            end
            return true
        end
    end
end

---@class ModalityInfo
---@field escapeButton number `1-3` the button function to mimic when the escape button is pressed
---@field enterButton number `1-3` the button function to mimic when the enter button is pressed
---@field OnlyWorldCover boolean if only the world is covered (i.e. it's non-modal)

--- Creates and manages an info dialog. Setting a callback for a button will prevent it from closing
--- the dialog unless `destroyOnCallback` is true (which is the default only when all three callbacks
--- are supplied).
---@param parent Control
---@param dialogText UnlocalizedString
---@param button1Text? UnlocalizedString text for the first button
---@param button1Callback fun() | nil callback function for the first button
---@param button2Text? UnlocalizedString text for the first button
---@param button2Callback fun() | nil callback function for the first button
---@param button3Text? UnlocalizedString text for the first button
---@param button3Callback fun() | nil callback function for the first button
---@param destroyOnCallback? boolean if true, the popup is closed when a button with a callback is pressed (if false, you must destroy); defaults to `true` when all three callback functions are supplied and `false` otherwise
---@param modalInfo ModalityInfo Sets up modality info for dialog
---@return Popup
function QuickDialog(parent, dialogText, button1Text, button1Callback, button2Text, button2Callback, button3Text, button3Callback, destroyOnCallback, modalInfo)
    -- if there is a callback and destroy not specified, assume destroy
    if destroyOnCallback == nil and (button1Callback or button2Callback or button3Callback) then
        destroyOnCallback = true
    end

    local dialog = Group(parent, "quickDialogGroup")

    local textLine = {}
    textLine[1] = CreateText(dialog, "", 18, titleFont)
    LayoutHelpers.AtTopIn(textLine[1], dialog, 15)
    LayoutHelpers.AtHorizontalCenterIn(textLine[1], dialog)

    LayoutHelpers.SetWidth(dialog, 428)
    local textBoxWidth = dialog.Width() - LayoutHelpers.ScaleNumber(80)
    local tempTable = import("/lua/maui/text.lua").WrapText(LOC(dialogText), textBoxWidth,
        function(text)
            return textLine[1]:GetStringAdvance(text)
        end
    )

    local textHeight = 0
    local prevControl = false
    for i, v in tempTable do
        if i == 1 then
            textLine[1]:SetText(v)
            prevControl = textLine[1]
        else
            textLine[i] = CreateText(dialog, v, 18, titleFont)
            LayoutHelpers.Below(textLine[i], prevControl)
            LayoutHelpers.AtHorizontalCenterIn(textLine[i], dialog)
            prevControl = textLine[i]
        end

        textHeight = textHeight + textLine[i]:Height()
    end

    dialog.Height:Set(textHeight + LayoutHelpers.ScaleNumber(85))

    local popup = Popup(parent, dialog)
    -- Don't close when the shadow is clicked.
    popup.OnShadowClicked = function() end
    popup.OnEscapePressed = function() end

    local numButtons = 0
    local function MakeButton(text, callback)
        numButtons = numButtons + 1
        local button = CreateButtonWithDropshadow(dialog, '/BUTTON/medium/', text)
        if callback then
            button.OnClick = function(self)
                callback()
                if destroyOnCallback then
                    popup:Close()
                end
            end
        else
            button.OnClick = function(self)
                popup:Close()
            end
        end
        LayoutHelpers.AtBottomIn(button, dialog, 10)
        return button
    end

    ---@type Button, Button, Button
    local button1, button2, button3 = false, false, false
    if button1Text then
        button1 = MakeButton(button1Text, button1Callback)
    end
    if button2Text then
        button2 = MakeButton(button2Text, button2Callback)
    end
    if button3Text then
        button3 = MakeButton(button3Text, button3Callback)
    end
    dialog._button1 = button1
    dialog._button2 = button2
    dialog._button3 = button3

    if numButtons > 1 then
        -- A button to either size...
        button1.Left:Set(function()
            return dialog.Left() + (dialog.Width() * 0.5 - dialog._button1.Width()) * 0.5 - 44
        end)

        local rightButton
        if numButtons == 3 then
            rightButton = button3

            -- The third (second) button goes in the middle.
            LayoutHelpers.AtHorizontalCenterIn(button2, dialog)
        else
            rightButton = button2
        end

        rightButton.Left:Set(function()
            local halfWidth = dialog.Width() * 0.5
            return dialog.Left() + halfWidth + (halfWidth - dialog._button2.Width()) * 0.5 + 44
        end)
    elseif numButtons == 1 then
        LayoutHelpers.AtHorizontalCenterIn(button1, dialog)
    end

    if modalInfo and not modalInfo.OnlyWorldCover then
        local function OnEnterFunc()
            local enterButton = modalInfo.enterButton
            if enterButton then
                local button
                if enterButton == 1 then
                    button = dialog._button1
                elseif enterButton == 2 then
                    button = dialog._button2
                elseif enterButton == 3 then
                    button = dialog._button3
                end
                if button then
                    button:OnClick()
                end
            end
        end

        local function OnEscFunc()
            local escapeButton = modalInfo.escapeButton
            if escapeButton then
                local button
                if escapeButton == 1 then
                    button = dialog._button1
                elseif escapeButton == 2 then
                    button = dialog._button2
                elseif escapeButton == 3 then
                    button = dialog._button3
                end
                if button then
                    button:OnClick()
                end
            end
        end

        MakeInputModal(dialog, OnEnterFunc, OnEscFunc)
    end

    return popup
end

---@param parent Control
---@param colorOverride? Color defaults to black
function CreateWorldCover(parent, colorOverride)
    colorOverride = colorOverride or "ff000000"
    local NumFrame = GetNumRootFrames() - 1
    local worldCovers = {}
    local parentFrame = parent:GetRootFrame()

    local function OnHide(self, hidden)
        for id, cover in worldCovers do
            if cover and id ~= self.ID then
                cover:SetHidden(hidden)
            end
        end
    end
    local function OnDestroy(self)
        for id, cover in worldCovers do
            if cover and id ~= self.ID then
                cover:Destroy()
            end
        end
    end
    local function OnFrame(self, delta)
        local targetAlpha = self:GetAlpha() + (delta * 1.5)
        if targetAlpha < 0.8 then
            self:SetAlpha(targetAlpha)
        else
            self:SetAlpha(0.8)
            self:SetNeedsFrameUpdate(false)
        end
    end

    for index = 0, NumFrame do
        local worldCover
        local frame = GetFrame(index)
        if frame == parentFrame then
            worldCover = Bitmap(parent)
            worldCover.ID = index
            worldCover.OnDestroy = OnDestroy
            worldCover.OnHide = OnHide
        else
            worldCover = Bitmap(frame)
        end
        worldCover.OnFrame = OnFrame
        worldCovers[index] = LayoutHelpers.ReusedLayoutFor(worldCover)
            :Color(colorOverride)
            :Fill(frame)
            :Under(parent, 2)
            :Alpha(0)
            :NeedsFrameUpdate(true)
            :End()
    end

    return worldCovers
end

---@param parent Control
---@param dialogText UnlocalizedString
---@param buttonText? UnlocalizedString
---@param buttonCallback fun() | nil
---@param destroyOnCallback? boolean
---@return Popup
function ShowInfoDialog(parent, dialogText, buttonText, buttonCallback, destroyOnCallback)
    return QuickDialog(parent, dialogText, buttonText, buttonCallback, nil, nil, nil, nil, destroyOnCallback, {worldCover = false, enterButton = 1, escapeButton = 1})
end

---@param factionIndex number
---@return FileName
function GetFactionIcon(factionIndex)
    return import("/lua/factions.lua").Factions[factionIndex + 1].Icon
end

---@param parent Control
---@param leftOffset number
---@param topOffset number
---@param rightOffset number
---@param bottomOffset number
---@param altTextures? boolean if it uses small brackets
function CreateDialogBrackets(parent, leftOffset, topOffset, rightOffset, bottomOffset, altTextures)
    local ret = Group(parent)

    local texturePath
    if altTextures then
        texturePath = "/scx_menu/panel-brackets-small"
    else
        texturePath = "/scx_menu/panel-brackets"
    end

    ret.topleft = Bitmap(ret, UIFile(texturePath .. '/bracket-ul_bmp.dds'))
    ret.topright = Bitmap(ret, UIFile(texturePath .. '/bracket-ur_bmp.dds'))
    ret.bottomleft = Bitmap(ret, UIFile(texturePath .. '/bracket-ll_bmp.dds'))
    ret.bottomright = Bitmap(ret, UIFile(texturePath .. '/bracket-lr_bmp.dds'))

    ret.topleftglow = Bitmap(ret, UIFile(texturePath .. '/bracket-glow-ul_bmp.dds'))
    ret.toprightglow = Bitmap(ret, UIFile(texturePath .. '/bracket-glow-ur_bmp.dds'))
    ret.bottomleftglow = Bitmap(ret, UIFile(texturePath .. '/bracket-glow-ll_bmp.dds'))
    ret.bottomrightglow = Bitmap(ret, UIFile(texturePath .. '/bracket-glow-lr_bmp.dds'))

    ret.topleftglow.Depth:Set(function() return ret.topleft.Depth() - 1 end)
    ret.toprightglow.Depth:Set(function() return ret.topright.Depth() - 1 end)
    ret.bottomleftglow.Depth:Set(function() return ret.bottomleft.Depth() - 1 end)
    ret.bottomrightglow.Depth:Set(function() return ret.bottomright.Depth() - 1 end)

    LayoutHelpers.AtCenterIn(ret.topleftglow, ret.topleft)
    LayoutHelpers.AtCenterIn(ret.toprightglow, ret.topright)
    LayoutHelpers.AtCenterIn(ret.bottomleftglow, ret.bottomleft)
    LayoutHelpers.AtCenterIn(ret.bottomrightglow, ret.bottomright)

    LayoutHelpers.AtLeftTopIn(ret.topleft, parent, -leftOffset, -topOffset)
    LayoutHelpers.AtRightTopIn(ret.topright, parent, -rightOffset, -topOffset)
    LayoutHelpers.AtLeftBottomIn(ret.bottomleft, parent, -leftOffset, -bottomOffset)
    LayoutHelpers.AtRightBottomIn(ret.bottomright, parent, -rightOffset, -bottomOffset)

    ret:DisableHitTest(true)
    LayoutHelpers.FillParent(ret, parent)

    return ret
end

--- Enable or disable a control based on a boolean
---@param control Control
---@param enabled boolean
function setEnabled(control, enabled)
    if enabled then
        control:Enable()
    else
        control:Disable()
    end
end

--- Show or hide a control based on a boolean
---@param control Control
---@param visible boolean
function setVisible(control, visible)
    if visible then
        control:Show()
    else
        control:Hide()
    end
end

---@return string
function GetReplayId()
    local id = nil

    if HasCommandLineArg("/syncreplay") and HasCommandLineArg("/gpgnet") and GetFrontEndData('syncreplayid') ~= nil and GetFrontEndData('syncreplayid') ~= 0 then
        id = GetFrontEndData('syncreplayid')
    elseif HasCommandLineArg("/savereplay") then
        -- /savereplay format is gpgnet://local_ip:port/replay_id/USERNAME.SCFAreplay
        -- see https://github.com/FAForever/downlords-faf-client/blob/b819997b2c4964ae6e6801d5d2eecd232bca5688/src/main/java/com/faforever/client/fa/LaunchCommandBuilder.java--L192
        local url = GetCommandLineArg("/savereplay", 1)[1]
        local fistpos = string.find(url, "/", 10) + 1
        local lastpos = string.find(url, "/", fistpos) - 1
        id = string.sub(url, fistpos, lastpos)
    elseif HasCommandLineArg("/replayid") then
        id =  GetCommandLineArg("/replayid", 1)[1]
    end

    return id
end

--- Create an input dialog with the given title and listener function
---@param parent Control
---@param title UnlocalizedString
---@param listener fun()
---@param fallbackBox? Control
---@param str? string
---@return InputDialog
function CreateInputDialog(parent, title, listener, fallbackBox, str)
    local dialog = InputDialog(parent, title, fallbackBox, str)
    dialog.OnInput = listener

    return dialog
end


---@param parent Control
---@return ItemList
function CreateTextBox(parent)
    local box = ItemList(parent)
    box:SetFont(bodyFont, 14)
    box:SetColors(bodyColor, "black",  highlightColor, "white")
    CreateVertScrollbarFor(box)
    return box
end

---@param textBox ItemList
---@param text UnlocalizedString
function SetTextBoxText(textBox, text)
    textBox:DeleteAllItems()
    local wrapped = import("/lua/maui/text.lua").WrapText(LOC(text), textBox.Width(), function(curText) return textBox:GetStringAdvance(curText) end)
    for i, line in wrapped do
        textBox:AddItem(line)
    end
end

local Window = import("/lua/maui/window.lua").Window
local windowTextures = {
    tl = UIFile('/game/mini-map-brd/mini-map_brd_ul.dds'),
    tr = UIFile('/game/mini-map-brd/mini-map_brd_ur.dds'),
    tm = UIFile('/game/mini-map-brd/mini-map_brd_horz_um.dds'),
    ml = UIFile('/game/mini-map-brd/mini-map_brd_vert_l.dds'),
    m =  UIFile('/game/mini-map-brd/mini-map_brd_m.dds'),
    mr = UIFile('/game/mini-map-brd/mini-map_brd_vert_r.dds'),
    bl = UIFile('/game/mini-map-brd/mini-map_brd_ll.dds'),
    bm = UIFile('/game/mini-map-brd/mini-map_brd_lm.dds'),
    br = UIFile('/game/mini-map-brd/mini-map_brd_lr.dds'),
    borderColor = 'ff415055',
}

--- Constructs a default window.
---@param parent? Control Parent of the window, defaults to GetFrame(0)
---@param title? UnlocalizedString Title of the window
---@param icon? FileName Path to the icon to use for the window, defaults to false (in other words: no icon) 
---@param pin? boolean Toggle for the pin button, override window.OnPinCheck(self, checked) to set the behavior
---@param config? boolean Toggle for configuration button, override window.OnConfigClick(self) to set the behavior
---@param lockSize? boolean Toggle to allow the user to adjust the size of the window.
---@param lockPosition? boolean Toggle to allow the user to adjust the position of the window.
---@param preferenceID? string Identifier used in the preference file to remember where this window was located last
---@param defaultLeft? Lazy<number> The default left boundary of the window, defaults to 10
---@param defaultTop? Lazy<number> The default top boundary of the window, defaults to 300
---@param defaultBottom? Lazy<number> The default bottom boundary of the window, defaults to 600
---@param defaultRight? Lazy<number> The default right boundary of the window, defaults to 210
---@return Window
function CreateWindowStd(parent, title, icon, pin, config, lockSize, lockPosition, preferenceID, defaultLeft, defaultTop, defaultBottom, defaultRight)
    parent = parent or GetFrame(0)
    defaultLeft = defaultLeft or 10
    defaultTop = defaultTop or 300
    defaultBottom = defaultBottom or 600
    defaultRight = defaultRight or 210
    local defaultPos = {
        Left = defaultLeft,
        Top = defaultTop,
        Bottom = defaultBottom,
        Right = defaultRight,
    }
    return Window(
        parent, title, icon,
        pin, config, lockSize, lockPosition,
        preferenceID, defaultPos, windowTextures
    )
end

---@param primary UnlocalizedString
---@param secondary UnlocalizedString
---@param control? Control defaults to duumy control at center of screen 
function CreateAnnouncementStd(primary, secondary, control)
    -- make it originate from the top
    if not control then
        local frame = GetFrame(0)
        control = Group(frame)
        control.Left:Set(function() return frame.Left() + 0.49 * frame.Right() end)
        control.Right:Set(function() return frame.Left() + 0.51 * frame.Right() end)
        control.Top = frame.Top
        control.Bottom = frame.Top
    end

    -- create the announcement accordingly
    import("/lua/ui/game/announcement.lua").CreateAnnouncement(
        primary,
        control,
        secondary
    )
end


---@param parent Control
---@param filename FileName
---@return Group
function CreateVertFillGroup(parent, filename)
    local group = Group(parent)
    local top = CreateBitmap(group, filename .. "_bmp_t.dds")
    local bottom = CreateBitmap(group, filename .. "_bmp_b.dds")
    local middle = CreateBitmap(group, filename .. "_bmp_m.dds")

    Layouter(top)
        :Over(group, 0)
        :AtLeftTopIn(group)

    Layouter(bottom)
        :Over(group, 0)
        :AtLeftBottomIn(group)

    Layouter(middle)
        :Over(group, 0)
        :AtLeftIn(group)
        :Top(function() return top.Bottom() - 2 end)
        :AnchorToTop(bottom)

    group.Width:Set(top.Width)
    group._top = top
    group._middle = middle
    group._bottom = bottom
    return group
end


---@param parent Control
---@param filename FileName
---@return Group
function CreateHorzFillGroup(parent, filename)
    local group = Group(parent)
    local left = CreateBitmap(group, filename .. "_bmp_l.dds")
    local right = CreateBitmap(group, filename .. "_bmp_r.dds")
    local middle = CreateBitmap(group, filename .. "_bmp_m.dds")

    Layouter(left)
        :Over(group, 0)
        :AtLeftTopIn(group)

    Layouter(right)
        :Over(group, 0)
        :AtRightTopIn(group)

    Layouter(middle)
        :Over(group, 0)
        :AtTopIn(group)
        :Left(function() return left.Right() - 2 end)
        :AnchorToLeft(right)

    group.Height:Set(right.Height)
    group._left = left
    group._middle = middle
    group._right = right
    return group
end
