---@meta

---@class moho.aipersonality_methods
local CAiPersonality = {}

--- returns `floor(a + (1 - difficulty) * a * b)`
---@param a integer
---@param b integer
---@return integer delay
function CAiPersonality:AdjustDelay(a, b)
end

---@return number
function CAiPersonality:GetAirUnitsEmphasis()
end

---@return number
function CAiPersonality:GetArmySize()
end

---@return number
function CAiPersonality:GetAttackFrequency()
end

---@return number
function CAiPersonality:GetBotUnitsEmphasis()
end

---@return number
function CAiPersonality:GetChatFrequency()
end

---@return string
function CAiPersonality:GetChatPersonality()
end

---@return number
function CAiPersonality:GetCoordinatedAttacks()
end

---@return number
function CAiPersonality:GetCounterForces()
end

---@return number
function CAiPersonality:GetDefenseDriven()
end

--- The difficulty value is in [0, 1] interpolating all other values between
--- their min and max definitions in the personality.
---@return number
function CAiPersonality:GetDifficulty()
end

---@return number
function CAiPersonality:GetDirectDamageEmphasis()
end

---@return number
function CAiPersonality:GetEconomyDriven()
end

---@return number
function CAiPersonality:GetExpansionDriven()
end

---@return number
function CAiPersonality:GetFactoryTycoon()
end

---@return string[]
function CAiPersonality:GetFavouriteStructures()
end

---@return string[]
function CAiPersonality:GetFavouriteUnits()
end

---@return number
function CAiPersonality:GetFormationUse()
end

---@return number
function CAiPersonality:GetInDirectDamageEmphasis()
end

---@return number
function CAiPersonality:GetIntelBuildingTycoon()
end

---@return number
function CAiPersonality:GetIntelGathering()
end

---@return string
function CAiPersonality:GetPersonalityName()
end

---@return number
function CAiPersonality:GetPlatoonSize()
end

---@return number
function CAiPersonality:GetQuittingTendency()
end

---@return number
function CAiPersonality:GetRepeatAttackFrequency()
end

---@return number
function CAiPersonality:GetSeaUnitsEmphasis()
end

---@return number
function CAiPersonality:GetSpecialtyForcesEmphasis()
end

---@return number
function CAiPersonality:GetSuperWeaponTendency()
end

---@return number
function CAiPersonality:GetSupportUnitsEmphasis()
end

---@return number
function CAiPersonality:GetSurvivalEmphasis()
end

---@return number
function CAiPersonality:GetTankUnitsEmphasis()
end

---@return number
function CAiPersonality:GetTargetSpread()
end

---@return number
function CAiPersonality:GetTeamSupport()
end

---@return number
function CAiPersonality:GetTechAdvancement()
end

---@return number
function CAiPersonality:GetUpgradesDriven()
end

return CAiPersonality
