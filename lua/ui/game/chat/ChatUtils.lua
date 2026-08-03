
local MauiWrapText = import("/lua/maui/text.lua").WrapText
local ChatPayload = import("/lua/shared/ChatPayload.lua")

-------------------------------------------------------------------------------
-- Shared, view-agnostic helpers for the chat tree.

--- Re-export of the chat-message length cap. Source of truth is
--- `/lua/shared/ChatPayload.lua` so the sim relay and the UI can't drift.
MaxMessageLength = ChatPayload.MaxMessageLength

--- Recipient-label / chat-line-prefix descriptors. Keys are localization
--- categories, not recipient constants. Receiver indexes by `msg.to` and
--- falls back to `private` for whispers. Each entry has a `text`
--- (lowercase), a `caps` (titlecase), and a `colorkey` resolved at render
--- time.
ToStrings = {
    all     = { text = '<LOC chat_0004>to all:',    caps = '<LOC chat_0005>To All:',    colorkey = 'all_color'    },
    allies  = { text = '<LOC chat_0002>to allies:', caps = '<LOC chat_0003>To Allies:', colorkey = 'allies_color' },
    private = { text = '<LOC chat_0006>to you:',    caps = '<LOC chat_0007>To You:',    colorkey = 'priv_color'   },
    notify  = { text = '<LOC chat_0002>to allies:', caps = '<LOC chat_0003>To Allies:', colorkey = 'notify_color' },
    to      = { text = '<LOC chat_0000>to',         caps = '<LOC chat_0001>To',         colorkey = 'all_color'    },
}

--- 8-colour swatch palette indexed by `ChatConfigModel` colour keys.
--- Looked up at render time via `entry.ColorKey`, so palette changes
--- take effect on the next `CalcVisible` pass without a rebuild.
ColorPalette = {
    'ffffffff', -- 1: white
    'ffff4242', -- 2: red
    'ffefff42', -- 3: yellow
    'ff4fff42', -- 4: green
    'ff42fff8', -- 5: cyan
    'ff424fff', -- 6: blue
    'ffff42eb', -- 7: magenta
    'ffff9f42', -- 8: orange
}

--- Wraps `entry.Text` to the row width and caches it as `entry.WrappedText`.
--- Pass `measureLine = nil` to skip wrapping and store the raw text as a
--- single chunk.
---@param entry UIChatEntry
---@param measureLine UIChatLineInterface | nil
function WrapEntry(entry, measureLine)
    -- Always overwrites WrappedText, callers gate on the cache to avoid
    -- a re-wrap. The first chunk reserves space for the name prefix so
    -- the body starts after Name.Right + 4. Subsequent chunks span the
    -- full body width.
    if not measureLine then
        entry.WrappedText = { entry.Text or '' }
        return
    end

    local name = entry.Name or ''
    local lines = MauiWrapText(entry.Text or '',
        function(lineIndex)
            if lineIndex == 1 then
                return measureLine.Right()
                    - (measureLine.Name.Left() + measureLine.Name:GetStringAdvance(name) + 4)
            else
                return measureLine.Right()
                    - (measureLine.Name.Left() + 4)
            end
        end,
        function(textChunk)
            return measureLine.Text:GetStringAdvance(textChunk)
        end)

    if table.empty(lines) then lines = { '' } end
    entry.WrappedText = lines
end

-------------------------------------------------------------------------------
--#region Debugging

--- Hot-reload hook: re-imports this module on save.
function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
