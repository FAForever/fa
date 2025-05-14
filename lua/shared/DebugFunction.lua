--**************************************************************************************************
--** Shared under the MIT license
--**************************************************************************************************
--- A library dedicated to investigating the bytecode of functions.
--- At a minimum, it can be used like
---
---   import("/lua/shared/debugfunction.lua").PrintOut(<your fn>)
---
--- The majority of the code is to pretty-up the output of the default
--- `debug.listcode` function.


local MathLdexp = math.ldexp
local MathMod = math.mod
local StringChar = string.char


local cacheInstructions = false



---@param info debuginfo
---@return string source
---@return string scope
---@return string name
function CollapseDebugInfo(info)
    local source = info.what or "unknown"
    local scope = info.namewhat
    -- prevent an empty scope
    if not scope or scope == "" then
        scope = "other"
    end
    local name = info.name or "<lambda>"
    return source, scope, name
end


---@class RawFunctionDebugInfo : debuginfo
---@field bytecode Bytecode
---@field constants any[]
-- @field prototypes nil -- we don't have access to these!
---@field upvalueNames string[]
---@field upvalues any[]

---@param f function | integer
---@return RawFunctionDebugInfo
function GetDebugPrototypeInfo(f)
    local info = debug.getinfo(f) --[[@as RawFunctionDebugInfo]]
    local fn = info.func -- the rest of the functions don't like thread traces
    local upvalueNames = {}
    for i = 1, info.nups do
        upvalueNames[i] = (debug.getupvalue(fn, i))
    end
    info.constants = debug.listk(fn)
    info.upvalueNames = upvalueNames
    return info
end

---@param f function | integer
---@return RawFunctionDebugInfo
function GetDebugFunctionInfo(f)
    local info = debug.getinfo(f)
    local fn = info.func -- the rest of the functions don't like thread traces
    local upvalues = {}
    local upvalueNames = {}
    for i = 1, info.nups do
        upvalueNames[i], upvalues[i] = debug.getupvalue(fn, i)
    end
    local constants = debug.listk(fn)
    local bytecode = debug.listcode(fn)
    return {
        bytecode = bytecode,
        constants = constants,
        info = info,
        upvalueNames = upvalueNames,
        upvalues = upvalues,
    }
end

---@param val any
---@return string
function Representation(val)
    if type(val) == "string" then
        return ("%q"):format(val)
    end
    return tostring(val)
end


local OP_SIZE = 6
local A_SIZE  = 8
local B_SIZE  = 9
local C_SIZE  = 9
local Bx_SIZE = B_SIZE + C_SIZE
local MAXSTACK = 250
local MAXUPVALUE = 32
local FIELDS_PER_FLUSH = 32

local hexWidth = math.ceil(Bx_SIZE * 0.25)
local addressPattern = "%0#" .. (hexWidth + 2) .. "x"
local addressZero = "0x" .. string.rep("0", hexWidth)

---@alias DebugOpArgKind
---| "boolean"
---| "const"
---| "double"
---| "offset"
---| "prototype"
---| "register"
---| "register_or_const"
---| "register_range"
---| "upvalue"
---| "value"
---@alias DebugOpControlFlow "call" | "jump" | "return" | "skip" | "tailcall"
---@alias DebugOpFormat "A" | "AB" | "ABC" | "ABx" | "AsBx"


---@param address? integer defaults to the instruction address
---@return string
function AddressToString(address)
    if address ~= 0 then
        return addressPattern:format(address)
    end
    -- the formatter just returns "00000" for 0
    return addressZero
end

---@param arg? DebugOpArgKind
---@return boolean
local function ArgKindIsDouble(arg)
    return arg == "const" or arg == "double" or arg == "offset" or arg == "prototype"
end

---@type table<DebugOpArgKind, fun(intr: DebugInstruction, val: integer, fn?: DebugFunction, addr?: integer, arg?: integer): string>
DebugOpcodeArgPrettyFormatters = {
    default = function(instr, arg, fn, addr)
        return tostring(arg)
    end,

    boolean = function(instr, arg, fn, addr)
        if arg == 1 then
            return "true"
        end
        return "false"
    end,
    const = function(instr, arg, fn, addr)
        if fn then
            return Representation(fn:GetConstant(arg + 1))
        end
        return "K(" .. arg .. ')'
    end,
    offset = function(instr, arg, fn, addr)
        -- adjust address offsets to absolute addresses
        addr = addr or 0
        return AddressToString(addr + instr:GetJump(arg))
    end,
    prototype = function(instr, arg, fn, addr)
        return "P(" .. arg .. ')'
    end,
    register = function(instr, arg, fn, addr)
        return 'R' .. arg
    end,
    register_or_const = function(instr, arg, fn, addr)
        if arg < MAXSTACK then
            return DebugOpcodeArgPrettyFormatters.register(instr, arg, fn, addr)
        end
        arg = arg - MAXSTACK
        return DebugOpcodeArgPrettyFormatters.const(instr, arg, fn, addr)
    end,
    register_range = function(instr, val, fn, addr, arg)
        val = val + instr[arg - 1]
        return DebugOpcodeArgPrettyFormatters.register(instr, val, fn, addr)
    end,
    upvalue = function(instr, arg, fn, addr)
        if fn then
            return Representation(fn:GetUpvalueName(arg + 1))
        end
        return "U(" .. arg .. ')'
    end,

    -- SETLIST is mangled to shove two numbers into one argument asymmetrically in Lua 5.0
    -- (SETLISTO reuses the first one)
    double = function(instr, arg, fn, addr)
        local len = MathMod(arg, FIELDS_PER_FLUSH) + 1
        local start = arg - len + 2
        return start .. ',' .. len
    end,
}
setmetatable(DebugOpcodeArgPrettyFormatters, {
    __index = function(tbl, key)
        if key ~= nil then
            return tbl.default
        end
    end
})

---@class DebugOpcode
---@field args integer
---@field aKind? DebugOpArgKind
---@field bKind? DebugOpArgKind
---@field cKind? DebugOpArgKind
---@field format DebugOpFormat
---@field controlFlow? DebugOpControlFlow
---@field name string
---@field index integer
DebugOpcode = ClassSimple {
    ---@param self DebugOpcode
    ---@param aKind DebugOpArgKind
    ---@param bKind? DebugOpArgKind
    ---@param cKind? DebugOpArgKind
    ---@param controlFlow? DebugOpControlFlow
    __init = function(self, index, aKind, bKind, cKind, controlFlow)
        self.aKind = aKind
        self.bKind = bKind
        self.cKind = cKind
        self.controlFlow = controlFlow
        self.index = index
        if cKind then
            self.args = 3
            self.format = "ABC"
        elseif bKind then
            self.args = 2
            if ArgKindIsDouble(bKind) then
                if bKind == "offset" then
                    self.format = "AsBx"
                else
                    self.format = "ABx"
                end
            else
                self.format = "AB"
            end
        else
            self.args = 1
            self.format = "A"
        end
    end,

    ---@param self DebugOpcode
    ---@return string
    __tostring = function(self)
        return self.name
    end,

    GetSkip = function(self, instr)
        if self.controlFlow == "skip" then
            return 1
        else
            return 0
        end
    end,

    ArgKind = function(self, arg)
        return self[StringChar(96 + arg) .. "Kind"]
    end,

    ---@param self DebugOpcode
    ---@param instr DebugInstruction
    ---@return string
    InstructionPrettyFormatName = function(self, instr)
        return self.name
    end,

    ---@param self DebugOpcode
    ---@param instr DebugInstruction
    ---@param arg integer
    ---@param fn? DebugFunction optional function to resolve constants from
    ---@param addr? integer
    ---@return string | nil
    InstructionPrettyFormatArg = function(self, instr, arg, fn, addr)
        local kind = self:ArgKind(arg)
        if not kind then
            return nil
        end
        arg = arg + 1
        return DebugOpcodeArgPrettyFormatters[kind](instr, instr[arg], fn, addr, arg)
    end,
}

---@class DebugVarNameOpcode : DebugOpcode
---@field notName string
---@field renamingArg integer
DebugVarNameOpcode = Class(DebugOpcode) {
    ---@param self DebugVarNameOpcode
    ---@param instr DebugInstruction
    ---@return string
    InstructionPrettyFormatName = function(self, instr)
        -- the first arg is the opcode
        if instr[self.renamingArg + 1] == 0 then
            return self.notName
        end
        return self.name
    end,

    ---@param self DebugVarNameOpcode
    ---@param instr DebugInstruction
    ---@param arg integer
    ---@param fn? DebugFunction optional function to resolve constants from
    ---@param addr? integer
    ---@return string | nil
    InstructionPrettyFormatArg = function(self, instr, arg, fn, addr)
        if arg == self.renamingArg then
            return nil
        end
        return DebugOpcode.InstructionPrettyFormatArg(self, instr, arg, fn, addr)
    end,
}

---@class DebugRangedOpcode : DebugOpcode
DebugRangedOpcode = Class(DebugOpcode) {
    ---@param self DebugVarNameOpcode
    ---@param instr DebugInstruction
    ---@param arg integer
    ---@param fn? DebugFunction optional function to resolve constants from
    ---@return string | nil
    InstructionPrettyFormatArg = function(self, instr, arg, fn, addr)
        if arg == self.renamingArg then
            return nil
        end
        return DebugOpcode.InstructionPrettyFormatArg(self, instr, arg, fn, addr)
    end,
}

---@type table<string, DebugOpcode>
OPCODE = {}
do
    -- store these strings so we can format the opcode construction 'prettily'
    local ___
    local BOL = "boolean"
    local CON = "const"
    local DBL = "double"
    local OFF = "offset"
    local PRO = "prototype"
    local REG = "register"
    local RRG = "register_range"
    local RK  = "register_or_const" -- if x < MAXSTACK then REG(x) else CON(x-MAXSTACK)
    local UPV = "upvalue"
    local VAL = "value"

    local CALL = "call"
    local JUMP = "jump"
    local SKIP = "skip"
    local RET  = "return"
    local TAIL = "tailcall"
    -- OPCODE.NAME   = OpcodeClass(index, argA, argB, argC, controlFlow)
                                                              -- PC++ assumes that the skipped instruction is a jump
    OPCODE.MOVE      = DebugOpcode(0x00, REG, REG)            -- R(A) := R(B)
    OPCODE.LOADK     = DebugOpcode(0x01, REG, CON)            -- R(A) := Kst(Bx)
    OPCODE.LOADBOOL  = DebugOpcode(0x02, REG, BOL, BOL, SKIP) -- R(A) := (Bool)B; if (C) PC++
    OPCODE.LOADNIL   = DebugOpcode(0x03, REG, RRG)            -- R(A) := ... := R(B) := nil
    OPCODE.GETUPVAL  = DebugOpcode(0x04, REG, UPV)            -- R(A) := UpValue[B]
    OPCODE.GETGLOBAL = DebugOpcode(0x05, REG, CON)            -- R(A) := Gbl[Kst(Bx)]
    OPCODE.GETTABLE  = DebugOpcode(0x06, REG, REG, RK)        -- R(A) := R(B)[RK(C)]
    OPCODE.SETGLOBAL = DebugOpcode(0x07, REG, CON)            -- Gbl[Kst(Bx)] := R(A)
    OPCODE.SETUPVAL  = DebugOpcode(0x08, REG, UPV)            -- UpValue[B] := R(A)
    OPCODE.SETTABLE  = DebugOpcode(0x09, REG, RK,  RK)        -- R(A)[RK(B)] := RK(C)
    OPCODE.NEWTABLE  = DebugOpcode(0x0a, REG, VAL, VAL)       -- R(A) := {} (arrsize = B, hashsize = C)
    OPCODE.SELF      = DebugOpcode(0x0b, REG, REG, RK)        -- R(A+1) := R(B); R(A) := R(B)[RK(C)]
    OPCODE.ADD       = DebugOpcode(0x0c, REG, RK,  RK)        -- R(A) := RK(B) + RK(C)
    OPCODE.SUB       = DebugOpcode(0x0d, REG, RK,  RK)        -- R(A) := RK(B) - RK(C)
    OPCODE.MUL       = DebugOpcode(0x0e, REG, RK,  RK)        -- R(A) := RK(B) * RK(C)
    OPCODE.DIV       = DebugOpcode(0x0f, REG, RK,  RK)        -- R(A) := RK(B) / RK(C)
    OPCODE.BAND      = DebugOpcode(0x10, REG, RK,  RK)        -- R(A) := RK(B) & RK(C)
    OPCODE.BOR       = DebugOpcode(0x11, REG, RK,  RK)        -- R(A) := RK(B) | RK(C)
    OPCODE.BSHL      = DebugOpcode(0x12, REG, RK,  RK)        -- R(A) := RK(B) << RK(C)
    OPCODE.BSHR      = DebugOpcode(0x13, REG, RK,  RK)        -- R(A) := RK(B) >> RK(C)
    OPCODE.POW       = DebugOpcode(0x14, REG, RK,  RK)        -- R(A) := RK(B) ^ RK(C)  also BXOR
    OPCODE.UNM       = DebugOpcode(0x15, REG, REG)            -- R(A) := -R(B)
    OPCODE.NOT       = DebugOpcode(0x16, REG, REG)            -- R(A) := not R(B)
    OPCODE.CONCAT    = DebugOpcode(0x17, REG, REG, RRG)       -- R(A) := R(B)... R(B+1) ... R(C-1) ...R(C)
    OPCODE.JMP       = DebugOpcode(0x18, ___, OFF, ___, JUMP) -- PC += sBx
    OPCODE.EQ = DebugVarNameOpcode(0x19, BOL, RK,  RK,  SKIP) -- if ((RK(B) == RK(C)) ~= A) then PC++
    OPCODE.LT = DebugVarNameOpcode(0x1a, BOL, RK,  RK,  SKIP) -- if ((RK(B) <  RK(C)) ~= A) then PC++
    OPCODE.LE = DebugVarNameOpcode(0x1b, BOL, RK,  RK,  SKIP) -- if ((RK(B) <= RK(C)) ~= A) then PC++
    OPCODE.TEST=DebugVarNameOpcode(0x1c, REG, REG, BOL, SKIP) -- if ((Bool)R(B) == C) then R(A) := R(B) else PC++   C specifies what conditions the test should accept
    OPCODE.CALL      = DebugOpcode(0x1d, REG, VAL, VAL, CALL) -- R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))   if (B == 0) then B = top. C is the number of returns + 1, and can be 0: CALL then sets `top' to last_result+1, so next open instruction (CALL, RETURN, SETLIST) may use `top'.
    OPCODE.TAILCALL  = DebugOpcode(0x1e, REG, VAL, VAL, TAIL) -- return R(A)(R(A+1), ... ,R(A+B-1))
    OPCODE.RETURN    = DebugOpcode(0x1f, REG, VAL, ___, RET)  -- return R(A), ... ,R(A+B-2)    if (B == 0) then return up to `top'
    OPCODE.FORLOOP   = DebugOpcode(0x20, REG, OFF)            -- R(A)+=R(A+2); if R(A) <?= R(A+1) then PC+= sBx
    OPCODE.TFORLOOP  = DebugOpcode(0x21, REG, ___, VAL, SKIP) -- R(A+2), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2)); if R(A+2) ~= nil then pc++
    OPCODE.TFORPREP  = DebugOpcode(0x22, REG, OFF, ___, JUMP) -- if type(R(A)) == table then R(A+1) := R(A), R(A) := next; finally, PC += sBx
    OPCODE.SETLIST   = DebugOpcode(0x23, REG, DBL)            -- R(A)[Bx-Bx%FPF+i] := R(A+i), 1 <= i <= Bx%FPF
    OPCODE.SETLISTO  = DebugOpcode(0x24, REG, DBL)            -- R(A)[Bx-Bx%FPF+i] := R(A+i), 1 <= i <= top-A
    OPCODE.CLOSE     = DebugOpcode(0x25, REG)                 -- close all variables in the stack up to (>=) R(A) to upvalues
    OPCODE.CLOSURE   = DebugOpcode(0x26, REG, PRO)            -- R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+nups))

    -- we could have included the redundant opcode name information in the constructor, but...
    --          ...it looks better to omit it above
    for name, opcode in OPCODE do
        opcode.name = name
    end

    -- it's easier to see the comparation mode argument as part of the name; merge them
    -- (the logic is already setup--this is why these use different opcode classes)
    OPCODE.TEST.notName = "NTEST"
    OPCODE.TEST.renamingArg = 3
    OPCODE.LT.notName = "GE"
    OPCODE.LT.renamingArg = 1
    OPCODE.LE.notName = "GR"
    OPCODE.LE.renamingArg = 1
    OPCODE.EQ.notName = "NEQ"
    OPCODE.EQ.renamingArg = 1

    OPCODE.TEST.InstructionPrettyFormatArg = function(self, instr, arg, fn, addr)
        if arg == 1 then
            if instr:A() == instr:B() then
                return nil
            end
        end
        return DebugVarNameOpcode.InstructionPrettyFormatArg(self, instr, arg, fn, addr)
    end

    OPCODE.NEWTABLE.InstructionPrettyFormatArg = function(self, instr, arg, fn, addr)
        local norm = DebugOpcode.InstructionPrettyFormatArg(self, instr, arg, fn, addr)
        if norm == "0" then
            return nil
        end
        if arg == 2 then
            return "arr:" .. norm
        end
        if arg == 3 then
            return "hash:" .. norm
        end
        return norm
    end

    -- `LOADBOOL`'s arg C determines whether to skip the next instruction
    OPCODE.LOADBOOL.GetSkip = function(self, instr)
        return instr:C()
    end
    OPCODE.LOADBOOL.InstructionPrettyFormatArg = function(self, instr, arg, fn, addr)
        if arg == 3 then
            if instr:C() == 1 then
                return "(skip)"
            else
                return nil
            end
        end
        return DebugOpcode.InstructionPrettyFormatArg(self, instr, arg, fn, addr)
    end

    OPCODE.RETURN.InstructionPrettyFormatArg = function(self, instr, arg, fn, addr)
        local numRet = instr:B() - 1
        if numRet == -1 then
            if arg == 1 then
                return "<jump to top>"
            end
            return nil
        end

        if numRet == 0 then
            return nil
        end
        if arg == 1 then
            local first = DebugOpcode.InstructionPrettyFormatArg(self, instr, arg, fn, addr)
            if numRet > 2 then
                local a = instr:A()
                local last = DebugOpcodeArgPrettyFormatters.register(instr, a + numRet - 1, fn, addr)
                return first .. "..." .. last
            end
            return first
        end

        if numRet ~= 2 then
            return nil
        end
        local a = instr:A()
        local reg = DebugOpcodeArgPrettyFormatters.register(instr, a + numRet - 1, fn, addr)
        return reg
    end

    OPCODE.SETLISTO.InstructionPrettyFormatArg = function(self, instr, arg, fn, addr)
        local norm = DebugOpcode.InstructionPrettyFormatArg(self, instr, arg, fn, addr)
        if arg ~= 2 then
            return norm
        end
        local a = instr:A()
        local start = norm:sub(1, norm:find(',', 1, true))
        if a == 0 then
            return start .. "<top>"
        end
        return start .. "<top-" .. a .. '>'
    end

    OPCODE.TFORLOOP.InstructionPrettyFormatArg = function(self, instr, arg, fn, addr)
        local a = instr:A()
        if arg == 1 then
            local regFn = DebugOpcode.InstructionPrettyFormatArg(self, instr, arg, fn, addr)
            local regState = DebugOpcodeArgPrettyFormatters.register(instr, a + 1, fn, addr)
            local regCont = DebugOpcodeArgPrettyFormatters.register(instr, a + 2, fn, addr)
            return regFn .. '(' .. regState .. ", " .. regCont .. ')'
        end

        if arg == 2 then
            return "=>"
        end

        if arg == 3 then
            local c = instr:C()
            local first = DebugOpcodeArgPrettyFormatters.register(instr, a + 2, fn, addr)
            if c == 0 then
                return first
            end
            local last = DebugOpcodeArgPrettyFormatters.register(instr, a + 2 + c, fn, addr)
            return first .. "..." .. last
        end
    end

    ---@param self DebugOpcode
    ---@param instr DebugInstruction
    ---@param arg integer
    ---@param fn? DebugFunction optional function to resolve constants from
    ---@param addr? integer
    ---@return string | nil
    local function CallFormatArg(self, instr, arg, fn, addr)
        if arg == 1 then
            local regFn = DebugOpcode.InstructionPrettyFormatArg(self, instr, arg, fn, addr)
            local params = instr:B() - 1
            if params == -1 then
                return regFn .. "(...<top>)"
            end
            if params == 0 then
                return regFn .. "()" -- no parameters
            end
            local a = instr:A()
            local last = DebugOpcodeArgPrettyFormatters.register(instr, a + params, fn, addr)
            if params == 1 then
                return regFn .. '(' .. last .. ')'
            end
            local first = DebugOpcodeArgPrettyFormatters.register(instr, a + 1, fn, addr)
            return regFn .. '(' .. first .. "..." .. last .. ')'
        end

        local numRet = instr:C() - 1
        if arg == 2 then
            if numRet > 0 then
                return "=>"
            end
        end

        if arg == 3 then
            if numRet == -1 then
                return "<set top>"
            end
            if numRet == 0 then
                return nil -- no returns
            end
            local a = instr:A()
            local first = DebugOpcodeArgPrettyFormatters.register(instr, a, fn, addr)
            if numRet == 1 then
                return first
            end
            local last = DebugOpcodeArgPrettyFormatters.register(instr, a + numRet - 1, fn, addr)
            return first .. "..." .. last
        end
    end
    OPCODE.CALL.InstructionPrettyFormatArg = CallFormatArg
    OPCODE.TAILCALL.InstructionPrettyFormatArg = CallFormatArg

    ---@param self DebugOpcode
    ---@param instr DebugInstruction
    ---@param arg integer
    ---@param fn? DebugFunction optional function to resolve constants from
    ---@param addr? integer
    ---@return string | nil
    local function UpvalueableFormatArg(self, instr, arg, fn, addr)
        -- recieve signal from a CLOSURE that this instruction will be used to close
        -- an upvalue; it will therefore not have a destination
        if arg == 1 and instr:A() == -1 then
            return nil
        end
        return DebugOpcode.InstructionPrettyFormatArg(self, instr, arg, fn, addr)
    end
    OPCODE.MOVE.InstructionPrettyFormatArg = UpvalueableFormatArg
    OPCODE.GETUPVAL.InstructionPrettyFormatArg = UpvalueableFormatArg

    ---@param self DebugOpcode
    ---@param instr DebugInstruction
    ---@param fn DebugFunction
    ---@return integer
    OPCODE.CLOSURE.GetSkip = function(self, instr, fn)
        if fn then
            return fn.prototype.prototypeUpvalues[instr:B() + 1]
        else
            return 0
        end
    end
end

---@class DebugInstruction
---@field [1] DebugOpcode opcode
---@field [2]? integer A
---@field [3]? integer B
---@field [4]? integer C
DebugInstruction = ClassSimple {
    ---@param self DebugInstruction
    ---@param opcode DebugOpcode
    ---@param argA integer
    ---@param argB? integer
    ---@param argC? integer
    __init = function(self, opcode, argA, argB, argC)
        self[1] = opcode
        self[2] = argA
        self[3] = argB
        self[4] = argC
    end,

    ---@return DebugOpcode
    Opcode = function(self)
        return self[1]
    end,
    A = function(self)
        return self[2]
    end,
    B = function(self)
        return self[3]
    end,
    C = function(self)
        return self[4]
    end,

    ---@param self DebugInstruction
    ---@return integer
    GetJump = function(self)
        if self:Opcode().bKind == "offset" then
            return self:B() + 1 -- add one because the PC would automatically increment
        end
        return 0
    end,

    ---@param self DebugInstruction
    ---@param fn? DebugFunction
    ---@param addr? integer
    ---@return string
    PrettyFormat = function(self, fn, addr)
        local str = self:PrettyFormatName()
        local opcode = self:Opcode()
        local last
        for i = 1, opcode.args do
            local arg = self:PrettyFormatArg(i, fn, addr)
            if arg then
                if opcode:ArgKind(i) == "register_range" then
                    if arg ~= last then
                        str = str .. "..." .. arg
                    end
                else
                    str = str .. ' ' .. arg
                end
                last = arg
            end
        end
        return str
    end,

    ---@param self DebugInstruction
    ---@return string
    PrettyFormatName = function(self)
        return self:Opcode():InstructionPrettyFormatName(self)
    end,

    ---@param self DebugInstruction
    ---@param arg integer
    ---@param fn? DebugFunction
    ---@param addr? integer
    ---@return string | nil
    PrettyFormatArg = function(self, arg, fn, addr)
        return self:Opcode():InstructionPrettyFormatArg(self, arg, fn, addr)
    end,
}

---@param opcode DebugOpcode
---@param a integer
---@param b integer
---@param c? integer
---@return number
function InstructionCacheKey(opcode, a, b, c)
    -- Instructions have this bit pattern of 6-8-9-9 (for opcode, a, b, and c size, respectively)
    -- note: numbers are a float32, so we'll need every piece of information we can fit into it
    -- to store all 32 bits
    -- floats have 23 bits for a mantissa, 1 bit for a sign, and 8 bits for the exponent
    local op = opcode.index
    if opcode.format == "AsBx" then
        b = 0x1ffff + b
    end
    local mantissa = (op & 0x1f) | (b << 5)
    if c then
        mantissa = mantissa | (c << 14)
    end
    if op & 0x20 ~= 0 then
        mantissa =- mantissa
    end
    return MathLdexp(mantissa, a - 23)
end

local instructionCache
if cacheInstructions then
    instructionCache = {}
end
---@param opcode DebugOpcode
---@param a integer
---@param b integer
---@param c? integer
---@return DebugInstruction
function InstructionFor(opcode, a, b, c)
    if not cacheInstructions then
        return DebugInstruction(opcode, a, b, c)
    end
    local num = InstructionCacheKey(opcode, a, b, c)
    local existing = instructionCache[num]
    if not existing then
        existing = DebugInstruction(opcode, a, b, c)
        instructionCache[num] = existing
    end
    return existing
end


---@class DebugPrototype
---@field constantCount    integer
---@field constants        (number | string)[]
---@field knownPrototypes  integer
---@field instructionCount integer
---@field instructions     DebugInstruction[]
---@field lineCount        integer
---@field lineAddresses    integer[]
---@field lineNumbers      integer[]
---@field jumps?           table<integer[]>
---@field maxstack         integer
---@field numparams        integer
---@field prototypeUpvalues integer[]
DebugPrototype = ClassSimple {
    __init = function(self, bytecode, constants)
        self.constants = constants
        self.constantCount = table.getn(constants)

        local instructions = {}
        self.instructions = instructions

        local lineNumbers = {}
        self.lineNumbers = lineNumbers
        local lineAddresses = {}
        self.lineAddresses = lineAddresses
        local lineCount = 0

        local instructionCount = 0
        local lastLine = nil
        local knownPrototypes = 0
        local prototypeUpvalues = {}
        local processingUpvalues, numUpvalues, curProto = false, 0, 0
        for _, line in bytecode do
            -- ignore `maxstack` and `numparams` for now
            if type(line) == "number" then
                continue
            end
            -- each line is in a format like `(<lineNumber>) <instrNumber> - <OPCODE> <A> [<B> [<C>]]`
            -- e.g. `(  35)   58 - JUMP 0 -4`
            local chunker = line:gmatch("-?[%w]+")
            local lineNum, addr = tonumber(chunker()), tonumber(chunker())
            local opcode, argA, argB = OPCODE[chunker()], tonumber(chunker()), chunker()
            local argC

            -- construct instruction
            if argB then -- fill up arguments
                argB = tonumber(argB)
                argC = chunker()
                if argC then
                    argC = tonumber(argC)
                elseif opcode.bKind == "prototype" then
                    -- check for prototypes, since we aren't provided with that information
                    local proto = argB + 1
                    if prototypeUpvalues[proto] == nil then
                        if proto > knownPrototypes then
                            knownPrototypes = proto
                        end
                        processingUpvalues = lineNum
                        curProto = proto
                    end
                end
            end

            -- CLOSURE will have the next instructions (the number being the number
            -- of upvalues it has) be either MOVE or UPVALUE and the LVM will process
            -- them during the CLOSURE instruction; give these instructions a signal
            if processingUpvalues then
                if lineNum ~= processingUpvalues then
                    processingUpvalues = false
                    prototypeUpvalues[curProto] = numUpvalues
                    curProto = nil
                    numUpvalues = 0
                else
                    -- arg B holds the variable that's the upvalue
                    if opcode == OPCODE.CLOSURE then
                    elseif opcode == OPCODE.MOVE or opcode == OPCODE.GETUPVAL then
                        numUpvalues = numUpvalues + 1
                        argA = -1
                    end
                end
            end

            local instr = InstructionFor(opcode, argA or 0, argB, argC)

            -- instruction starts a different line
            if lastLine ~= lineNum then
                lineCount = lineCount + 1
                lineNumbers[lineCount] = lineNum
                lineAddresses[lineCount] = addr
                lastLine = lineNum
            end
            instructionCount = instructionCount + 1
            instructions[instructionCount] = instr
        end

        self.maxstack = bytecode.maxstack
        self.numparams = bytecode.numparams
        self.lineCount = lineCount
        self.instructionCount = instructionCount
        self.knownPrototypes = knownPrototypes
        self.prototypeUpvalues = prototypeUpvalues
    end,

    ---@param self DebugPrototype
    ---@param k number
    ---@return any
    GetConstant = function(self, k)
        return self.constants[k]
    end,

    --- Returns a table with keys being line numbers and values being an array of lines that jump to
    --- those lines
    ---@param self DebugPrototype
    ---@return table<number[]>
    ResolveJumps = function(self)
        local jumps = self.jumps
        if jumps then
            return jumps
        end
        jumps = {}
        self.jumps = jumps

        local TableInsert = table.insert
        local instructions = self.instructions
        for i = 1, self.instructionCount do
            local jmp = instructions[i]:GetJump()
            if jmp == 0 then
                continue
            end
            local addr = i - 1

            local loc = addr + jmp
            local jump = jumps[loc]
            if not jump then
                jump = {}
                jumps[loc] = jump
            end
            TableInsert(jump, addr)
        end
        return jumps
    end,
}

---@class DebugFunction
---@field currentline?     number
---@field fenv             table
---@field func             function
---@field location         string
---@field name             string
---@field prototype        DebugPrototype
---@field scope            string
---@field short_loc        string
---@field source           ProfilerSource
---@field upvalues         string[]
DebugFunction = ClassSimple {
    ---@param self DebugFunction
    ---@param f integer | function | RawFunctionDebugInfo
    __init = function(self, f)
        local info, upvalues, constants, bytecode = f.info, f.upvalueNames, f.constants, f.bytecode
        if info and upvalues and constants and bytecode then
        else
            f = GetDebugFunctionInfo(f)
            info, upvalues, constants, bytecode = f.info, f.upvalueNames, f.constants, f.bytecode
        end

        self.source, self.scope, self.name = CollapseDebugInfo(info)
        self.nups = info.nups
        self.short_loc = info.short_src
        if '@' .. info.short_src ~= info.source then
            self.location = info.source
        end
        local fn = info.func
        self.func = fn
        self.fenv = getfenv(fn)

        local currentline = info.currentline
        if currentline and currentline ~= -1 then
            self.currentline = currentline
        end

        self.upvalues = upvalues
        self.prototype = DebugPrototype(bytecode, constants)
    end,

    ---@param self DebugFunction
    ---@param ... any
    ---@return ...
    Call = function(self, ...)
        return self.func(unpack(arg))
    end,

    ---@param self DebugFunction
    ---@param k integer
    ---@return any
    GetConstant = function(self, k)
        return self.prototype:GetConstant(k)
    end,

    ---@param self DebugFunction
    ---@param k integer
    ---@return any
    GetGlobal = function(self, k)
        local key = self:GetConstant(k)
        return self.fenv[key]
    end,

    ---@param self DebugFunction
    ---@param k integer
    ---@return string
    GetUpvalueName = function(self, k)
        return self.upvalues[k]
    end,

    ---@param self DebugFunction
    ---@param k integer
    ---@return any
    GetUpvalue = function(self, k)
        local _, val = debug.getupvalue(self.func, k)
        return val
    end,


    ----------
    -- Pretty Formatting
    ----------

    ---@param self DebugFunction
    ---@param inlineLines? boolean whether line numbers are inline with its first address
    PrettyPrint = function(self, inlineLines)
        for _, line in self:PrettyFormat(inlineLines) do
            LOG(line)
        end
    end,

    ---@param self DebugFunction
    ---@param inlineLines? boolean whether line numbers are inline with its first address
    ---@return string[]
    PrettyFormat = function(self, inlineLines)
        local output = {}
        local outputCount = 0

        local prototype = self.prototype
        local jumps = prototype:ResolveJumps()
        local lineNumbers = prototype.lineNumbers
        local lineAddresses = prototype.lineAddresses

        local lineLocalizer = LOC("<LOC debug_0000>Line %d:")
        local curLine = 1
        local nextLineAddr = lineAddresses[curLine]

        local indent = "    "
        local margin = indent
        if inlineLines then
            local maxLine = lineNumbers[prototype.lineCount]
            margin = (' '):rep(lineLocalizer:format(maxLine):len() + 1)
        end

        local skipping = 0
        for k, instr in prototype.instructions do
            local addr = k - 1
            local prefix = margin

            if addr == nextLineAddr then
                local lineNum = lineLocalizer:format(lineNumbers[curLine])
                curLine = curLine + 1
                nextLineAddr = lineAddresses[curLine]

                if not inlineLines then
                    outputCount = outputCount + 1
                    output[outputCount] = lineNum
                else
                    prefix = lineNum .. margin:sub(lineNum:len() + 1)
                end
            end

            local indentation
            if skipping > 0 then
                indentation = indent
                skipping = skipping - 1
            else
                local curSkip = instr:Opcode():GetSkip(instr, self)
                if curSkip > 0 then
                    skipping = curSkip
                end
            end
            local outputLine = self:PrettyFormatLine(instr, addr, jumps[addr], indentation)

            outputCount = outputCount + 1
            output[outputCount] = prefix .. outputLine
        end
        return output
    end,

    ---@param self DebugFunction
    ---@param instr DebugInstruction
    ---@param addr integer
    ---@param jmpInd? boolean
    ---@param indentation? string
    ---@return string line
    PrettyFormatLine = function(self, instr, addr, jmpInd, indentation)
        local prettyAddr = AddressToString(addr)
        if jmpInd then
            prettyAddr = prettyAddr .. " >"
        else
            prettyAddr = prettyAddr .. "  "
        end

        local prettyInstr = instr:PrettyFormat(self, addr)
        if indentation then
            prettyInstr = indentation .. prettyInstr
        end

        return prettyAddr .. prettyInstr
    end,
}

function PrintOut(f)
    DebugFunction(f):PrettyPrint()
end
