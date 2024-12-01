--*******************************************************************************
-- MIT License
--
-- Copyright (c) 2024 (Jip) Willem Wijnia
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.
--
--*******************************************************************************

local PreferenceKey = "CinematicsMoveTo"
local DefaultCamera = "WorldCamera"

---@type TrashBag
local ModuleTrash = TrashBag()

---@type number
SequenceIndex = 1

---@type UserCameraSettings[]
Sequence = {}

--- Moves the given camera to the specified settings.
---@param camera UserCamera
---@param settings UserCameraSettings
---@param duration? number
local MoveTo = function(camera, settings, duration)
    duration = duration or 4

    camera:MoveTo(settings.Focus, { settings.Heading, settings.Pitch, 0 }, settings.Zoom, duration)
end

--- Moves the given camera to the specified settings.
---@param camera UserCamera
---@param settings UserCameraSettings
local SnapTo = function(camera, settings)
    camera:SnapTo(settings.Focus, { settings.Heading, settings.Pitch, 0 }, settings.Zoom)
end

--- Wraps the given index so that it always fits within the sequence.
---@param index number
---@param count number
---@return number
local WrapSequenceIndex = function(index, count)
    return math.mod(index - 1 + count, count) + 1
end

--- Clears the sequence.
---@param doPrint? boolean
Clear = function(doPrint)
    SequenceIndex = 1
    Sequence = {}

    if doPrint then
        print("MoveTo - reset sequence")
    end
end

--- Stores the current sequence to the preference file.
---@param key string
---@param doPrint? boolean
StoreToDisk = function(key, doPrint)
    local prefs = import("/lua/user/prefs.lua")

    local stringifiedKey = tostring(key)
    prefs.SetToCurrentProfile(PreferenceKey .. stringifiedKey, Sequence)
    SavePreferences()

    if doPrint then
        print("MoveTo - Saved sequence for MoveTo to key '" .. stringifiedKey .. "'")
    end
end

--- Retrieves a sequence from the preference file.
---@param key string
---@param doPrint? boolean
RetrieveFromDisk = function(key, doPrint)
    local prefs = import("/lua/user/prefs.lua")

    local stringifiedKey = tostring(key)
    local sequence = prefs.GetFromCurrentProfile(PreferenceKey .. stringifiedKey)
    if not sequence then
        if doPrint then
            print("MoveTo - No sequence found for key '" .. stringifiedKey .. "'")
        end
    end

    Sequence = sequence
    SequenceIndex = 1

    -- inform user
    if doPrint then
        print("MoveTo - Loaded sequence for MoveTo to key '" ..
            stringifiedKey .. "' (" .. table.getn(Sequence) .. " steps)")
    end
end

--- Append a camera position to the end of the sequence.
---@param doPrint? boolean
Append = function(doPrint)
    local camera = GetCamera(DefaultCamera)
    table.insert(Sequence, camera:SaveSettings())

    if doPrint then
        print("MoveTo - Add to sequence (" .. table.getn(Sequence) .. " steps)")
    end
end

--- Inserts a camera position at the specified index.
---@param doPrint? boolean
Insert = function(doPrint)
    local sequenceCount = table.getn(Sequence)
    if sequenceCount == 0 then
        SequenceIndex = 1
    else
        SequenceIndex = WrapSequenceIndex(SequenceIndex, sequenceCount)
    end

    local camera = GetCamera(DefaultCamera)
    table.insert(camera, SequenceIndex + 1, camera:SaveSettings())

    if doPrint then
        print("MoveTo - Insert into sequence at index " .. SequenceIndex .. " (" .. sequenceCount .. " steps)")
    end
end

--- Overwrites the camera position at the specified index.
---@param doPrint? boolean
Overwrite = function(doPrint)
    local sequenceCount = table.getn(Sequence)
    if sequenceCount == 0 then
        SequenceIndex = 1
    else
        SequenceIndex = WrapSequenceIndex(SequenceIndex, sequenceCount)
    end

    local camera = GetCamera(DefaultCamera)
    if Sequence[SequenceIndex] then
        Sequence[SequenceIndex] = camera:SaveSettings()

        if doPrint then
            print("MoveTo - Overwritten into sequence at index " .. SequenceIndex .. " (" .. sequenceCount .. " steps)")
        end
    end
end

--- Removes the current camera position.
---@param doPrint? boolean
Remove = function(doPrint)
    local sequenceCount = table.getn(Sequence)
    if sequenceCount == 0 then
        print("No camera sequence defined")
        return nil
    end

    table.remove(Sequence, SequenceIndex)

    if doPrint then
        print("MoveTo - Removed sequence " .. SequenceIndex .. " (" .. sequenceCount .. " steps)")
    end
end

--- Immediately jump to the current position in the sequence.
---@param doPrint? boolean # defaults to false
---@return UserCamera?
JumpToCurrent = function(doPrint)
    doPrint = doPrint or false

    local sequenceCount = table.getn(Sequence)
    if sequenceCount == 0 then
        print("No camera sequence defined")
        return nil
    end

    -- update sequence index
    SequenceIndex = WrapSequenceIndex(SequenceIndex, sequenceCount)

    local state = Sequence[SequenceIndex]
    local camera = GetCamera(DefaultCamera)
    SnapTo(camera, state)

    if doPrint then
        print("MoveTo - jumped to (" .. SequenceIndex .. "/" .. sequenceCount .. ")")
    end

    return camera
end

--- Immediately jump to the next position in the sequence.
---@param doPrint? boolean # defaults to false
---@return UserCamera?
JumpForward = function(doPrint)
    doPrint = doPrint or false

    local sequenceCount = table.getn(Sequence)
    if sequenceCount == 0 then
        print("MoveTo - No camera sequence defined")
        return nil
    end

    -- update sequence index
    SequenceIndex = WrapSequenceIndex(SequenceIndex + 1, sequenceCount)

    local state = Sequence[SequenceIndex]
    local camera = GetCamera(DefaultCamera)
    SnapTo(camera, state)

    if doPrint then
        print("MoveTo - jumped to (" .. SequenceIndex .. "/" .. sequenceCount .. ")")
    end

    return camera
end

--- Immediately jump to the previous position in the sequence.
---@param doPrint? boolean
---@return UserCamera?
JumpBackward = function(doPrint)
    doPrint = doPrint or false

    local sequenceCount = table.getn(Sequence)
    if sequenceCount == 0 then
        print("MoveTo - No camera sequence defined")
        return nil
    end

    -- update sequence index
    SequenceIndex = WrapSequenceIndex(SequenceIndex - 1, sequenceCount)

    local state = Sequence[SequenceIndex]
    local camera = GetCamera(DefaultCamera)
    SnapTo(camera, state)

    if doPrint then
        print("MoveTo - jumped to (" .. SequenceIndex .. "/" .. sequenceCount .. ")")
    end

    return camera
end

--- Animate the camera to the next position.
---@see `ToPreviousState`
---@param doPrint? boolean
---@return UserCamera?   # Allows you to wait for the camera to finish
AnimateForward = function(doPrint)
    local sequenceCount = table.getn(Sequence)
    if sequenceCount == 0 then
        print("MoveTo - No camera sequence defined")
        return nil
    end

    -- update sequence index
    SequenceIndex = WrapSequenceIndex(SequenceIndex + 1, sequenceCount)

    local state = Sequence[SequenceIndex]
    local camera = GetCamera(DefaultCamera)
    MoveTo(camera, state)

    if doPrint then
        print("MoveTo - animating to (" .. SequenceIndex .. "/" .. sequenceCount .. ")")
    end

    return camera
end

--- Move the camera to the previous position in the sequence.
---@see `ToNextState`
---@param doPrint? boolean
---@return UserCamera?   # Allows you to wait for the camera to finish
AnimateBackwards = function(doPrint)
    local sequenceCount = table.getn(Sequence)
    if sequenceCount == 0 then
        print("MoveTo - No camera sequence defined")
        return nil
    end

    -- update sequence index
    SequenceIndex = WrapSequenceIndex(SequenceIndex - 1, sequenceCount)

    local state = Sequence[SequenceIndex]
    local camera = GetCamera(DefaultCamera)
    MoveTo(camera, state)

    if doPrint then
        print("MoveTo - animating to (" .. SequenceIndex .. "/" .. sequenceCount .. ")")
    end

    return camera
end

--- Jump the camera to the next position and then proceed to animate to the position after that.
---@param doPrint? boolean
---@return UserCamera?   # Allows you to wait for the camera to finish
JumpAndAnimateNext = function(doPrint)
    return JumpForward(doPrint) and AnimateForward(doPrint)
end

--- Jump the camera to the previous position and then proceed to animate to the position before that.
---@param doPrint? boolean
---@return UserCamera?   # Allows you to wait for the camera to finish
JumpAndAnimatePrevious = function(doPrint)
    return JumpBackward(doPrint) and AnimateBackwards(doPrint)
end

-------------------------------------------------------------------------------
--#region Debugging

-- This section provides a hot-reload like functionality when debugging this
-- module. It requires the `/EnableDiskWatch` program argument.
--
-- The code is not required for normal operation.

--- Called by the module manager when this module is reloaded
---@param newModule any
function __moduleinfo.OnReload(newModule)
    -- copy over state
    newModule.SequenceIndex = SequenceIndex
    newModule.Sequence = Sequence
end

--- Called by the module manager when this module becomes dirty.
function __moduleinfo.OnDirty()
    ModuleTrash:Destroy()
end

--#endregion
