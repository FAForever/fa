---@meta

---@class moho.IEffect : Destroyable
local IEffect = {}

---@alias IEffectBeamParameters
--- | 'POSITION' # See `POSITION_X`, `POSITION_Y` or `POSITION_Z` instead
--- | 'POSITION_X' # number
--- | 'POSITION_Y' # number
--- | 'POSITION_Z' # number
--- | 'ENDPOSITION' # See `ENDPOSITION_X`, `ENDPOSITION_Y` or `ENDPOSITION_Z` instead
--- | 'ENDPOSITION_X' # number
--- | 'ENDPOSITION_Y' # number
--- | 'ENDPOSITION_Z' # number
--- | 'LENGTH' # number
--- | 'LIFETIME' # number
--- | 'STARTCOLOR' # See `STARTCOLOR_R`, `STARTCOLOR_G` or `STARTCOLOR_B` `START_COLOR_A` instead
--- | 'STARTCOLOR_R' # number
--- | 'STARTCOLOR_G' # number
--- | 'STARTCOLOR_B' # number
--- | 'STARTCOLOR_A' # number
--- | 'ENDCOLOR' # See `ENDCOLOR_R`, `ENDCOLOR_G` or `ENDCOLOR_B` `END_COLOR_A` instead
--- | 'ENDCOLOR_R' # number
--- | 'ENDCOLOR_G' # number
--- | 'ENDCOLOR_B' # number
--- | 'ENDCOLOR_A' # number
--- | 'THICKNESS' # number
--- | 'USHIFT' # number
--- | 'VSHIFT' # number
--- | 'REPEATRATE' # number
--- | 'LODCUTOFF' # number
--- | 'LASTPARAM' # ?

---@alias IEffectCurveParameters
--- | 'XDIR_CURVE'
--- | 'YDIR_CURVE'
--- | 'ZDIR_CURVE'
--- | 'EMITRATE_CURVE'
--- | 'LIFETIME_CURVE'
--- | 'VELOCITY_CURVE'
--- | 'X_ACCEL_CURVE'
--- | 'Y_ACCEL_CURVE'
--- | 'Z_ACCEL_CURVE'
--- | 'RESISTANCE_CURVE'
--- | 'SIZE_CURVE'
--- | 'X_POSITION_CURVE'
--- | 'Y_POSITION_CURVE'
--- | 'Z_POSITION_CURVE'
--- | 'BEGINSIZE_CURVE'
--- | 'ENDSIZE_CURVE'
--- | 'ROTATION_CURVE'
--- | 'ROTATION_RATE_CURVE'
--- | 'FRAMERATE_CURVE'
--- | 'TEXTURESELECTION_CURVE'
--- | 'RAMPSELECTION_CURVE
--- | 'LAST_CURVE' # ?

---@alias IEffectParameters
--- | 'POSITION' # See `POSITION_X`, `POSITION_Y` or `POSITION_Z` instead
--- | 'POSITION_X' # number
--- | 'POSITION_Y' # number
--- | 'POSITION_Z' # number
--- | 'TICKCOUNT' # number
--- | 'LIFETIME' # number
--- | 'REPEATTIME' # number
--- | 'TICKINCREMENT' # number
--- | 'BLENDMODE' # { 1, 2, 3, 4 }
--- | 'FRAMECOUNT' # number
--- | 'USE_LOCAL_VELOCITY' # 0 for false, 1 for true
--- | 'USE_LOCAL_ACCELERATION' # 0 for false, 1 for true
--- | 'USE_GRAVITY' # 0 for false, 1 for true
--- | 'ALIGN_ROTATION' # 0 for false, 1 for true
--- | 'INTERPOLATE_EMISSION' # 0 for false, 1 for true
--- | 'TEXTURE_STRIPCOUNT' # number
--- | 'ALIGN_TO_BONE' # 0 for false, 1 for true
--- | 'SORTORDER' # number
--- | 'FLAT' # number
--- | 'SCALE' # number
--- | 'LODCUTOFF' # number
--- | 'EMITIFVISIBLE' # 0 for false, 1 for true
--- | 'CATCHUPEMIT' # 0 for false, 1 for true
--- | 'CREATEIFVISIBLE' # 0 for false, 1 for true
--- | 'SNAPTOWATERLINE' # 0 for false, 1 for true
--- | 'ONLYEMITONWATER' # 0 for false, 1 for true
--- | 'PARTICLERESISTANCE' # number
--- | 'LASTPARAM' # ?

---@alias IEffectTrailParameters
--- | 'POSITION' # See `POSITION_X`, `POSITION_Y` or `POSITION_Z` instead
--- | 'POSITION_X' #number
--- | 'POSITION_Y' # number
--- | 'POSITION_Z' # number
--- | 'LIFETIME' # number
--- | 'LENGTH' # number
--- | 'SCALE' # number
--- | 'LASTPARAM' # ?

--- Destroy the effect, de-allocating it from memory
function IEffect:Destroy()
end

--- Offset (in local space) of the origin of the emitter
---@param x number
---@param y number
---@param z number
---@return moho.IEffect
function IEffect:OffsetEmitter(x, y, z)
end

--- Resize the emitter curve to the number of ticks passed in. This is so if we change the lifetime of the emitter we can rescale some of the curves to match if needed. Arguably this should happen automatically to all curves but the original design was screwed up
---@param param IEffectCurveParameters
---@param timeInTicks number
---@return moho.IEffect
function IEffect:ResizeEmitterCurve(param, timeInTicks)
end

--- Scales the emitter
---@param scale number
---@return moho.IEffect
function IEffect:ScaleEmitter(scale)
end

--- Defines a beam parameter, allowing you to tweak beams on an individual basis
---@param name IEffectBeamParameters
---@param value number
---@return moho.IEffect
function IEffect:SetBeamParam(name, value)
end

--- Defines a curve parameter, allowing you to tweak effects on an individual basis
---@param param IEffectCurveParameters
---@param height number
---@param size number
function IEffect:SetEmitterCurveParam(param, height, size)
end

--- Defines a emitter parameter, allowing you to tweak effects on an individual basis. Note that if a parameter is also a curve, the curve takes precedence and this function will have no effect
---@param param IEffectParameters
---@param value number
---@return moho.IEffect
function IEffect:SetEmitterParam(param, value)
end

return IEffect
