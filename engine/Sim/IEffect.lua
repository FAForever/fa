---@declare-global
---@class moho.IEffect
local IEffect = {}

---@alias IEffectBeamParameters
--- | 'Length' # number
--- | 'Thickness' # number
--- | 'Lifetime' # number
--- | 'TextureName' # string (path to a texture file)
--- | 'UShift' # number
--- | 'VShift' # number
--- | 'RepeatRate' # number
--- | 'LODCutoff' # number

---@alias iEffectCurveParameters
--- | 'XDirectionCurve'
--- | 'YDirectionCurve'
--- | 'ZDirectionCurve'
--- | 'EmitRateCurve'
--- | 'LifetimeCurve'
--- | 'VelocityCurve'
--- | 'XAccelCurve'
--- | 'YAccelCurve'
--- | 'ZAccelCurve'
--- | 'ResistanceCurve'
--- | 'SizeCurve'
--- | 'XPosCurve'
--- | 'YPosCurve'
--- | 'ZPosCurve'
--- | 'StartSizeCurve'
--- | 'EndSizeCurve'
--- | 'InitialRotationCurve'
--- | 'RotationRateCurve'
--- | 'FrameRateCurve'
--- | 'TextureSelectionCurve'
--- | 'RampSelectionCurve'

---@alias IEffectParameters
--- | 'Lifetime' # number
--- | 'RepeatTime' # number
--- | 'TextureFramecount' # number
--- | 'Blendmode' # integer (1, 2, 3 or 4)
--- | 'LocalVelocity' # boolean
--- | 'LocalAcceleration' # boolean
--- | 'Gravity' # boolean
--- | 'AlignRotation' # boolean
--- | 'AlignToBone' # boolean
--- | 'Flat' # boolean
--- | 'LODCutoff' # number
--- | 'CatchupEmit' # boolean
--- | 'CreateIfVisible' # boolean
--- | 'SnapToWaterline' # boolean
--- | 'OnlyEmitOnWater' # boolean
--- | 'ParticleResistance' # boolean
--- | 'InterpolateEmission' # boolean
--- | 'SortOrder' # number
--- | 'Texture' # string (path to a texture file)
--- | 'RampTexture' # string (path to a texture file)

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
---@param param iEffectCurveParameters
---@param timeInTicks
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
---@param param iEffectCurveParameters
---@param height number
---@param size number
function IEffect:SetEmitterCurveParam(param, height, size)
end

--- Defines a emitter parameter, allowing you to tweak effects on an individual basis
---@param param IEffectParameters
---@param value number
---@return moho.IEffect
function IEffect:SetEmitterParam(param, value)
end

return IEffect
