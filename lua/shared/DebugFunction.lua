--- meh. ill comment later




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


--- Broken, can only get the first parameter
---@param fn function
---@param numparams number
---@return string[]
function GetParameterNames(fn, numparams)
    local parameters = {}
    if numparams == 1 then
        -- it appears that we can still pull out the first parameter name, regardless of if
        -- we're inside it
        parameters[1] = debug.listlocals(fn, 1)
    elseif numparams ~= 1 then
        -- the else case crashes the game, so this is the solution
        parameters[1] = debug.listlocals(fn, 1)
        for i = 2, numparams do
            parameters[i] = "unknown"
        end
    else
        -- little bit of a hack to pull out the parameter names, since the function needs to be
        -- running to get able to get more than the first parameter
        local th = coroutine.create(fn)
        -- save the currently debug hook (use of this file probably means that the profiler is on)
        local restoreHook, restoreMask, restoreCount = debug.gethook()
        local ignore = true
        debug.sethook(function()
            -- ignore initial `coroutine.resume` call
            if ignore then
                ignore = false
                return
            end
            local fun = debug.getinfo(2, "f").func -- `debug.listlocals` doesn't accept a function level
            local parameters = parameters
            local DebugListlocal = debug.listlocals
            for i = 1, numparams do
                -- doesn't work
                parameters[i] = DebugListlocal(fun, i)
            end
            KillThread(th)
            ignore = true -- ignore debug.sethook too?
        end, "c")
        coroutine.resume(th) -- immediately ends
        if restoreHook ~= nil then
            debug.sethook(restoreHook, restoreMask, restoreCount)
        else
            debug.sethook()
        end
    end
    return parameters
end

---@class RawFunctionDebugInfo : debuginfo
---@field bytecode Bytecode
---@field constants any[]
---@field parameters string[]
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
    local bytecode = debug.listcode(fn)
    info.parameters = GetParameterNames(fn, bytecode.numparams)
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
    local parameters = GetParameterNames(fn, bytecode.numparams)
    return {
        bytecode = bytecode,
        constants = constants,
        info = info,
        parameters = parameters,
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
---| "const"
---| "double"
---| "global"
---| "offset"
---| "prototype"
---| "register"
---| "register_or_const"
---| "upvalue"
---| "value"
---@alias DebugOpControlFlow "call" | "jump" | "return" | "skip" | "tailcall"
---@alias DebugOpFormat "A" | "AB" | "ABC" | "ABx" | "AsBx"


---@param address? integer defaults to the instruction address
---@return string
local function AddressToString(address)
    if address ~= 0 then
        return addressPattern:format(address)
    end
    -- the formatter just returns "00000" for 0
    return addressZero
end

---@param arg? DebugOpArgKind
---@return boolean
local function ArgKindIsDouble(arg)
    return arg == "double" or arg == "global" or arg == "offset" or arg == "prototype"
end

---@type table<DebugOpArgKind, fun(intr: DebugInstruction, arg: integer, fn?: DebugFunction): string>
DebugOpcodeArgFormatters = {
    default = function(instr, arg, fn)
        return tostring(arg)
    end,

    const = function(instr, arg, fn)
        if fn then
            return Representation(fn:GetConstant(arg + 1))
        end
        return "K(" .. arg .. ')'
    end,
    global = function(instr, arg, fn)
        if fn then
            return Representation(fn:GetConstant(arg + 1))
        end
        return "G(K(" .. arg .. "))"
    end,
    offset = function(instr, arg, fn)
        -- adjust address offsets to absolute addresses
        return AddressToString(instr:GetJump(arg))
    end,
    prototype = function(instr, arg, fn)
        return "P(" .. arg .. ')'
    end,
    register = function(instr, arg, fn)
        return 'R' .. arg
    end,
    register_or_const = function(instr, arg, fn)
        if arg < MAXSTACK then
            return 'R' .. arg
        else
            arg = arg - MAXSTACK
            if fn then
                return Representation(fn:GetConstant(arg + 1))
            end
            return "K(" .. arg .. ')'
        end
    end,
    upvalue = function(instr, arg, fn)
        if fn then
            return Representation(fn:GetUpvalueName(arg + 1))
        end
        return "U(" .. arg .. ')'
    end,

    -- SETLIST is mangled to shove two numbers into one argument asymmetrically in Lua 5.0
    -- (SETLISTO reuses the first one)
    double = function(instr, arg, fn)
        local len = math.mod(arg, FIELDS_PER_FLUSH) + 1
        local start = arg - len + 2
        return start .. ',' .. len
    end,
}
setmetatable(DebugOpcodeArgFormatters, {
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

    ---@param self DebugOpcode
    ---@param instr DebugInstruction
    ---@return string
    InstructionName = function(self, instr)
        return self.name
    end,

    ---@param self DebugOpcode
    ---@param instr DebugInstruction
    ---@param arg integer
    ---@param fn? DebugFunction optional function to resolve constants from
    ---@return string | nil
    InstructionArgToString = function(self, instr, arg, fn)
        local type = self[string.char(64 + arg) .. "Kind"]
        if not type then
            return nil
        end
        return DebugOpcodeArgFormatters[type](instr, instr[arg + 1], fn)
    end,
}

---@class DebugVarNameOpcode : DebugOpcode
---@field notName string
---@field renamingArg integer
DebugVarNameOpcode = Class(DebugOpcode) {
    ---@param self DebugVarNameOpcode
    ---@param instr DebugInstruction
    ---@return string
    InstructionName = function(self, instr)
        if instr[self.renamingArg + 1] == 0 then
            return self.name
        end
        return self.notName
    end,

    ---@param self DebugVarNameOpcode
    ---@param instr DebugInstruction
    ---@param arg integer
    ---@param fn? DebugFunction optional function to resolve constants from
    ---@return string | nil
    InstructionArgToString = function(self, instr, arg, fn)
        if arg == self.renamingArg then
            return nil
        end
        return DebugOpcode.InstructionArgToString(self, instr, arg, fn)
    end,
}

---@type table<string, DebugOpcode>
OPCODE = {}
local opcodeForIndex = {}
do
    -- store these strings so we can format the opcode construction 'prettily'
    local CON = "const"
    local DBL = "double"
    local GLO = "global"
    local OFF = "offset"
    local PRO = "prototype"
    local REG = "register"
    local RK  = "register_or_const" -- if x < MAXSTACK then REG(x) else CON(x-MAXSTACK)
    local UPV = "upvalue"
    local VAL = "value"
    local CALL = "call"
    local JUMP = "jump"
    local SKIP = "skip"
    local RET  = "return"
    local TAIL = "tailcall"
    local ___
    -- OPCODE.NAME   = OpcodeClass(index, argA, argB, argC, controlFlow)
                                                              -- PC++ assumes that the skipped instruction is a jump
    OPCODE.MOVE      = DebugOpcode(0x00, REG, REG)            -- R(A) := R(B)
    OPCODE.LOADK     = DebugOpcode(0x01, REG, CON)            -- R(A) := Kst(Bx)
    OPCODE.LOADBOOL  = DebugOpcode(0x02, REG, VAL, VAL, SKIP) -- R(A) := (Bool)B; if (C) PC++
    OPCODE.LOADNIL   = DebugOpcode(0x03, REG, REG)            -- R(A) := ... := R(B) := nil
    OPCODE.GETUPVAL  = DebugOpcode(0x04, REG, UPV)            -- R(A) := UpValue[B]
    OPCODE.GETGLOBAL = DebugOpcode(0x05, REG, GLO)            -- R(A) := Gbl[Kst(Bx)]
    OPCODE.GETTABLE  = DebugOpcode(0x06, REG, REG, RK)        -- R(A) := R(B)[RK(C)]
    OPCODE.SETGLOBAL = DebugOpcode(0x07, REG, GLO)            -- Gbl[Kst(Bx)] := R(A)
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
    OPCODE.POW       = DebugOpcode(0x14, REG, RK,  RK)        -- R(A) := RK(B) ^ RK(C)
    OPCODE.UNM       = DebugOpcode(0x15, REG, REG)            -- R(A) := -R(B)
    OPCODE.NOT       = DebugOpcode(0x16, REG, REG)            -- R(A) := not R(B)
    OPCODE.CONCAT    = DebugOpcode(0x17, REG, REG, REG)       -- R(A) := R(B)... R(B+1) ... R(C-1) ...R(C)
    OPCODE.JMP       = DebugOpcode(0x18, ___, OFF, ___, JUMP) -- PC += sBx
    OPCODE.EQ = DebugVarNameOpcode(0x19, VAL, RK,  RK,  SKIP) -- if ((RK(B) == RK(C)) ~= A) then PC++
    OPCODE.LT = DebugVarNameOpcode(0x1a, VAL, RK,  RK,  SKIP) -- if ((RK(B) <  RK(C)) ~= A) then PC++
    OPCODE.LE = DebugVarNameOpcode(0x1b, VAL, RK,  RK,  SKIP) -- if ((RK(B) <= RK(C)) ~= A) then PC++
    OPCODE.TEST=DebugVarNameOpcode(0x1c, REG, REG, VAL, SKIP) -- if ((Bool)R(B) == C) then R(A) := R(B) else PC++   C specifies what conditions the test should accept
    OPCODE.CALL      = DebugOpcode(0x1d, REG, VAL, VAL, CALL) -- R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))   if (B == 0) then B = top. C is the number of returns - 1, and can be 0: CALL then sets `top' to last_result+1, so next open instruction (CALL, RETURN, SETLIST) may use `top'.
    OPCODE.TAILCALL  = DebugOpcode(0x1e, REG, VAL, VAL, TAIL) -- return R(A)(R(A+1), ... ,R(A+B-1))
    OPCODE.RETURN    = DebugOpcode(0x1f, REG, VAL, ___, RET)  -- return R(A), ... ,R(A+B-2)    if (B == 0) then return up to `top'
    OPCODE.FORLOOP   = DebugOpcode(0x20, REG, OFF)            -- R(A)+=R(A+2); if R(A) <?= R(A+1) then PC+= sBx
    OPCODE.TFORLOOP  = DebugOpcode(0x21, REG, ___, VAL, SKIP) -- R(A+2), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2)); if R(A+2) ~= nil then pc++
    OPCODE.TFORPREP  = DebugOpcode(0x22, REG, OFF, ___, SKIP) -- if type(R(A)) == table then R(A+1) := R(A), R(A) := next; finally, PC += sBx
    OPCODE.SETLIST   = DebugOpcode(0x23, REG, DBL)            -- R(A)[Bx-Bx%FPF+i] := R(A+i), 1 <= i <= Bx%FPF
    OPCODE.SETLISTO  = DebugOpcode(0x24, REG, DBL)            -- R(A)[Bx-Bx%FPF+i] := R(A+i), 1 <= i <= top-A
    OPCODE.CLOSE     = DebugOpcode(0x25, REG)                 -- close all variables in the stack up to (>=) R(A) to upvalues
    OPCODE.CLOSURE   = DebugOpcode(0x26, REG, PRO)            -- R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))

    -- we could have included the redundant opcode name information in the constructor, but...
    --          ...it looks better to omit it above
    for name, opcode in OPCODE do
        opcode.name = name
        opcodeForIndex[opcode.index] = opcode
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
end

---@param opcode DebugOpcode
---@param a integer
---@param b integer
---@param c? integer
---@return integer
function InstructionToInt32(opcode, a, b, c)
    -- If you'll recall, instructions have this weird bit pattern of 6-8-9-9 (for opcode, a, b,
    -- and c size, respectively) which means a similarly weird mapping into 32 bits.
    -- It works like this:
    --
    --     {C[9:8],OP[6:1], B[9],C[7:1], B[8:1], A[8:1]}
    --          byte 1        byte 2     byte 3  byte 4
    --
    -- (represented with Verilog bit operators + Lua 1-indexing). The most confusing part
    -- is the little endianness not splicing pleasantly--otherwise, it'd just be
    -- `{A[1:8],B[1:9],C[1:9],OP[1:6]}` in big-endian
    local int = opcode.index << 24
    if c then
        return int |
            ((c & 3) << 30) |
            ((b & 1) << 23) | (c & 0xfc << 14) |
            (b & 0xfe) << 7 |
            a
    end
    -- actually, if `C` is absent, it's replaced by `B`
    --
    --     {B[9:8],OP[6:1], 1'b0,B[7:1], 8'b0, A[8:1]}
    if opcode.format == "AsBx" then
        b = 0x1ffff + b -- recenter signed numbers
    end
    int = ((b & 3) << 30) | int
    local byte2 = b >> 2
    if ArgKindIsDouble(opcode.bKind) then
        -- unless `B` is really a double, `Bx`
        --
        --     {Bx[9:8],OP[6:1], Bx[10],Bx[7:1], Bx[18:11], A[8:1]}
        byte2 = byte2 & 0xff
        byte3 = (b >> 10) & 0xff
    end
    int = int | byte2 << 16
    return int
end

---@class DebugInstruction
---@field [1] DebugOpcode
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

    ---@param self DebugInstruction
    ---@return string
    GetName = function(self)
        return self[1]:InstructionName(self)
    end,

    ---@param self DebugInstruction
    ---@param arg integer
    ---@param fn? DebugFunction
    ---@return string | nil
    ArgToString = function(self, arg, fn)
        return self[1]:InstructionArgToString(self, arg, fn)
    end,

    ---@param self DebugInstruction
    ---@return integer
    GetJump = function(self)
        if self[1].bKind == "offset" then
            return self[3] + 1 -- add one because the PC would automatically increment
        end
        return 0
    end,

    ---@param self DebugInstruction
    ---@param fn? DebugFunction
    ---@return string
    InstructionToString = function(self, fn)
        local str = self:GetName()
        for i = 1, self[1].args do
            local arg = self:ArgToString(i, fn)
            if arg then
                str = str .. ' ' .. arg
            end
        end
        return str
    end,

    ---@param self DebugInstruction
    ---@return integer
    AsInt32 = function(self)
        return InstructionToInt32(self[1], self[2] or 0, self[3], self[4])
    end,

    ---@param self DebugInstruction
    ---@return string
    Serialize = function(self)
        -- see comments above for `InstructionToInt32`
        local byte1, byte2, byte3, byte4
        local opcode = self[1]
        byte1 = opcode.index
        byte4 = self[2] or 0
        local b = self[3]
        local c = self[4]
        if c then
            byte1 = ((c & 3) << 6) | byte1
            byte2 = ((b & 1) << 7) | (c >> 2)
            byte3 =  b >> 1
        else
            if opcode.format == "Asbx" then
                b = 0x1ffff + b
            end
            byte1 = ((b & 3) << 6) | byte1
            byte2 = b >> 2
            if ArgKindIsDouble(opcode.bKind) then
                byte2 = byte2 & 0xff
                byte3 = (b >> 10) & 0xff
            else
                byte3 = 0
            end
        end
        return ("%02x %02x %02x %02x"):format(byte1, byte2, byte3, byte4)
    end,
}

local instructionCache = {}
---@param opcode DebugOpcode
---@param a integer
---@param b integer
---@param c? integer
---@return DebugInstruction
function InstructionFor(opcode, a, b, c)
    local int32 = InstructionToInt32(opcode, a, b, c)
    local existing = instructionCache[int32]
    if not existing then
        existing = DebugInstruction(opcode, a, b, c)
        instructionCache[int32] = existing
    end
    return existing
end



---@class DebugLine : DebugInstruction[]
---@field lineNumber integer
---@field instructionCount integer
DebugLine = ClassSimple {
    ---@param self DebugLine
    ---@param lineNum integer
    __init = function(self, lineNum)
        self.lineNumber = lineNum
    end,
}

---@class DebugPrototype
---@field constantCount    integer
---@field constants        (number | string)[]
---@field instructionCount integer
---@field instructions     DebugInstruction[]
---@field jumps?           table<integer[]>
---@field maxstack         integer
---@field numparams        integer
DebugPrototype = ClassSimple {
    __init = function(self, bytecode, constants)
        self.constants = constants
        self.constantCount = table.getn(constants)

        local lines = {}
        self.lines = lines

        local instructions = {}
        self.instructions = instructions

        local lineCount = 0
        local debugLine
        local instructionCount = 0
        local totalInstrCount = 0
        local lastLine = nil
        local knownPrototypes = 0
        for _, line in bytecode do
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
                    if proto > knownPrototypes then
                        knownPrototypes = proto
                    end
                end
            end

            local instr = InstructionFor(opcode, argA or 0, argB, argC)

            -- instruction starts a different line
            if lastLine ~= lineNum then
                if debugLine ~= nil then
                    debugLine.instructionCount = instructionCount
                end
                debugLine = DebugLine(lineNum)
                lineCount = lineCount + 1
                lines[lineCount] = debugLine
                instructionCount = 0
                lastLine = lineNum
            end
            instructionCount = instructionCount + 1
            debugLine[instructionCount] = instr
            totalInstrCount = totalInstrCount + 1
            instructions[totalInstrCount] = instr
        end
        if debugLine ~= nil then
            debugLine.instructionCount = instructionCount
        end

        -- the bytecode table reports two numbers: maxstack and numparams--transfer them here
        self.maxstack = bytecode.maxstack
        self.numparams = bytecode.numparams
        self.lineCount = lineCount
        self.instructionCount = totalInstrCount
        self.knownPrototypes = knownPrototypes
    end,

    ---@param self DebugPrototype
    ---@param k number
    ---@return any
    GetConstant = function(self, k)
        return self.constants[k]
    end,

    ---@param self DebugPrototype
    ---@param k number
    ---@return any
    GetGlobal = function(self, k)
        local key = self:GetConstant(k)
        return _G[key]
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
        local TableInsert = table.insert
        jumps = {}
        self.jumps = jumps
        local instructions = self.instructions
        for i = 1, self.instructionCount do
            local instr = instructions[i]
            if instr[1].bKind == "offset" then
                local loc = i + instr:GetJump() + 1
                local jump = jumps[loc]
                if not jump then
                    jump = {}
                    jumps[loc] = jump
                end
                TableInsert(jump, i - 1)
            end
        end
        return jumps
    end,
}

---@class DebugFunction
---@field currentline?     number
---@field func             function
---@field knownPrototypes  number
---@field lineCount        number
---@field lines            DebugLine[]
---@field location         string
---@field short_loc        string
---@field source           ProfilerSource
DebugFunction = ClassSimple {
    ---@param self DebugFunction
    ---@param f integer | function | RawFunctionDebugInfo
    __init = function(self, f)
        local info, parameters, upvalues, constants, bytecode = f.info, f.parameters, f.upvalueNames, f.constants, f.bytecode
        if info and parameters and upvalues and constants and bytecode then
        else
            f = GetDebugFunctionInfo(f)
            info, parameters, upvalues, constants, bytecode = f.info, f.parameters, f.upvalueNames, f.constants, f.bytecode
        end

        self.source, self.scope, self.name = CollapseDebugInfo(info)
        self.nups = info.nups
        self.short_loc = info.short_src
        if '@' .. info.short_src ~= info.source then
            self.location = info.source
        end
        local fn = info.func
        self.func = fn

        local currentline = info.currentline
        if currentline and currentline ~= -1 then
            self.currentline = currentline
        end

        self.upvalues = upvalues
        self.parameters = parameters
        self.constants = constants
        self.constantCount = table.getn(constants)

        local lines = {}
        self.lines = lines

        local instructions = {}
        self.instructions = instructions

        local lineCount = 0
        local debugLine
        local instructionCount = 0
        local totalInstrCount = 0
        local lastLine = nil
        local knownPrototypes = 0
        for _, line in bytecode do
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
                elseif opcode.B == "prototype" then
                    -- check for prototypes, since we aren't provided with that information
                    local proto = argB + 1
                    if proto > knownPrototypes then
                        knownPrototypes = proto
                    end
                end
            end

            local instr = DebugInstruction(addr, opcode, argA, argB, argC)

            -- instruction starts a different line
            if lastLine ~= lineNum then
                if debugLine ~= nil then
                    debugLine.instructionCount = instructionCount
                end
                debugLine = DebugLine(lineNum)
                lineCount = lineCount + 1
                lines[lineCount] = debugLine
                instructionCount = 0
                lastLine = lineNum
            end
            instructionCount = instructionCount + 1
            debugLine[instructionCount] = instr
            totalInstrCount = totalInstrCount + 1
            instructions[totalInstrCount] = instr
        end
        if debugLine ~= nil then
            debugLine.instructionCount = instructionCount
        end

        -- the bytecode table reports two numbers: maxstack and numparams--transfer them here
        -- (excluding these two values is entirely why we recreated the bytecode table)
        self.maxstack = bytecode.maxstack
        self.numparams = bytecode.numparams
        self.lineCount = lineCount
        self.instructionCount = totalInstrCount
        self.knownPrototypes = knownPrototypes

        -- let them call the debug function directly, I guess?
        setmetatable(self, {
            __index = DebugFunction,
            __call = self.func
        })
    end,

    ---@param self DebugFunction
    ---@param k number
    ---@return any
    GetConstant = function(self, k)
        return self.constants[k]
    end,

    ---@param self DebugFunction
    ---@param k number
    ---@return any
    GetGlobal = function(self, k)
        local key = self:GetConstant(k)
        return _G[key]
    end,

    ---@param self DebugFunction
    ---@param k number
    ---@return string
    GetUpvalueName = function(self, k)
        return self.upvalues[k]
    end,

    ---@param self DebugFunction
    ---@param k number
    ---@return any
    GetUpvalue = function(self, k)
        local _, val = debug.getupvalue(self.func, k)
        return val
    end,

    --- Returns a table with keys being line numbers and values being an array of lines that jump to
    --- those lines
    ---@param self DebugFunction
    ---@return table<number[]>
    ResolveJumps = function(self)
        local jumps = self.jumps
        if jumps then
            return jumps
        end
        local TableInsert = table.insert
        jumps = {}
        self.jumps = jumps
        local instructions = self.instructions
        for i = 1, self.instructionCount do
            local instr = instructions[i]
            if instr.opcode.B == "offset" then
                local loc = instr:ResolveAbsoluteAddress(instr.B) + 1
                local jump = jumps[loc]
                if not jump then
                    jump = {}
                    jumps[loc] = jump
                end
                TableInsert(jump, i - 1)
            end
        end
        return jumps
    end,

    ---@param self DebugFunction
    ---@return string[]
    PrettyPrint = function(self)
        local lines = {}
        local lineLocalizer = LOC("<LOC debug_0000>Line %d:")
        local jumps = self:ResolveJumps()
        local instructionCount = 0
        local lineCount = 0
        for _, line in self.lines do
            lineCount = lineCount + 1
            lines[lineCount] = lineLocalizer:format(line.lineNumber)
            local prepend
            for i = 1, line.instructionCount do
                local instr = line[i]
                -- insert jump indicator if the instruction is jumped to by another instruction
                local str = instr:OperationToString(self)
                instructionCount = instructionCount + 1
                if jumps[instructionCount] then
                    str = '>' .. str
                end

                local controlFlow = instr.opcode.controlFlow
                if prepend then
                    str = prepend .. str
                    prepend = nil
                end
                if controlFlow == "skip" then
                    prepend = "    "
                end

                str = "    " .. instr:AddressToString() .. "  " .. str
                lineCount = lineCount + 1
                lines[lineCount] = str
            end
        end
        return lines
    end,
}
