doscript '/lua/system/repr.lua'
-- local user = {AITarget = true, AddBlinkyBox = true, AddCommandFeedbackBlip = true, AddConsoleOutputReciever = true, AddInputCapture = true, AddSelectUnits = true, AddToSessionExtraSelectList = true, AnyInputCapture = true, AudioSetLanguage = true, Basename = true, BeginLoggingStats = true, BlueprintLoaderUpdateProgress = true, ClearBuildTemplates = true, ClearCurrentFactoryForQueueDisplay = true, ClearFrame = true, ClearSessionExtraSelectList = true, ConExecute = true, ConExecuteSave = true, ConTextMatches = true, CopyCurrentReplay = true, CreatePrefetchSet = true, CreateUnitAtMouse = true, CurrentThread = true, CurrentTime = true, DebugFacilitiesEnabled = true, DecreaseBuildCountInQueue = true, DeleteCommand = true, Dirname = true, DisableWorldSounds = true, DiskFindFiles = true, DiskGetFileInfo = true, DiskToLocal = true, EjectSessionClient = true, EnableWorldSounds = true, EndLoggingStats = true, EngineStartFrontEndUI = true, EngineStartSplashScreens = true, EntityCategoryContains = true, EntityCategoryEmpty = true, EntityCategoryFilterDown = true, EntityCategoryFilterOut = true, EntityCategoryGetUnitList = true, EnumColorNames = true, EulerToQuaternion = true, ExecLuaInSim = true, ExitApplication = true, ExitGame = true, FileCollapsePath = true, FlushEvents = true, ForkThread = true, FormatTime = true, GameTick = true, GameTime = true, GenerateBuildTemplateFromSelection = true, GetActiveBuildTemplate = true, GetAntiAliasingOptions = true, GetArmiesTable = true, GetArmyAvatars = true, GetArmyScore = true, GetAssistingUnitsList = true, GetAttachedUnitsList = true, GetBlueprint = true, GetCamera = true, GetCommandLineArg = true, GetCueBank = true, GetCurrentUIState = true, GetCursor = true, GetDepositsAroundPoint = true, GetEconomyTotals = true, GetFireState = true, GetFocusArmy = true, GetFrame = true, GetFrontEndData = true, GetGameSpeed = true, GetGameTime = true, GetGameTimeSeconds = true, GetIdleEngineers = true, GetIdleFactories = true, GetInputCapture = true, GetIsAutoMode = true, GetIsAutoSurfaceMode = true, GetIsPaused = true, GetIsSubmerged = true, GetMouseScreenPos = true, GetMouseWorldPos = true, GetMovieDuration = true, GetMovieVolume = true, GetNumRootFrames = true, GetOptions = true, GetPreference = true, GetResourceSharing = true, GetRolloverInfo = true, GetScriptBit = true, GetSelectedUnits = true, GetSessionClients = true, GetSimRate = true, GetSimTicksPerSecond = true, GetSpecialFileInfo = true, GetSpecialFilePath = true, GetSpecialFiles = true, GetSpecialFolder = true, GetSystemTime = true, GetSystemTimeSeconds = true, GetTextureDimensions = true, GetTimeForProfile = true, GetUIControlsAlpha = true, GetUnitById = true, GetUnitCommandData = true, GetUnitCommandFromCommandCap = true, GetValidAttackingUnits = true, GetVersion = true, GetVolume = true, GpgNetActive = true, GpgNetSend = true, HasCommandLineArg = true, HasLocalizedVO = true, IN_AddKeyMapTable = true, IN_ClearKeyMap = true, IN_RemoveKeyMapTable = true, IncreaseBuildCountInQueue = true, InternalCreateBitmap = true, InternalCreateBorder = true, InternalCreateDiscoveryService = true, InternalCreateDragger = true, InternalCreateEdit = true, InternalCreateFrame = true, InternalCreateGroup = true, InternalCreateHistogram = true, InternalCreateItemList = true, InternalCreateLobby = true, InternalCreateMapPreview = true, InternalCreateMesh = true, InternalCreateMovie = true, InternalCreateScrollbar = true, InternalCreateText = true, InternalCreateWldUIProvider = true, InternalCreateWorldMesh = true, InternalSaveGame = true, IsAlly = true, IsDestroyed = true, IsEnemy = true, IsKeyDown = true, IsNeutral = true, IsObserver = true, IssueBlueprintCommand = true, IssueCommand = true, IssueDockCommand = true, IssueUnitCommand = true, KeycodeMSWToMaui = true, KeycodeMauiToMSW = true, KillThread = true, LOG = true, LaunchGPGNet = true, LaunchReplaySession = true, LaunchSinglePlayerSession = true, LoadSavedGame = true, LuaDumpBinary = true, MATH_IRound = true, MATH_Lerp = true, MapBorderAdd = true, MapBorderClear = true, MinLerp = true, MinSlerp = true, OpenURL = true, OrientFromDir = true, ParseEntityCategory = true, PauseSound = true, PauseVoice = true, PlaySound = true, PlayTutorialVO = true, PlayVoice = true, PointVector = true, PostDragger = true, PrefetchSession = true, RPCSound = true, Random = true, Rect = true, RegisterBeamBlueprint = true, RegisterEmitterBlueprint = true, RegisterMeshBlueprint = true, RegisterProjectileBlueprint = true, RegisterPropBlueprint = true, RegisterTrailEmitterBlueprint = true, RegisterUnitBlueprint = true, RemoveConsoleOutputReciever = true, RemoveFromSessionExtraSelectList = true, RemoveInputCapture = true, RemoveProfileDirectories = true, RemoveSpecialFile = true, RenderOverlayEconomy = true, RenderOverlayIntel = true, RenderOverlayMilitary = true, RestartSession = true, ResumeThread = true, SPEW = true, STR_GetTokens = true, STR_Utf8Len = true, STR_Utf8SubString = true, STR_itox = true, STR_xtoi = true, SavePreferences = true, SecondsPerTick = true, SelectUnits = true, SessionCanRestart = true, SessionEndGame = true, SessionGetCommandSourceNames = true, SessionGetLocalCommandSource = true, SessionGetScenarioInfo = true, SessionIsActive = true, SessionIsBeingRecorded = true, SessionIsGameOver = true, SessionIsMultiplayer = true, SessionIsObservingAllowed = true, SessionIsPaused = true, SessionIsReplay = true, SessionRequestPause = true, SessionResume = true, SessionSendChatMessage = true, SetActiveBuildTemplate = true, SetAutoMode = true, SetAutoSurfaceMode = true, SetCurrentFactoryForQueueDisplay = true, SetCursor = true, SetFireState = true, SetFocusArmy = true, SetFrontEndData = true, SetGameSpeed = true, SetMovieVolume = true, SetOverlayFilter = true, SetOverlayFilters = true, SetPaused = true, SetPreference = true, SetUIControlsAlpha = true, SetVolume = true, SimCallback = true, Sound = true, SoundIsPrepared = true, SpecFootprints = true, StartSound = true, StopAllSounds = true, StopSound = true, SuspendCurrentThread = true, SyncPlayableRect = true, TeamColorMode = true, ToggleFireState = true, ToggleScriptBit = true, Trace = true, UISelectAndZoomTo = true, UISelectionByCategory = true, UIZoomTo = true, UnProject = true, VAdd = true, VDiff = true, VDist2 = true, VDist2Sq = true, VDist3 = true, VDist3Sq = true, VDot = true, VMult = true, VPerpDot = true, ValidateIPAddress = true, ValidateUnitsList = true, Vector = true, Vector2 = true, WARN = true, WaitFor = true, WorldIsLoading = true, WorldIsPlaying = true, _ALERT = true, _TRACEBACK = true, _c_CreateCursor = true, _c_CreateDecal = true, _c_CreatePathDebugger = true}
-- local sim = {ITarget = true, AddBuildRestriction = true, ArmyGetHandicap = true, ArmyInitializePrebuiltUnits = true, ArmyIsCivilian = true, ArmyIsOutOfGame = true, AttachBeamEntityToEntity = true, AttachBeamToEntity = true, AudioSetLanguage = true, Basename = true, BeginLoggingStats = true, BlueprintLoaderUpdateProgress = true, ChangeUnitArmy = true, CheatsEnabled = true, CoordinateAttacks = true, CreateAimController = true, CreateAnimator = true, CreateAttachedBeam = true, CreateAttachedEmitter = true, CreateBeamEmitter = true, CreateBeamEmitterOnEntity = true, CreateBeamEntityToEntity = true, CreateBeamToEntityBone = true, CreateBuilderArmController = true, CreateCollisionDetector = true, CreateDecal = true, CreateEconomyEvent = true, CreateEmitterAtBone = true, CreateEmitterAtEntity = true, CreateEmitterOnEntity = true, CreateFootPlantController = true, CreateInitialArmyUnit = true, CreateLightParticle = true, CreateLightParticleIntel = true, CreatePrefetchSet = true, CreateProp = true, CreatePropHPR = true, CreateResourceDeposit = true, CreateRotator = true, CreateSlaver = true, CreateSlider = true, CreateSplat = true, CreateSplatOnBone = true, CreateStorageManip = true, CreateThrustController = true, CreateTrail = true, CreateUnit = true, CreateUnit2 = true, CreateUnitHPR = true, CurrentThread = true, Damage = true, DamageArea = true, DamageRing = true, DebugGetSelection = true, Dirname = true, DiskFindFiles = true, DiskGetFileInfo = true, DiskToLocal = true, DrawCircle = true, DrawLine = true, DrawLinePop = true, EconomyEventIsDone = true, EndGame = true, EndLoggingStats = true, EntityCategoryContains = true, EntityCategoryCount = true, EntityCategoryCountAroundPosition = true, EntityCategoryEmpty = true, EntityCategoryFilterDown = true, EntityCategoryGetUnitList = true, EnumColorNames = true, EulerToQuaternion = true, FileCollapsePath = true, FlattenMapRect = true, FlushIntelInRect = true, ForkThread = true, GenerateArmyStart = true, GenerateRandomOrientation = true, GetArmyBrain = true, GetArmyUnitCap = true, GetArmyUnitCostTotal = true, GetBlueprint = true, GetCueBank = true, GetCurrentCommandSource = true, GetDepositsAroundPoint = true, GetEntitiesInRect = true, GetEntityById = true, GetFocusArmy = true, GetGameTick = true, GetGameTimeSeconds = true, GetMapSize = true, GetMovieDuration = true, GetReclaimablesInRect = true, GetSurfaceHeight = true, GetSystemTimeSecondsOnlyForProfileUse = true, GetTerrainHeight = true, GetTerrainType = true, GetTerrainTypeOffset = true, GetTimeForProfile = true, GetUnitBlueprintByName = true, GetUnitById = true, GetUnitsInRect = true, GetVersion = true, HasLocalizedVO = true, InitializeArmyAI = true, IsAlly = true, IsBlip = true, IsCollisionBeam = true, IsCommandDone = true, IsDestroyed = true, IsEnemy = true, IsEntity = true, IsGameOver = true, IsNeutral = true, IsProjectile = true, IsProp = true, IsUnit = true, IssueAggressiveMove = true, IssueAttack = true, IssueBuildFactory = true, IssueBuildMobile = true, IssueCapture = true, IssueClearCommands = true, IssueClearFactoryCommands = true, IssueDestroySelf = true, IssueDive = true, IssueFactoryAssist = true, IssueFactoryRallyPoint = true, IssueFerry = true, IssueFormAggressiveMove = true, IssueFormAttack = true, IssueFormMove = true, IssueFormPatrol = true, IssueGuard = true, IssueKillSelf = true, IssueMove = true, IssueMoveOffFactory = true, IssueNuke = true, IssueOverCharge = true, IssuePatrol = true, IssuePause = true, IssueReclaim = true, IssueRepair = true, IssueSacrifice = true, IssueScript = true, IssueSiloBuildNuke = true, IssueSiloBuildTactical = true, IssueStop = true, IssueTactical = true, IssueTeleport = true, IssueTeleportToBeacon = true, IssueTransportLoad = true, IssueTransportUnload = true, IssueTransportUnloadSpecific = true, IssueUpgrade = true, KillThread = true, LOG = true, LUnitMove = true, LUnitMoveNear = true, ListArmies = true, LuaDumpBinary = true, MATH_IRound = true, MATH_Lerp = true, MetaImpact = true, MinLerp = true, MinSlerp = true, NotifyUpgrade = true, OkayToMessWithArmy = true, OrientFromDir = true, ParseEntityCategory = true, PlayLoop = true, PointVector = true, RPCSound = true, Random = true, Rect = true, RegisterBeamBlueprint = true, RegisterEmitterBlueprint = true, RegisterMeshBlueprint = true, RegisterProjectileBlueprint = true, RegisterPropBlueprint = true, RegisterTrailEmitterBlueprint = true, RegisterUnitBlueprint = true, RemoveBuildRestriction = true, RemoveEconomyEvent = true, ResumeThread = true, SPEW = true, STR_GetTokens = true, STR_Utf8Len = true, STR_Utf8SubString = true, STR_itox = true, STR_xtoi = true, SecondsPerTick = true, SelectedUnit = true, SessionIsReplay = true, SetAlliance = true, SetAllianceOneWay = true, SetAlliedVictory = true, SetArmyAIPersonality = true, SetArmyColor = true, SetArmyColorIndex = true, SetArmyEconomy = true, SetArmyFactionIndex = true, SetArmyOutOfGame = true, SetArmyPlans = true, SetArmyShowScore = true, SetArmyStart = true, SetArmyStatsSyncArmy = true, SetArmyUnitCap = true, SetCommandSource = true, SetFocusArmy = true, SetIgnoreArmyUnitCap = true, SetIgnorePlayableRect = true, SetPlayableRect = true, SetTerrainType = true, SetTerrainTypeRect = true, ShouldCreateInitialArmyUnits = true, SimConExecute = true, Sound = true, SpecFootprints = true, SplitProp = true, StopLoop = true, SubmitXMLArmyStats = true, SuspendCurrentThread = true, Trace = true, TryCopyPose = true, VAdd = true, VDiff = true, VDist2 = true, VDist2Sq = true, VDist3 = true, VDist3Sq = true, VDot = true, VMult = true, VPerpDot = true, Vector = true, Vector2 = true, WARN = true, WaitFor = true, Warp = true, _ALERT = true, _TRACEBACK = true, _c_CreateEntity = true, _c_CreateShield = true}

-- local userFunctions = {}
-- local simFunctions = {}
-- local coreFunctions = {}

-- for fn,_ in user do
--     if sim[fn] then
--         table.insert(coreFunctions, fn)
--     else
--         table.insert(userFunctions, fn)
--     end
-- end
-- for fn,_ in sim do
--     if not user[fn] then
--         table.insert(simFunctions, fn)
--     end
-- end
-- table.sort(simFunctions)
-- table.sort(coreFunctions)
-- table.sort(userFunctions)
-- LOG("Sim functions: " .. table.concat(simFunctions, ', '))
-- LOG("Core functions: " .. table.concat(coreFunctions, ', '))
-- LOG("User functions: " .. table.concat(userFunctions, ', '))

-- local blacklist = {
--     __factory_objects = true,

--     math = true,
--     moho = true,
--     debug = true,
--     coroutine = true,
--     serialize = true,
--     string = true,
--     table = true,
--     _G = true,
--     _VERSION = true,
--     _LOADED = true,
--     __pow = true,
--     assert = true,
--     collectgarbage = true,
--     dofile = true,
--     error = true,
--     gcinfo = true,
--     getfenv = true,
--     getmetatable = true,
--     import = true,
--     ipairs = true,
--     loadfile = true,
--     loadstring = true,
--     newproxy = true,
--     next = true,
--     pairs = true,
--     pcall = true,
--     print = true,
--     rawequal = true,
--     rawget = true,
--     rawset = true,
--     require = true,
--     setfenv = true,
--     setmetatable = true,
--     tonumber = true,
--     tostring = true,
--     type = true,
--     unpack = true,
--     -- loaded repr.lua; ignore those functions
--     repr = true,
--     reprs = true,
--     reprsl = true,
--     repru = true,
-- }
-- LOG("INITIALIZING USER")
-- local functions = {}
-- local i = 1
-- for name, value in _G do
--     if not blacklist[name] then
--         -- LOG(string.format("%-50s%s", name, reprs(value, true)))
--         if type(value) == "cfunction" then
--             functions[i] = name
--             i = i + 1
--         else
--             LOG(" ! Flag " .. name .. " for review !")
--         end
--     end
-- end
-- local function lexicographic(name1, name2)
--     name1 = string.lower(name1)
--     name2 = string.lower(name2)
--     for i = 1, math.min(string.len(name1), string.len(name1)) do
--         local cmp = string.byte(name1, i) - string.byte(name2, i)
--         if cmp != 0 then
--             return cmp > 0
--         end
--     end
--     return string.len(name1) > string.len(name1)
-- end
-- table.sort(functions)
-- LOG(table.concat(functions, ', '))


-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--
-- This is the user-specific top-level lua initialization file. It is run at initialization time
-- to set up all lua state for the user layer.

-- Init our language from prefs. This applies to both front-end and session init; for
-- the Sim init, the engine sets __language for us.
__language = GetPreference('options_overrides.language', '')
-- Build language select options
__installedlanguages = DiskFindFiles("/loc/", '*strings_db.lua')
for index, language in __installedlanguages do
    language =  string.upper(string.gsub(language, ".*/(.*)/.*","%1"))
    __installedlanguages[index] = {text = language, key = language}
end


-- Do global init
doscript '/lua/globalInit.lua'

-- Do we have an custom language set inside user-options ?
local selectedlanguage = import('/lua/user/prefs.lua').GetFromCurrentProfile('options').selectedlanguage
if selectedlanguage ~= nil then
    __language = selectedlanguage
    SetPreference('options_overrides.language', __language)
    doscript '/lua/system/Localization.lua'
end

-- Do we have SC_LuaDebugger window positions in the config ?
if not GetPreference("Windows.Debug") then
    -- no, we set them to some sane defaults if they are missing. Othervise Debugger window is messed up
    SetPreference('Windows.Debug', {
        x = 10,
        y = 10,
        height = 550,
        width = 900,
        Sash = { horizontal = 212, vertical = 330 },
        Watch = {
            Stack = { block = 154, source = 212, line = 72 },
            Global = { value = 212, type = 215, name = 220 },
            Local = { value = 212, type = 134, name = 217 }
        }
    })
end

local AvgFPS = 10
WaitFrames = coroutine.yield

function WaitSeconds(n)
    local start = CurrentTime()
    local elapsed_frames = 0
    local elapsed_time = 0
    local wait_frames

    repeat
        wait_frames = math.ceil(math.max(1, AvgFPS*0.1, n * AvgFPS))
        WaitFrames(wait_frames)
        elapsed_frames = elapsed_frames + wait_frames
        elapsed_time = CurrentTime() - start
    until elapsed_time >= n

    if elapsed_time >= 3 then
        AvgFPS = math.max(10, math.min(200, math.ceil(elapsed_frames / elapsed_time)))
    end
end


-- a table designed to allow communication from different user states to the front end lua state
FrontEndData = {}

-- Prefetch user side data
Prefetcher = CreatePrefetchSet()

local FileCache =  {}
local oldDiskGetFileInfo = DiskGetFileInfo
function DiskGetFileInfo(file)
    if FileCache[file] == nil then
        FileCache[file] = oldDiskGetFileInfo(file) or false
    end
    return FileCache[file]
end

local oldEntityCategoryFilterOut = EntityCategoryFilterOut
function EntityCategoryFilterOut(categories, units)
    return oldEntityCategoryFilterOut(categories, units or {})
end

function PrintText(textData)
    if textData then
        local data = textData
        if type(textData) == 'string' then
            data = {text = textData, size = 14, color = 'ffffffff', duration = 5, location = 'center'}
        end
        import('/lua/ui/game/textdisplay.lua').PrintToScreen(data)
    end
end

local replayID = import('/lua/ui/uiutil.lua').GetReplayId()
if replayID then
    LOG("REPLAY ID: " .. replayID)
end
