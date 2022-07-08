---@declare-global
---Module: User
--@module User


---@class SoundHandle


--- No clue what this does
---@param entityId number
---@param onTime number
---@param offTime number
---@param totalTime number
function AddBlinkyBox(entityId,  onTime,  offTime,  totalTime)
end

---
---@param meshInfo MeshInfo
---@param duration number
function AddCommandFeedbackBlip(meshInfo,  duration)
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
---@param selection table<Unit>
function AddSelectUnits(selection)
end

--- Add unit to the session extra select list
---@param unit Unit
function AddToSessionExtraSelectList(unit)
end

--- Return true if there is anything currently on the capture stack
---@return boolean
function AnyInputCapture()
end

--- Clear and disable the build templates
function ClearBuildTemplates()
end

---
function ClearCurrentFactoryForQueueDisplay()
end

--- Destroy all controls in frame, `nil` head will clear all frames
---@param head integer | nil
function ClearFrame(head)
end

--- Clear the session extra select list
function ClearSessionExtraSelectList()
end

--- Perform a console command
---@param command string
function ConExecute(command)
end

--- Perform a console command, saved to stack
---@param command string
function ConExecuteSave(command)
end

---comment
---@param text string
function ConTextMatches(text)
end

--- Copy the current replay to another file
---@param profile string
---@param newFilename string
function CopyCurrentReplay(profile, newFilename)
end

--- CreateUnitAtMouse
---@param blueprintId string
---@param ownerArmyIndex integer
---@param offsetMouseWorldPosX number
---@param offsetMouseWorldPosZ number
---@param rotation number
---@return Unit
function CreateUnitAtMouse(blueprintId, ownerArmyIndex, offsetMouseWorldPosX, offsetMouseWorldPosZ, rotation)
end

--- Get the current time in seconds, counting from 0 at application start.
--- This is wall-clock time and is unaffected by gameplay.
---@return number
function CurrentTime()
end

--- Return true if debug facilities are enabled
---@return boolean
function DebugFacilitiesEnabled()
end

---
---@param queueIndex integer
---@param count integer
function DecreaseBuildCountInQueue(queueIndex, count)
end

---
---@param id unknown
function DeleteCommand(id)
end

---
function DisableWorldSounds()
end

--- Eject another client from your session
---@param clientIndex integer
function EjectSessionClient(clientIndex)
end

---
function EnableWorldSounds()
end

--- Kill current UI and start main menu from top
function EngineStartFrontEndUI()
end

--- Kill current UI and start splash screens
function EngineStartSplashScreens()
end

--- See if a unit category contains this unit
function EntityCategoryContains()
end

--- Filter a list of units to only those found in the category
function EntityCategoryFilterDown()
end

--- Filter a list of units to exclude those found in the category
function EntityCategoryFilterOut()
end

--- Execute some lua code in the sim
function ExecLuaInSim()
end

--- Request that the application shut down
function ExitApplication()
end

--- Quit the sim, but not the app
function ExitGame()
end

--- Flush mouse/keyboard events
function FlushEvents()
end

--- Format a string displaying the time specified in seconds
---@param seconds number
---@return string
function FormatTime(seconds)
end

--- Get the current game time in ticks. The game time is the simulation time, that stops when the game is paused.
function GameTick()
end

--- Get the current game time in seconds. The game time is the simulation time, that stops when the game is paused.
function GameTime()
end

--- Generate and enable build templates from the current selection
function GenerateBuildTemplateFromSelection()
end

--- Get active build template back to Lua
function GetActiveBuildTemplate()
end

---
---@return table<integer>
function GetAntiAliasingOptions()
end

---
---@return ArmyInfo
function GetArmiesTable()
end

--- Return a table of avatar units for the army
---@return table
function GetArmyAvatars()
end

---
---@return integer
function GetArmyScore(armyIndex)
end

--- Get a list of units assisting me
function GetAssistingUnitsList()
end

--- Get a list of units blueprint attached to transports
function GetAttachedUnitsList()
end

---
function GetBlueprint()
end

---
---@param name any
---@return 
function GetCamera(name)
end

---
---@return CommandArgTable
function GetCommandLineArg(option,  number)
end

--- Return 'splash', 'frontend' or 'game' depending on the current state of the ui
---@return 'splash' | 'frontend' | 'game'
function GetCurrentUIState()
end

---
function GetCursor()
end

---
---@return table
function GetEconomyTotals()
end

--- Get the right fire state for the units passed in
---@param units table<Unit>
---@return boolean
function GetFireState(units)
end

---
---@return integer
function GetFocusArmy()
end

--- Return the root UI frame for a given head
---@param head integer
---@return Frame
function GetFrame(head)
end

---
---@param key string
---@return any
function GetFrontEndData(key)
end

--- Return the current game speed
---@return number
function GetGameSpeed()
end

--- Returns a formatted string displaying the time the game has been played
---@return string
function GetGameTime()
end

--- Returns game time in seconds
---@return number
function GetGameTimeSeconds()
end

--- Return a table of idle engineer units for the army
---@return table<Unit>
function GetIdleEngineers()
end

--- Return a table of idle factory units for the army
---@return table<Unit>
function GetIdleFactories()
end

--- Returns the current capture control, or nil if none
---@return Control | nil
function GetInputCapture()
end

--- See if anyone in the list is auto building
---@param units table<Unit>
---@return boolean
function GetIsAutoMode(units)
end

--- See if anyone in the list is auto surfacing
---@param units table<Unit>
---@return boolean
function GetIsAutoSurfaceMode(units)
end

--- Is anyone in this list builder paused?
---@param units table<Unit>
---@return boolean
function GetIsPaused(units)
end

-- FIXME it doesn't like negative numbers

---@alias SubmergeStatus
---| -1 #submerged
---| 0 #unknown
---| 1 #not submerged

--- Determine if units are submerged
---@param units table<Unit>
---@return SubmergeStatus
function GetIsSubmerged(units)
end

-- TODO these vectors may actually use x,y,z, fields?

---
---@return Vector
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

--- Return the current number of root frames (typically one per head)
---@return integer
function GetNumRootFrames()
end

---
---@return obj
function GetOptions()
end

---
---@param string string
---@param default any?
---@return obj
function GetPreference(string, default)
end

---
---@return boolean
function GetResourceSharing()
end

---
---@return RolloverInfo
function GetRolloverInfo()
end

--- Get the state for the script bit
function GetScriptBit()
end

--- Return a table of the currently selected units
---@return table
function GetSelectedUnits()
end

--- Return a table of the various clients in the current session
function GetSessionClients()
end

---
---@return number
function GetSimRate()
end

---
---@return integer
function GetSimTicksPerSecond()
end

--- Get information on a profile based file, `nil` if unable to find
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

--- Return a table of strings which are the names of files in special locations (currently SaveFile, Replay)
---@param type string
---@return table
function GetSpecialFiles(type)
end

---
---@param type string
---@return string
function GetSpecialFolder(type)
end

--- Return a formatted string displaying the System time
---@return string
function GetSystemTime()
end

--- Return System time in seconds
---@return number
function GetSystemTimeSeconds()
end

---
---@param filename string
---@param border number? default value 1
---@return number width, number height
function GetTextureDimensions(filename,  border)
end

--- Get the alpha multiplier for 2d UI controls
---@return number
function GetUIControlsAlpha()
end

---
---@param id string
---@return Unit
function GetUnitById(id)
end

--- Given a set of units, get the union of orders and unit categories (for determining builds)
---@param unitSet any
---@return table<string> orders
---@return table<OrderInfo> availableToggles
---@return table<CategorieType> buildableCategories
function GetUnitCommandData(unitSet)
end

--- Given a RULEUCC type command, return the equivalent UNITCOMMAND command
---@return string
function GetUnitCommandFromCommandCap(string)
end

--- Return a table of the currently selected units
---@return table
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

---
---@param language Language
function HasLocalizedVO(language)
end

--- Add a set of key mappings
function IN_AddKeyMapTable(keyMapTable)
end

--- Clear all key mappings
function IN_ClearKeyMap()
end

--- Remove the keys from the key map
function IN_RemoveKeyMapTable(keyMapTable)
end

---comment
---@param queueIndex any
---@param count integer
function IncreaseBuildCountInQueue(queueIndex, count)
end

--- For internal use by CreateBitmap()
---@param luaobj any
---@param parent any
function InternalCreateBitmap(luaobj, parent)
end

--- For internal use by CreateBorder()
---@param luaobj any
---@param parent any
function InternalCreateBorder(luaobj, parent)
end

---
---@param service Class
---@return Service
function InternalCreateDiscoveryService(service)
end

--- For internal use by CreateDragger()
---@param luaobj any
function InternalCreateDragger(luaobj)
end

---
---@param luaobj any
---@param parent any
function InternalCreateEdit(luaobj, parent)
end

--- For internal use by CreateFrame()
---@param luaobj any
function InternalCreateFrame(luaobj)
end

--- For internal use by CreateGroup()
---@param luaobj any
---@param parent any
function InternalCreateGroup(luaobj, parent)
end

--- For internal use by CreateHistogram()
---@param luaobj any
---@param parent any
function InternalCreateHistogram(luaobj, parent)
end

--- For internal use by CreateItemList()
---@param luaobj any
---@param parent any
function InternalCreateItemList(luaobj, parent)
end

---
---@param class any
---@param protocol string
---@param localPort integer
---@param maxConnections integer
---@param playerName string
---@param playerUID string
---@param natTraversalProvider userdata
function InternalCreateLobby(class, protocol, localPort, maxConnections, playerName, playerUID, natTraversalProvider)
end

---
---@param luaobj any
---@param parent any
function InternalCreateMapPreview(luaobj, parent)
end

--- For internal use by CreateMesh()
---@param luaobj any
---@param parent any
function InternalCreateMesh(luaobj, parent)
end

--- For internal use by CreateMovie()
---@param luaobj any
---@param parent any
function InternalCreateMovie(luaobj, parent)
end

--- For internal use by CreateScrollBar()
---@param luaobj any
---@param parent any
---@param axis "Vert"|"Horz" found in `/lua/scrollbar.lua#ScrollAxis`
function InternalCreateScrollbar(luaobj, parent, axis)
end

---
---@param luaobj any
---@param parent any
function InternalCreateText(luaobj, parent)
end

--- Create the C++ script object
---@param luaobj any
function InternalCreateWldUIProvider(luaobj)
end

--- For internal use by WorldMesh()
---@param luaobj any
function InternalCreateWorldMesh(luaobj)
end

--- Save the current session
---@param filename any
---@param friendlyname any
---@param oncompletion any
function InternalSaveGame(filename,  friendlyname,  oncompletion)
end

---
---@param army1 integer
---@param army2 integer
---@return boolean
function IsAlly(army1, army2)
end

---
---@param army1 integer
---@param army2 integer
---@return boolean
function IsEnemy(army1, army2)
end

---
---@param keyCode string
---@return boolean
function IsKeyDown(keyCode)
end

---
---@param army1 integer
---@param army2 integer
---@return boolean
function IsNeutral(army1, army2)
end

---
---@return boolean
function IsObserver()
end

---
---@param command string
---@param blueprintid string
---@param count integer
---@param clear boolean? defaults to false
function IssueBlueprintCommand(command, blueprintid, count, clear)
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
---@param unitList table<Unit>
---@param command string
---@param string string?
---@param clear boolean?
function IssueUnitCommand(unitList, command, string, clear)
end

--- Given a MS Windows char code, returns the Maui char code
---@param charcode integer
---@return integer
function KeycodeMSWToMaui(charcode)
end

--- Given a char code from a key event, returns the MS Windows char code
---@param charcode integer
---@return integer
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
---@param sessionInfo SessionInfo
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

--- Parse a string to generate a new entity category
---@param cat string
---@return CategorieType
function ParseEntityCategory(cat)
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
---@param sound BpSoundResult
---@param prepareOnly? boolean
---@return handle
function PlaySound(sound, prepareOnly)
end

---
---@param params any
function PlayTutorialVO(params)
end

---
---@param sound Sound
---@param duck? boolean
function PlayVoice(sound, duck)
end

--- Make 'dragger' the active dragger from a particular frame.
--- You can pass nil to cancel the current dragger.
---@param originFrame Frame
---@param keycode string
---@param dragger Dragger | nil
function PostDragger(originFrame,  keycode,  dragger)
end

--- Start a background load with the given map and mods.
--- If `hipri` is true, this will interrupt any previous loads in progress.
---@param mapname string
---@param mods table<Mod>
---@param hipri? boolean
function PrefetchSession(mapname,  mods,  hipri)
end

---
---@param min? number
---@param max number
---@overload fun(max?: number)
function Random(min, max)
end

---
---@param handler function
function RemoveConsoleOutputReciever(handler)
end

--- Remove unit from the session extra select list
---@param unit Unit
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
---@param units table<Unit>
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

--- Return a table of command sources.
---@return table<string>
function SessionGetCommandSourceNames()
end

--- Return the local command source, or `0` if the local client can't issue commands
---@return integer
function SessionGetLocalCommandSource()
end

--- Return the table of scenario info that was originally passed to the sim on launch
---@return ScenarioInfoTable
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

--- Return true iff the active session is a replay session
---@return boolean
function SessionIsReplay()
end

--- Pause the world simulation
function SessionRequestPause()
end

--- Resume the world simulation
function SessionResume()
end

---
---@param client? integer | table<integer> client or clients
---@param message string
function SessionSendChatMessage(client, message)
end

--- Set this as an active build template
---@param template BuildQueue
function SetActiveBuildTemplate(template)
end

--- Set if anyone in the list is auto building
---@param units table<Unit>
---@param mode boolean
function SetAutoMode(units, mode)
end

--- Set if anyone in the list is auto surfacing
---@param units table<Unit>
---@param mode boolean
function SetAutoSurfaceMode(units, mode)
end

---
---@param unit Unit
---@return BuildQueue
function SetCurrentFactoryForQueueDisplay(unit)
end

---
---@param cursor Cursor
function SetCursor(cursor)
end

--- Set the specific fire state for the units passed in
---@param units table<Unit>
---@param fireState FireState
function SetFireState(units, fireState)
end

---
---@param armyIndex integer index or -1
function SetFocusArmy(armyIndex)
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
---@param categories CategorieType
---@param normalColor string
---@param selectColor string
---@param rolloverColor string
---@param inner1 number
---@param inner2 number
---@param outer1 number
---@param outer2 number
function SetOverlayFilter(overlay, categories, normalColor, selectColor, rolloverColor, inner1, inner2, outer1, outer2)
end

---
---@param list table<RangeOverlay>
---@see `/lua/ui/game/RangeOverlayParams.lua`
function SetOverlayFilters(list)
end

--- Pause builders in this list
---@param selection table<Unit>
---@param paused boolean
function SetPaused(selection, paused)
end

---
---@param key string
---@param obj any
function SetPreference(key, obj)
end

--- Set the alpha multiplier for 2d UI controls
---@param alpha number
function SetUIControlsAlpha(alpha)
end

---
---@param category string
---@param volume number 0.0 - 2.0
function SetVolume(category, volume)
end

--- Performs a callback with the given identifier from `/lua/sim/simcallbacks.lua`.
--- Optionally appends the unit selection to the arguments.
---@param callback {Func: string, Args: table} where Func represents the callback functions and Args additional data
---@param addUnitSelection? boolean toggles appending the unit selection to the callback
function SimCallback(callback, addUnitSelection)
end

-- Something got messed up with whatever imported these functions, and not only did it
-- mix up comments and function names, it got them off by one
-- This means that I have no idea what function this goes to:
--       If bool is specified and true, sends the current selection with the command

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

---
---@param mode boolean
function TeamColorMode(mode)
end

-- TODO do these kinds of functions (that duplicate in `Unit.lua`) also accept single units
-- like some of the other functions alude to?

--- Set the right fire state for the units passed in
---@param units table<Unit>
---@param fireState FireState
function ToggleFireState(units, fireState)
end

---
---@param units table<Unit>
---@param bit integer
---@param state boolean
function ToggleScriptBit(units, bit, state)
end

---
---@param userunit Unit
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
---@param units table<Unit>
---@param seconds? number
function UIZoomTo(units, seconds)
end

---
---@param self WorldView maybe?
---@param point Vector2D
---@return Vector
function UnProject(self, point)
end

---
---@param ipaddr string
---@return string
function ValidateIPAddress(ipaddr)
end

--- Validate a list of units
---@param units table<Unit>
---@return table<Unit>
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

---
---@param luaobj any
---@param spec any
function _c_CreateCursor(luaobj, spec)
end

--- Create a decal in the user layer
function _c_CreateDecal(luaobj, spec)
end

---
---@param luaobj any
---@param spec any
function _c_CreatePathDebugger(luaobj, spec)
end

-- TODO due to how neglected these last functions seem to have been, PLEASE CHECK
-- then move to `/User/CDiscoveryService.lua`
moho.discovery_service_methods = {}

function moho.CDiscoveryService:Edit()
end

-- which is it????
---  CDiscoveryService.GetCount(self)
function GetGameCount()
end

---
function moho.CDiscoveryService.Reset(self)
end

------
-- New functions from engine patch:
------

---@alias PatchedDepositType
---| 0 #all
---| 1 #mass
---| 2 #hydrocarbon

---@class PatchedDepositResult
---@field X1 number
---@field X2 number
---@field Z1 number
---@field Z2 number
---@field Type PatchedDepositType
---@field Dist number

--- Return list of deposits around a point of type
---@param x number
---@param z number
---@param radius number
---@param type PatchedDepositType
---@return table<PatchedDepositResult>
function GetDepositsAroundPoint(x, z, radius, type)
end
