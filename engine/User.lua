---@meta


---@alias SubmergeStatus
---| -1  # submerged
---|  0  # unknown
---|  1  # not submerged


---@alias FireState
---| 0 # Return fire
---| 1 # Hold fire
---| 2 # Ground fire

--- No clue what this does
---@param entityId number
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

---
---@param id unknown
function DeleteCommand(id)
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

--- Executes some Lua code in the sim
---@param func function
---@param ... any this may actually be a comma-separated string of args instead of a vararg
---@return any
function ExecLuaInSim(func, ...)
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
---@return BuildTemplate
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

--- Gets the following arguments to a commandline option. For example, if `/arg -flag key:value drop`
--- was passed to the commandline, then `GetCommandLineArg("/arg", 2)` would return
--- `{"-flag", "key:value"}`
---@see GetCommandLineArgTable(option) for parsing key-values
---@param option string
---@param maxArgs number
---@return string[]?
function GetCommandLineArg(option, maxArgs)
end

--- Returns 'splash', 'frontend', or 'game' depending on the current state of the UI
---@return 'splash' | 'frontend' | 'game'
function GetCurrentUIState()
end

---
---@return Cursor
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

--- Returns the root UI frame for a given head
---@param head number
---@return Frame
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

--- Returns the current number of root frames (typically one per head)
---@return number
function GetNumRootFrames()
end

---
---@param key string
---@return string[]
function GetOptions(key)
end

---
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
---@param filename string
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
---@param unitSet any
---@return string[] orders
---@return CommandCap[] availableToggles
---@return EntityCategory buildableCategories
function GetUnitCommandData(unitSet)
end

--- Retrieves the orders, toggles and buildable categories of the given unit. You can use `GetUnitCommandFromCommandCap` to convert the toggles to unit commands
---@param unit any
---@return string[] orders
---@return CommandCap[] availableToggles
---@return EntityCategory buildableCategories
function GetUnitCommandDataOfUnit(unit)
end

--- Givens a `RULEUCC` type command, return the equivalent `UNITCOMMAND` command.
--- See `/lua/ui/game/commandgraphparams.lua#CommandGraphParams`.
---@param rule CommandCap
---@return string
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

---@param cmd string
---@param ... any
function GpgNetSend(cmd, ...)
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

---
---@param queueIndex any
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
---@return DiscoveryService
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

--- For internal use by `CreateLobbyComm()`
---@param lobbyComClass fa-class
---@param protocol string
---@param localPort number
---@param maxConnections number
---@param playerName string
---@param playerUID string
---@param natTraversalProvider userdata
---@return LobbyComm
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

---
---@param playerId string
---@return boolean
function IsObserver(playerId)
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

---
---@param command any
---@param string any?
---@param clear boolean?
function IssueCommand(command, string, clear)
end

---
---@param clear boolean
function IssueDockCommand(clear)
end

---
---@param unitList UserUnit[]
---@param command string
---@param string? string
---@param clear? boolean
function IssueUnitCommand(unitList, command, string, clear)
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
---@param sessionInfo UIScenarioInfo
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
---@param keycode string
---@param dragger Dragger | nil
function PostDragger(originFrame, keycode, dragger)
end

--- Start a background load with the given map and mods.
--- If `hipri` is true, this will interrupt any previous loads in progress.
---@param mapname string
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

---
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
---@return UIScenarioInfo
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
 
---
---@param client? number | number[] client or clients
---@param message table | number | string
function SessionSendChatMessage(client, message)
end

--- Set this as an active build template
---@param template BuildTemplate
function SetActiveBuildTemplate(template)
end

--- Set if anyone in the list is auto building
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
---@param cursor Cursor
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

---
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
---@param cursor Cursor
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