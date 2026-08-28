
---Helper class that manages construction projects of mobile units by engineers in the BaseManager.
---
---Used for building units that can't be produced from factories and must be built by engineers.
--- - experimentals
--- - sonars
--- - any other mobile unit that the engineers can build.
---@class ConditionalBuildManager
---@field Index integer                  # Index of the conditional build entry from the base manager that is being built
---@field IsBuilding boolean             # Is currently producing unit?
---True when the engineer is starting a new build, 
---prevents other engineers from starting their own builds
---@field IsInitiated boolean
---@field MainBuilder? Unit              # Engineer that was issued to build the required unit.
---@field MaxAssisting integer           # Max engineers that can assist the construction
---@field NumAssisting integer           # Number of engies currently assisting
---@field Unit? Unit                     # The actual unit being constructed currently
---@field WaitSecondsAfterDeath? integer # Time to wait after conditional build's death before starting a new one.
---@overload fun(): ConditionalBuildManager
local CBM = {}
function CBM:__init()
    self.IsInitiated = false
    self.IsBuilding = false
    self.NumAssisting = 0
    self.MaxAssisting = 1
    self.Index = 0
end
---Store the engineer that was issued to start the construction and update the values so other
---engineers won't try to start their own.
---@param builder Unit
---@param data AddUnitAIData
function CBM:OnUnitConstructionRequested(builder, data)
    self.MainBuilder = builder
    self.NumAssisting = 1
    self.MaxAssisting = data.MaxAssist or 1
    self.Unit = nil
    self.IsInitiated = true
    self.IsBuilding = false
    self.WaitSecondsAfterDeath = data.WaitSecondsAfterDeath
end
---Stores the unit and sets variables so other engineers can see what's going on
---@param unitBeingbuilt Unit
function CBM:OnUnitConstructionStarted(unitBeingbuilt)
    self.IsInitiated = false
    self.IsBuilding = true
    self.Unit = unitBeingbuilt
end
function CBM:IncrementAssisting()
    self.NumAssisting = self.NumAssisting + 1
end
function CBM:DecrementAssisting()
    self.NumAssisting = self.NumAssisting - 1
end
---Resets the stored values so it can be reused for another build project
function CBM:Reset()
    self.IsInitiated = false
    self.IsBuilding = false
    self.NumAssisting = 0
    self.MaxAssisting = 1
    self.Unit = nil
    self.MainBuilder = nil
    self.Index = 0
    self.WaitSecondsAfterDeath = nil
end
---@return boolean?
function CBM:NeedsMoreBuilders()
    return self.IsBuilding and self.Unit and not self.Unit.Dead and (self.NumAssisting < self.MaxAssisting)
end

ConditionalBuildManager = ClassSimple(CBM)
