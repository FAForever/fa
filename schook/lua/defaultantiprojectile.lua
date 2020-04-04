-- Hooking two classes

Flare = Class(Entity) {
    OnCreate = function(self, spec)
        self.Army = self:GetArmy()
        self.Owner = spec.Owner
        self.Radius = spec.Radius or 5
        self.OffsetMult = spec.OffsetMult or 0
        self:SetCollisionShape('Sphere', 0, 0, self.Radius * self.OffsetMult, self.Radius)
        self:SetDrawScale(self.Radius)
        self:AttachTo(spec.Owner, -1)
        self.RedirectCat = spec.Category or 'MISSILE'
    end,

    -- We only divert projectiles. The flare-projectile itself will be responsible for
    -- accepting the collision and causing the hostile projectile to impact.
    OnCollisionCheck = function(self,other)
        myArmy = self.Army
        otherArmy = other.Army
        if EntityCategoryContains(ParseEntityCategory(self.RedirectCat), other) and myArmy ~= otherArmy and IsAlly(myArmy, otherArmy) == false then
            other:SetNewTarget(self.Owner)
        end
        return false
    end,
}


DepthCharge = Class(Entity) {
    OnCreate = function(self, spec)
        self.Army = self:GetArmy()
        self.Owner = spec.Owner
        self.Radius = spec.Radius
        self:SetCollisionShape('Sphere', 0, 0, 0, self.Radius)
        self:SetDrawScale(self.Radius)
        self:AttachTo(spec.Owner, -1)
    end,

    -- We only divert projectiles. The flare-projectile itself will be responsible for
    -- accepting the collision and causing the hostile projectile to impact.
    OnCollisionCheck = function(self,other)
        myArmy = self.Army
        otherArmy = other.Army
        if EntityCategoryContains(categories.TORPEDO, other) and myArmy ~= otherArmy and IsAlly(myArmy, otherArmy) == false then
            other:SetNewTarget(self.Owner)
        end
        return false
    end,
}
