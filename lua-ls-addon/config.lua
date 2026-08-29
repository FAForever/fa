-- Applies the workspace settings FA's dialect needs but no scanner rewrites - SupCom-only
-- tokens, engine globals, and require/path conventions - automatically to any matching project.
--
-- Loaded by LuaLS's third-party config system (script/library.lua) whenever the workspace name
-- or an open file matches `words` below; each entry in `configs` is then applied to the user's
-- own settings once, the first time a match is found.

-- if not set, the folder name will be used
name    = 'Forged Alliance'
-- match any word to load
words   = {'.'}
-- list of settings to be changed
---@type config.change[]
configs = {
    {
        key    = 'Lua.runtime.version',
        action = 'set',
        value  = 'Lua 5.1',
    },
    {
        key    = 'Lua.runtime.path',
        action = 'add',
        value  = '/?',
    },
    {
        key    = 'Lua.completion.showWord',
        action = 'set',
        value  = 'Disable',
    },
    {
        key    = 'Lua.runtime.special',
        action = 'prop',
        prop   = 'import',
        value  = 'require',
    },
    {
        key    = 'Lua.runtime.special',
        action = 'prop',
        prop   = 'doscript',
        value  = 'require',
    },
    {
        key    = 'Lua.runtime.nonstandardSymbol',
        action = 'add',
        value  = 'continue',
    },
    {
        key    = 'Lua.runtime.nonstandardSymbol',
        action = 'add',
        value  = '!=',
    },
    {
        key    = 'Lua.completion.requireSeparator',
        action = 'set',
        value  = '/',
    },
    {
        key    = 'Lua.runtime.pathStrict',
        action = 'set',
        value  = false,
    },
    {
        -- `<<`/`>>` (bitwise shift) are version-gated in script/parser/compile.lua to
        -- Lua 5.3+/LuaJIT, not controllable via nonstandardSymbol - but SupCom's engine
        -- supports them despite everything else here needing Lua.runtime.version = 'Lua 5.1'.
        -- Parsing itself isn't affected (the version check only pushes a diagnostic, parsing
        -- continues either way), so just silence it.
        key    = 'Lua.diagnostics.disable',
        action = 'add',
        value  = 'unsupport-symbol',
    },
    {
        -- inject-field's "is this class exact" escape hatch (script/core/diagnostics/
        -- inject-field.lua) depends on guide.getSelfNode, which only recognizes the implicit
        -- `self` colon-sugar creates (function Foo:Method()) - not FA's own convention of
        -- writing `self` out as an explicit parameter (Method = function(self) ... end). That
        -- makes vm.getDefinedClass return nil for every FA method's `self`, which skips the
        -- "class isn't exact, allow it" check entirely and falls into a stricter path that
        -- flags any field first assigned via self.X = ... without a matching ---@field. Since
        -- that's FA's normal way of initializing instance fields (e.g. BaseManager:Create()),
        -- this fires constantly for correct code - disable rather than hand-document every field.
        key    = 'Lua.diagnostics.disable',
        action = 'add',
        value  = 'inject-field',
    },
}
for _, name in ipairs {'moho'} do
    configs[#configs+1] = {
        key    = 'Lua.diagnostics.globals',
        action = 'add',
        value  = name,
    }
end
