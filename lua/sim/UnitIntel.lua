
-- Intel fields found in blueprint files of:
-- - Base game
-- - Blackops 
-- - Total Mayhem

-- - primary

-- Cloak: true
-- CloakField: true
-- CloakFieldRadius: true
-- JamRadius: true

-- OmniRadius: true
-- RadarRadius: true
-- RadarStealth: true
-- RadarStealthField: true
-- RadarStealthFieldRadius: true

-- Sonar: true
-- SonarRadius: true
-- SonarStealth: true
-- SonarStealthFieldRadius: true

-- - secondary

-- ActiveIntel: true
-- CloakWaitTime: true
-- FreeIntel: true
-- IntelDurationOnDeath: true
-- JammerBlips: true
-- MaxVisionRadius: true
-- MinVisionRadius: true
-- ShowIntelOnSelect: true
-- RecloakAfterFiringDelay: true
-- ReactivateTime: true
-- RemoteViewingRadius: true

-- StealthWaitTime: true
-- VisionRadius: true
-- VisionRadiusOnDeath: true
-- WaterVisionRadius: true

-- - mistakes

-- WaterVisionradius: true


local IntelMap = {

    Cloak = 'Cloak'
    CloakField = 'CloakField'
    CloakFieldRadius = 'CloakField'
    JamRadius = 'Spoof'

    RadarRadius = 'Radar'
    RadarStealth = 'RadarStealth'
    RadarStealthField = 'RadarStealthField'
    RadarStealthFieldRadius = 'RadarStealthField'

    Sonar = 'Sonar'
    SonarRadius = 'Sonar'
    SonarStealth = 'SonarStealth'
    SonarStealthFieldRadius = 'SonarStealthField'
}

UnitIntelBase = Class {

    OnPostCreate = function(self)

        local specs = self.Blueprint.Intel

        -- populate intel table based on specs
        self.Intel = { }

        
    end,

    DisableUnitIntel = function(self, cause, intelType)
        if self.Intel then 
            local specs = self.Blueprint.Intel

            -- intel is free, can't disable
            if specs.FreeIntel then 
                return 
            end

            -- disable one intel, keep track of why
            if intelType then 
                -- check if we can disable 
                if not (specs.ActiveIntel and specs.ActiveIntel[intelType]) then 
                    if next(self.Intel[intelType]) == nil then 
                        self:DisableIntel(intelType)
                        self:OnIntelDisabled(cause, intelType)
                    end
                    self.Intel[intelType][cause] = true 
                end

            -- disable all intel, keep track of why
            else 
                local disabledOne = false 
                for intelType, _ in self.Intel do 
                    -- check if we can disable 
                    if not (specs.ActiveIntel and specs.ActiveIntel[intelType]) then 
                        if next(self.Intel[intelType]) == nil then 
                            self:DisableIntel(intelType)
                            disabledOne = true 
                        end

                        self.Intel[intelType][cause] = true 
                        
                    end
                end

                if disabledOne then 
                    self:OnIntelDisabled(cause)
                end
            end

            -- cloak fx specifics
            if intelType == 'Cloak' or intelType == 'CloakField' then
                if specs[intelType] then
                    self:UpdateCloakEffect(false, intelType)
                end
            end
        end
    end,

    EnableUnitIntel = function(self, cause, intelType)
        if self.Intel then 
            self.Intel[intelType] = self.Intel[intelType] or { }
            self.Intel[intelType][cause] = nil 
            if not next(self.Intel[intelType]) then 
                self:DisableIntel(intelType)
            end
        end
    end,

    UpdateCloakEffect = function(self, cloaked, intel)
    end,

    CloakFieldWatcher = function(self)
    end,

    CloakFXWatcher = function(self)
    end,

    ShouldWatchIntel = function(self)
    end,

    IntelWatchThread = function(self)
    end,

    CreateEnhancement = function(self, enh)
    end,

    OnIntelEnabled = function(self) end,
    OnIntelDisabled = function(self) end,

    


}