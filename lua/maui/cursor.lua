-- Class methods:
-- SetNewTexture(filename, hotspotX, hotspotY)
-- SetDefaultTexture(filename, hotspotX, hotspotY)
-- Reset() -- re-applies default texture

---@class Cursor : moho.cursor_methods, InternalObject
---@field _hotspotX number
---@field _hotspotY number
---@field _filename LazyVar<FileName>
---@field _animThread? thread
Cursor = ClassUI(moho.cursor_methods) {
    ---@param self Cursor
    ---@param defaultTexture FileName
    ---@param defaultHotspotX number
    ---@param defaultHotspotY number
    __init = function(self, defaultTexture, defaultHotspotX, defaultHotspotY)
        _c_CreateCursor(self, nil)
        self:SetDefaultTexture(defaultTexture, defaultHotspotX, defaultHotspotY)
        self:ResetToDefault()

        self._hotspotX = 0
        self._hotspotY = 0

        self._filename = import("/lua/lazyvar.lua").Create()
        self._filename.OnDirty = function(var)
            self:SetNewTexture(var(), self._hotspotX, self._hotspotY)
        end

        self._animThread = nil
    end,

    ---@param self Cursor
    ---@param filename FileName
    ---@param hotspotX? number defaults to 0
    ---@param hotspotY? number defaults to 0
    ---@param numFrames? number
    ---@param fps? number
    SetTexture = function(self, filename, hotspotX, hotspotY, numFrames, fps)
        self._hotspotX = hotspotX or 0
        self._hotspotY = hotspotY or 0

        KillThread(self._animThread)
        if filename and numFrames and numFrames != 1 then
            local extPos = filename:find(".dds")
            filename = filename:sub(1, extPos - 1)
            self._animThread = ForkThread(function()
                fps = 1 / fps
                local _filename = self._filename
                local filename = filename
                local curFrame = 1
                while true do
                    _filename:Set(("%s%02d.dds"):format(filename, curFrame))
                    curFrame = curFrame + 1
                    if curFrame > numFrames then
                        curFrame = 1
                    end
                    WaitSeconds(fps)
                end
            end)
        else
            self._filename:Set(filename)
        end
    end,

    ---@param self Cursor
    Reset = function(self)
        if self._animThread then
            KillThread(self._animThread)
        end
        self:ResetToDefault()
    end
}
