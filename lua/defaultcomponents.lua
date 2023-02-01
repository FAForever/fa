---@class ShieldEffectsComponent : Unit
---@field Trash TrashBag
---@field ShieldEffectsBag TrashBag
---@field ShieldEffectsBone Bone
---@field ShieldEffectsScale number
ShieldEffectsComponent = ClassSimple {

    ShieldEffects = {},
    ShieldEffectsBone = 0,
    ShieldEffectsScale = 1,

    ---@param self ShieldEffectsComponent
    OnCreate = function(self)
        self.ShieldEffectsBag = TrashBag()
        self.Trash:Add(self.ShieldEffectsBag)
    end,

    ---@param self ShieldEffectsComponent
    OnShieldEnabled = function(self)
        self.ShieldEffectsBag:Destroy()
        for _, v in self.ShieldEffects do
            self.ShieldEffectsBag:Add(CreateAttachedEmitter(self, self.ShieldEffectsBone, self.Army, v):ScaleEmitter(self
                .ShieldEffectsScale))
        end
    end,

    ---@param self ShieldEffectsComponent
    OnShieldDisabled = function(self)
        self.ShieldEffectsBag:Destroy()
    end,
}


---@type table<string, number>
local TechToDuration = {
    TECH1 = 1,
    TECH2 = 2,
    TECH3 = 4,
    EXPERIMENTAL = 16,
}

---@type table<string, number>
local TechToLOD = {
    TECH1 = 120,
    TECH2 = 180,
    TECH3 = 240,
    EXPERIMENTAL = 320,
}

---@class TreadComponent
---@field TreadBlueprint UnitBlueprintTreads
---@field TreadSuspend? boolean
---@field TreadThreads? table<number, thread>
TreadComponent = ClassSimple {

    ---@param self Unit | TreadComponent
    OnCreate = function(self)
        self.TreadBlueprint = self.Blueprint.Display.MovementEffects.Land.Treads
    end,

    ---@param self Unit | TreadComponent
    CreateMovementEffects = function(self)
        local treads = self.TreadBlueprint
        if treads then
            self:AddThreadScroller(1.0, treads.ScrollMultiplier or 0.2)

            local treadMarks = treads.TreadMarks
            local treadType = self.TerrainType.Treads
            if treadMarks and treadType and treadType ~= 'None' then
                self:CreateTreads(treadMarks)
            end
        end
    end,

    ---@param self Unit | TreadComponent
    DestroyMovementEffects = function(self)
        local treads = self.TreadBlueprint
        if treads then
            self:RemoveScroller()

            if self.TreadThreads then
                self.TreadSuspend = true
            end
        end
    end,

    ---@param self Unit | TreadComponent
    ---@param treadsBlueprint UnitBlueprintTreadMarks
    CreateTreads = function(self, treadsBlueprint)
        local treadThreads = self.TreadThreads
        if not treadThreads then
            treadThreads = { }

            for k, treadBlueprint in treadsBlueprint do
                local thread = ForkThread(self.CreateTreadsThread, self, treadBlueprint)
                treadThreads[k] = thread
                self.Trash:Add(thread)
            end

            self.TreadThreads = treadThreads
        else
            self.TreadSuspend = nil
            for k, thread in treadThreads do
                ResumeThread(thread)
            end
        end
    end,

    ---@param self Unit | TreadComponent
    ---@param treads UnitBlueprintTreadMarks
    CreateTreadsThread = function(self, treads)

        -- to local scope for performance
        local WaitTicks = WaitTicks
        local CreateSplatOnBone = CreateSplatOnBone
        local SuspendCurrentThread = SuspendCurrentThread

        local tech = self.Blueprint.TechCategory
        local sizeX = treads.TreadMarksSizeX
        local sizeZ = treads.TreadMarksSizeZ
        local interval = 10 * (treads.TreadMarksInterval or 0.1)
        local treadOffset = treads.TreadOffset
        local treadBone = treads.BoneName or 0
        local treadTexture = treads.TreadMarks

        local duration = treads.TreadLifeTime or TechToDuration[tech] or 1
        local lod = TechToLOD[tech] or 120
        local army = self.Army

        -- prevent infinite loops
        if interval < 1 then
            interval = 1
        end

        while true do
            while not self.TreadSuspend do
                CreateSplatOnBone(self, treadOffset, treadBone, treadTexture, sizeX, sizeZ, lod, duration, army)
                WaitTicks(interval)
            end

            SuspendCurrentThread()
            self.TreadSuspend = nil
            WaitTicks(1)
        end
    end,
}
