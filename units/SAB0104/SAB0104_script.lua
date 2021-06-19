local CConstructionStructureUnit = import('/lua/cybranunits.lua').CConstructionStructureUnit
local CreateAeonCommanderBuildingEffects = import('/lua/EffectUtilities.lua').CreateAeonCommanderBuildingEffects

SAB0104 = Class(CConstructionStructureUnit) {
    OnCreate = function(self)
        CConstructionStructureUnit.OnCreate(self)
        self.BuildingOpenAnimManip = CreateAnimator(self)
        self.BuildingOpenAnimManip:SetPrecedence(1)
        self.BuildingOpenAnimManip:PlayAnim(__blueprints.sab0104.Display.AnimationBuild, false):SetRate(0)
    end,

    OnStartBuild = function(self, unitBeingBuilt, order)
        CConstructionStructureUnit.OnStartBuild(self, unitBeingBuilt, order)
        self.BuildingOpenAnimManip:SetRate(3)
        self.PanelsOpen = true
    end,

    OnStopBuild = function(self, unitBeingBuilt)
        CConstructionStructureUnit.OnStopBuild(self, unitBeingBuilt)
        self.BuildingOpenAnimManip:SetRate(-3)
        self.PanelsOpen = nil
    end,

    CreateBuildEffects = function(self, unitBeingBuilt, order)
        CreateAeonCommanderBuildingEffects( self, unitBeingBuilt, __blueprints.sab0104.General.BuildBones.BuildEffectBones, self.BuildEffectsBag )
    end,

    PlayAnimationThread = function(self, anim, rate)
        if anim == 'AnimationDeath' then
            if self.PanelsOpen then
                local bp = __blueprints.sab0104.Display[anim]
                self.DeathAnimManip = CreateAnimator(self)
                self.DeathAnimManip:PlayAnim(bp[1].Animation):SetRate(math.random(bp[1].AnimationRateMin, bp[1].AnimationRateMax))
                self.Trash:Add(self.DeathAnimManip)
                WaitFor(self.DeathAnimManip)
            end
        else
            CConstructionStructureUnit.PlayAnimationThread(self, anim, rate)
        end
    end,
}
TypeClass = SAB0104
