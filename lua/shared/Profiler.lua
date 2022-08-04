
---@alias ProfilerSource "C" | "Lua" | "main" | "unknown"

---@class ProfilerData
---@field C ProfilerSourceData
---@field Lua ProfilerSourceData
---@field main ProfilerSourceData
---@field unknown ProfilerSourceData

---@alias ProfilerScope "field" | "global" | "local" | "method" | "other" | "upvalue"

---@class ProfilerSourceData
---@field global ProfilerScopeData
---@field upval  ProfilerScopeData
---@field local  ProfilerScopeData
---@field method ProfilerScopeData
---@field field  ProfilerScopeData
---@field other  ProfilerScopeData

---@alias ProfilerScopeData ProfilerFunctionData[]

---@alias ProfilerField "growth" | "name" | "nameLower" | "scope" | "source" | "value"

---@class ProfilerFunctionData
---@field growth number
---@field name string
---@field nameLower string
---@field scope string
---@field source string
---@field value number

---@class ProfilerGrowth
---@field C table<string, number>
---@field Lua table<string, number>
---@field main table<string, number>
---@field unknown table<string, number>

---@class BenchmarkModuleMetadataFormat
---@field BenchmarkData? table<string, BenchmarkMetadataFormat | string>
---@field Exclude? table<string, boolean>
---@field ModuleDescription? string
---@field ModuleName? string defaults to the file name
---@field NotBenchmarkModule? boolean

---@class BenchmarkMetadataFormat
---@field desc? string
---@field exclude? boolean
---@field name? string defaults to the function name
---@field runs? number defaults to `/lua/sim/Profiler.lua#defaultBenchmarkRuns`
---@field sort? number defaults to `0`


--- Constructs an empty table that the profiler can populate
---@return ProfilerData
function CreateEmptyProfilerTable()
    return {
        Lua = {
            ["field"]  = {},
            ["global"] = {},
            ["local"]  = {},
            ["method"] = {},
            ["other"]  = {},
            ["upval"]  = {},
        },
        C = {
            ["field"]  = {},
            ["global"] = {},
            ["local"]  = {},
            ["method"] = {},
            ["other"]  = {},
            ["upval"]  = {},
        },
        main = {
            ["field"]  = {},
            ["global"] = {},
            ["local"]  = {},
            ["method"] = {},
            ["other"]  = {},
            ["upval"]  = {},
        },
        unknown = {
            ["field"]  = {},
            ["global"] = {},
            ["local"]  = {},
            ["method"] = {},
            ["other"]  = {},
            ["upval"]  = {},
        },
    }
end

-- the profiler benchmarks must be guarded so that players can't maliciously send requests
local devs = {"jip", "hdt80bro"}
---@param player Army | AIBrain | string
---@return boolean
function PlayerIsDev(player)
    local t = type(player)
    if t == "number" then -- army
        player = ArmyBrains[player].Nickname:lower()
    elseif t ~= "string" then -- AIBrain
        player = player.Nickname:lower()
    end
    for _, dev in devs do
        if player == dev then
            return true
        end
    end
    return false
end

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
    local name = info.name or "lambda"
    return source, scope, name
end

local function FormatToString(val)
    if type(val) == "string" then
        return string.format("%q", val)
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

local hexWidth = math.ceil(Bx_SIZE / 4)
local addressPattern = "%0#" .. (hexWidth + 2) .. "x"
local addressZero = "0x" .. string.rep("0", hexWidth)

---@alias DebugOpArgKind "const" | "double" | "global" | "offset" | "prototype" | "register" | "register|const" | "upvalue" | "value"
---@alias DebugOpControlFlow "call" | "jump" | "return" | "skip" | "tailcall"
---@alias DebugOpFormat "A" | "AB" | "ABC" | "ABx" | "AsBx"

---@class DebugOpcode
---@field args number
---@field A?  DebugOpArgKind
---@field B?  DebugOpArgKind
---@field C?  DebugOpArgKind
---@field format DebugOpFormat
---@field controlFlow? DebugOpControlFlow
---@field name string
DebugOpcode = Class() {
    ---@param a DebugOpArgKind
    ---@param b? DebugOpArgKind
    ---@param c? DebugOpArgKind
    ---@param controlFlow? DebugOpControlFlow
    ---@return DebugOpcode
    __init = function(self, a, b, c, controlFlow)
        self.A = a
        if controlFlow then
            self.controlFlow = controlFlow
        end
        local size = OP_SIZE + A_SIZE
        if b then
            self.B = b
            if b == "register" or b == "register|const" or b == "upvalue" or b == "value" then
                size = size + B_SIZE
                if c then
                    size = size + C_SIZE
                    self.args = 3
                    self.C = c
                    self.format = "ABC"
                else
                    self.args = 2
                    self.format = "AB"
                end
            else
                size = size + Bx_SIZE
                self.args = 2
                if b == "offset" then
                    self.format = "AsBx"
                else
                    self.format = "ABx"
                end
            end
        elseif c then
            size = size + B_SIZE + C_SIZE
            self.args = 3
            self.C = c
            self.format = "ABC"
        else
            self.args = 1
            self.format = "A"
        end
        self.size = size
        return self
    end;

    __tostring = function(self)
        return self.name
    end;

    InstructionName = function(self, instr)
        return self.name
    end;

    ---@param self DebugOpcode
    ---@param instr DebugInstruction
    ---@param arg number | string
    ---@param fn? DebugFunction optional function to resolve constants from
    InstructionArgToString = function(self, instr, arg, fn)
        if type(arg) == "number" then
            arg = string.char(64 + arg)
        end
        local type = self[arg]
        if not type then
            return nil
        end
        local value = instr[arg]
        if type == "register|const" then
            if value < MAXSTACK then
                type = "register"
            else
                type = "const"
                value = value - MAXSTACK
            end
        end
        if type == "register" then
            return "R" .. value
        elseif type == "const" then
            if fn then
                return FormatToString(fn:GetConstant(value + 1))
            end
            return "K(" .. value .. ")"
        elseif type == "global" then
            if fn then
                return FormatToString(fn:GetConstant(value + 1))
            end
            return "G(K(" .. value .. "))"
        elseif type == "prototype" then
            return "P(" .. value .. ")"
        elseif type == "offset" then
            -- adjust address offsets to absolute addresses
            value = instr:ResolveAbsoluteAddress(value)
            if value == 0 then
                -- the formatter just returns "00000" for 0
                return addressZero
            end
            return addressPattern:format(value)
        elseif type == "upvalue" then
            if fn then
                return FormatToString(fn:GetUpvalueName(value + 1))
            end
            return "U(" .. value .. ")"
        else -- value or double
            return tostring(value)
        end
    end;
}

---@class DebugVarNameOpcode : DebugOpcode
---@field notName string
---@field argName string
DebugVarNameOpcode = Class(DebugOpcode) {
    InstructionName = function(self, instr)
        if instr[self.argName] == 0 then
            return self.name
        else
            return self.notName
        end
    end;

    InstructionArgToString = function(self, arg, fn)
        if type(arg) == "number" then
            arg = string.char(64 + arg)
        end
        if arg == self.argName then
            return nil
        end
        return DebugOpcode.InstructionArgToString(self, arg, fn)
    end;
}

---@type table<string, DebugOpcode>
OPCODE = {}
do
    -- store these strings so we can format the opcode construction 'prettily'
    local CON = "const"
    local DBL = "double"
    local GLO = "global"
    local OFF = "offset"
    local PRO = "prototype"
    local REG = "register"
    local RK  = "register|const" -- if x < MAXSTACK then REG(x) else CON(x-MAXSTACK)
    local UPV = "upvalue"
    local VAL = "value"
    local CALL = "call"
    local JUMP = "jump"
    local SKIP = "skip"
    local RET  = "return"
    local TAIL = "tailcall"
    local ___
    -- OPCODE.NAME   = OpcodeClass(argA, argB, argC, controlFlow)
                                                        -- PC++ assumes that the skipped instruction is a jump
    OPCODE.MOVE      = DebugOpcode(REG, REG)            -- R(A) := R(B)
    OPCODE.LOADK     = DebugOpcode(REG, CON)            -- R(A) := Kst(Bx)
    OPCODE.LOADBOOL  = DebugOpcode(REG, VAL, VAL, SKIP) -- R(A) := (Bool)B; if (C) PC++
    OPCODE.LOADNIL   = DebugOpcode(REG, REG)            -- R(A) := ... := R(B) := nil
    OPCODE.GETUPVAL  = DebugOpcode(REG, UPV)            -- R(A) := UpValue[B]
    OPCODE.GETGLOBAL = DebugOpcode(REG, GLO)            -- R(A) := Gbl[Kst(Bx)]
    OPCODE.GETTABLE  = DebugOpcode(REG, REG, RK)        -- R(A) := R(B)[RK(C)]
    OPCODE.SETGLOBAL = DebugOpcode(REG, GLO)            -- Gbl[Kst(Bx)] := R(A)
    OPCODE.SETUPVAL  = DebugOpcode(REG, UPV)            -- UpValue[B] := R(A)
    OPCODE.SETTABLE  = DebugOpcode(REG, RK,  RK)        -- R(A)[RK(B)] := RK(C)
    OPCODE.NEWTABLE  = DebugOpcode(REG, VAL, VAL)       -- R(A) := {} (arrsize = B, hashsize = C)
    OPCODE.SELF      = DebugOpcode(REG, REG, RK)        -- R(A+1) := R(B); R(A) := R(B)[RK(C)]
    OPCODE.ADD       = DebugOpcode(REG, RK,  RK)        -- R(A) := RK(B) + RK(C)
    OPCODE.SUB       = DebugOpcode(REG, RK,  RK)        -- R(A) := RK(B) - RK(C)
    OPCODE.MUL       = DebugOpcode(REG, RK,  RK)        -- R(A) := RK(B) * RK(C)
    OPCODE.DIV       = DebugOpcode(REG, RK,  RK)        -- R(A) := RK(B) / RK(C)
    OPCODE.POW       = DebugOpcode(REG, RK,  RK)        -- R(A) := RK(B) ^ RK(C)
    OPCODE.UNM       = DebugOpcode(REG, REG)            -- R(A) := -R(B)
    OPCODE.NOT       = DebugOpcode(REG, REG)            -- R(A) := not R(B)
    OPCODE.CONCAT    = DebugOpcode(REG, REG, REG)       -- R(A) := R(B)... R(B+1) ... R(C-1) ...R(C)
    OPCODE.JMP       = DebugOpcode(___, OFF, ___, JUMP) -- PC += sBx
    OPCODE.EQ = DebugVarNameOpcode(VAL, RK,  RK,  SKIP) -- if ((RK(B) == RK(C)) ~= A) then PC++
    OPCODE.LT = DebugVarNameOpcode(VAL, RK,  RK,  SKIP) -- if ((RK(B) <  RK(C)) ~= A) then PC++
    OPCODE.LE = DebugVarNameOpcode(VAL, RK,  RK,  SKIP) -- if ((RK(B) <= RK(C)) ~= A) then PC++
    OPCODE.TEST=DebugVarNameOpcode(REG, REG, VAL, SKIP) -- if ((Bool)R(B) == C) then R(A) := R(B) else PC++   C specifies what conditions the test should accept
    OPCODE.CALL      = DebugOpcode(REG, VAL, VAL, CALL) -- R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))   if (B == 0) then B = top. C is the number of returns - 1, and can be 0: CALL then sets `top' to last_result+1, so next open instruction (CALL, RETURN, SETLIST) may use `top'.
    OPCODE.TAILCALL  = DebugOpcode(REG, VAL, VAL, TAIL) -- return R(A)(R(A+1), ... ,R(A+B-1))
    OPCODE.RETURN    = DebugOpcode(REG, VAL, ___, RET)  -- return R(A), ... ,R(A+B-2)    if (B == 0) then return up to `top'
    OPCODE.FORLOOP   = DebugOpcode(REG, OFF)            -- R(A)+=R(A+2); if R(A) <?= R(A+1) then PC+= sBx
    OPCODE.TFORLOOP  = DebugOpcode(REG, ___, VAL, SKIP) -- R(A+2), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2)); if R(A+2) ~= nil then pc++
    OPCODE.TFORPREP  = DebugOpcode(REG, OFF, ___, SKIP) -- if type(R(A)) == table then R(A+1) := R(A), R(A) := next; finally, PC += sBx
    OPCODE.SETLIST   = DebugOpcode(REG, DBL)            -- R(A)[Bx-Bx%FPF+i] := R(A+i), 1 <= i <= Bx%FPF
    OPCODE.SETLISTO  = DebugOpcode(REG, OFF)            --
    OPCODE.CLOSE     = DebugOpcode(REG)                 -- close all variables in the stack up to (>=) R(A)
    OPCODE.CLOSURE   = DebugOpcode(REG, PRO)            -- R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))

    -- this opcode is mangled to shove two numbers into one argument asymmetrically in Lua 5.0; override its
    -- representation to get both to appear nicely
    function OPCODE.SETLIST:InstructionArgToString(arg)
        if arg == 1 or arg == "A" then
            return "R" .. self.A
        elseif arg == 2 or arg == "B" then
            local Bx = self.B
            local len = math.mod(Bx, FIELDS_PER_FLUSH) + 1
            local start = Bx - len + 2
            return start .. "," .. len
        end
    end
    -- we could have included the redundant opcode name information in the constructor, but...
    --          ...it looks better to omit it above
    for name, opcode in OPCODE do
        opcode.name = name
    end
    -- it's easier to see the comparation mode argument as part of the name; merge them
    -- (the logic is already setup--this is why these use different opcode classes)
    OPCODE.TEST.notName = "NTEST"
    OPCODE.TEST.argName = "C"
    OPCODE.LT.notName = "GE"
    OPCODE.LT.argName = "A"
    OPCODE.LE.notName = "GR"
    OPCODE.LE.argName = "A"
    OPCODE.EQ.notName = "NEQ"
    OPCODE.EQ.argName = "A"
end


---@class DebugInstruction
---@field A number
---@field B? number
---@field C? number
---@field opcode DebugOpcode
---@field address number
DebugInstruction = Class() {
    GetName = function(self)
        return self.opcode:InstructionName(self)
    end;
    ArgToString = function(self, arg, fn)
        return self.opcode:InstructionArgToString(self, arg, fn)
    end;

    ResolveAbsoluteAddress = function(self, relAddr)
        return self.address + relAddr + 1 -- add one because the PC automatically increments
    end;

    AddressToString = function(self, address)
        address = address or self.address
        if address == 0 then
            -- the formatter just returns "00000" for 0
            return addressZero
        else
            return addressPattern:format(address)
        end
    end;

    OperationToString = function(self, fn)
        local str = self:GetName()
        for i = 1, self.opcode.args do
            local arg = self:ArgToString(i, fn)
            if arg then
                str = str .. " " .. arg
            end
        end
        return str
    end;

    InstructionToString = function(self, fn)
        return self:AddressToString() .. "  " .. self:OperationToString(fn)
    end;
}

---@class DebugLine : DebugInstruction[]
---@field lineNumber number
---@field instructionCount number
DebugLine = Class() {
    GetSize = function(self)
        -- all instructions are aligned to a 32 bit int, so no need to add up all instruction sizes
        -- actually, I'm not even sure what we'd use the instruction size for
        return self.instructionCount * 4
    end;
}

---@class DebugFunction
---@field bytecode         string[]
---@field currentline?     number
---@field from             number | function
---@field func             function
---@field lineCount        number
---@field linedefined      number
---@field lines            DebugLine[]
---@field instructionCount number
---@field instructions     DebugInstruction[]
---@field location         string
---@field maxstack         number
---@field namewhat         string
---@field nups             number
---@field short_loc        string
---@field source           ProfilerSource
---@field upvalues         string[]
---@field variableCount?   number
---@field variables?       string[]
DebugFunction = Class() {
    __init = function(self, f, debuginfo)
        local StringGMatch = string.gmatch
        self.from = f

        local info = debug.getinfo(f, debuginfo)

        self.source, self.scope, self.name = CollapseDebugInfo(info)
        self.nups = info.nups
        self.short_loc = info.short_src
        self.location = info.source

        local currentline = info.currentline
        if currentline and currentline ~= -1 then
            self.currentline = currentline
        end

        local upvalues = {}
        for i = 1, self.nups do
            -- also returns the current value, but we don't care about that right now
            upvalues[i] = (debug.getupvalue(f, i))
        end
        self.upvalues = upvalues

        self.constants = debug.listk(f)
        self.constantCount = table.getn(self.constants)

        local bytecode = debug.listcode(f)
        local onlyBytecode = {}
        self.bytecode = onlyBytecode

        local lines = {}
        self.lines = lines

        local instructions = {}
        self.instructions = instructions

        local lineCount = 0
        local debugLine
        local instructionCount = 0
        local totalInstrCount = 0
        local lastLine = nil
        for _, line in bytecode do
            if type(line) == "number" then
                continue
            end
            -- each line is in a format like `(<lineNumber>) <instrNumber> - <OPCODE> <A> [<B> [<C>]]`
            -- e.g. `( 35)  58 - JUMP 0 -4`
            local chunker = StringGMatch(line, "-?[%w]+")
            local lineNum, pos = chunker(), chunker()
            local opcode, argA, argB = chunker(), tonumber(chunker()), chunker()

            local instr = DebugInstruction()
            instr.A = argA
            instr.opcode = OPCODE[opcode]
            instr.address = tonumber(pos)
            if argB then
                instr.B = tonumber(argB)
                local argC = chunker()
                if argC then
                    instr.C = tonumber(argC)
                end
            end

            -- instruction starts a different line
            if lastLine ~= lineNum then
                if debugLine ~= nil then
                    debugLine.instructionCount = instructionCount
                end
                debugLine = DebugLine()
                debugLine.lineNumber = lineNum
                lineCount = lineCount + 1
                lines[lineCount] = debugLine
                instructionCount = 0
                lastLine = lineNum
            end
            instructionCount = instructionCount + 1
            debugLine[instructionCount] = instr
            totalInstrCount = totalInstrCount + 1
            instructions[totalInstrCount] = instr
            onlyBytecode[totalInstrCount] = line
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

        -- only works/is useful while inside a function call
        if type(f) == "number" then
            local parameters = {}
            local parameterCount = self.numparams
            for i = 1, parameterCount do
                parameters[i] = debug.listlocals(f, i)
            end
            self.parameters = parameters

            local variables = {}
            local variableCount = 0
            local var = debug.listlocals(f, parameterCount)
            while var ~= parameters[1] do
                variableCount = variableCount + 1
                variables[variableCount] = var
                var = debug.listlocals(f, variableCount + parameterCount)
            end
            self.variables = variables
            self.variableCount = variableCount
        else
            -- though we can still get the first parameter for some reason
            self.parameters = {debug.listlocals(f, 1)}
        end
        -- let them call the debug function directly, I guess?
        setmetatable(self, {
            __index = DebugFunction,
            __call = self.func
        })
    end;

    GetSize = function(self)
        return self.instructionCount * 4
    end;

    GetConstant = function(self, k)
        return self.constants[k]
    end;

    GetGlobal = function(self, k)
        local key = self:GetConstant(k)
        return _G[key]
    end;

    GetLocalName = function(self, k)
        if self.variables then
            return self.variables[k]
        end
    end;

    GetUpvalueName = function(self, k)
        return self.upvalues[k]
    end;

    GetUpvalue = function(self, k)
        local _, val = debug.getupvalue(self.from, k)
        return val
    end;

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
    end;

    PrettyPrint = function(self)
        local lines = {}
        local lineLocalizer = LOC("<LOC profiler_0001>Line %d:")
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
                str = instr:AddressToString() .. "  " .. str

                local controlFlow = instr.opcode.controlFlow
                if prepend then
                    str = prepend .. str
                    prepend = nil
                else
                    str = "    " .. str
                end
                if controlFlow == "skip" then
                    prepend = "        "
                end
                lineCount = lineCount + 1
                lines[lineCount] = str
            end
        end
        return lines
    end;
}
