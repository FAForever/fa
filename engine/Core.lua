---@meta
---@diagnostic disable: lowercase-global

---@class FileName: string, stringlib
---@operator concat(FileName | string): FileName

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

---@class Rectangle     # A point-to-point based rectangle, where the first point is usually in the top left corner
---@field x0 number
---@field y0 number
---@field x1 number
---@field y1 number

---@alias Color string `EnumColor` or hexcode like `'RrGgBb'`, or `'AaRrGgBb'` with transparency
---@alias Bone string | number
---@alias Army string | number
---@alias Language "cn" | "cz" | "de" | "es" | "fr" | "it" | "pl" | "ru" | "tw" | "tzm" | "us"

-- note that these object span both the sim and user states
---@alias GoalObject moho.manipulator_methods | EconomyEvent | Camera

---@unknown
function AITarget()
end

--- sets the audio language
---@param language Language
function AudioSetLanguage(language)
end

--- returns the last component of a path
---@param fullPath FileName
---@param stripExtension boolean?
---@return FileName
function Basename(fullPath, stripExtension)
end

--- likely used for debugging, but the use is unknown
---@unknown
function BeginLoggingStats()
end

--- called during blueprint loading to update the loading animation
function BlueprintLoaderUpdateProgress()
end

--- creates an empty prefetch set
---@return moho.CPrefetchSet
function CreatePrefetchSet()
end

--- returns the currently running thread
---@return thread?
function CurrentThread()
end

--- returns the directory name
---@param fullPath FileName
---@return string
function Dirname(fullPath)
end

--- returns all files in the directory that matches the pattern
---@param directory FileName
---@param pattern string
---@return FileName[]
function DiskFindFiles(directory,  pattern)
end

--- returns a table of information for the given file, or `false` if the file doesn't exist 
---@param filename FileName
---@return table | false
function DiskGetFileInfo(filename)
end

--- converts a system path to a local path (based on the init file directories),
--- returns the path if it is already local
---@param SysOrLocalPath FileName
---@return FileName
function DiskToLocal(SysOrLocalPath)
end

--- stops logging stats and optionally exits the application
---@param exit boolean
function EndLoggingStats(exit)
end

--- returns true if a unit category contains this unit
---@param category EntityCategory
---@param unit Unit | UserUnit | UnitId | Projectile
function EntityCategoryContains(category, unit)
end

--- checks if the category is the empty category
---@param category EntityCategory
---@return boolean
function EntityCategoryEmpty(category)
end

---@overload fun(units: UserUnit[]): UserUnit[]
--- filters a list of units to only those found in the category
---@param category EntityCategory
---@param units Unit[]
---@return Unit[]
function EntityCategoryFilterDown(category, units)
end

--- computes a list of unit blueprint names that match the categories
---@param category EntityCategory
---@return string[]
function EntityCategoryGetUnitList(category)
end

--- returns an ordered list of named colors available for a `Color` instead of using a hexcode
---@return EnumColor[]
function EnumColorNames()
end

--- converts an Euler angle to a quaternion
---@param roll number
---@param pitch number
---@param yaw number
---@return Quaternion
function EulerToQuaternion(roll, pitch, yaw)
end

--- collapses all relative `/./` or `/../` directory names from a path
---@param fullPath FileName
---@return FileName
function FileCollapsePath(fullPath)
end

--- creates a new thread, passing all additional arguments to the callback
---@param callback function
---@param ... any
---@return thread
function ForkThread(callback, ...)
end

--- gets the blueprint of an object
---@overload fun(entity: Entity): EntityBlueprint
---@overload fun(mesh: Mesh): MeshBlueprint
---@overload fun(effect: moho.IEffect): EffectBlueprint
---@overload fun(projectile: Projectile): ProjectileBlueprint
---@overload fun(prop: Prop): PropBlueprint
---@overload fun(unit: UserUnit | Unit): UnitBlueprint
---@overload fun(weapon: Weapon): WeaponBlueprint
---@param object Object
---@return Blueprint
function GetBlueprint(object)
end

--- Retrieves the cue and bank of a sound table
---@param sound SoundHandle
---@return string cue
---@return string bank
function GetCueBank(sound)
end

--- The current army number that the player has focused, or `-1` for none (i.e. observer)
---@return number
function GetFocusArmy()
end

--- Return game time in seconds
---@return number
function GetGameTimeSeconds()
end

--- Retrieves the movie duration
---@param localFileName FileName
---@return number
function GetMovieDuration(localFileName)
end

---@param id EntityId
---@return UserUnit | Unit
function GetUnitById(id)
end

--- Retrieves the game version, as set by `version.lua`
---@return VERSION
function GetVersion()
end

---@param language Language
function HasLocalizedVO(language)
end

---@param army1 Army
---@param army2 Army
---@return boolean
function IsAlly(army1, army2)
end

--- Checks if the C-side of an object is destroyed / de-allocated
---@param entity? InternalObject
---@return boolean
function IsDestroyed(entity)
end

---@param army1 Army
---@param army2 Army
---@return boolean
function IsEnemy(army1, army2)
end

---@param army1 Army
---@param army2 Army
---@return boolean
function IsNeutral(army1, army2)
end

--- Destroys the c-side of a thread
---@param thread thread
function KillThread(thread)
end

--- Rounds a number to the nearest integer using the half-round-even rounding (banker's rules)
--- This means that it returns the closest integer and tie-breaks towards even numbers
--- (since a bias towards even numbers is less detrimental than an upward bias).
---@param number number
---@return integer
function MATH_IRound(number)
end

--- Applies linear interpolation between two values `a` and `b`
---@param s number Usually between 0 (returns `a`) and 1 (returns `b`)
---@param a number
---@param b number
---@return number
function MATH_Lerp(s,  a,  b)
end

--- Applies linear interpolation between two quaternions `L` and `R`
---@param alpha number
---@param L Quaternion
---@param R Quaternion
---@return Quaternion
function MinLerp(alpha, L, R)
end

--- Applies spherical linear interpolation between two quaternions `L` and `R`
---@param alpha number
---@param L Quaternion
---@param R Quaternion
---@return Quaternion
function MinSlerp(alpha, L, R)
end

--- Converts an orientation to a quaternion
---@param vector Vector
---@return Quaternion
function OrientFromDir(vector)
end

--- Parse a string to generate a new entity category
---@param cat UnparsedCategory
---@return EntityCategory
function ParseEntityCategory(cat)
end

--- Creates a point vector
---@alternative Not used, better off allocating a separate position and vector
---@param px number
---@param py number
---@param pz number
---@param vx number
---@param vy number
---@param vz number
---@return Vector position
---@return Vector velocity
function PointVector(px, py, pz, vx, vy, vz)
end

--- Generate a random number between `min` and `max`
---@param min number defaults to `0`
---@param max number defaults to `1`
---@return number
---@overload fun(max: number): number
---@overload fun(): number
function Random(min, max)
end

--- Make a sound parameters object. Note that this does not
--- take the same parameter that `Sound` does, this requires lowercase fields.
---@param sound {cue: string, bank: string, cutoff: number}
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

--- Define a beam effect, only works in `blueprints.lua`
---@param spec BeamBlueprint
function RegisterBeamBlueprint(spec)
end

--- Define a particle emitter, only works in `blueprints.lua`
---@param spec EmitterBlueprint
function RegisterEmitterBlueprint(spec)
end

--- Define mesh properties, only works in `blueprints.lua`
---@param spec MeshBlueprint
function RegisterMeshBlueprint(spec)
end

--- Define a projectile, only works in `blueprints.lua`
---@param spec ProjectileBlueprint
function RegisterProjectileBlueprint(spec)
end

--- Define a prop, only works in `blueprints.lua`
---@param spec PropBlueprint
function RegisterPropBlueprint(spec)
end

--- Defile a poly trail emitter, only works in `blueprints.lua`
---@param spec TrailBlueprint
function RegisterTrailEmitterBlueprint(spec)
end

--- Define a unit, only works in `blueprints.lua`
---@param spec UnitBlueprint
function RegisterUnitBlueprint(spec)
end

--- Resumes the thread after suspending it, does nothing if the thread wasn't suspended
---@see # Counterpart of SuspendCurrentThread
---@param thread thread
function ResumeThread(thread)
end

--- Returns how many seconds in a tick
---@return number
function SecondsPerTick()
end

--- Return true iff the active session is a replay session
---@return boolean
function SessionIsReplay()
end

---@param armyIndex number index or -1
function SetFocusArmy(armyIndex)
end

--- Prints a debug message to the moholog, this shouldn't be used in production code
---@param out any
---@param ... any
function SPEW(out, ...)
end

--- Splits the string on the delimiter, returning several smaller strings
---@param string string
---@param delimiter string
---@return string[]
function STR_GetTokens(string, delimiter)
end

--- Returns the number of characters in a UTF-8 string
---@param string string
---@return number
function STR_Utf8Len(string)
end

--- Returns a substring from start to count
---@param string string
---@param start number
---@param count number
---@return string
function STR_Utf8SubString(string,  start,  count)
end

--- Converts an integer into a hexidecimal string
---@param int number
---@return string 
function STR_itox(int)
end

--- Converts a hexidecimal string to an integer
---@param string string
---@return number
function STR_xtoi(string)
end

--- Sound({cue,bank,cutoff}) - Make a sound parameters object
---@param sound SoundBlueprint
---@return SoundHandle
function Sound(sound)
end

--- Define the footprint types for pathfinding, only works in `blueprints.lua`
---@param specs FootprintSpec[]
function SpecFootprints(specs)
end

--- Suspends the current thread indefinitely; only a call to `ResumeThread(thread)` can resume it
---@see ResumeThread
function SuspendCurrentThread()
end

--- Turns tracing on / off
---@param enable boolean
function Trace(enable)
end

--- Adds vector `b` to vector `a`
---@param a Vector
---@param b Vector
---@return Vector
function VAdd(a, b)
end

--- Subtracts vector `b` from vector `a`
---@param a Vector
---@param b Vector
---@return Vector
function VDiff(a, b)
end

--- Computes the distance between two points
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function VDist2(x1, y1, x2, y2)
end

--- Computes the squared distance between two points
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function VDist2Sq(x1, y1, x2, y2)
end

--- Computes the distance between the vectors `a` and `b`
---@param a Vector
---@param b Vector
---@return number
function VDist3(a, b)
end

--- Computes the squared distance between the vectors `a` and `b`
---@deprecated It is faster to compute it in Lua
---@param a Vector
---@param b Vector
---@return number
function VDist3Sq(a, b)
end

--- Computes the dot product between the vectors `a` and `b`
---@param a Vector
---@param b Vector
---@return number
function VDot(a, b)
end

--- Scales the vector `v` with the scalar `s`
---@param v Vector
---@param s number
---@return Vector
function VMult(v, s)
end

--- Computes the vector perpendicular to the plane described by the vectors `a` and `b`
---@param a Vector
---@param b Vector
---@return Vector
function VPerpDot(a, b)
end

--- Populates a new table with the corresponding meta table
---@param x number
---@param y number
---@param z number
---@return Vector
function Vector(x, y, z)
end

--- Populates a new table with the corresponding meta table
---@param x number
---@param y number
---@return Vector2
function Vector2(x, y)
end

--- Print a warning message to the moholog, this shouldn't be used in production code
---@param out any
---@param ... any
function WARN(out, ...)
end

--- suspends the thread until the object reaches its goal
---@param manipulator GoalObject
function WaitFor(manipulator)
end

--- Runs another script file. The environment table, if given,
--- will be used for the script's global variables.
---@param script FileName
---@param env? table
function doscript(script,  env)
end

--- returns true if the given resource file exists
---@param name FileName
function exists(name)
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
---@return PatchedDepositResult[]
function GetDepositsAroundPoint(x, z, radius, type)
end

