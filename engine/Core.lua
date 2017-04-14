---Module: Core
-- @module Core

---
--  Create a target object
function AITarget()
end

---
--  base = Basename(fullPath,stripExtension?) -- return the last component of a path
function Basename(fullPath, stripExtension?)
end

---
--  Begin logging stats
function BeginLoggingStats()
end

---
--
function BlueprintLoaderUpdateProgress()
end

---
--  create an empty prefetch set
function CreatePrefetchSet()
end

---
--  thread=CurrentThread() -- get a handle to the running thread for later use with ResumeThread() or KillThread()
function CurrentThread()
end

---
--  base = Dirname(fullPath) -- return a path with trailing filename removed
function Dirname(fullPath)
end

---
--  files = DiskFindFiles(directory, pattern)returns a list of files in a directory
function DiskFindFiles(directory,  pattern)
end

---
--  info = DiskGetFileInfo(filename)returns a table describing the given file, or false if the file doesn't exist.
function DiskGetFileInfo(filename)
end

---
--  localPath = DiskToLocal(SysOrLocalPath)Converts a system path to a local path. Leaves path alone if already local.
function DiskToLocal(SysOrLocalPath)
end

---
--  EndLoggingStats(bool exit) - End logging stats and optionally exit app
function EndLoggingStats(bool exit)
end

---
--  Test for an empty category
function EntityCategoryEmpty()
end

---
--  Get a list of units blueprint names from a category
function EntityCategoryGetUnitList()
end

---
--  table EnumColorNames() - returns a table containing strings of all the color names
function EnumColorNames()
end

---
--  quaternion EulerToQuaternion(float roll, float pitch, float yaw) - converts euler angles to a quaternion
function EulerToQuaternion(float roll,  float pitch,  float yaw)
end

---
--  path = FileCollapsePath(fullPath) -- collapse out any intermediate /./ or /../ directory names from a path
function FileCollapsePath(fullPath)
end

---
--  thread = ForkThread(function, ...)Spawns a new thread running the given function with the given args.
function ForkThread(function,  ...)
end

---
--  cue,bank = GetCueBank(params)
function GetCueBank(params)
end

---
--  GetMovieDuration(localFileName)
function GetMovieDuration(localFileName)
end

---
--  GetVersion() -> string
function GetVersion()
end

---
--  Has the c++ object been destroyed?
function IsDestroyed()
end

---
--  KillThread(thread) -- destroy a thread started with ForkThread()
function KillThread(thread)
end

---
--  Print a log message
function LOG()
end

---
--  Round a number to the nearest integer
function MATH_IRound()
end

---
--  MATH_Lerp(s, a, b) or MATH_Lerp(s, sMin, sMax, a, b) -> number -- linear interpolation from a (at s=0 or s=sMin) to b (at s=1 or s=sMax)
function MATH_Lerp(s,  a,  b)
end

---
--  quaternion MinLerp(float alpha, quaternion L, quaternion R) - returns minimal lerp between L and R
function MinLerp(float alpha,  quaternion L,  quaternion R)
end

---
--  quaternion MinSlerp(float alpha, quaternion L, quaternion R) - returns minimal slerp between L and R
function MinSlerp(float alpha,  quaternion L,  quaternion R)
end

---
--  quaternion OrientFromDir(vector)
function OrientFromDir(vector)
end

---
--  Create a point vector(px,py,pz, vx,vy,vz)
function PointVector()
end

---
--  RPCSound({cue,bank,cutoff}) - Make a sound parameters object
function RPCSound({cue, bank, cutoff})
end

---
--  Create a 2d Rectangle (x0,y0,x1,y1)
function Rect()
end

---
--  BeamBlueprint { spec } - define a beam effect
function RegisterBeamBlueprint()
end

---
--  EmitterBlueprint { spec } - define a particle emitter
function RegisterEmitterBlueprint()
end

---
--  MeshBlueprint { spec } - define mesh properties
function RegisterMeshBlueprint()
end

---
--  ProjectileBlueprint { spec } - define a type of projectile
function RegisterProjectileBlueprint()
end

---
--  PropBlueprint { spec } - define a type of prop
function RegisterPropBlueprint()
end

---
--  TrailEmitterBlueprint { spec } - define a polytrail emitter
function RegisterTrailEmitterBlueprint()
end

---
--  UnitBlueprint { spec } - define a type of unit
function RegisterUnitBlueprint()
end

---
--  ResumeThread(thread) -- resume a thread that had been suspended with SuspendCurrentThread(). Does nothing if the thread wasn't suspended.
function ResumeThread(thread)
end

---
--  Spew to log
function SPEW()
end

---
--  table STR_GetTokens(string,delimiter)
function STR_GetTokens(string, delimiter)
end

---
--  int STR_Utf8Len(string) - return the number of characters in a UTF-8 string
function STR_Utf8Len(string)
end

---
--  string STR_Utf8SubString(string, start, count) - return a substring from start to count
function STR_Utf8SubString(string,  start,  count)
end

---
--  string STR_itox(int) - converts an integer into a hexidecimal string
function STR_itox(int)
end

---
--  int STR_xtoi(string) - converts a hexidecimal string to an integer
function STR_xtoi(string)
end

---
--  SecondsPerTick() - Return how many seconds in a tick
function SecondsPerTick()
end

---
--  Sound({cue,bank,cutoff}) - Make a sound parameters object
function Sound({cue, bank, cutoff})
end

---
--  SpecFootprints { spec } -- define the footprint types for pathfinding
function SpecFootprints()
end

---
--  SuspendCurrentThread() -- suspend this thread indefinitely. Some external event must eventually call ResumeThread() to resume it.
function SuspendCurrentThread()
end

---
--  Trace(true) -- turns on debug tracingTrace(false) -- turns it off again
function Trace(true)
end

---
--  Addition of two vectors
function VAdd()
end

---
--  Difference of two vectors
function VDiff()
end

---
--  Distance between two 2d points (x1,y1,x2,y2)
function VDist2()
end

---
--  Square of Distance between two 2d points (x1,y1,x2,y2)
function VDist2Sq()
end

---
--  Distance between two 3d points (v1,v2)
function VDist3()
end

---
--  Square of Distance between two 3d points (v1,v2)
function VDist3Sq()
end

---
--  Dot product of two vectors
function VDot()
end

---
--  Multiplication of vector with scalar
function VMult()
end

---
--  Perp dot product of two vectors
function VPerpDot()
end

---
--  Create a vector (x,y,z)
function Vector()
end

---
--  Create a vector (x,y)
function Vector2()
end

---
--  Pop up a warning dialog
function WARN()
end

---
--  WaitFor(event) -- suspend this thread until the event is set
function WaitFor(event)
end

---
--  doscript(script, [env]) -- run another script. The environment table, if given, will be used for the script's global variables.
function doscript(script,  [env])
end

---
--  exists(name) -> bool -- returns true if the given resource file exists
function exists(name)
end

