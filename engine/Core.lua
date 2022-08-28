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

---@class Rectangle     # A point-to-point based rectangle, where the first point is usually in the top left corner
---@field x0 number
---@field y0 number
---@field x1 number
---@field y1 number

---@alias Color string # `EnumColor` or hexcode like `'RrGgBb'`, or `'AaRrGgBb'` with transparency

---@unknown
function AITarget()
end

--- Returns the last component of a path
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
---@return userdata
function CreatePrefetchSet()
end

--- Returns the current running thread
---@return thread?
function CurrentThread()
end

--- Returns the directory name
---@param fullPath any
---@result string
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
---@return any | boolean
function DiskGetFileInfo(filename)
end

--- Converts a system path to a local path (based on the init file directories), returns the path if it is already local
---@param SysOrLocalPath string
---@return string
function DiskToLocal(SysOrLocalPath)
end


---End logging stats and optionally exit app
---@param exit boolean
function EndLoggingStats(exit)
end

--- Checks for the empty category
---@param categories Color
---@return boolean
function EntityCategoryEmpty(categories)
end

--- Computes a list of unit blueprint names that match the categories
---@param categories EntityCategory
---@return string[]
function EntityCategoryGetUnitList(categories)
end

--- Returns an ordered list of named colors available for a `Color` instead of using a hexcode
---@return EnumColor[]
function EnumColorNames()
end

--- Converts euler angles to a quaternion
---@param roll number
---@param pitch number
---@param yaw number
---@return Quaternion
function EulerToQuaternion(roll, pitch, yaw)
end

--- Collapse all intermediate `/./` or `/../` directory names from a path
---@param fullPath string
---@return string
function FileCollapsePath(fullPath)
end

--- Creates a new thread, passing all additional arguments to the callback
---@param callback function
---@vararg any
---@return thread
function ForkThread(callback,  ...)
end

--- Retrieves the cue and bank of a sound table
---@param sound BpAudio
---@return string The cue identifier within the bank
---@return string The bank identifier
function GetCueBank(sound)
end

--- Retrieves the movie duration
---@param localFileName string
---@return number
function GetMovieDuration(localFileName)
end

--- Retrieves the game version, as set by `version.lua`
---@return string
function GetVersion()
end

--- Checks if the C-side of an object is destroyed / de-allocated
---@param entity Entity | Unit | Prop | Weapon
---@return boolean
function IsDestroyed(entity)
end

--- Destroys the c-side of a thread
---@param thread thread
function KillThread(thread)
end

--- Print a message to the moho logger, this shouldn't be used in production code
---@param TextOne string
---@param TextTwo? string
function LOG(TextOne, TextTwo)
end

--- Rounds a number to the nearest integer using the half-round-even rounding (banker's rules)
---@param number number
function MATH_IRound(number)
end

--- Applies linear interpolation between two values `a` and `b`
---@param s number Usually between 0 (returns `a`) and 1 (returns `b`)
---@param a number
---@param b number
function MATH_Lerp(s,  a,  b)
end

--- Applies linear interpolation between two quaternions `L` and `R`
---@param alpha number
---@param L Quaternion
---@param R Quaternion
function MinLerp(alpha, L, R)
end

--- Applies spherical linear interpolation between two quaternions `L` and `R`
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
---@alternative Not used, better off allocating a separate position and vector
---@param px number
---@param py number
---@param pz number
---@param vx number
---@param vy number
---@param vz number
function PointVector(px, py, pz, vx, vy, vz)
end

--- RPCSound({cue,bank,cutoff}) - Make a sound parameters object
---@param sound { cue:string, bank:string, cutoff:number }
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
---@param spec any
function RegisterBeamBlueprint(spec)
end

--- Define a particle emitter, only works in `blueprints.lua`
---@param spec any
function RegisterEmitterBlueprint(spec)
end

--- Define mesh properties, only works in `blueprints.lua`
---@param spec any
function RegisterMeshBlueprint(spec)
end

--- Define a projectile, only works in `blueprints.lua`
---@param spec any
function RegisterProjectileBlueprint(spec)
end

--- Define a prop, only works in `blueprints.lua`
---@param spec any
function RegisterPropBlueprint(spec)
end

--- Defile a poly trail emitter, only works in `blueprints.lua`
---@param spec any
function RegisterTrailEmitterBlueprint(spec)
end

--- Define a unit, only works in `blueprints.lua`
---@param spec any
function RegisterUnitBlueprint(spec)
end

--- Resumes the thread after suspending it, does nothing if the thread wasn't suspended
---@see # Counterpart of SuspendCurrentThread
---@param thread thread
function ResumeThread(thread)
end

--- Print a debug message to the moholog, this shouldn't be used in production code
---@param TextOne string Debug message
---@param TextTwo string? Optional text
-- Output: "DEBUG: TextOne\000TextTwo"
function SPEW(TextOne,TextTwo)
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
function STR_Utf8SubString(string,  start,  count)
end

--- Converts an integer into a hexidecimal string
---@param int number
---@return string 
function STR_itox(int)
end

---  Converts a hexidecimal string to an integer
---@param string string
---@return number
function STR_xtoi(string)
end

--- Returns how many seconds in a tick
---@return number
function SecondsPerTick()
end

--- Sound({cue,bank,cutoff}) - Make a sound parameters object
---@param sound BpSound
---@return BpSoundResult
function Sound(sound)
end

--- Define the footprint types for pathfinding, only works in `blueprints.lua`
---@param spec any
function SpecFootprints(spec)
end

--- Suspends the current thread indefinitely. Only a call to `ResumeThread(thread)` can resume it
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

--- Print a warning message to the moholog, this shouldn't be used in production code
---@param TextOne string Warning message
---@param TextTwo string? Optional text
-- Output: "WARNING: TextOne\000TextTwo"
function WARN(TextOne, TextTwo)
end

--- Suspends the thread until the manipulator reaches its goal
---@param manipulator moho.manipulator_methods
function WaitFor(manipulator)
end

--- Run another script. The environment table, if given, will be used for the script's global variables.
---@param script string
---@param env? table
---@diagnostic disable-next-line: lowercase-global
function doscript(script,  env)
end

--- Returns if the given resource file exists
---@param name string
---@diagnostic disable-next-line: lowercase-global
function exists(name)
end


---@alias EnumColor
---| "AliceBlue"            #F7FBFF
---| "AntiqueWhite"         #FFEBD6
---| "Aqua"                 #00FFFF
---| "Aquamarine"           #7BFFD6
---| "Azure"                #F7FFFF
---| "Beige"                #F7F7DE
---| "Bisque"               #FFE7C6
---| "Black"                #000000
---| "BlanchedAlmond"       #FFEBCE
---| "Blue"                 #0000FF
---| "BlueViolet"           #8C28E7
---| "Brown"                #A52829
---| "BurlyWood"            #DEBA84
---| "CadetBlue"            #5A9EA5
---| "Chartreuse"           #7BFF00
---| "Chocolate"            #D66918
---| "Coral"                #FF7D52
---| "CornflowerBlue"       #6396EF
---| "Cornsilk"             #FFFBDE
---| "Crimson"              #DE1439
---| "Cyan"                 #00FFFF
---| "DarkBlue"             #00008C
---| "DarkCyan"             #008A8C
---| "DarkGoldenrod"        #BD8608
---| "DarkGray"             #ADAAAD
---| "DarkGreen"            #006500
---| "DarkKhaki"            #BDB66B
---| "DarkMagenta"          #8C008C
---| "DarkOliveGreen"       #526929
---| "DarkOrange"           #FF8E00
---| "DarkOrchid"           #9C30CE
---| "DarkRed"              #8C0000
---| "DarkSalmon"           #EF967B
---| "DarkSeaGreen"         #8CBE8C
---| "DarkSlateBlue"        #4A3C8C
---| "DarkSlateGray"        #294D4A
---| "DarkTurquoise"        #00CFD6
---| "DarkViolet"           #9400D6
---| "DeepPink"             #FF1494
---| "DeepSkyBlue"          #00BEFF
---| "DimGray"              #6B696B
---| "DodgerBlue"           #1892FF
---| "Firebrick"            #B52021
---| "FloralWhite"          #FFFBF7
---| "ForestGreen"          #218A21
---| "Fuchsia"              #FF00FF
---| "Gainsboro"            #DEDFDE
---| "GhostWhite"           #FFFBFF
---| "Gold"                 #FFD700
---| "Goldenrod"            #DEA621
---| "Gray"                 #848284
---| "Green"                #008200
---| "GreenYellow"          #ADFF29
---| "Honeydew"             #F7FFF7
---| "HotPink"              #FF69B5
---| "IndianRed"            #CE5D5A
---| "Indigo"               #4A0084
---| "Ivory"                #FFFFF7
---| "Khaki"                #F7E78C
---| "Lavender"             #E7E7FF
---| "LavenderBlush"        #FFF3F7
---| "LawnGreen"            #7BFF00
---| "LemonChiffon"         #FFFBCE
---| "LightBlue"            #ADDBE7
---| "LightCoral"           #F78284
---| "LightCyan"            #E7FFFF
---| "LightGoldenrodYellow" #FFFBD6
---| "LightGray"            #D6D3D6
---| "LightGreen"           #94EF94
---| "LightPink"            #FFB6C6
---| "LightSalmon"          #FFA27B
---| "LightSeaGreen"        #21B2AD
---| "LightSkyBlue"         #84CFFF
---| "LightSlateGray"       #738A9C
---| "LightSteelBlue"       #B5C7DE
---| "LightYellow"          #FFFFE7
---| "Lime"                 #00FF00
---| "LimeGreen"            #31CF31
---| "Linen"                #FFF3E7
---| "Magenta"              #FF00FF
---| "Maroon"               #840000
---| "MediumAquamarine"     #63CFAD
---| "MediumBlue"           #0000CE
---| "MediumOrchid"         #BD55D6
---| "MediumPurple"         #9471DE
---| "MediumSeaGreen"       #39B273
---| "MediumSlateBlue"      #7B69EF
---| "MediumSpringGreen"    #00FB9C
---| "MediumTurquoise"      #4AD3CE
---| "MediumVioletRed"      #C61484
---| "MidnightBlue"         #181873
---| "MintCream"            #F7FFFF
---| "MistyRose"            #FFE7E7
---| "Moccasin"             #FFE7B5
---| "NavajoWhite"          #FFDFAD
---| "Navy"                 #000084
---| "OldLace"              #FFF7E7
---| "Olive"                #848200
---| "OliveDrab"            #6B8E21
---| "Orange"               #FFA600
---| "OrangeRed"            #FF4500
---| "Orchid"               #DE71D6
---| "PaleGoldenrod"        #EFEBAD
---| "PaleGreen"            #9CFB9C
---| "PaleTurquoise"        #ADEFEF
---| "PaleVioletRed"        #DE7194
---| "PapayaWhip"           #FFEFD6
---| "PeachPuff"            #FFDBBD
---| "Peru"                 #CE8639
---| "Pink"                 #FFC3CE
---| "Plum"                 #DEA2DE
---| "PowderBlue"           #B5E3E7
---| "Purple"               #840084
---| "Red"                  #FF0000
---| "RosyBrown"            #BD8E8C
---| "RoyalBlue"            #4269E7
---| "SaddleBrown"          #8C4510
---| "Salmon"               #FF8273
---| "SandyBrown"           #F7A663
---| "SeaGreen"             #298A52
---| "SeaShell"             #FFF7EF
---| "Sienna"               #A55129
---| "Silver"               #C6C3C6
---| "SkyBlue"              #84CFEF
---| "SlateBlue"            #6B59CE
---| "SlateGray"            #738294
---| "Snow"                 #FFFBFF
---| "SpringGreen"          #00FF7B
---| "SteelBlue"            #4282B5
---| "Tan"                  #D6B68C
---| "Teal"                 #008284
---| "Thistle"              #DEBEDE
---| "Tomato"               #FF6142
---| "Turquoise"            #42E3D6
---| "Violet"               #EF82EF
---| "Wheat"                #F7DFB5
---| "White"                #FFFFFF
---| "WhiteSmoke"           #F7F7F7
---| "Yellow"               #FFFF00
---| "YellowGreen"          #9CCF31
---| "transparent"          #00000000
