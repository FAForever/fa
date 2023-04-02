--***************************************************************************
--*
--**  File     :  /lua/sim/BuilderManager.lua
--**
--**  Summary  : Manage builders
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local BuilderManager = import("/lua/sim/buildermanager.lua").BuilderManager
local AIUtils = import("/lua/ai/aiutilities.lua")
local Builder = import("/lua/sim/builder.lua")

---@class PlatoonFormManager : BuilderManager
PlatoonFormManager = Class(BuilderManager) {
    ---@param self PlatoonFormManager
    ---@param brain AIBrain
    ---@param lType LocationType
    ---@param location Vector
    ---@param radius number
    ---@return boolean
    Create = function(self, brain, lType, location, radius)
        BuilderManager.Create(self, brain, lType, location, radius)

        if not lType or not location or not radius then
            error('*PLATOOM FORM MANAGER ERROR: Invalid parameters; requires locationType, location, and radius')
            return false
        end

        -- backwards compatibility for mods
        self.Location = self.Location or location
        self.Radius = self.Radius or radius
        self.LocationType = self.LocationType or lType

        self:AddBuilderType('Any')

        self.BuilderCheckInterval = 5
    end,

    ---@param self PlatoonFormManager
    ---@param builderData table
    ---@param locationType Vector
    ---@param builderType string
    ---@return boolean
    AddBuilder = function(self, builderData, locationType, builderType)
        local newBuilder = Builder.CreatePlatoonBuilder(self.Brain, builderData, locationType)
        self:AddInstancedBuilder(newBuilder, builderType)
        return newBuilder
    end,

    ---@param self PlatoonFormManager
    ---@param templateName string
    ---@return table
    GetPlatoonTemplate = function(self, templateName)
        local templateData = PlatoonTemplates[templateName]
        if not templateData then
            error('*AI ERROR: Invalid platoon template named - ' .. templateName)
        end
        local template = {}
        if templateData.GlobalSquads then
            template = {
                templateData.Name,
                templateData.Plan,
                unpack(templateData.GlobalSquads)
            }
        else
            template = {
                templateData.Name,
                templateData.Plan,
            }
            for k,v in templateData.FactionSquads do
                table.insert(template, unpack(v))
            end
        end
        return template
    end,

    ---@param self PlatoonFormManager
    ---@param buildingCategory string
    ---@param builderCategory string
    ---@return table
    GetUnitsBeingBuilt = function(self, buildingCategory, builderCategory)
        local position = self.Location
        local radius = self.Radius
        local filterUnits = AIUtils.GetOwnUnitsAroundPoint(self.Brain, builderCategory, position, radius)

        local retUnits = {}

        for k,v in filterUnits do

            -- Make sure the unit is building or upgrading
            if not v:IsUnitState('Building') and not v:IsUnitState('Upgrading') then
                continue
            end

            -- Engineer doesn't want to be assisted
            if v.DesiresAssist == false then
                continue
            end

            -- Check for unit being built compatibility
            local beingBuiltUnit = v.UnitBeingBuilt
            if not beingBuiltUnit or not EntityCategoryContains(buildingCategory, beingBuiltUnit) then
                continue
            end

            -- Engineer doesn't want any more assistance
            if v.NumAssistees and table.getn(v:GetGuards()) >= v.NumAssistees then
                continue
            end

            -- Check if valid economy exists for this assist

            -- Unit had not problems; add to possible list
            table.insert(retUnits, v)
        end

        return retUnits
    end,

    ---@param self PlatoonFormManager
    ---@param builder Unit
    ---@param bType string
    ManagerLoopBody = function(self,builder,bType)
        BuilderManager.ManagerLoopBody(self,builder,bType)
        -- Try to form all builders that pass
        if self.Brain.BuilderManagers[self.LocationType] and builder.Priority >= 1 and builder:CheckInstanceCount() then
            local personality = self.Brain:GetPersonality()
            local poolPlatoon = self.Brain:GetPlatoonUniquelyNamed('ArmyPool')
            local template = self:GetPlatoonTemplate(builder:GetPlatoonTemplate())
            builder:FormDebug()
            local radius = self.Radius
            if builder:GetFormRadius() then radius = builder:GetFormRadius() end
            if not template or not self.Location or not radius then
                if type(template) != 'table' or type(template[1]) != 'string' or type(template[2]) != 'string' then
                    WARN('*Platoon Form: Could not find template named: ' .. builder:GetPlatoonTemplate())
                    return
                end
                WARN('*Platoon Form: Could not find template named: ' .. builder:GetPlatoonTemplate())
                return
            end
            local formIt = poolPlatoon:CanFormPlatoon(template, personality:GetPlatoonSize(), self.Location, radius)
            if formIt and builder:GetBuilderStatus() then
                local hndl = poolPlatoon:FormPlatoon(template, personality:GetPlatoonSize(), self.Location, radius)

                --LOG('*AI DEBUG: ARMY ', repr(self.Brain:GetArmyIndex()),': Platoon Form Manager Forming - ',repr(builder.BuilderName),': Location = ',self.LocationType)
                --LOG('*AI DEBUG: ARMY ', repr(self.Brain:GetArmyIndex()),': Platoon Form Manager - Platoon Size = ', table.getn(hndl:GetPlatoonUnits()))
                hndl.PlanName = template[2]

                --If we have specific AI, fork that AI thread
                if builder:GetPlatoonAIFunction() then
                    hndl:StopAI()
                    local aiFunc = builder:GetPlatoonAIFunction()
                    hndl:ForkAIThread(import(aiFunc[1])[aiFunc[2]])
                end
                if builder:GetPlatoonAIPlan() then
                    hndl.PlanName = builder:GetPlatoonAIPlan()
                    hndl:SetAIPlan(hndl.PlanName)
                end

                --If we have additional threads to fork on the platoon, do that as well.
                if builder:GetPlatoonAddPlans() then
                    for papk, papv in builder:GetPlatoonAddPlans() do
                        hndl:ForkThread(hndl[papv])
                    end
                end

                if builder:GetPlatoonAddFunctions() then
                    for pafk, pafv in builder:GetPlatoonAddFunctions() do
                        hndl:ForkThread(import(pafv[1])[pafv[2]])
                    end
                end

                if builder:GetPlatoonAddBehaviors() then
                    for pafk, pafv in builder:GetPlatoonAddBehaviors() do
                        hndl:ForkThread(import("/lua/ai/aibehaviors.lua")[pafv])
                    end
                end

                hndl.Priority = builder.Priority
                hndl.BuilderName = builder.BuilderName

                hndl:SetPlatoonData(builder:GetBuilderData(self.LocationType))

                for k,v in hndl:GetPlatoonUnits() do
                    if not v.PlatoonPlanName then
                        v.PlatoonHandle = hndl
                    end
                end

                builder:StoreHandle(hndl)
            end
        end
    end,
}

---@param brain AIBrain
---@param lType any
---@param location Vector
---@param radius number
---@return PlatoonFormManager
function CreatePlatoonFormManager(brain, lType, location, radius)
    local pfm = PlatoonFormManager()
    pfm:Create(brain, lType, location, radius)
    return pfm
end

--- Moved Unsused imports to bottome for mod support
local AIBuildUnits = import("/lua/ai/aibuildunits.lua")