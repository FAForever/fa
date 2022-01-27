-- lust v0.1.0 - Lua test framework
-- https://github.com/bjornbytes/lust
-- MIT LICENSE
-- Modified by Askaholic for lua 5.0

-- Useful for better test output
require "../lua/system/repr.lua"

local lust = {}
lust.level = 0
lust.passes = 0
lust.errors = 0
lust.befores = {}
lust.afters = {}

local red = string.char(27) .. '[31m'
local green = string.char(27) .. '[32m'
local normal = string.char(27) .. '[0m'
local function indent(level) return string.rep('\t', level or lust.level) end

function lust.finish()
  if lust.errors ~= 0 then
    os.exit(-1)
  end
end

function lust.describe(name, fn)
  print(indent() .. name)
  lust.level = lust.level + 1
  fn()
  lust.befores[lust.level] = {}
  lust.afters[lust.level] = {}
  lust.level = lust.level - 1
end

function lust.it(name, fn)
  for level = 1, lust.level do
    if lust.befores[level] then
      for i = 1, table.getn(lust.befores[level]) do
        lust.befores[level][i](name)
      end
    end
  end

  local success, err = pcall(fn)
  if success then lust.passes = lust.passes + 1
  else lust.errors = lust.errors + 1 end
  local color = success and green or red
  local label = success and 'PASS' or 'FAIL'
  print(indent() .. color .. label .. normal .. ' ' .. name)
  if err then
    print(indent(lust.level + 1) .. red .. err .. normal)
  end

  for level = 1, lust.level do
    if lust.afters[level] then
      for i = 1, table.getn(lust.afters[level]) do
        lust.afters[level][i](name)
      end
    end
  end
end

function lust.before(fn)
  lust.befores[lust.level] = lust.befores[lust.level] or {}
  table.insert(lust.befores[lust.level], fn)
end

function lust.after(fn)
  lust.afters[lust.level] = lust.afters[lust.level] or {}
  table.insert(lust.afters[lust.level], fn)
end

-- Assertions
local function isa(v, x)
  if type(x) == 'string' then
    return type(v) == x,
      'expected ' .. repr(v) .. ' to be a ' .. x,
      'expected ' .. repr(v) .. ' to not be a ' .. x
  elseif type(x) == 'table' then
    if type(v) ~= 'table' then
      return false,
        'expected ' .. repr(v) .. ' to be a ' .. repr(x),
        'expected ' .. repr(v) .. ' to not be a ' .. repr(x)
    end

    local seen = {}
    local meta = v
    while meta and not seen[meta] do
      if meta == x then return true end
      seen[meta] = true
      meta = getmetatable(meta) and getmetatable(meta).__index
    end

    return false,
      'expected ' .. repr(v) .. ' to be a ' .. repr(x),
      'expected ' .. repr(v) .. ' to not be a ' .. repr(x)
  end

  error('invalid type ' .. repr(x))
end

local function has(t, x)
  for k, v in pairs(t) do
    if v == x then return true end
  end
  return false
end

local function strict_eq(t1, t2)
  if type(t1) ~= type(t2) then return false end
  if type(t1) ~= 'table' then return t1 == t2 end
  for k, _ in pairs(t1) do
    if not strict_eq(t1[k], t2[k]) then return false end
  end
  for k, _ in pairs(t2) do
    if not strict_eq(t2[k], t1[k]) then return false end
  end
  return true
end

local paths = {
  [''] = { 'to', 'to_not' },
  to = { 'have', 'equal', 'be', 'exist', 'fail' },
  to_not = { 'have', 'equal', 'be', 'exist', 'fail', chain = function(a) a.negate = not a.negate end },
  a = { test = isa },
  an = { test = isa },
  be = { 'a', 'an', 'truthy',
    test = function(v, x)
      return v == x,
        'expected ' .. repr(v) .. ' and ' .. repr(x) .. ' to be equal',
        'expected ' .. repr(v) .. ' and ' .. repr(x) .. ' to not be equal'
    end
  },
  exist = {
    test = function(v)
      return v ~= nil,
        'expected ' .. repr(v) .. ' to exist',
        'expected ' .. repr(v) .. ' to not exist'
    end
  },
  truthy = {
    test = function(v)
      return v,
        'expected ' .. repr(v) .. ' to be truthy',
        'expected ' .. repr(v) .. ' to not be truthy'
    end
  },
  equal = {
    test = function(v, x)
      return strict_eq(v, x),
        'expected ' .. repr(v) .. ' and ' .. repr(x) .. ' to be exactly equal',
        'expected ' .. repr(v) .. ' and ' .. repr(x) .. ' to not be exactly equal'
    end
  },
  have = {
    test = function(v, x)
      if type(v) ~= 'table' then
        error('expected ' .. repr(v) .. ' to be a table')
      end

      return has(v, x),
        'expected ' .. repr(v) .. ' to contain ' .. repr(x),
        'expected ' .. repr(v) .. ' to not contain ' .. repr(x)
    end
  },
  fail = {
    test = function(v)
      return not pcall(v),
        'expected ' .. repr(v) .. ' to fail',
        'expected ' .. repr(v) .. ' to not fail'
    end
  }
}

function lust.expect(v)
  local assertion = {}
  assertion.val = v
  assertion.action = ''
  assertion.negate = false

  setmetatable(assertion, {
    __index = function(t, k)
      if has(paths[rawget(t, 'action')], k) then
        rawset(t, 'action', k)
        local chain = paths[rawget(t, 'action')].chain
        if chain then chain(t) end
        return t
      end
      return rawget(t, k)
    end,
    __call = function(t, ...)
      if paths[t.action].test then
        local res, err, nerr = paths[t.action].test(t.val, unpack(arg))
        if assertion.negate then
          res = not res
          err = nerr or err
        end
        if not res then
          error(err or 'unknown failure', 2)
        end
      end
    end
  })

  return assertion
end

function lust.spy(target, name, run)
  local spy = {}
  local subject

  local function capture(...)
    table.insert(spy, arg)
    return subject(unpack(arg))
  end

  if type(target) == 'table' then
    subject = target[name]
    target[name] = capture
  else
    run = name
    subject = target or function() end
  end

  setmetatable(spy, {__call = function(_, ...) return capture(unpack(arg)) end})

  if run then run() end

  return spy
end

lust.test = lust.it
lust.paths = paths

return lust
