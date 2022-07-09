---@declare-global
---Module: Core
-- @module Core

---@class Quaternion
---@field [1] number
---@field [2] number
---@field [3] number
---@field [4] number

---@class Vector
---@field [1] number
---@field [2] number
---@field [3] number

---@class Vector2
---@field [1] number
---@field [2] number

---@class Position
---@field [1] number
---@field [2] number
---@field [3] number

---@class Rectangle     # A point-to-point based rectangle, where the first point is usually in the top left corner
---@field x0 number
---@field y0 number
---@field x1 number
---@field y1 number

---
--  Create a target object

function AITarget()
end

--- return the last component of a path
---@param fullPath string
---@param stripExtension boolean?
function Basename(fullPath, stripExtension)
end

--- Likely used for debugging, but the use is unknown
---@unknown
function BeginLoggingStats()
end


--- Called during blueprint loading to update the loading animation
function BlueprintLoaderUpdateProgress()
end

--- Create an empty prefetch set
---@unknown
function CreatePrefetchSet()
end

--- Returns the current running thread
---@return thread?
function CurrentThread()
end

---comment
---@param fullPath any
---@result 
function Dirname(fullPath)
end

--- Returns all files in the directory that matches the pattern
---@param directory any
---@param pattern any
---@return string[]
function DiskFindFiles(directory,  pattern)
end

--- Returns a table of information for the given file, or false if the file doesn't exist 
---@param filename string
---@return File | boolean
function DiskGetFileInfo(filename)
end

---
--  localPath = DiskToLocal(SysOrLocalPath)Converts a system path to a local path. Leaves path alone if already local.
function DiskToLocal(SysOrLocalPath)
end


---End logging stats and optionally exit app
---@param exit boolean
function EndLoggingStats(exit)
end

---
--  Test for an empty category
function EntityCategoryEmpty()
end

---
--  Get a list of units blueprint names from a category

--- Computes a list of unit blueprint names that match the categories
---@param categories Categories
---@return string[]
function EntityCategoryGetUnitList(categories)
end

---
--  table EnumColorNames() - returns a table containing strings of all the color names
function EnumColorNames()
end

--- Converts euler angles to a quaternion
---@param roll number float
---@param pitch number float
---@param yaw number float
---@return Quaternion
function EulerToQuaternion(roll, pitch, yaw)
end

---
--  path = FileCollapsePath(fullPath) -- collapse out any intermediate /./ or /../ directory names from a path
function FileCollapsePath(fullPath)
end

---
--  thread = ForkThread(function, ...)Spawns a new thread running the given function with the given args.

--- Creates a new thread, passing all additional arguments to the callback
---@param callback function
---@vararg any
---@return thread
function ForkThread(callback,  ...)
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

---  Print a log message
-- @param TextOne Log message
-- @param TextTwo Optional text
-- Output: "INFO: TextOne\000TextTwo"
function LOG(TextOne, TextTwo)
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
---@param alpha number
---@param L Quaternion
---@param R Quaternion
function MinLerp(alpha, L, R)
end

---
--  quaternion MinSlerp(float alpha, quaternion L, quaternion R) - returns minimal slerp between L and R
---@param alpha number
---@param L Quaternion
---@param R Quaternion
function MinSlerp(alpha, L, R)
end

--- Converts an orientation to a quaternion
---@param vector Vector
---@return Quaternion
function OrientFromDir(vector)
end


--- Creates a point vector
---@param px number
---@param py number
---@param pz number
---@param vx number
---@param vy number
---@param vz number
---@unknown
function PointVector(px, py, pz, vx, vy, vz)
end

---
--  RPCSound({cue,bank,cutoff}) - Make a sound parameters object
---@param sound {cue:unknown, bank:unknown, cutoff:unknown}
function RPCSound(sound)
end

--- Constructs a rectangle, usually the first point is in the top-left corner and the second is in the bottom-right corner
---@param x0 number
---@param y0 number
---@param x1 number
---@param y1 number
---@return Rectangle
function Rect(x0, y0, x1, y1)
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

--- Resumes the thread after suspending it, does nothing if the thread wasn't suspended
---@see # Counterpart of SuspendCurrentThread
---@param thread thread
function ResumeThread(thread)
end

---  Print a debug message
---@param TextOne string Debug message
---@param TextTwo string? Optional text
-- Output: "DEBUG: TextOne\000TextTwo"
function SPEW(TextOne,TextTwo)
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
---@param sound BpSound
---@return BpSoundResult
function Sound(sound)
end

---
--  SpecFootprints { spec } -- define the footprint types for pathfinding
function SpecFootprints()
end

---
--  SuspendCurrentThread() -- suspend this thread indefinitely. Some external event must eventually call ResumeThread() to resume it.

--- Suspends the current thread indefinitely. Only a call to `ResumeThread(thread)` can resume it
---@see ResumeThread
function SuspendCurrentThread()
end

---
--  Trace(true) -- turns on debug. tracingTrace(false) -- turns it off again
---@param enable boolean
function Trace(enable)
end

--- Adds vector `b` to vector `a`
---@param a Vector
---@param b Vector
function VAdd(a, b)
end

--- Subtracts vector `b` from vector `a`
---@param a Vector
---@param b Vector
function VDiff(a, b)
end

--- Computes the distance between two points
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function VDist2(x1, y1, x2, y2)
end

--- Computes the squared distance between two points
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
function VDist2Sq(x1, y1, x2, y2)
end

--- Computes the distance between the vectors `a` and `b`
---@param a Vector
---@param b Vector
function VDist3()
end

--- Computes the squared distance between the vectors `a` and `b`
---@deprecated It is faster to compute it in Lua
---@param a Vector
---@param b Vector
function VDist3Sq(a, b)
end

--- Computes the dot product between the vectors `a` and `b`
---@param a Vector
---@param b Vector
function VDot(a, b)
end

--- Scales the vector `v` with the scalar `s`
---@param v Vector
---@param s number
function VMult(v, s)
end
--- Computes the vector perpendicular to the plane described by the vectors `a` and `b`
---@param a Vector
---@param b Vector
function VPerpDot(a, b)
end

--- Populates a new table with the corresponding meta table
---@param x number
---@param y number
---@param z number
function Vector(x, y, z)
end

--- Populates a new table with the corresponding meta table
---@param x number
---@param y number
function Vector2(x, y)
end

---  Print a warning message
---@param TextOne string Warning message
---@param TextTwo string? Optional text
-- Output: "WARNING: TextOne\000TextTwo"
function WARN(TextOne, TextTwo)
end

--- Suspends the thread until the manipulator reaches its goal
---@param manipulator moho.manipulator_methods
function WaitFor(manipulator)
end

---
--  doscript(script, [env]) -- run another script. The environment table, if given, will be used for the script's global variables.
---comment
---@param script string
---@param env table?
---@diagnostic disable-next-line: lowercase-global
function doscript(script,  env)
end

---
--  exists(name) -> bool -- returns true if the given resource file exists
---@param name string
---@diagnostic disable-next-line: lowercase-global
function exists(name)
end

