
local MauiWrapText = import("/lua/maui/text.lua").WrapText
local ChatPayload = import("/lua/shared/ChatPayload.lua")

-------------------------------------------------------------------------------
-- Shared, view-agnostic helpers for the chat tree. Each function operates
-- on a `UIChatEntry` (or related primitive) and stays free of any one
-- view's internal layout — anything that both `ChatLinesInterface` and
-- `ChatFeedInterface` (or future views) can reuse without coupling them
-- to each other lives here.

--- Re-export of the chat-message length cap; the single source of truth
--- lives in `/lua/shared/ChatPayload.lua` so the sim relay and the UI
--- receive path can't drift on the bound. Call sites that already
--- reference `ChatUtils.MaxMessageLength` (the edit box's `SetMaxChars`,
--- the receive validator) keep working without learning a new path.
MaxMessageLength = ChatPayload.MaxMessageLength

--- Recipient-label / chat-line-prefix descriptors. Conceptually a label
--- table — the keys are not recipient constants but localization
--- categories, even when the string happens to coincide with a recipient
--- value (`all`/`allies`/`notify`). The receiver indexes by `msg.to` and
--- falls back to `private` for whispers; the edit interface and config
--- dialog look up `to` for the generic "To <name>:" prefix. Loc keys
--- mirror the legacy `chat.lua` table so the rendered prefix reads
--- identically. Each entry carries a `text` (lowercase, e.g.
--- `"to all:"`), a `caps` (titlecase, e.g. `"To All:"`), and a
--- `colorkey` resolved against the palette at render time.
ToStrings = {
    all     = { text = '<LOC chat_0004>to all:',    caps = '<LOC chat_0005>To All:',    colorkey = 'all_color'    },
    allies  = { text = '<LOC chat_0002>to allies:', caps = '<LOC chat_0003>To Allies:', colorkey = 'allies_color' },
    private = { text = '<LOC chat_0006>to you:',    caps = '<LOC chat_0007>To You:',    colorkey = 'priv_color'   },
    notify  = { text = '<LOC chat_0002>to allies:', caps = '<LOC chat_0003>To Allies:', colorkey = 'notify_color' },
    to      = { text = '<LOC chat_0000>to',         caps = '<LOC chat_0001>To',         colorkey = 'all_color'    },
}

--- 8-colour swatch palette indexed by `ChatConfigModel` colour keys
--- (`all_color`, `allies_color`, `priv_color`, `link_color`,
--- `notify_color`). The config dialog renders these as `BitmapCombo`
--- choices; `ChatLineInterface.SetHeader` looks them up at render time
--- via `entry.ColorKey` so palette changes take effect on the next
--- `CalcVisible` pass without a full rebuild.
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

--- Wraps an entry's body text against `measureLine`'s row width and stores
--- the result as `entry.WrappedText`. The first wrapped chunk reserves
--- horizontal space for the entry's name prefix (so the body starts
--- after `Name.Right + 4`); subsequent chunks span the full body width
--- starting from the team-colour column.
---
--- Always overwrites `entry.WrappedText` — callers gate (`if not
--- entry.WrappedText then ... end`) for the cache-hit path; resize and
--- font-size changes call this directly to force a fresh wrap.
---
--- With `measureLine == nil` we degrade to a single-chunk wrap that just
--- hands back the raw text; lets callers without a measurement source
--- (an empty pool, a standalone-launched debug feed) still produce
--- something renderable instead of crashing on the missing controls.
---@param entry UIChatEntry
---@param measureLine UIChatLineInterface | nil
function WrapEntry(entry, measureLine)
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

function __moduleinfo.OnDirty()
    import(__moduleinfo.name)
end

--#endregion
