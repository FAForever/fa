---Module: User
-- @module User

---
--  AddBlinkyBox(entityId, onTime, offTime, totalTime)
function AddBlinkyBox(entityId,  onTime,  offTime,  totalTime)
end

---
--  AddCommandFeedbackBlip(meshInfoTable, duration)
function AddCommandFeedbackBlip(meshInfoTable,  duration)
end

---
--  handler AddConsoleOutputReciever(func(text))
function AddConsoleOutputReciever(func(text)
end

---
--  AddInputCapture(control) - set a control as the current capture
function AddInputCapture(control)
end

---
--  Add these units to the currently Selected lists
function AddSelectUnits()
end

---
--  Add unit to the session extra select list
function AddToSessionExtraSelectList()
end

---
--  bool AnyInputCapture() - returns true if there is anything currently on the capture stack
function AnyInputCapture()
end

---
--  AudioSetLanguage(name()
function AudioSetLanguage(name()
end

---
--  clear and disable the build templates.
function ClearBuildTemplates()
end

---
--  ClearCurrentFactoryForQueueDisplay()
function ClearCurrentFactoryForQueueDisplay()
end

---
--  ClearFrame(int head) - destroy all controls in frame, nil head will clear all frames
function ClearFrame(int head)
end

---
--  Clear the session extra select list
function ClearSessionExtraSelectList()
end

---
--  ConExecute('command string') -- Perform a console command
function ConExecute('command string')
end

---
--  ConExecuteSave('command string') -- Perform a console command, saved to stack
function ConExecuteSave('command string')
end

---
--  strings ContextMatches(string)
function ConTextMatches()
end

---
--  CopyCurrentReplay(string profile, string newFilename) - copy the current replay to another file
function CopyCurrentReplay(string profile,  string newFilename)
end

---
--  CreateUnitAtMouse
function CreateUnitAtMouse(string blueprintId, int ownerArmyIndex, float offsetMouseWorldPosX, float offsetMouseWorldPosZ, float rotation)
end

---
--  Get the current time in seconds, counting from 0 at application start. This is wall-clock time and is unaffected by gameplay.
function CurrentTime()
end

---
--  bool DebugFacilitiesEnabled() - returns true if debug facilities are enabled.
function DebugFacilitiesEnabled()
end

---
--  DecreaseBuildCountInQueue(queueIndex, count)
function DecreaseBuildCountInQueue(queueIndex,  count)
end

---
--  DeleteCommand(id)
function DeleteCommand(id)
end

---
--  DisableWorldSounds
function DisableWorldSounds()
end

---
--  EjectSessionClient(int clientIndex) -- eject another client from your session
function EjectSessionClient(int clientIndex)
end

---
--  EnableWorldSounds
function EnableWorldSounds()
end

---
--  EngineStartFrontEndUI() - kill current UI and start main menu from top
function EngineStartFrontEndUI()
end

---
--  EngineStartSplashScreens() - kill current UI and start splash screens
function EngineStartSplashScreens()
end

---
--  See if a unit category contains this unit
function EntityCategoryContains()
end

---
--  Filter a list of units to only those found in the category
function EntityCategoryFilterDown()
end

---
--  Filter a list of units to exclude those found in the category
function EntityCategoryFilterOut()
end

---
--  Execute some lua code in the sim
function ExecLuaInSim()
end

---
--  ExitApplication - request that the application shut down
function ExitApplication()
end

---
--  ExitGame() - Quits the sim, but not the app
function ExitGame()
end

---
--  FlushEvents() -- flush mouse/keyboard events
function FlushEvents()
end

---
--  string FormatTime(seconds) - format a string displaying the time specified in seconds
function FormatTime(seconds)
end

---
--  Get the current game time in ticks. The game time is the simulation time, that stops when the game is paused.
function GameTick()
end

---
--  Get the current game time in seconds. The game time is the simulation time, that stops when the game is paused.
function GameTime()
end

---
--  generate and enable build templates from the current selection.
function GenerateBuildTemplateFromSelection()
end

---
--  get active build template back to lua.
function GetActiveBuildTemplate()
end

---
--  obj GetAntiAliasingOptions()
function GetAntiAliasingOptions()
end

---
--  armyInfo GetArmiesTable()
function GetArmiesTable()
end

---
--  table GetArmyAvatars() - return a table of avatar units for the army
function GetArmyAvatars()
end

---
--  int GetArmyScore(armyIndex)
function GetArmyScore(armyIndex)
end

---
--  Get a list of units assisting me
function GetAssistingUnitsList()
end

---
--  Get a list of units blueprint attached to transports
function GetAttachedUnitsList()
end

---
--  blueprint = GetBlueprint()
function GetBlueprint()
end

---
--  GetCamera(name)
function GetCamera(name)
end

---
--  CommandArgTable GetCommandLineArg(option, number)
function GetCommandLineArg(option,  number)
end

---
--  state GetCurrentUIState() - returns 'splash', 'frontend' or 'game' depending on the current state of the ui
function GetCurrentUIState()
end

---
--  GetCursor()
function GetCursor()
end

---
--  table GetEconomyTotals()
function GetEconomyTotals()
end

---
--  Get the right fire state for the units passed in
function GetFireState()
end

---
--  GetFocusArmy()
function GetFocusArmy()
end

---
--  frame GetFrame(int head) - return the root UI frame for a given head
function GetFrame(int head)
end

---
--  table GetFrontEndData(key)
function GetFrontEndData(key)
end

---
--  Return the current game speed
function GetGameSpeed()
end

---
--  string GetGameTime() - returns a formatted string displaying the time the game has been played
function GetGameTime()
end

---
--  float GetGameTimeSeconds() - returns game time in seconds
function GetGameTimeSeconds()
end

---
--  table GetIdleEngineers() - return a table of idle engineer units for the army
function GetIdleEngineers()
end

---
--  table GetIdleFactories() - return a table of idle factory units for the army
function GetIdleFactories()
end

---
--  control GetInputCapture() - returns the current capture control, or nil if none
function GetInputCapture()
end

---
--  See if anyone in the list is auto building
function GetIsAutoMode()
end

---
--  See if anyone in the list is auto surfacing
function GetIsAutoSurfaceMode()
end

---
--  Is anyone ins this list builder paused?
function GetIsPaused()
end

---
--  Determine if units are submerged (-1), not submerged(1) or unable to tell (0)
function GetIsSubmerged()
end

---
--  vector GetMouseScreenPos()
function GetMouseScreenPos()
end

---
--  vector GetMouseWorldPos()
function GetMouseWorldPos()
end

---
--  GetMovieVolume()
function GetMovieVolume()
end

---
--  int GetNumRootFrames() - returns the current number of root frames (typically one per head
function GetNumRootFrames()
end

---
--  obj GetOptions()
function GetOptions()
end

---
--  obj GetPreference(string, [default])
function GetPreference(string,  [default])
end

---
--  bool GetResourceSharing()
function GetResourceSharing()
end

---
--  rolloverInfo GetRolloverInfo()
function GetRolloverInfo()
end

---
--  Get the state for the script big
function GetScriptBit()
end

---
--  table GetSelectedUnits() - return a table of the currently selected units
function GetSelectedUnits()
end

---
--  GetSessionClients() -- return a table of the various clients in the current session.
function GetSessionClients()
end

---
--  number GetSimRate()
function GetSimRate()
end

---
--  int GetSimTicksPerSecond()
function GetSimTicksPerSecond()
end

---
--  table GetSpecialFileInfo(string profileName, string basename, string type) - get information on a profile based file, nil if unable to find
function GetSpecialFileInfo(string profileName,  string basename,  string type)
end

---
--  string GetSpecialFilePath(string profilename, string filename, string type) - Given the base name of a special file, retuns the complete path
function GetSpecialFilePath(string profilename,  string filename,  string type)
end

---
--  table GetSpecialFiles(string type)- returns a table of strings which are the names of files in special locations (currently SaveFile, Replay)
function GetSpecialFiles(string type)
end

---
--  string GetSpecialFolder(string type)
function GetSpecialFolder(string type)
end

---
--  string GetSystemTime() - returns a formatted string displaying the System time
function GetSystemTime()
end

---
--  float GetSystemTimeSeconds() - returns System time in seconds
function GetSystemTimeSeconds()
end

---
--  width, height GetTextureDimensions(filename, border = 1)
function GetTextureDimensions(filename,  border = 1)
end

---
--  float GetUIControlsAlpha() -- get the alpha multiplier for 2d UI controls
function GetUIControlsAlpha()
end

---
--  GetUnitById(id)
function GetUnitById(id)
end

---
--  orders, buildableCategories, GetUnitCommandData(unitSet) -- given a set of units, gets the union of orders and unit categories (for determining builds)
function GetUnitCommandData(unitSet)
end

---
--  string GetUnitCommandFromCommandCap(string) - given a RULEUCC type command, return the equivalent UNITCOMMAND command
function GetUnitCommandFromCommandCap(string)
end

---
--  table GetValidAttackingUnits() - return a table of the currently selected units
function GetValidAttackingUnits()
end

---
--  float GetVolume(category)
function GetVolume(category)
end

---
--  bool GpgNetActive()
function GpgNetActive()
end

---
--  GpgNetSend(cmd,args...)
function GpgNetSend(cmd, args...)
end

---
--  HasCommandLineArg(option)
function HasCommandLineArg(option)
end

---
--  HasLocalizedVO(languageCode)
function HasLocalizedVO(languageCode)
end

---
--  IN_AddKeyMapTable(keyMapTable) - add a set of key mappings
function IN_AddKeyMapTable(keyMapTable)
end

---
--  IN_ClearKeyMap() - clears all key mappings
function IN_ClearKeyMap()
end

---
--  IN_RemoveKeyMapTable(keyMapTable) - removes the keys from the key map
function IN_RemoveKeyMapTable(keyMapTable)
end

---
--  DecreaseBuildCountInQueue(queueIndex, count)
function IncreaseBuildCountInQueue()
end

---
--  InternalCreateBitmap(luaobj,parent) -- for internal use by CreateBitmap()
function InternalCreateBitmap(luaobj, parent)
end

---
--  InternalCreateBorder(luaobj,parent) -- for internal use by CreateBorder()
function InternalCreateBorder(luaobj, parent)
end

---
--  InternalCreateDiscoveryService(class)
function InternalCreateDiscoveryService(class)
end

---
--  InternalCreateDragger(luaobj) -- for internal use by CreateDragger()
function InternalCreateDragger(luaobj)
end

---
--  InternalCreateEdit(luaobj,parent)
function InternalCreateEdit(luaobj, parent)
end

---
--  InternalCreateFrame(luaobj) -- For internal use by CreateFrame()
function InternalCreateFrame(luaobj)
end

---
--  InternalCreateGroup(luaobj,parent) -- For internal use by CreateGroup()
function InternalCreateGroup(luaobj, parent)
end

---
--  InternalCreateHistogram(luaobj,parent) -- For internal use by CreateHistogram()
function InternalCreateHistogram(luaobj, parent)
end

---
--  InternalCreateItemList(luaobj,parent) -- for internal use by CreateItemList()
function InternalCreateItemList(luaobj, parent)
end

---
--  InternalCreateLobby(class, string protocol, int localPort, int maxConnections, string playerName, string playerUID, Boxed<weak_ptr<INetNATTraversalProvider> > natTraversalProvider)
function InternalCreateLobby(class,  string protocol,  int localPort,  int maxConnections,  string playerName,  string playerUID,  Boxed<weak_ptr<INetNATTraversalProvider> > natTraversalProvider)
end

---
--  InternalCreateMapPreview(luaobj,parent)
function InternalCreateMapPreview(luaobj, parent)
end

---
--  InternalCreateMesh(luaobj,parent) -- for internal use by CreateMesh()
function InternalCreateMesh(luaobj, parent)
end

---
--  InternalCreateMovie(luaobj,parent) -- for internal use by CreateMovie()
function InternalCreateMovie(luaobj, parent)
end

---
--  InternalCreateScrollbar(luaobj,parent,axis) -- for internal use by CreateScrollBar()
function InternalCreateScrollbar(luaobj, parent, axis)
end

---
--  InternalCreateText(luaobj,parent)
function InternalCreateText(luaobj, parent)
end

---
--  InternalCreateWldUIProvider(luaobj) - create the C++ script object
function InternalCreateWldUIProvider(luaobj)
end

---
--  InternalCreateWorldMesh(luaobj) -- for internal use by WorldMesh()
function InternalCreateWorldMesh(luaobj)
end

---
--  InternalSaveGame(filename, friendlyname, oncompletion) -- save the current session.
function InternalSaveGame(filename,  friendlyname,  oncompletion)
end

---
--  IsAlly(army1,army2)
function IsAlly(army1, army2)
end

---
--  IsEnemy(army1,army2)
function IsEnemy(army1, army2)
end

---
--  IsKeyDown(keyCode)
function IsKeyDown(keyCode)
end

---
--  IsNeutral(army1,army2)
function IsNeutral(army1, army2)
end

---
--  IsObserver()
function IsObserver()
end

---
--  IssueBlueprintCommand(command, blueprintid, count, clear = false)
function IssueBlueprintCommand(command,  blueprintid,  count,  clear = false)
end

---
--  IssueCommand(command,[string],[clear])
function IssueCommand(command, [string], [clear])
end

---
--  IssueDockCommand(clear)
function IssueDockCommand(clear)
end

---
--  IssueUnitCommand(unitList,command,[string],[clear])
function IssueUnitCommand(unitList, command, [string], [clear])
end

---
--  int KeycodeMSWToMaui(int) - given a MS Windows char code, returns the Maui char code
function KeycodeMSWToMaui(int)
end

---
--  int KeycodeMauiToMSW(int) - given a char code from a key event, returns the MS Windows char code
function KeycodeMauiToMSW(int)
end

---
--  LaunchGPGNet()
function LaunchGPGNet()
end

---
--  bool LaunchReplaySession(filename) - starts a replay of a given file, returns false if unable to launch
function LaunchReplaySession(filename)
end

---
--  LaunchSinglePlayerSession(sessionInfo) -- launch a new single player session.
function LaunchSinglePlayerSession(sessionInfo)
end

---
--  bool LoadSavedGame(filename)
function LoadSavedGame(filename)
end

---
--  MapBorderAdd(blueprintid)
function MapBorderAdd(blueprintid)
end

---
--  MapBorderClear()
function MapBorderClear()
end

---
--  OpenURL(string) - open the default browser window to the specified URL
function OpenURL(string)
end

---
--  parse a string to generate a new entity category
function ParseEntityCategory()
end

---
--  PauseSound(categoryString,bPause)
function PauseSound(categoryString, bPause)
end

---
--  PauseVoice(categoryString,bPause)
function PauseVoice(categoryString, bPause)
end

---
--  handle = PlaySound(sndParams,prepareOnly)
function PlaySound(sndParams, prepareOnly)
end

---
--  PlayTutorialVO(params)
function PlayTutorialVO(params)
end

---
--  PlayVoice(params,duck)
function PlayVoice(params, duck)
end

---
--  PostDragger(originFrame, keycode, dragger)Make 'dragger' the active dragger from a particular frame. You can pass nil to cancel the current dragger.
function PostDragger(originFrame,  keycode,  dragger)
end

---
--  PrefetchSession(mapname, mods, hipri) -- start a background load with the given map and mods. If hipri is true, this will interrupt any previous loads in progress.
function PrefetchSession(mapname,  mods,  hipri)
end

---
--  Random([[min,] max])
function Random([[min, ] max])
end

---
--  RemoveConsoleOutputReciever(handler)
function RemoveConsoleOutputReciever(handler)
end

---
--  Remove unit from the session extra select list
function RemoveFromSessionExtraSelectList()
end

---
--  RemoveInputCapture(control) - remove the control from the capture array (always first from back)
function RemoveInputCapture(control)
end

---
--  RemoveProfileDirectories(string profile) - Removes the profile directory and all special files
function RemoveProfileDirectories(string profile)
end

---
--  RemoveSpecialFile(string profilename, string basename, string type) - remove a profile based file from the disc
function RemoveSpecialFile(string profilename,  string basename,  string type)
end

---
--  RenderOverlayEconomy(bool)
function RenderOverlayEconomy(bool)
end

---
--  RenderOverlayIntel(bool)
function RenderOverlayIntel(bool)
end

---
--  RenderOverlayMilitary(bool)
function RenderOverlayMilitary(bool)
end

---
--  RestartSession() - Restart the current mission/skirmish/etc
function RestartSession()
end

---
--  SavePreferences()
function SavePreferences()
end

---
--  Select the specified units
function SelectUnits()
end

---
--  Return true iff the active session can be restarted.
function SessionCanRestart()
end

---
--  End the current game session.:The session says active, we just disconnect from everyone else and freeze play.
function SessionEndGame()
end

---
--  Return a table of:command sources.
function SessionGetCommandSourceNames()
end

---
--  Return the local command source.:Returns 0 if the local client can't issue commands.
function SessionGetLocalCommandSource()
end

---
--  Return the table of scenario info that was originally passed to the sim on launch.
function SessionGetScenarioInfo()
end

---
--  Return true iff there is a session currently running
function SessionIsActive()
end

---
--  Return true iff the active session is a being recorded.
function SessionIsBeingRecorded()
end

---
--  Return true iff the session has been won or lost yet.
function SessionIsGameOver()
end

---
--  Return true iff the active session is a multiplayer session.
function SessionIsMultiplayer()
end

---
--  Return true iff observing is allowed in the active session.
function SessionIsObservingAllowed()
end

---
--  Return true iff the session is paused.
function SessionIsPaused()
end

---
--  Return true iff the active session is a replay session.
function SessionIsReplay()
end

---
--  Pause the world simulation.
function SessionRequestPause()
end

---
--  Resume the world simulation.
function SessionResume()
end

---
--  SessionSendChatMessage([client-or-clients,] message)
function SessionSendChatMessage([client-or-clients, ] message)
end

---
--  set this as an active build template.
function SetActiveBuildTemplate()
end

---
--  See if anyone in the list is auto building
function SetAutoMode()
end

---
--  See if anyone in the list is auto surfacing
function SetAutoSurfaceMode()
end

---
--  currentQueueTable SetCurrentFactoryForQueueDisplay(unit)
function SetCurrentFactoryForQueueDisplay(unit)
end

---
--  SetCursor(cursor)
function SetCursor(cursor)
end

---
--  Set the specific fire state for the units passed in
function SetFireState()
end

---
--  SetFocusArmy(armyIndex or -1)
function SetFocusArmy(armyIndex or -1)
end

---
--  SetFrontEndData(key, data)
function SetFrontEndData(key,  data)
end

---
--  Set the desired game speed
function SetGameSpeed()
end

---
--  SetMovieVolume(volume): 0.0 - 2.0
function SetMovieVolume(volume)
end

---
--  SetOverlayFilter()
function SetOverlayFilter()
end

---
--  SetOverlayFilters(list)
function SetOverlayFilters(list)
end

---
--  Pause builders in this list
function SetPaused()
end

---
--  SetPreference(string, obj)
function SetPreference(string,  obj)
end

---
--  SetUIControlsAlpha(float alpha) -- set the alpha multiplier for 2d UI controls
function SetUIControlsAlpha(float alpha)
end

---
--  SetVolume(category, volume)
function SetVolume(category,  volume)
end

---
--  SimCallback(callback[,bool]): Execute a lua function in sim
function SimCallback(callback[, bool])
end

---
-- SoundIsPrepared
function If bool is specified and true, sends the current selection with the command()
end

---
-- StartSound
function INFO: bool = SoundIsPrepared(handle)()
end

---
-- StopAllSounds
function INFO: StartSound(handle)()
end

---
-- StopSound
function INFO: StopAllSounds()
end

---
-- SyncPlayableRect
function INFO: StopSound(handle,[immediate=false])()
end

---
-- TeamColorMode
function INFO: SyncPlayableRect(region)()
end

---
-- ToggleFireState
function INFO: TeamColorMode(bool)()
end

---
-- ToggleScriptBit
function INFO: Set the right fire state for the units passed in()
end

---
-- UISelectAndZoomTo
function INFO: Set the right fire state for the units passed in()
end

---
-- UISelectionByCategory
function INFO: UISelectAndZoomTo(userunit,[seconds])()
end

---
-- UIZoomTo
function INFO: UISelectionByCategory(expression, addToCurSel, inViewFrustum, nearestToMouse, mustBeIdle) - selects units based on a category expression()
end

---
-- UnProject
function INFO: UIZoomTo(units,[seconds])()
end

---
-- ValidateIPAddress
function INFO: VECTOR3 UnProject(self,VECTOR2)()
end

---
-- ValidateUnitsList
function INFO: str = ValidateIPAddress(ipaddr)()
end

---
-- WorldIsLoading
function INFO: Validate a list of units()
end

---
-- WorldIsPlaying
function INFO: bool = WorldIsLoading()()
end

---
-- _c_CreateCursor
function INFO: bool = WorldIsPlaying()()
end

---
-- _c_CreateDecal
function INFO: _c_CreateCursor(luaobj,spec)()
end

---
-- _c_CreatePathDebugger
function INFO: Create a decal in the user layer()
end

---
-- print
function INFO: _c_CreatePathDebugger(luaobj,spec)()
end

---
--  User.CDiscoveryService Edit
function INFO: Print a log message()
end

---
--  CDiscoveryService.GetCount(self)
function GetGameCount()
end

---
--  CDiscoveryService.Reset(self)
function Reset(self)
end

---
--
function moho.discovery_service_methods()
end

------
-- New functions from engine patch:
------

-- Returns list of deposits
-- Type: 0 - All, 1 - Mass, 2 - Energy
-- Result: {{X1,X2,Z1,Z2,Type,Dist},...}
function GetDepositsAroundPoint(X, Z, Radius, Type)
end
