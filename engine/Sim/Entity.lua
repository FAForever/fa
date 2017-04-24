--- Class Entity
-- @classmod Sim.Entity

---
--  Entity:AddManualScroller(scrollSpeed1, scrollSpeed2)
function Entity:AddManualScroller(scrollSpeed1,  scrollSpeed2)
end

---
--  Entity:AddPingPongScroller(ping1, pingSpeed1, pong1, pongSpeed1, ping2, pingSpeed2, pong2, pongSpeed2)
function Entity:AddPingPongScroller(ping1,  pingSpeed1,  pong1,  pongSpeed1,  ping2,  pingSpeed2,  pong2,  pongSpeed2)
end

---
--  AddShooter(shooter)
function Entity:AddShooter(shooter)
end

---
--  Entity:AddThreadScroller(sideDist, scrollMult)
function Entity:AddThreadScroller(sideDist,  scrollMult)
end

---
--  AddWorldImpulse(self, Ix, Iy, Iz, Px, Py, Pz) Note: Does not appear to be functional.
function Entity:AddWorldImpulse(self,  Ix,  Iy,  Iz,  Px,  Py,  Pz)
end

---
--  Entity:AdjustHealth(instigator, delta)
function Entity:AdjustHealth(instigator,  delta)
end

---
--  Entity:AttachBoneTo(selfbone, entity, bone)
function Entity:AttachBoneTo(selfbone,  entity,  bone)
end

---
--  Attach a unit bone position to an entity bone position
function Entity:AttachBoneToEntityBone()
end

---
--  Entity:AttachTo(entity, bone)
function Entity:AttachTo(entity,  bone)
end

---
--  Entity:BeenDestroyed()
function Entity:BeenDestroyed()
end

---
--  Entity:CreateProjectile(proj_bp, [ox, oy, oz], [dx, dy, dz]
function Entity:CreateProjectile()
end

---
--  Entity:CreateProjectileAtBone(projectile_blueprint, bone)
function Entity:CreateProjectileAtBone(projectile_blueprint,  bone)
end

---
--  Entity:CreatePropAtBone(boneindex,prop_blueprint_id)
function Entity:CreatePropAtBone(boneindex, prop_blueprint_id)
end

---
--  Entity:Destroy()
function Entity:Destroy()
end

---
--  Entity:DetachAll(bone,[skipBallistic])
function Entity:DetachAll(bone, [skipBallistic])
end

---
--  Entity:DetachFrom([skipBallistic])
function Entity:DetachFrom([skipBallistic])
end

---
--  Intel:DisableIntel(type)
function Entity:DisableIntel(type)
end

---
--  EnableIntel(type)
function Entity:EnableIntel(type)
end

---
--  Entity:FallDown(dx,dy,dz,force) -- start falling down
function Entity:FallDown(dx, dy, dz, force)
end

---
--  GetAIBrain(self)
function Entity:GetAIBrain(self)
end

---
--  GetArmy(self)
function Entity:GetArmy(self)
end

---
--  blueprint = Entity:GetBlueprint()
function Entity:GetBlueprint()
end

---
--  Entity:GetBoneCount() -- returns number of bones in this entity's skeleton
function Entity:GetBoneCount()
end

---
--  Entity:GetBoneDirection(bone_name)
function Entity:GetBoneDirection(bone_name)
end

---
--  Entity:GetBoneName(i) -- return the name of the i'th bone of this entity (counting from 0)
function Entity:GetBoneName(i)
end

---
--  Entity:GetCollisionExtents()
function Entity:GetCollisionExtents()
end

---
--  Entity:GetEntityId()
function Entity:GetEntityId()
end

---
--  Entity:GetFractionComplete()
function Entity:GetFractionComplete()
end

---
--  Entity:GetHeading()
function Entity:GetHeading()
end

---
--  Entity:GetHealth()
function Entity:GetHealth()
end

---
--  GetIntelRadius(type)
function Entity:GetIntelRadius(type)
end

---
--  Entity:GetMaxHealth()
function Entity:GetMaxHealth()
end

---
--  Entity:GetOrientation()
function Entity:GetOrientation()
end

---
--  Entity:GetParent()
function Entity:GetParent()
end

---
--  Entity:GetPosition([bone_name])
function Entity:GetPosition([bone_name])
end

---
--  Entity:GetPositionXYZ([bone_name])
function Entity:GetPositionXYZ([bone_name])
end

---
--  Entity:GetScale() -> sx,sy,sz -- return current draw scale of this entity
function Entity:GetScale()
end

---
--  InitIntel(army,type,<radius>)
function Entity:InitIntel(army, type, <radius>)
end

---
--  IsIntelEnabled(type)
function Entity:IsIntelEnabled(type)
end

---
--  Entity:IsValidBone(nameOrIndex,allowNil=false)
function Entity:IsValidBone(nameOrIndex, allowNil=false)
end

---
--  Entity:Kill(instigator,type,excessDamageRatio)
function Entity:Kill(instigator, type, excessDamageRatio)
end

---
--  Entity:PlaySound(params)
function Entity:PlaySound(params)
end

---
--  Entity:PushOver(nx, ny, nz, depth)
function Entity:PushOver(nx,  ny,  nz,  depth)
end

---
--  ReachedMaxShooters()
function Entity:ReachedMaxShooters()
end

---
--  Entity:RemoveScroller()
function Entity:RemoveScroller()
end

---
--  RemoveShooter(shooter)
function Entity:RemoveShooter(shooter)
end

---
--  Entity:RequestRefreshUI()
function Entity:RequestRefreshUI()
end

---
--  Entity:SetAmbientSound(paramTableDetail,paramTableRumble)
function Entity:SetAmbientSound(paramTableDetail, paramTableRumble)
end

---
--  Entity:SetCollisionShape(['Box'|'Sphere'|'None'], centerX, Y, Z, size) -- size is radius for sphere, x,y,z extent for box
function Entity:SetCollisionShape(['Box'|'Sphere'|'None'],  centerX,  Y,  Z,  size)
end

---
--  Entity:SetDrawScale(size): Change mesh scale on the fly
function Entity:SetDrawScale(size)
end

---
--  Entity:SetHealth(instigator,health)
function Entity:SetHealth(instigator, health)
end

---
--  SetRadius(type,radius)
function Entity:SetIntelRadius()
end

---
--  Entity:SetMaxHealth(maxhealth)
function Entity:SetMaxHealth(maxhealth)
end

---
--  Entity:SetMesh(meshBp, bool keepActor): Change mesh on the fly
function Entity:SetMesh(meshBp,  bool keepActor)
end

---
--  Entity:SetOrientation(orientation, immediately)
function Entity:SetOrientation(orientation,  immediately)
end

---
--  Entity:SetParentOffset(vector)
function Entity:SetParentOffset(vector)
end

---
--  Entity:SetPosition(vector,[immediate])
function Entity:SetPosition(vector, [immediate])
end

---
--  Entity:SetScale(s) or Entity:SetScale(sx,sy,sz)
function Entity:SetScale(s)
end

---
--  SetVizToAllies(type)
function Entity:SetVizToAllies(type)
end

---
--  SetVizToEnemies(type)
function Entity:SetVizToEnemies(type)
end

---
--  SetVizToFocusPlayer(type)
function Entity:SetVizToFocusPlayer(type)
end

---
--  SetVizToNeutrals(type)
function Entity:SetVizToNeutrals(type)
end

---
--  Entity:ShakeCamera(radius, max, min, duration)Shake the camera. This is a method of entities rather than a global functionbecause it takes the position of the entity as the epicenter where it shakes more.
function Entity:ShakeCamera(radius,  max,  min,  duration)
end

