---@meta

---@class UIHighlightedCommand
---@field x number
---@field y number
---@field z number
---@field targetId? EntityId
---@field blueprintId? UnitId
---@field commandType number

---@alias SubmergeStatus
---| -1  # submerged
---|  0  # unknown
---|  1  # not submerged


---@alias FireState
---| 0 # Return fire
---| 1 # Hold fire
---| 2 # Ground fire

---@alias Keycode
--- | 'BACK'
--- | 'TAB'
--- | 'RETURN'
--- | 'ESCAPE'
--- | 'SPACE'
--- | 'DELETE'
--- | 'START'
--- | 'LBUTTON'
--- | 'RBUTTON'
--- | 'CANCEL'
--- | 'MBUTTON'
--- | 'CLEAR'
--- | 'SHIFT'
--- | 'ALT'
--- | 'CONTROL'
--- | 'MENU'
--- | 'PAUSE'
--- | 'CAPITAL'
--- | 'PRIOR'
--- | 'NEXT'
--- | 'END'
--- | 'HOME'
--- | 'LEFT'
--- | 'UP'
--- | 'RIGHT'
--- | 'DOWN'
--- | 'SELECT'
--- | 'PRINT'
--- | 'EXECUTE'
--- | 'SNAPSHOT'
--- | 'INSERT'
--- | 'HELP'
--- | 'NUMPAD0'
--- | 'NUMPAD1'
--- | 'NUMPAD2'
--- | 'NUMPAD3'
--- | 'NUMPAD4'
--- | 'NUMPAD5'
--- | 'NUMPAD6'
--- | 'NUMPAD7'
--- | 'NUMPAD8'
--- | 'NUMPAD9'
--- | 'MULTIPLY'
--- | 'ADD'
--- | 'SEPARATOR'
--- | 'SUBTRACT'
--- | 'DECIMAL'
--- | 'DIVIDE'
--- | 'F1'
--- | 'F2'
--- | 'F3'
--- | 'F4'
--- | 'F5'
--- | 'F6'
--- | 'F7'
--- | 'F8'
--- | 'F9'
--- | 'F10'
--- | 'F11'
--- | 'F12'
--- | 'F13'
--- | 'F14'
--- | 'F15'
--- | 'F16'
--- | 'F17'
--- | 'F18'
--- | 'F19'
--- | 'F20'
--- | 'F21'
--- | 'F22'
--- | 'F23'
--- | 'F24'
--- | 'NUMLOCK'
--- | 'SCROLL'
--- | 'PAGEUP'
--- | 'PAGEDOWN'
--- | 'NUMPAD_SPACE'
--- | 'NUMPAD_TAB'
--- | 'NUMPAD_ENTER'
--- | 'NUMPAD_F1'
--- | 'NUMPAD_F2'
--- | 'NUMPAD_F3'
--- | 'NUMPAD_F4'
--- | 'NUMPAD_HOME'
--- | 'NUMPAD_LEFT'
--- | 'NUMPAD_UP'
--- | 'NUMPAD_RIGHT'
--- | 'NUMPAD_DOWN'
--- | 'NUMPAD_PRIOR'
--- | 'NUMPAD_PAGEUP'
--- | 'NUMPAD_NEXT'
--- | 'NUMPAD_PAGEDOWN'
--- | 'NUMPAD_END'
--- | 'NUMPAD_BEGIN'
--- | 'NUMPAD_INSERT'
--- | 'NUMPAD_DELETE'
--- | 'NUMPAD_EQUAL'
--- | 'NUMPAD_MULTIPLY'
--- | 'NUMPAD_ADD'
--- | 'NUMPAD_SEPARATOR'
--- | 'NUMPAD_SUBTRACT'
--- | 'NUMPAD_DECIMAL'
--- | 'NUMPAD_DIVIDE'

---@class UISinglePlayerArmy
---@field PlayerName string
---@field Faction number
---@field Human boolean

---@class UISinglePlayerSessionConfiguration
---@field scenarioInfo UILobbyScenarioInfo
---@field scenarioMods ModInfo[]
---@field teamInfo table
---@field RandomSeed number
---@field createReplay boolean
---@field playerName string

--- Repeatedly the selection box of the unit to the hovered-over state to create a blinking effect
---@param entityId EntityId
---@param onTime number
---@param offTime number
---@param totalTime number
function AddBlinkyBox(entityId, onTime, offTime, totalTime)
end

---
---@param meshInfo MeshInfo
---@param duration number
function AddCommandFeedbackBlip(meshInfo, duration)
end

---
---@param func fun(text: string): any
function AddConsoleOutputReciever(func)
end

---
---@param control Control
function AddInputCapture(control)
end

---
---@param selection UserUnit[]
function AddSelectUnits(selection)
end

--- Adds unit to the session extra select list
---@param unit UserUnit
function AddToSessionExtraSelectList(unit)
end

--- Returns `true` if there is anything currently on the capture stack
---@return boolean
function AnyInputCapture()
end

--- Clears and disables the build templates
function ClearBuildTemplates()
end

---
function ClearCurrentFactoryForQueueDisplay()
end

--- Destroys all controls in frame, `nil` head will clear all frames
---@param head number | nil
function ClearFrame(head)
end

--- Clears the session extra select list
function ClearSessionExtraSelectList()
end

--- Performs a console command
---@param command string
function ConExecute(command)
end

--- Performs a console command, saved to stack
---@param command string
function ConExecuteSave(command)
end

--- Gets console commands that `text` can auto-complete to
---@param text string
---@return string[]
function ConTextMatches(text)
end

--- Copies the current replay to another file
---@param profile string
---@param newFilename FileName
function CopyCurrentReplay(profile, newFilename)
end

---Copies given string to clipboard, returns true if succeeded
---@param s string
---@return boolean
function CopyToClipboard(s)
end

--- Creates a Unit AtMouse
---@param blueprintId string
---@param ownerArmyIndex number
---@param offsetMouseWorldPosX number
---@param offsetMouseWorldPosZ number
---@param rotation number
---@return UserUnit
function CreateUnitAtMouse(blueprintId, ownerArmyIndex, offsetMouseWorldPosX, offsetMouseWorldPosZ, rotation)
end

--- Gets the current time in seconds, counting from 0 at application start.
--- This is wall-clock time and is unaffected by gameplay.
---@return number
function CurrentTime()
end

--- Returns `true` if debug facilities are enabled
---@return boolean
function DebugFacilitiesEnabled()
end

---
---@param queueIndex number
---@param count number
function DecreaseBuildCountInQueue(queueIndex, count)
end

---Deletes a command from the player command queue.
---Each player has an array that holds all commands for all units, the commandID indexes to that array.
---Note: this function doesn't receive any units as arguments--you will have to retrieve the commandId by UserUnit:GetCommandQueue()[commandIndex].ID
---@param commandId number commandId, from UserUnit:GetCommandQueue()[commandIndex].ID
function DeleteCommand(commandId)
end

---
function DisableWorldSounds()
end

--- Ejects another client from your session
---@param clientIndex number
function EjectSessionClient(clientIndex)
end

---
function EnableWorldSounds()
end

--- Kills current UI and starts main menu from top
function EngineStartFrontEndUI()
end

--- Kills current UI and starts splash screens
function EngineStartSplashScreens()
end

--- Filters a list of units to exclude from those found in the category
---@param category EntityCategory
---@param units UserUnit[]
---@return UserUnit[]
function EntityCategoryFilterOut(category, units)
end

--- Executes some Lua code in the sim. Requires cheats to be enabled
---@param func string # global sim func
---@param arg any # arg to the func
function ExecLuaInSim(func, arg)
end

--- Requests that the application shut down
function ExitApplication()
end

--- Quits the sim, but not the app
function ExitGame()
end

--- Flushes mouse/keyboard events
function FlushEvents()
end

--- Formats a string displaying the time specified in seconds
---@param seconds number
---@return string
function FormatTime(seconds)
end

--- Gets the current game time in ticks. The game time is the simulation time,
--- that stops when the game is paused.
---@return number
function GameTick()
end

--- Gets the current game time in seconds. The game time is the simulation time,
--- that stops when the game is paused.
---@return number
function GameTime()
end

--- Generates and enables build templates from the current selection
function GenerateBuildTemplateFromSelection()
end

--- Gets active build template back to Lua
---@return UIBuildTemplate
function GetActiveBuildTemplate()
end

---
---@return number[]
function GetAntiAliasingOptions()
end

---
--- Note that this is cached by `/lua/ui/override/ArmiesTable.lua`
---@return ArmiesTable
function GetArmiesTable()
end

--- Returns a table of avatar units for the army
---@return UserUnit[]
function GetArmyAvatars()
end

--- It is unknown where this result gets pulled from
---@param armyIndex number
---@return number
function GetArmyScore(armyIndex)
end

--- Gets a list of units assisting me
---@param units UserUnit[]
---@return UserUnit[]
function GetAssistingUnitsList(units)
end

--- Gets a list of units blueprint attached to transports
---@param units UserUnit[]
---@return UserUnit[]
function GetAttachedUnitsList(units)
end

---
---@param name string
---@return Camera
function GetCamera(name)
end

--- Gets the "arguments" (tokens split by spaces) that follow a commandline option,
--- disregarding if they start with `/` like other commandline options.  
--- Returns `false` if there are not `maxArgs` tokens after the `option`.
---@see GetCommandLineArgTable(option) for parsing key-values
---@param option string
---@param maxArgs number
---@return string[] | false
function GetCommandLineArg(option, maxArgs)
end

--- Returns 'splash', 'frontend', or 'game' depending on the current state of the UI
---@return 'splash' | 'frontend' | 'game' | 'none'
function GetCurrentUIState()
end

---
---@return UICursor
function GetCursor()
end

--- Gets the player's economy totals, for things such as resources `reclaimed` or `income`
---@return EconomyTotals
function GetEconomyTotals()
end

--- Gets the right fire state for the units passed in
---@param units UserUnit[]
---@return FireState
function GetFireState(units)
end

--- Returns the root UI frame for a given adapter. You can use `GetFrame(0)` to retrieve the primary adapter. And you can use `GetFrame(1)` to retrieve the secondary adapter. 
---
--- In the game options you can add a second adapter under the 'Video' tab.
--- 
--- See also `GetNumRootFrames()` to determine the number of root frames. 
--- 
--- See also the following modules that manage these frames:
--- - Primary adapter: lua\ui\game\worldview.lua
--- - Secondary adapter: lua\ui\game\multihead.lua
---@param head 0 | 1
---@return Frame | nil
function GetFrame(head)
end

---
---@param key string
---@return any
function GetFrontEndData(key)
end

--- Returns the current game speed
---@return number
function GetGameSpeed()
end

--- Returns a formatted string displaying the time the game has been played
---@return string
function GetGameTime()
end

--- Returns information about the command of the command graph that is below the cursor
---@return UIHighlightedCommand?
function GetHighlightCommand()
end

--- Returns a table of idle engineer units for the army
---@return UserUnit[]
function GetIdleEngineers()
end

--- Returns a table of idle factory units for the army
---@return UserUnit[]
function GetIdleFactories()
end

--- Returns the current capture control, or `nil` if none
---@returns Control | nil
function GetInputCapture()
end

--- Sees if any units in the list are auto-building
---@param units UserUnit[]
---@return boolean
function GetIsAutoMode(units)
end

--- Sees if any units in the list are auto-surfacing
---@param units UserUnit[]
---@return boolean
function GetIsAutoSurfaceMode(units)
end

--- Sees if any units in the list are paused
---@param units UserUnit[]
---@return boolean
function GetIsPaused(units)
end

--- Returns a boolean that indicates the unit is paused
---@param unit UserUnit[]
---@return boolean
function GetIsPausedOfUnit(unit)
end

--- Sees if any units in the list are submerged
---@param units UserUnit[]
---@return SubmergeStatus
function GetIsSubmerged(units)
end

---
---@return Vector2
function GetMouseScreenPos()
end

---
---@return Vector
function GetMouseWorldPos()
end

---
---@return number
function GetMovieVolume()
end

--- Returns the current number of root frames. There is usually only one root frame for each adapter (monitor). This is often referred to as a 'head' in other comments. The game supports up to two root frames.
--- 
--- In the game options you can add a second adapter under the 'Video' tab.
---
--- See also `GetFrame(0)` to retrieve the root frame of the primary adapter and `GetFrame(1)` to retrieve the root frame of the secondary adapter. 
--- See also the following modules that manage these frames:
--- - Primary adapter: lua\ui\game\worldview.lua
--- - Secondary adapter: lua\ui\game\multihead.lua
---@return number
function GetNumRootFrames()
end

--- Retrieves the value of a game option from the preference file. The value is retrieved from the 'option' table in the preference file.
---@param key string
---@return any
function GetOptions(key)
end

--- Retrieves a value in the memory-stored preference file. The value retrieved is a deep copy of what resides in the actual 
--- preference file. Therefore this function can be expensive to use directly - if you're not careful you may be allocating 
--- kilobytes worth of data!
---
--- You're encouraged to use `/lua/user/prefs.lua` to interact with the preference file.
---@param string string
---@param default any?
---@return any
function GetPreference(string, default)
end

---
---@return boolean
function GetResourceSharing()
end

--- Gets the rollover information about the unit the cursor is currently hovered over.
--- The output of this function is replicated by `/lua/keymap/selectedinfo.lua#GetUnitRolloverInfo`
--- for any unit.
---@return RolloverInfo
function GetRolloverInfo()
end

--- Gets the state for the script bit
---@param unit UserUnit
---@param bit number
---@return boolean
function GetScriptBit(unit, bit)
end

--- Returns a table of the currently selected units
---@return UserUnit[]
function GetSelectedUnits()
end

--- Returns a table of the various clients in the current session.
--- Note that this is cached by `/lua/ui/override/SessionClients.lua`
---@return Client[]
function GetSessionClients()
end

---
---@return number
function GetSimRate()
end

---
---@return number
function GetSimTicksPerSecond()
end

--- Gets information on a profile based file, `nil` if unable to find
---@param profileName string
---@param basename string
---@param type string
---@return table
function GetSpecialFileInfo(profileName, basename, type)
end

--- Given the base name of a special file, returns the complete path
---@param profilename string
---@param filename string
---@param type string
---@return string
function GetSpecialFilePath(profilename,  filename,  type)
end

--- Returns a table of strings which are the names of files in special locations (currently SaveFile, Replay)
---@param type string
---@return { extension: string, directory: string, files: table<string, string[]> }
function GetSpecialFiles(type)
end

---
---@param type string
---@return string
function GetSpecialFolder(type)
end

--- Returns a formatted string displaying the System time
---@return string
function GetSystemTime()
end

--- Returns System time in seconds
---@return number
function GetSystemTimeSeconds()
end

---
---@param filename FileName
---@param border number? defaults to 1
---@return number width
---@return number height
function GetTextureDimensions(filename,  border)
end

--- Gets the alpha multiplier for 2D UI controls
---@return number
function GetUIControlsAlpha()
end

--- Given a set of units, gets the union of orders and unit categories (for determining builds). You can use `GetUnitCommandFromCommandCap` to convert the toggles to unit commands
---@param unitSet UserUnit[]
---@return string[] orders
---@return CommandCap[] availableToggles
---@return EntityCategory buildableCategories
function GetUnitCommandData(unitSet)
end

--- Retrieves the orders, toggles and buildable categories of the given unit. You can use `GetUnitCommandFromCommandCap` to convert the toggles to unit commands
---@param unit UserUnit
---@return string[] orders
---@return CommandCap[] availableToggles
---@return EntityCategory buildableCategories
function GetUnitCommandDataOfUnit(unit)
end

--- Given a `RULEUCC` type command, return the equivalent `UNITCOMMAND` command or "None" otherwise.  
--- See `/lua/ui/game/commandgraphparams.lua#CommandGraphParams` or `UserUnitCommand`.
--[[```
             RULEUCC_Move = Move
             RULEUCC_Stop = Stop
           RULEUCC_Attack = Attack
            RULEUCC_Guard = Guard
           RULEUCC_Patrol = Patrol
  RULEUCC_RetaliateToggle = None
           RULEUCC_Repair = Repair
          RULEUCC_Capture = Capture
        RULEUCC_Transport = TransportUnloadUnits
    RULEUCC_CallTransport = TransportLoadUnits
             RULEUCC_Nuke = Nuke
         RULEUCC_Tactical = Tactical
         RULEUCC_Teleport = Teleport
            RULEUCC_Ferry = Ferry
RULEUCC_SiloBuildTactical = BuildSiloTactical
    RULEUCC_SiloBuildNuke = BuildSiloNuke
        RULEUCC_Sacrifice = Sacrifice
            RULEUCC_Pause = Pause
       RULEUCC_Overcharge = OverCharge
             RULEUCC_Dive = Dive
          RULEUCC_Reclaim = Reclaim
    RULEUCC_SpecialAction = SpecialAction
             RULEUCC_Dock = None
           RULEUCC_Script = None
          RULEUCC_Invalid = None
```]]
---@param rule EngineCommandCap
---@return string | "None"
function GetUnitCommandFromCommandCap(rule)
end

--- Return a table of the currently selected units
---@return UserUnit[]
function GetValidAttackingUnits()
end

---
---@param category string
---@return number
function GetVolume(category)
end

---@return boolean
function GpgNetActive()
end

---@param command string
---@param ... number | string
function GpgNetSend(command, ...)
end

---
---@return boolean
function HasCommandLineArg(option)
end

--- Add a set of key mappings
---@param keyMapTable table<string, string>
function IN_AddKeyMapTable(keyMapTable)
end

--- Clear all key mappings
function IN_ClearKeyMap()
end

--- Remove the keys from the key map
---@param keyMapTable table<string, string>
function IN_RemoveKeyMapTable(keyMapTable)
end

--- Increase the count at a given location of the current build queue
---@param queueIndex number
---@param count number
function IncreaseBuildCountInQueue(queueIndex, count)
end

--- For internal use by `Bitmap.__init()`
---@param bitmap Bitmap
---@param parent Control
function InternalCreateBitmap(bitmap, parent)
end

--- For internal use by `Border.__init()`
---@param border Border
---@param parent Control
function InternalCreateBorder(border, parent)
end

--- For internal use by `CreateDiscoveryService()`
---@param serviceClass fa-class
---@return UILobbyDiscoveryService
function InternalCreateDiscoveryService(serviceClass)
end

--- For internal use by `Dragger.__init()`
---@param dragger Dragger
function InternalCreateDragger(dragger)
end

--- For internal use by `Edit.__init()`
---@param edit Edit
---@param parent Control
function InternalCreateEdit(edit, parent)
end

--- For internal use by `Frame.__init()`
---@param frame Frame
function InternalCreateFrame(frame)
end

--- For internal use by `Group.__init()`
---@param group Group
---@param parent Control
function InternalCreateGroup(group, parent)
end

--- For internal use by `Histogram.__init()`
---@param histogram Histogram
---@param parent Control
function InternalCreateHistogram(histogram, parent)
end

--- For internal use by `ItemList.__init()`
---@param itemList ItemList
---@param parent Control
function InternalCreateItemList(itemList, parent)
end

---@alias UILobbyProtocols "UDP" | "TCP" | "None

--- For internal use by `CreateLobbyComm()`
---@generic T
---@param lobbyComClass T
---@param protocol UILobbyProtocols
---@param localPort number
---@param maxConnections number
---@param playerName string
---@param playerUID? string
---@param natTraversalProvider? userdata
---@return T
function InternalCreateLobby(lobbyComClass, protocol, localPort, maxConnections, playerName, playerUID, natTraversalProvider)
end

--- For internal use by `MapPreview.__init()`
---@param mapPreview MapPreview
---@param parent Control
function InternalCreateMapPreview(mapPreview, parent)
end

--- For internal use by `Mesh.__init()`
---@param mesh Mesh
---@param parent Control
function InternalCreateMesh(mesh, parent)
end

--- For internal use by `Movie.__init()`
---@param movie Movie
---@param parent Control
function InternalCreateMovie(movie, parent)
end

--- For internal use by `ScrollBar.__init()`
---@param scrollBar Scrollbar
---@param parent Control
---@param axis ScrollAxis found in `/lua/scrollbar.lua#ScrollAxis`
function InternalCreateScrollbar(scrollBar, parent, axis)
end

--- For internal use by `Text.__init()`. This adds the engine lazyvars
--- `FontAscent`, `FontDescent`, `FontExternalLeading`, and `TextAdvance`.
---@param text Text
---@param parent Control
function InternalCreateText(text, parent)
end

--- For internal use by `WldUIProvider.__init()`
---@param wldUIProvider WldUIProvider
function InternalCreateWldUIProvider(wldUIProvider)
end

--- For internal use by `WorldMesh.__init()`
---@param worldMesh WorldMesh
function InternalCreateWorldMesh(worldMesh)
end

--- Save the current session
---@param filename string
---@param friendlyname string
---@param oncompletion fun(worked: boolean, errmsg: string)
function InternalSaveGame(filename, friendlyname, oncompletion)
end

---
---@param keyCode string | number
---@return boolean
function IsKeyDown(keyCode)
end

---@param playerId? string  # if not provided, will return whether the local player is an observer
---@return boolean
function IsObserver()
end

--- Issue a factory build or upgrade command to your selection
---@param command UserUnitBlueprintCommand
---@param blueprintid UnitId
---@param count number
---@param clear boolean? defaults to false
function IssueBlueprintCommand(command, blueprintid, count, clear)
end

--- Issue a factory build or upgrade command to the given units
---@see IssueBlueprintCommand
---@param units UserUnit[]
---@param command UserUnitBlueprintCommand
---@param blueprintid UnitId
---@param count number
---@param clear boolean? defaults to false
function IssueBlueprintCommandToUnits(units, command, blueprintid, count, clear)
end

--- Issue a factory build or upgrade command to the given unit
---@see IssueBlueprintCommand
---@param unit UserUnit
---@param command UserUnitBlueprintCommand
---@param blueprintid UnitId
---@param count number
---@param clear boolean? defaults to false
function IssueBlueprintCommandToUnit(unit, command, blueprintid, count, clear)
end

--- Issue a command to a given unit
---@param unit UserUnit
---@param command UserUnitCommand # Will crash the game if not a valid command.
---@param luaParams? table | string | number | boolean # Will crash the game if the table contains non-serializable types.
---@param clear? boolean
IssueUnitCommandToUnit = function(unit, command, luaParams, clear)
end

--- Issue a command to the current selection. 
---@param command UserUnitCommand # Will crash the game if not a valid command.
---@param luaParams? table | string | number | boolean # Will crash the game if the table contains non-serializable types.
---@param clear boolean?
function IssueCommand(command, luaParams, clear)
end

---
---@param clear boolean
function IssueDockCommand(clear)
end

--- Issue a command to the given units.
---@param unitList UserUnit[]
---@param command UserUnitCommand # Will crash the game if not a valid command.
---@param luaParams? table | string | number | boolean # Will crash the game if the table contains non-serializable types.
---@param clear? boolean
function IssueUnitCommand(unitList, command, luaParams, clear)
end

--- Given a MS Windows char code, returns the Maui char code
---@param charcode number
---@return number
function KeycodeMSWToMaui(charcode)
end

--- Given a char code from a key event, returns the MS Windows char code
---@param charcode number
---@return number
function KeycodeMauiToMSW(charcode)
end

---@deprecated
--- Will not work
function LaunchGPGNet()
end

--- Starts a replay of a given file, returns false if unable to launch
---@param filename string
---@return boolean
function LaunchReplaySession(filename)
end

--- Launch a new single player session
---@param sessionInfo UISinglePlayerSessionConfiguration
function LaunchSinglePlayerSession(sessionInfo)
end

---
---@param filename string
---@return boolean
function LoadSavedGame(filename)
end

---
---@param blueprintId string
function MapBorderAdd(blueprintId)
end

---
function MapBorderClear()
end

--- Open the default browser window to the specified URL
---@param url string
function OpenURL(url)
end

---
---@param category string
---@param pause boolean
function PauseSound(category, pause)
end

---
---@param category string
---@param pause boolean
function PauseVoice(category, pause)
end

---
---@param sound SoundHandle
---@param prepareOnly? boolean
---@return SoundHandle
function PlaySound(sound, prepareOnly)
end

---
---@param params any
function PlayTutorialVO(params)
end

---
---@param sound SoundHandle
---@param duck? boolean
---@return SoundHandle
function PlayVoice(sound, duck)
end

--- Make `dragger` the active dragger from a particular frame.
--- You can pass `nil` to cancel the current dragger.
---@param originFrame Frame
---@param keycode 'LBUTTON' | 'MBUTTON' | 'RBUTTON'
---@param dragger Dragger | nil
function PostDragger(originFrame, keycode, dragger)
end

--- Start a background load with the given map and mods.
--- If `hipri` is true, this will interrupt any previous loads in progress.
---@param mapname string        # path to the `scmap` file
---@param mods ModInfo[]
---@param hipri? boolean
function PrefetchSession(mapname, mods, hipri)
end

---
---@param handler function
function RemoveConsoleOutputReciever(handler)
end

--- Remove unit from the session extra select list
---@param unit UserUnit
function RemoveFromSessionExtraSelectList(unit)
end

--- Remove the control from the capture array (always first from back)
---@param control Control
function RemoveInputCapture(control)
end

--- Remove the profile directory and all special files
---@param profile string
function RemoveProfileDirectories(profile)
end

--- Remove a profile based file from the disc
---@param profilename string
---@param basename string
---@param type string
function RemoveSpecialFile(profilename, basename, type)
end

---
---@param render boolean
function RenderOverlayEconomy(render)
end

---
---@param render boolean
function RenderOverlayIntel(render)
end

---
---@param render boolean
function RenderOverlayMilitary(render)
end

--- Restart the current mission/skirmish/etc
function RestartSession()
end

--- Writes the preferences to disk to make it persistent. This is an expensive operation. The 
--- game does this automatically when it exits, there should be no reason to call this manually.
---
--- You're encouraged to use `/lua/user/prefs.lua` to interact with the preference file.
function SavePreferences()
end

--- Select the specified units
---@param units UserUnit[]?
function SelectUnits(units)
end

--- Return true iff the active session can be restarted
---@return boolean
function SessionCanRestart()
end

--- End the current game session.
--- The session says active, we just disconnect from everyone else and freeze play.
function SessionEndGame()
end

--- Return a table of command sources
---@return string[]
function SessionGetCommandSourceNames()
end

--- Return the local command source, or `0` if the local client can't issue commands
---@return number
function SessionGetLocalCommandSource()
end

--- Return the table of scenario info that was originally passed to the sim on launch
--- Unlike other engine functions that return tables, this function returns the same table each time it is called.
---@return UISessionSenarioInfo
function SessionGetScenarioInfo()
end

--- Return true iff there is a session currently running
---@return boolean
function SessionIsActive()
end

--- Return true iff the active session is a being recorded
---@return boolean
function SessionIsBeingRecorded()
end

--- Return true iff the session has been won or lost yet
---@return boolean
function SessionIsGameOver()
end

--- Return true iff the active session is a multiplayer session
---@return boolean
function SessionIsMultiplayer()
end

--- Return true iff observing is allowed in the active session
---@return boolean
function SessionIsObservingAllowed()
end

--- Return true iff the session is paused
---@return boolean
function SessionIsPaused()
end

--- Pause the world simulation
function SessionRequestPause()
end

--- Resume the world simulation
function SessionResume()
end

--- Sends a message to one, more or all other connected clients. This message is sent separately from the simulation. The message is not recorded in the replay. The message is transmit and received in order.
---@overload fun(message: table | number | string)
---@param client? number | number[]         # client or clients
---@param message table | number | string   # Can not be larger than 1024 bytes
function SessionSendChatMessage(client, message)
end

--- Set this as an active build template
---@param template UIBuildTemplate
function SetActiveBuildTemplate(template)
end

--- Set if anyone in the list is auto building or auto assisting
---@param units UserUnit[]
---@param mode boolean
function SetAutoMode(units, mode)
end

--- Set if anyone in the list is auto surfacing
---@param units UserUnit[]
---@param mode boolean
function SetAutoSurfaceMode(units, mode)
end

---
---@param unit UserUnit
---@return UIBuildQueue
function SetCurrentFactoryForQueueDisplay(unit)
end

---
---@param cursor UICursor
function SetCursor(cursor)
end

--- Set the specific fire state for the units passed in
---@param units UserUnit[]
---@param fireState FireState
function SetFireState(units, fireState)
end

---
---@param key string
---@param data any
function SetFrontEndData(key, data)
end

--- Set the desired game speed
---@param speed number
function SetGameSpeed(speed)
end

---
---@param volume number 0.0 - 2.0
function SetMovieVolume(volume)
end

---
---@param overlay string
---@param categories EntityCategory
---@param normalColor Color
---@param selectColor Color
---@param rolloverColor Color
---@param inner1 number
---@param inner2 number
---@param outer1 number
---@param outer2 number
function SetOverlayFilter(overlay, categories, normalColor, selectColor, rolloverColor, inner1, inner2, outer1, outer2)
end

---
---@param list RangeOverlay[]
---@see `/lua/ui/game/RangeOverlayParams.lua`
function SetOverlayFilters(list)
end

--- Pause or unpause the given units
---@param units UserUnit[]
---@param pause boolean
function SetPaused(units, pause)
end

--- Pause or unpause the given unit
---@param unit UserUnit
---@param pause boolean
function SetPausedOfUnit(unit, pause)
end

--- Updates a value in the preference file. Updating the preference file on disk is delayed until the application exits.
---
--- You're encouraged to use `/lua/user/prefs.lua` to interact with the preference file.
---@param key string
---@param obj any
function SetPreference(key, obj)
end

--- Set the alpha multiplier for 2D UI controls
---@param alpha number
function SetUIControlsAlpha(alpha)
end

---
---@param category string
---@param volume number 0.0 - 2.0
function SetVolume(category, volume)
end

--- If set, inverts the middle mouse button
---@param flag boolean
function SetInvertMidMouseButton(flag)
end

--- Performs a callback with the given identifier from `callback.Func` in `/lua/simcallbacks.lua`.
--- Optionally appends the unit selection to the arguments.
---@param callback SimCallback where `Func` represents the callback function and `Args` is additional data
---@param addUnitSelection? boolean toggles appending the unit selection to the callback
function SimCallback(callback, addUnitSelection)
end

---
---@param handle SoundHandle
---@return boolean
function SoundIsPrepared(handle)
end

---
---@param handle SoundHandle
function StartSound(handle)
end

---
function StopAllSounds()
end

---
---@param handle SoundHandle
---@param immediate? boolean defaults to false
function StopSound(handle, immediate)
end

---
---@param region Rectangle
function SyncPlayableRect(region)
end

--- Now also supports string with hex colors
--- Colors separated by commas, no spaces. Example:
--- TeamColorMode("ffffffff,ffff32ff,ffb76518,ffa79602")
--- colors will be applied to army according to its index. first color -> army with index 1, second color -> 2 etc.
---@param mode boolean | string
function TeamColorMode(mode)
end


-- TODO: do these kinds of functions (that duplicate in `Unit.lua`) also accept single units
-- like some of the other functions alude to?

--- Set the right fire state for the units passed in
---@param units UserUnit[]
---@param fireState FireState
function ToggleFireState(units, fireState)
end

---
---@param units UserUnit[]
---@param bit number
---@param state boolean
function ToggleScriptBit(units, bit, state)
end

---
---@param userunit UserUnit
---@param seconds? number
function UISelectAndZoomTo(userunit, seconds)
end

--- Select units based on a category expression
---@param expression string
---@param addToCurSel boolean
---@param inViewFrustum boolean
---@param nearestToMouse boolean
---@param mustBeIdle boolean
function UISelectionByCategory(expression, addToCurSel, inViewFrustum, nearestToMouse, mustBeIdle)
end

---
---@param units UserUnit[]
---@param seconds? number
function UIZoomTo(units, seconds)
end

--- Draws a circle in world. Must be called from `WorldView:OnRenderWorld` or it won't draw anything.
---@param pos Vector  # in world coordinates
---@param size number
---@param color Color
---@param thickness? number
function UI_DrawCircle(pos, size, color, thickness)

  -- Introduced by an assembly function, see also:
  -- - https://github.com/FAForever/FA-Binary-Patches/pull/47
  -- - https://github.com/FAForever/FA-Binary-Patches/pull/111
  -- - https://github.com/FAForever/FA-Binary-Patches/pull/112

end

--- Draws a rectangle in world. Must be called from `WorldView:OnRenderWorld` or it won't draw anything.
---@param pos Vector  # in world coordinates
---@param size number
---@param color Color
---@param thickness? number
function UI_DrawRect(pos, size, color, thickness)

  -- Introduced by an assembly function, see also:
  -- - https://github.com/FAForever/FA-Binary-Patches/pull/47
  -- - https://github.com/FAForever/FA-Binary-Patches/pull/111
  -- - https://github.com/FAForever/FA-Binary-Patches/pull/112

end

--- Draws a line in world. Must be called from `WorldView:OnRenderWorld` or it won't draw anything.
---@param position1 Vector  # in world coordinates
---@param position2 Vector  # in world coordinates
---@param color Color
---@param thickness? number
function UI_DrawLine(position1, position2, color, thickness)

  -- Introduced by an assembly function, see also:
  -- - https://github.com/FAForever/FA-Binary-Patches/pull/47
  -- - https://github.com/FAForever/FA-Binary-Patches/pull/111
  -- - https://github.com/FAForever/FA-Binary-Patches/pull/112

end

--- Draws a line in world. Must be called within `WorldView:OnRenderWorld`
---@param position1 Vector
---@param position2 Vector
---@param color Color
---@param thickness? number
function UI_DrawLine(position1, position2, color, thickness)
end

---
---@param view WorldView
---@param point Vector2
---@return Vector
function UnProject(view, point)
end

---
---@param ipaddr string
---@return string
function ValidateIPAddress(ipaddr)
end

--- Validate a list of units
---@param units UserUnit[]
---@return UserUnit[]
function ValidateUnitsList(units)
end

---
---@return boolean
function WorldIsLoading()
end

---
---@return boolean
function WorldIsPlaying()
end

--- For internal use by `Cursor.__init()`
---@param cursor UICursor
---@param spec fa-class | nil
function _c_CreateCursor(cursor, spec)
end

--- For internal use by `UserDecal.__init()`
---@param decal UserDecal
---@param spec fa-class | nil
function _c_CreateDecal(decal, spec)
end

--- For internal use by `PathDebugger.__init()`
---@param pathDebugger PathDebugger
---@param spec fa-class
function _c_CreatePathDebugger(pathDebugger, spec)
end