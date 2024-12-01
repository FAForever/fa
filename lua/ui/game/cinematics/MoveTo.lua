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

---@param index number
---@param count number
---@return number
local WrapSequenceIndex = function(index, count)
    return math.mod(index - 1 + count, count) + 1
end

--- Clears the sequence.
Clear = function()
    SequenceIndex = 1
    Sequence = {}

    print("Reset sequence for MoveTo")
end

--- Stores the current sequence to the preference file.
---@param key any
StoreToDisk = function(key)
    local prefs = import("/lua/user/prefs.lua")

    local stringifiedKey = tostring(key)
    prefs.SetToCurrentProfile(PreferenceKey .. stringifiedKey, Sequence)

    -- inform user
    print("Saved sequence for MoveTo to key '" .. stringifiedKey .. "'")
    SavePreferences()
end

--- Retrieves a sequence from the preference file.
---@param key any
RetrieveFromDisk = function(key)
    local prefs = import("/lua/user/prefs.lua")

    local stringifiedKey = tostring(key)
    local sequence = prefs.GetFromCurrentProfile(PreferenceKey .. stringifiedKey)
    if not sequence then
        print("No sequence found for key '" .. stringifiedKey .. "'")
    end

    Sequence = sequence
    SequenceIndex = 1

    -- inform user
    print("Loaded sequence for MoveTo to key '" .. stringifiedKey .. "' (" .. table.getn(Sequence) .. " steps)")
end

--- Add a camera position to the sequence.
Add = function()
    local camera = GetCamera(DefaultCamera)
    table.insert(Sequence, camera:SaveSettings())

    reprsl(camera)
    reprsl(getmetatable(camera))
    print("Add to sequence (" .. table.getn(Sequence) .. " steps)")
end

--- Inserts a camera position at the specified index.
---@param index number
Insert = function(index)
    local camera = GetCamera(DefaultCamera)
    table.insert(camera, index)

    print("Insert into sequence at index " .. index .. " (" .. table.getn(Sequence) .. " steps)")
end

--- Overwrites the camera position at the specified index.
---@param index number
Overwrite = function(index)
    local camera = GetCamera(DefaultCamera)
    if Sequence[index] then
        Sequence[index] = camera:SaveSettings()
        print("Overwritten into sequence at index " .. index .. " (" .. table.getn(Sequence) .. " steps)")
    end
end

--- Move the camera to the last position in the sequence.
---@see `ToFirstState`
ToLastState = function()
    local count = table.getn(Sequence)
    if count == 0 then
        print("No camera sequence defined")
        return
    end

    SequenceIndex = count
    local state = Sequence[count]
    local camera = GetCamera(DefaultCamera)
    camera:RestoreSettings(state)
end

--- Move the camera to the first position in the sequence.
---@see `ToLastState`
ToFirstState = function()
    local count = table.getn(Sequence)
    if count == 0 then
        print("No camera sequence defined")
        return
    end

    SequenceIndex = count
    local state = Sequence[count]
    local camera = GetCamera(DefaultCamera)
    camera:RestoreSettings(state)
end

--- Immediately jump to the current position in the sequence.
---@param doPrint? boolean # defaults to false
JumpToCurrent = function(doPrint)
    doPrint = doPrint or false

    local index = GetSequenceIndex()
    if not index then
        return
    end

    local state = Sequence[index]
    local camera = GetCamera(DefaultCamera)
    camera:RestoreSettings(state)

    if doPrint then
        print("Jumped to index " .. SequenceIndex .. " of " .. table.getn(Sequence))
    end
end

--- Immediately jump to the next position in the sequence.
---@param doPrint? boolean # defaults to false
---@return UserCamera?
JumpToNext = function(doPrint)
    doPrint = doPrint or false

    local sequenceCount = table.getn(Sequence)
    if sequenceCount == 0 then
        print("No camera sequence defined")
        return nil
    end

    -- update sequence index
    SequenceIndex = WrapSequenceIndex(SequenceIndex + 1, sequenceCount)

    local state = Sequence[SequenceIndex]
    local camera = GetCamera(DefaultCamera)
    camera:RestoreSettings(state)

    if doPrint then
        print("Jumped to index " .. SequenceIndex .. " of " .. table.getn(Sequence))
    end

    return camera
end

--- Immediately jump to the previous position in the sequence.
---@param doPrint? boolean
---@return UserCamera?
JumpToPrevious = function(doPrint)
    doPrint = doPrint or false

    local sequenceCount = table.getn(Sequence)
    if sequenceCount == 0 then
        print("No camera sequence defined")
        return nil
    end

    -- update sequence index
    SequenceIndex = WrapSequenceIndex(SequenceIndex - 1, sequenceCount)

    local state = Sequence[SequenceIndex]
    local camera = GetCamera(DefaultCamera)
    camera:RestoreSettings(state)

    if doPrint then
        print("Jumped to index " .. SequenceIndex .. " of " .. table.getn(Sequence))
    end

    return camera
end

--- Animate the camera to the next position.
---@see `ToPreviousState`
---@return UserCamera?   # Allows you to wait for the camera to finish
AnimateNext = function()
    local index = GetSequenceIndex()
    if not index then
        return
    end

    local state = Sequence[index]
    local camera = GetCamera(DefaultCamera)
    MoveTo(camera, state)

    -- push the sequence
    SequenceIndex = SequenceIndex + 1

    return camera
end

--- Move the camera to the previous position in the sequence.
---@see `ToNextState`
---@return UserCamera?   # Allows you to wait for the camera to finish
AnimatePrevious = function()
    local index = GetSequenceIndex()
    if not index then
        return
    end

    local state = Sequence[index]
    local camera = GetCamera(DefaultCamera)
    MoveTo(camera, state)

    -- push the sequence
    SequenceIndex = SequenceIndex - 1

    return camera
end

--- Jump the camera to the next position and then proceed to animate to the position after that.
---@return UserCamera?   # Allows you to wait for the camera to finish
JumpAndAnimateNext = function()
    JumpToNext()
    return AnimateNext()
end

--- Jump the camera to the previous position and then proceed to animate to the position before that.
---@return UserCamera?   # Allows you to wait for the camera to finish
JumpAndAnimatePrevious = function()
    JumpToPrevious()
    return AnimatePrevious()
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
