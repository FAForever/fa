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

---@class RawFunctionDebugInfo
---@field bytecode Bytecode
---@field constants any[]
---@field info debuginfo
---@field parameters string[]
-- @field prototypes nil -- we don't have access to these!
---@field upvalueNames string[]
---@field upvalues any[]


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

function Representation(val)
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

---@param arg DebugOpArgKind
---@return boolean
local function ArgKindIsDouble(arg)
    return arg == "double" or arg == "global" or arg == "offset" or arg == "prototype"
end

---@type table<DebugOpArgKind, fun(intr: DebugInstruction, arg: number, fn?: DebugFunction): string>
DebugOpcodeArgFormatters = {
    ["default"] = function(instr, arg, fn)
        return tostring(arg)
    end,

    ["const"] = function(instr, arg, fn)
        if fn then
            return Representation(fn:GetConstant(arg + 1))
        end
        return "K(" .. arg .. ")"
    end,
    ["global"] = function(instr, arg, fn)
        if fn then
            return Representation(fn:GetConstant(arg + 1))
        end
        return "G(K(" .. arg .. "))"
    end,
    ["offset"] = function(instr, arg, fn)
        -- adjust address offsets to absolute addresses
        arg = instr:ResolveAbsoluteAddress(arg)
        if arg == 0 then
            -- the formatter just returns "00000" for 0
            return addressZero
        end
        return addressPattern:format(arg)
    end,
    ["prototype"] = function(instr, arg, fn)
        return "P(" .. arg .. ")"
    end,
    ["register"] = function(instr, arg, fn)
        return "R" .. arg
    end,
    ["register|const"] = function(instr, arg, fn)
        if arg < MAXSTACK then
            return "R" .. arg
        else
            arg = arg - MAXSTACK
            if fn then
                return Representation(fn:GetConstant(arg + 1))
            end
            return "K(" .. arg .. ")"
        end
    end,
    ["upvalue"] = function(instr, arg, fn)
        if fn then
            return Representation(fn:GetUpvalueName(arg + 1))
        end
        return "U(" .. arg .. ")"
    end,

    -- SETLIST is mangled to shove two numbers into one argument asymmetrically in Lua 5.0
    ["double"] = function(instr, arg, fn)
        local len = math.mod(arg, FIELDS_PER_FLUSH) + 1
        local start = arg - len + 2
        return start .. "," .. len
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
---@field args number
---@field A? function
---@field B? function
---@field C? function
---@field format DebugOpFormat
---@field controlFlow? DebugOpControlFlow
---@field name string
DebugOpcode = Class() {
    ---@param self DebugOpcode
    ---@param a DebugOpArgKind
    ---@param b? DebugOpArgKind
    ---@param c? DebugOpArgKind
    ---@param controlFlow? DebugOpControlFlow
    __init = function(self, a, b, c, controlFlow)
        self.A = DebugOpcodeArgFormatters[a]
        self.B = DebugOpcodeArgFormatters[b]
        self.C = DebugOpcodeArgFormatters[c]
        self.controlFlow = controlFlow
        if c then
            self.args = 3
            self.format = "ABC"
        elseif b then
            self.args = 2
            if ArgKindIsDouble(b) then
                if b == "offset" then
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
    end;

    ---@param self DebugOpcode
    ---@return string
    __tostring = function(self)
        return self.name
    end;

    ---@param self DebugOpcode
    ---@param instr DebugInstruction
    ---@return string
    InstructionName = function(self, instr)
        return self.name
    end;

    ---@param self DebugOpcode
    ---@param instr DebugInstruction
    ---@param arg number | string
    ---@param fn? DebugFunction optional function to resolve constants from
    ---@return string | nil
    InstructionArgToString = function(self, instr, arg, fn)
        if type(arg) == "number" then
            arg = string.char(64 + arg)
        end
        local type = self[arg]
        if not type then
            return nil
        end
        return type(instr, instr[arg], fn)
    end;
}

---@class DebugVarNameOpcode : DebugOpcode
---@field notName string
---@field argName string
DebugVarNameOpcode = Class(DebugOpcode) {
    ---@param self DebugVarNameOpcode
    ---@param instr DebugInstruction
    ---@return string
    InstructionName = function(self, instr)
        if instr[self.argName] == 0 then
            return self.name
        else
            return self.notName
        end
    end;

    ---@param self DebugVarNameOpcode
    ---@param instr DebugInstruction
    ---@param arg number | string
    ---@param fn? DebugFunction optional function to resolve constants from
    ---@return string | nil
    InstructionArgToString = function(self, instr, arg, fn)
        if type(arg) == "number" then
            arg = string.char(64 + arg)
        end
        if arg == self.argName then
            return nil
        end
        return DebugOpcode.InstructionArgToString(self, instr, arg, fn)
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
    ---@param self DebugInstruction
    ---@return string
    GetName = function(self)
        return self.opcode:InstructionName(self)
    end;
    ---@param self DebugInstruction
    ---@param arg string | number
    ---@param fn DebugFunction
    ---@return string | nil
    ArgToString = function(self, arg, fn)
        return self.opcode:InstructionArgToString(self, arg, fn)
    end;

    ---@param self DebugInstruction
    ---@param relAddr number
    ---@return number
    ResolveAbsoluteAddress = function(self, relAddr)
        return self.address + relAddr + 1 -- add one because the PC automatically increments
    end;

    ---@param self DebugInstruction
    ---@param address? number defaults to the instruction address
    ---@return string
    AddressToString = function(self, address)
        address = address or self.address
        if address == 0 then
            -- the formatter just returns "00000" for 0
            return addressZero
        else
            return addressPattern:format(address)
        end
    end;

    ---@param self DebugInstruction
    ---@param fn DebugFunction
    ---@return string
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

    ---@param self DebugInstruction
    ---@param fn DebugFunction
    ---@return string
    InstructionToString = function(self, fn)
        return self:AddressToString() .. "  " .. self:OperationToString(fn)
    end;
}

---@class DebugLine : DebugInstruction[]
---@field lineNumber number
---@field instructionCount number
DebugLine = Class() {
    ---@param self DebugLine
    ---@param lineNum number
    __init = function(self, lineNum)
        self.lineNumber = lineNum
    end;

    ---@param self DebugLine
    ---@return number
    GetSize = function(self)
        return self.instructionCount * 4 -- all instructions are aligned to a 32 bit int
    end;
}

---@class DebugFunction
---@field bytecode         string[]
---@field constants        any[]
---@field constantCount    number
---@field currentline?     number
---@field from             integer | function | RawFunctionDebugInfo
---@field func             function
---@field knownPrototypes  number
---@field lineCount        number
---@field lines            DebugLine[]
---@field instructionCount number
---@field instructions     DebugInstruction[]
---@field location         string
---@field maxstack         number
---@field nups             number
---@field short_loc        string
---@field source           ProfilerSource
---@field upvalues         string[]
---@field variableCount?   number
---@field variables?       string[]
DebugFunction = Class() {
    ---@param self DebugFunction
    ---@param f integer | function | RawFunctionDebugInfo
    __init = function(self, f)
        local info, parameters, upvalues, constants, bytecode = f.info, f.parameters, f.upvalueNames, f.constants, f.bytecode
        if info and upvalues and constants and bytecode then
            self.from = info.func
        else
            self.from = f
            f = GetDebugFunctionInfo(f)
            info, parameters, upvalues, constants, bytecode = f.info, f.parameters, f.upvalueNames, f.constants, f.bytecode
        end

        self.source, self.scope, self.name = CollapseDebugInfo(info)
        self.nups = info.nups
        self.short_loc = info.short_src
        if "@" .. info.short_src ~= info.source then
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

            -- construct instruction
            local instr = DebugInstruction()
            instr.opcode = opcode
            instr.address = addr
            instr.A = argA
            if argB then -- fill up arguments
                argB = tonumber(argB)
                instr.B = argB
                local argC = chunker()
                if argC then
                    instr.C = tonumber(argC)
                elseif opcode.B == "prototype" then
                    -- check for prototypes, since we aren't provided with that information
                    local proto = argB + 1
                    if proto > knownPrototypes then
                        knownPrototypes = proto
                    end
                end
            end

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
        self.knownPrototypes = knownPrototypes

        -- only works/is useful while inside a function call
        if type(f) == "number" then
            local variables = {}
            local variableCount = 0
            local var = debug.listlocals(fn, self.numparams)
            while var ~= parameters[1] do
                variableCount = variableCount + 1
                variables[variableCount] = var
                var = debug.listlocals(fn, variableCount + self.numparams)
            end
            self.variables = variables
            self.variableCount = variableCount
        end
        -- let them call the debug function directly, I guess?
        setmetatable(self, {
            __index = DebugFunction,
            __call = self.func
        })
    end;

    ---@param self DebugFunction
    ---@return number
    GetSize = function(self)
        return self.instructionCount * 4
    end;

    ---@param self DebugFunction
    ---@param k number
    ---@return any
    GetConstant = function(self, k)
        return self.constants[k]
    end;

    ---@param self DebugFunction
    ---@param k number
    ---@return any
    GetGlobal = function(self, k)
        local key = self:GetConstant(k)
        return _G[key]
    end;

    ---@param self DebugFunction
    ---@param k number
    ---@return string | nil
    GetLocalName = function(self, k)
        if self.variables then
            return self.variables[k]
        end
    end;

    ---@param self DebugFunction
    ---@param k number
    ---@return string
    GetUpvalueName = function(self, k)
        return self.upvalues[k]
    end;

    ---@param self DebugFunction
    ---@param k number
    ---@return any
    GetUpvalue = function(self, k)
        local _, val = debug.getupvalue(self.from, k)
        return val
    end;

    ---@param self DebugFunction
    ---@return number[][]
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

    ---@param self DebugFunction
    ---@return string[]
    PrettyPrint = function(self)
        local lines = {}
        local lineLocalizer = LOC("<LOC debug_0000>Line %d:")
        local jumps = self:ResolveJumps()
        for k,v in jumps do
            local str = "line " .. k
            for k,v in v do
                str = str .. "  " .. v
            end
            SPEW(str)
        end
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
    end;
}
