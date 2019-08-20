local emmy = require 'parser.emmy'

local tonumber   = tonumber
local stringChar = string.char
local utf8Char   = utf8.char
local type       = type
local ipairs     = ipairs

local State
local pushError
local pushAst
local getAst

-- goto 单独处理
local RESERVED = {
    ['and']      = true,
    ['break']    = true,
    ['do']       = true,
    ['else']     = true,
    ['elseif']   = true,
    ['end']      = true,
    ['false']    = true,
    ['for']      = true,
    ['function'] = true,
    ['if']       = true,
    ['in']       = true,
    ['local']    = true,
    ['nil']      = true,
    ['not']      = true,
    ['or']       = true,
    ['repeat']   = true,
    ['return']   = true,
    ['then']     = true,
    ['true']     = true,
    ['until']    = true,
    ['while']    = true,
}

local VersionOp = {
    ['&']  = {'Lua 5.3', 'Lua 5.4'},
    ['~']  = {'Lua 5.3', 'Lua 5.4'},
    ['|']  = {'Lua 5.3', 'Lua 5.4'},
    ['<<'] = {'Lua 5.3', 'Lua 5.4'},
    ['>>'] = {'Lua 5.3', 'Lua 5.4'},
    ['//'] = {'Lua 5.3', 'Lua 5.4'},
}

local function checkOpVersion(op)
    local opAst = getAst(op)
    local versions = VersionOp[opAst.type]
    if not versions then
        return
    end
    for i = 1, #versions do
        if versions[i] == State.Version then
            return
        end
    end
    pushError {
        type    = 'UNSUPPORT_SYMBOL',
        start   = opAst.start,
        finish  = opAst.finish,
        version = versions,
        info    = {
            version = State.Version,
        }
    }
end

local Exp

local function expSplit(list, start, finish, level)
    if start == finish then
        return list[start]
    end
    local info = Exp[level]
    if not info then
        return
    end
    local func = info[1]
    return func(list, start, finish, level)
end

local function binaryForward(list, start, finish, level)
    local info = Exp[level]
    for i = finish-1, start+1, -1 do
        local op = list[i]
        local opType = getAst(op).type
        if info[opType] then
            local e1 = expSplit(list, start, i-1, level)
            if not e1 then
                goto CONTINUE
            end
            local e2 = expSplit(list, i+1, finish, level+1)
            if not e2 then
                goto CONTINUE
            end
            checkOpVersion(op)
            return pushAst {
                type   = 'binary',
                op     = op,
                start  = getAst(e1).start,
                finish = getAst(e2).finish,
                [1]    = e1,
                [2]    = e2,
            }
        end
        ::CONTINUE::
    end
    return expSplit(list, start, finish, level+1)
end

local function binaryBackward(list, start, finish, level)
    local info = Exp[level]
    for i = start+1, finish-1 do
        local op = list[i]
        local opType = getAst(op).type
        if info[opType] then
            local e1 = expSplit(list, start, i-1, level+1)
            if not e1 then
                goto CONTINUE
            end
            local e2 = expSplit(list, i+1, finish, level)
            if not e2 then
                goto CONTINUE
            end
            checkOpVersion(op)
            return pushAst {
                type   = 'binary',
                op     = op,
                start  = getAst(e1).start,
                finish = getAst(e2).finish,
                [1]    = e1,
                [2]    = e2,
            }
        end
        ::CONTINUE::
    end
    return expSplit(list, start, finish, level+1)
end

local function unary(list, start, finish, level)
    local info = Exp[level]
    local op = list[start]
    local opType = getAst(op).type
    if info[opType] then
        local e1 = expSplit(list, start+1, finish, level)
        if e1 then
            checkOpVersion(op)
            return pushAst {
                type   = 'unary',
                op     = op,
                start  = getAst(op).start,
                finish = getAst(e1).finish,
                [1]    = e1,
            }
        end
    end
    return expSplit(list, start, finish, level+1)
end

local function checkMissEnd(start)
    if not State.MissEndErr then
        return
    end
    local err = State.MissEndErr
    State.MissEndErr = nil
    local _, finish = State.Lua:find('[%w_]+', start)
    if not finish then
        return
    end
    err.info.related = { start, finish }
    pushError {
        type   = 'MISS_END',
        start  = start,
        finish = finish,
    }
end

Exp = {
    {
        ['or'] = true,
        binaryForward,
    },
    {
        ['and'] = true,
        binaryForward,
    },
    {
        ['<='] = true,
        ['>='] = true,
        ['<']  = true,
        ['>']  = true,
        ['~='] = true,
        ['=='] = true,
        binaryForward,
    },
    {
        ['|'] = true,
        binaryForward,
    },
    {
        ['~'] = true,
        binaryForward,
    },
    {
        ['&'] = true,
        binaryForward,
    },
    {
        ['<<'] = true,
        ['>>'] = true,
        binaryForward,
    },
    {
        ['..'] = true,
        binaryBackward,
    },
    {
        ['+'] = true,
        ['-'] = true,
        binaryForward,
    },
    {
        ['*']  = true,
        ['//'] = true,
        ['/']  = true,
        ['%']  = true,
        binaryForward,
    },
    {
        ['^'] = true,
        binaryBackward,
    },
    {
        ['not'] = true,
        ['#']   = true,
        ['~']   = true,
        ['-']   = true,
        unary,
    },
}

local Defs = {
    Nil = function (pos)
        return pushAst {
            type   = 'nil',
            start  = pos,
            finish = pos + 2,
        }
    end,
    True = function (pos)
        return pushAst {
            type   = 'boolean',
            start  = pos,
            finish = pos + 3,
            [1]    = true,
        }
    end,
    False = function (pos)
        return pushAst {
            type   = 'boolean',
            start  = pos,
            finish = pos + 4,
            [1]    = false,
        }
    end,
    LongComment = function (beforeEq, afterEq, str, missPos)
        if missPos then
            local endSymbol = ']' .. ('='):rep(afterEq-beforeEq) .. ']'
            local s, _, w = str:find('(%][%=]*%])[%c%s]*$')
            if s then
                pushError {
                    type   = 'ERR_LCOMMENT_END',
                    start  = missPos - #str + s - 1,
                    finish = missPos - #str + s + #w - 2,
                    info   = {
                        symbol = endSymbol,
                    },
                    fix    = {
                        title = 'FIX_LCOMMENT_END',
                        {
                            start  = missPos - #str + s - 1,
                            finish = missPos - #str + s + #w - 2,
                            text   = endSymbol,
                        }
                    },
                }
            end
            pushError {
                type   = 'MISS_SYMBOL',
                start  = missPos,
                finish = missPos,
                info   = {
                    symbol = endSymbol,
                },
                fix    = {
                    title = 'ADD_LCOMMENT_END',
                    {
                        start  = missPos,
                        finish = missPos,
                        text   = endSymbol,
                    }
                },
            }
        end
    end,
    CLongComment = function (start1, finish1, start2, finish2)
        pushError {
            type   = 'ERR_C_LONG_COMMENT',
            start  = start1,
            finish = finish2 - 1,
            fix    = {
                title = 'FIX_C_LONG_COMMENT',
                {
                    start  = start1,
                    finish = finish1 - 1,
                    text   = '--[[',
                },
                {
                    start  = start2,
                    finish = finish2 - 1,
                    text   =  '--]]'
                },
            }
        }
    end,
    CCommentPrefix = function (start, finish)
        pushError {
            type   = 'ERR_COMMENT_PREFIX',
            start  = start,
            finish = finish - 1,
            fix    = {
                title = 'FIX_COMMENT_PREFIX',
                {
                    start  = start,
                    finish = finish - 1,
                    text   = '--',
                },
            }
        }
        return false
    end,
    String = function (start, quote, str, finish)
        return pushAst {
            type   = 'string',
            start  = start,
            finish = finish - 1,
            [1]    = str,
            [2]    = quote,
        }
    end,
    LongString = function (beforeEq, afterEq, str, missPos)
        if missPos then
            local endSymbol = ']' .. ('='):rep(afterEq-beforeEq) .. ']'
            local s, _, w = str:find('(%][%=]*%])[%c%s]*$')
            if s then
                pushError {
                    type   = 'ERR_LSTRING_END',
                    start  = missPos - #str + s - 1,
                    finish = missPos - #str + s + #w - 2,
                    info   = {
                        symbol = endSymbol,
                    },
                    fix    = {
                        title = 'FIX_LSTRING_END',
                        {
                            start  = missPos - #str + s - 1,
                            finish = missPos - #str + s + #w - 2,
                            text   = endSymbol,
                        }
                    },
                }
            end
            pushError {
                type   = 'MISS_SYMBOL',
                start  = missPos,
                finish = missPos,
                info   = {
                    symbol = endSymbol,
                },
                fix    = {
                    title = 'ADD_LSTRING_END',
                    {
                        start  = missPos,
                        finish = missPos,
                        text   = endSymbol,
                    }
                },
            }
        end
        return '[' .. ('='):rep(afterEq-beforeEq) .. '[', str
    end,
    Char10 = function (char)
        char = tonumber(char)
        if not char or char < 0 or char > 255 then
            return ''
        end
        return stringChar(char)
    end,
    Char16 = function (pos, char)
        if State.Version == 'Lua 5.1' then
            pushError {
                type = 'ERR_ESC',
                start = pos-1,
                finish = pos,
            }
            return char
        end
        return stringChar(tonumber(char, 16))
    end,
    CharUtf8 = function (pos, char)
        if  State.Version ~= 'Lua 5.3'
        and State.Version ~= 'Lua 5.4'
        and State.Version ~= 'LuaJIT'
        then
            pushError {
                type = 'ERR_ESC',
                start = pos-3,
                finish = pos-2,
            }
            return char
        end
        if #char == 0 then
            pushError {
                type = 'UTF8_SMALL',
                start = pos-3,
                finish = pos,
            }
            return ''
        end
        local v = tonumber(char, 16)
        if not v then
            for i = 1, #char do
                if not tonumber(char:sub(i, i), 16) then
                    pushError {
                        type = 'MUST_X16',
                        start = pos + i - 1,
                        finish = pos + i - 1,
                    }
                end
            end
            return ''
        end
        if State.Version == 'Lua 5.4' then
            if v < 0 or v > 0x7FFFFFFF then
                pushError {
                    type = 'UTF8_MAX',
                    start = pos-3,
                    finish = pos+#char,
                    info = {
                        min = '00000000',
                        max = '7FFFFFFF',
                    }
                }
            end
        else
            if v < 0 or v > 0x10FFFF then
                pushError {
                    type = 'UTF8_MAX',
                    start = pos-3,
                    finish = pos+#char,
                    version = v <= 0x7FFFFFFF and 'Lua 5.4' or nil,
                    info = {
                        min = '000000',
                        max = '10FFFF',
                    }
                }
            end
        end
        if v >= 0 and v <= 0x10FFFF then
            return utf8Char(v)
        end
        return ''
    end,
    Number = function (start, number, finish)
        local n = tonumber(number)
        if n then
            State.LastNumber = pushAst {
                type   = 'number',
                start  = start,
                finish = finish - 1,
                [1]    = n,
            }
            return State.LastNumber
        else
            pushError {
                type   = 'MALFORMED_NUMBER',
                start  = start,
                finish = finish - 1,
            }
            State.LastNumber = pushAst {
                type   = 'number',
                start  = start,
                finish = finish - 1,
                [1]    = 0,
            }
            return State.LastNumber
        end
    end,
    FFINumber = function (start, symbol)
        if math.type(State.LastNumber[1]) == 'float' then
            pushError {
                type = 'UNKNOWN_SYMBOL',
                start = start,
                finish = start + #symbol - 1,
                info = {
                    symbol = symbol,
                }
            }
            State.LastNumber[1] = 0
            return
        end
        if State.Version ~= 'LuaJIT' then
            pushError {
                type = 'UNSUPPORT_SYMBOL',
                start = start,
                finish = start + #symbol - 1,
                version = 'LuaJIT',
                info = {
                    version = State.Version,
                }
            }
            State.LastNumber[1] = 0
        end
    end,
    ImaginaryNumber = function (start, symbol)
        if State.Version ~= 'LuaJIT' then
            pushError {
                type = 'UNSUPPORT_SYMBOL',
                start = start,
                finish = start + #symbol - 1,
                version = 'LuaJIT',
                info = {
                    version = State.Version,
                }
            }
        end
        State.LastNumber[1] = 0
    end,
    Name = function (start, str, finish)
        local isKeyWord
        if RESERVED[str] then
            isKeyWord = true
        elseif str == 'goto' then
            if State.Version ~= 'Lua 5.1' and State.Version ~= 'LuaJIT' then
                isKeyWord = true
            end
        end
        if isKeyWord then
            pushError {
                type = 'KEYWORD',
                start = start,
                finish = finish - 1,
            }
        end
        return pushAst {
            type   = 'name',
            start  = start,
            finish = finish - 1,
            [1]    = str,
        }
    end,
    GetField = function (dot, field)
        return pushAst {
            type   = 'getfield',
            field  = field,
            dot    = dot,
            start  = getAst(dot).start,
            finish = getAst(field).finish,
        }
    end,
    GetIndex = function (start, index, finish)
        return pushAst {
            type   = 'getindex',
            start  = start,
            finish = finish - 1,
            index  = index,
        }
    end,
    GetMethod = function (colon, method)
        return pushAst {
            type   = 'getmethod',
            method = method,
            colon  = colon,
            start  = getAst(colon).start,
            finish = getAst(method).finish,
        }
    end,
    Simple = function (units)
        local last = units[1]
        for i = 2, #units do
            local current  = getAst(units[i])
            current.parent = last
            current.start  = getAst(last).start
            last = units[i]
        end
        return last
    end,
    SimpleCall = function (simple)
        if not simple then
            return nil
        end
        if simple.type ~= 'simple' then
            pushError {
                type   = 'EXP_IN_ACTION',
                start  = simple.start,
                finish = simple.finish,
            }
            return simple
        end
        local last = simple[#simple]
        if last.type == 'call' then
            return simple
        end
        local colon = simple[#simple-1]
        if colon and colon.type == ':' then
            -- 型如 `obj:method`，将错误让给MISS_SYMBOL
            return simple
        end
        pushError {
            type   = 'EXP_IN_ACTION',
            start  = simple[1].start,
            finish = last.finish,
        }
        return simple
    end,
    BinaryOp = function (start, op)
        return pushAst {
            type   = op,
            start  = start,
            finish = start + #op - 1,
        }
    end,
    UnaryOp = function (start, op)
        return pushAst {
            type   = op,
            start  = start,
            finish = start + #op - 1,
        }
    end,
    Exp = function (first, ...)
        if not ... then
            return first
        end
        local list = {first, ...}
        return expSplit(list, 1, #list, 1)
    end,
    Prefix = function (start, exp, finish)
        return exp
    end,
    Call = function (start, args, finish)
        args.type    = 'callargs'
        args.start   = start
        args.finish  = finish - 1
        local max = #args
        local wantExp = true
        local expCount = 0
        local lastFinish = start
        for i = 1, max do
            local arg = args[i]
            local argAst = getAst(arg)
            local isExp = argAst.type ~= ','
            if wantExp and not isExp then
                pushError {
                    type   = 'MISS_EXP',
                    start  = lastFinish + 1,
                    finish = argAst.start - 1,
                }
            elseif not wantExp and isExp then
                pushError {
                    type   = 'MISS_SYMBOL',
                    start  = lastFinish + 1,
                    finish = argAst.start - 1,
                    info = {
                        symbol = ',',
                    }
                }
            end
            if isExp then
                expCount = expCount + 1
                args[expCount] = arg
                wantExp = false
            else
                wantExp = true
            end
            lastFinish = argAst.finish
        end
        for i = expCount + 1, max do
            args[i] = nil
        end
        if wantExp and max > 0 then
            pushError {
                type   = 'MISS_EXP',
                start  = lastFinish + 1,
                finish = finish - 1,
            }
        end
        return pushAst {
            type   = 'call',
            start  = start,
            finish = finish - 1,
            args   = pushAst(args),
        }
    end,
    COMMA = function (start)
        return pushAst {
            type   = ',',
            start  = start,
            finish = start,
        }
    end,
    SEMICOLON = function (start)
        return pushAst {
            type   = ';',
            start  = start,
            finish = start,
        }
    end,
    DOTS = function (start)
        return pushAst {
            type   = '...',
            start  = start,
            finish = start + 2,
        }
    end,
    DotsAsArg = function (obj)
        State.Dots[#State.Dots] = true
        return obj
    end,
    DotsAsExp = function (obj)
        if not State.Dots[#State.Dots] then
            pushError {
                type = 'UNEXPECT_DOTS',
                start = getAst(obj).start,
                finish = getAst(obj).finish,
            }
        end
        return obj
    end,
    COLON = function (start)
        return pushAst {
            type   = ':',
            start  = start,
            finish = start,
        }
    end,
    DOT = function (start)
        return pushAst {
            type   = '.',
            start  = start,
            finish = start,
        }
    end,
    Function = function (start, args, actions, finish)
        actions.type    = 'function'
        actions.start   = start
        actions.finish  = finish - 1
        actions.args    = args
        checkMissEnd(start)
        return pushAst(actions)
    end,
    NamedFunction = function (start, name, argStart, arg, argFinish, ...)
        local obj = {
            type      = 'function',
            start     = start,
            name      = name,
            arg       = arg,
            argStart  = argStart - 1,
            argFinish = argFinish,
            ...
        }
        local max = #obj
        obj.finish = obj[max] - 1
        obj[max]   = nil
        if obj.argFinish > obj.finish then
            obj.argFinish = obj.finish
        end
        checkMissEnd(start)
        return obj
    end,
    LocalFunction = function (start, name, argStart, arg, argFinish, ...)
        local obj = {
            type      = 'localfunction',
            start     = start,
            name      = name,
            arg       = arg,
            argStart  = argStart - 1,
            argFinish = argFinish,
            ...
        }
        local max = #obj
        obj.finish = obj[max] - 1
        obj[max]   = nil
        if obj.argFinish > obj.finish then
            obj.argFinish = obj.finish
        end

        if name.type ~= 'name' then
            pushError {
                type = 'UNEXPECT_LFUNC_NAME',
                start = name.start,
                finish = name.finish,
            }
        end

        checkMissEnd(start)
        return obj
    end,
    Table = function (start, tbl, finish)
        tbl.type   = 'table'
        tbl.start  = start
        tbl.finish = finish - 1
        local wantField = true
        local lastStart = start + 1
        local fieldCount = 0
        for i, field in ipairs(tbl) do
            local fieldAst = getAst(field)
            if fieldAst.type == ',' or fieldAst.type == ';' then
                if wantField then
                    pushError {
                        type = 'MISS_EXP',
                        start = lastStart,
                        finish = fieldAst.start - 1,
                    }
                end
                wantField = false
            else
                if not wantField then
                    pushError {
                        type = 'MISS_SEP_IN_TABLE',
                        start = lastStart,
                        finish = fieldAst.start - 1,
                    }
                end
                wantField = true
                fieldCount = fieldCount + 1
                tbl[fieldCount] = field
            end
        end
        for i = fieldCount + 1, #tbl do
            tbl[i] = nil
        end
        return pushAst(tbl)
    end,
    NewField = function (field, value)
        return pushAst {
            type   = 'tablefield',
            start  = getAst(field).start,
            finish = getAst(value).finish,
            field  = field,
            value  = value,
        }
    end,
    Index = function (start, index, finish)
        return pushAst {
            type   = 'index',
            start  = start,
            finish = finish - 1,
            index  = index,
        }
    end,
    NewIndex = function (index, value)
        return pushAst {
            type   = 'tableindex',
            start  = getAst(index).start,
            finish = getAst(value).finish,
            index  = index,
            value  = value,
        }
    end,
    List = function (first, second, ...)
        if second then
            local list = {
                type = 'list',
                start = first.start,
                first, second, ...
            }
            local last = list[#list]
            list.finish = last.finish
            return list
        elseif type(first) == 'table' then
            return first
        else
            return nil
        end
    end,
    FuncArgs = function (start, args, finish)
        args.type   = 'funcargs'
        args.start  = start
        args.finish = finish - 1
        local lastStart = start + 1
        local wantName = true
        local argCount = 0
        for i, arg in ipairs(args) do
            local argAst = getAst(arg)
            if argAst.type == ',' then
                if wantName then
                    pushError {
                        type = 'MISS_NAME',
                        start = lastStart,
                        finish = argAst.start-1,
                    }
                end
                wantName = true
            else
                if not wantName then
                    pushError {
                        type = 'MISS_SYMBOL',
                        start = lastStart-1,
                        finish = argAst.start-1,
                        info = {
                            symbol = ',',
                        }
                    }
                end
                wantName = false
                argCount = argCount + 1
                args[argCount] = arg

                if argAst.type == '...' then
                    if i < #args then
                        local a = args[i+1]
                        local b = args[#args]
                        pushError {
                            type   = 'ARGS_AFTER_DOTS',
                            start  = getAst(a).start,
                            finish = getAst(b).finish,
                        }
                    end
                    break
                end
            end
            lastStart = argAst.finish + 1
        end
        for i = argCount + 1, #args do
            args[i] = nil
        end
        if wantName and argCount > 0 then
            pushError {
                type   = 'MISS_NAME',
                start  = lastStart,
                finish = finish - 1,
            }
        end
        return pushAst(args)
    end,
    Nothing = function ()
        return nil
    end,
    None = function()
        return
    end,
    Skip = function ()
        return false
    end,
    Set = function (keys, values)
        return {
            type = 'set',
            keys, values,
        }
    end,
    LocalTag = function (...)
        if not ... or ... == '' then
            return nil
        end
        local tags = {...}
        for i, tag in ipairs(tags) do
            if State.Version ~= 'Lua 5.4' then
                pushError {
                    type = 'UNSUPPORT_SYMBOL',
                    start = tag.start,
                    finish = tag.finish,
                    version = 'Lua 5.4',
                    info = {
                        version = State.Version,
                    }
                }
            elseif tag[1] ~= 'const' and tag[1] ~= 'close' then
                pushError {
                    type = 'UNKNOWN_TAG',
                    start = tag.start,
                    finish = tag.finish,
                    info = {
                        tag = tag[1],
                    }
                }
            elseif i > 1 then
                pushError {
                    type = 'MULTI_TAG',
                    start = tag.start,
                    finish = tag.finish,
                    info = {
                        tag = tag[1],
                    }
                }
            end
        end
        return tags
    end,
    LocalName = function (name, tags)
        name.tags = tags
        return name
    end,
    Local = function (keys, values)
        return {
            type = 'local',
            keys, values,
        }
    end,
    DoBody = function (...)
        if ... == '' then
            return {
                type = 'do',
            }
        else
            return {
                type = 'do',
                ...
            }
        end
    end,
    Do = function (start, action, finish)
        action.start  = start
        action.finish = finish - 1
        checkMissEnd(start)
        return action
    end,
    Break = function (finish, ...)
        if State.Break > 0 then
            local breakChunk = {
                type = 'break',
            }
            if not ... then
                return breakChunk
            end
            local action = select(-1, ...)
            if not action then
                return breakChunk
            end
            if State.Version == 'Lua 5.1' or State.Version == 'LuaJIT' then
                pushError {
                    type = 'ACTION_AFTER_BREAK',
                    start = finish - #'break',
                    finish = finish - 1,
                }
            end
            return breakChunk, action
        else
            pushError {
                type = 'BREAK_OUTSIDE',
                start = finish - #'break',
                finish = finish - 1,
            }
            if not ... then
                return false
            end
            local action = select(-1, ...)
            if not action then
                return false
            end
            return action
        end
    end,
    BreakStart = function ()
        State.Break = State.Break + 1
    end,
    BreakEnd = function ()
        State.Break = State.Break - 1
    end,
    Return = function (start, exp, finish)
        if not finish then
            finish = exp
            exp = {
                type = 'return',
                start = start,
                finish = finish - 1,
            }
        else
            if exp.type == 'list' then
                exp.type = 'return'
                exp.start = start
                exp.finish = finish - 1
            else
                exp = {
                    type = 'return',
                    start = start,
                    finish = finish - 1,
                    [1] = exp,
                }
            end
        end
        return exp
    end,
    Label = function (start, name, finish)
        if State.Version == 'Lua 5.1' then
            pushError {
                type = 'UNSUPPORT_SYMBOL',
                start = start,
                finish = finish - 1,
                version = {'Lua 5.2', 'Lua 5.3', 'Lua 5.4', 'LuaJIT'},
                info = {
                    version = State.Version,
                }
            }
            return false
        end
        name.type = 'label'
        local labels = State.Label[#State.Label]
        local str = name[1]
        if labels[str] then
            --pushError {
            --    type = 'REDEFINE_LABEL',
            --    start = name.start,
            --    finish = name.finish,
            --    info = {
            --        label = str,
            --        related = {labels[str].start, labels[str].finish},
            --    }
            --}
        else
            labels[str] = name
        end
        return name
    end,
    GoTo = function (start, name, finish)
        if State.Version == 'Lua 5.1' then
            pushError {
                type = 'UNSUPPORT_SYMBOL',
                start = start,
                finish = finish - 1,
                version = {'Lua 5.2', 'Lua 5.3', 'Lua 5.4', 'LuaJIT'},
                info = {
                    version = State.Version,
                }
            }
            return false
        end
        name.type = 'goto'
        local labels = State.Label[#State.Label]
        labels[#labels+1] = name
        return name
    end,
    -- TODO 这里的检查不完整，但是完整的检查比较复杂，开销比较高
    -- 不能jump到另一个局部变量的作用域
    -- 函数会切断goto与label
    -- 不能从block外jump到block内，但是可以从block内jump到block外
    BlockStart = function ()
        State.Label[#State.Label+1] = {}
        State.Dots[#State.Dots+1] = false
    end,
    BlockEnd = function ()
        local labels = State.Label[#State.Label]
        State.Label[#State.Label] = nil
        State.Dots[#State.Dots] = nil
        for i = 1, #labels do
            local name = labels[i]
            local str = name[1]
            if not labels[str] then
                pushError {
                    type = 'NO_VISIBLE_LABEL',
                    start = name.start,
                    finish = name.finish,
                    info = {
                        label = str,
                    }
                }
            end
        end
    end,
    IfBlock = function (exp, start, ...)
        local obj = {
            filter = exp,
            start  = start,
            ...
        }
        local max = #obj
        obj.finish = obj[max]
        obj[max]   = nil
        return obj
    end,
    ElseIfBlock = function (exp, start, ...)
        local obj = {
            filter = exp,
            start  = start,
            ...
        }
        local max = #obj
        obj.finish = obj[max]
        obj[max]   = nil
        return obj
    end,
    ElseBlock = function (start, ...)
        local obj = {
            start  = start,
            ...
        }
        local max = #obj
        obj.finish = obj[max]
        obj[max]   = nil
        return obj
    end,
    If = function (start, ...)
        local obj = {
            type  = 'if',
            start = start,
            ...
        }
        local max = #obj
        obj.finish = obj[max] - 1
        obj[max]   = nil
        checkMissEnd(start)
        return obj
    end,
    Loop = function (start, arg, min, max, step, ...)
        local obj = {
            type  = 'loop',
            start = start,
            arg   = arg,
            min   = min,
            max   = max,
            step  = step,
            ...
        }
        local max = #obj
        obj.finish = obj[max] - 1
        obj[max]   = nil
        checkMissEnd(start)
        return obj
    end,
    In = function (start, arg, exp, ...)
        local obj = {
            type  = 'in',
            start = start,
            arg   = arg,
            exp   = exp,
            ...
        }
        local max = #obj
        obj.finish = obj[max] - 1
        obj[max]   = nil
        checkMissEnd(start)
        return obj
    end,
    While = function (start, filter, ...)
        local obj = {
            type   = 'while',
            start  = start,
            filter = filter,
            ...
        }
        local max = #obj
        obj.finish = obj[max] - 1
        obj[max]   = nil
        checkMissEnd(start)
        return obj
    end,
    Repeat = function (start, ...)
        local obj = {
            type  = 'repeat',
            start = start,
            ...
        }
        local max = #obj
        obj.finish = obj[max] - 1
        obj.filter = obj[max-1]
        obj[max]   = nil
        obj[max-1] = nil
        return obj
    end,
    Lua = function (...)
        if ... == '' then
            return {}
        end
        return {...}
    end,

    -- 捕获错误
    UnknownSymbol = function (start, symbol)
        pushError {
            type = 'UNKNOWN_SYMBOL',
            start = start,
            finish = start + #symbol - 1,
            info = {
                symbol = symbol,
            }
        }
        return
    end,
    UnknownAction = function (start, symbol)
        pushError {
            type = 'UNKNOWN_SYMBOL',
            start = start,
            finish = start + #symbol - 1,
            info = {
                symbol = symbol,
            }
        }
        return false
    end,
    DirtyName = function (pos)
        pushError {
            type = 'MISS_NAME',
            start = pos,
            finish = pos,
        }
        return {
            type   = 'name',
            start  = pos-1,
            finish = pos-1,
            [1]    = ''
        }
    end,
    DirtyExp = function (pos)
        pushError {
            type = 'MISS_EXP',
            start = pos,
            finish = pos,
        }
        return {
            type   = 'name',
            start  = pos,
            finish = pos,
            [1]    = ''
        }
    end,
    MissExp = function (pos)
        pushError {
            type = 'MISS_EXP',
            start = pos,
            finish = pos,
        }
    end,
    MissExponent = function (start, finish)
        pushError {
            type = 'MISS_EXPONENT',
            start = start,
            finish = finish - 1,
        }
    end,
    MissQuote1 = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = '"'
            }
        }
    end,
    MissQuote2 = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = "'"
            }
        }
    end,
    MissEscX = function (pos)
        pushError {
            type = 'MISS_ESC_X',
            start = pos-2,
            finish = pos+1,
        }
    end,
    MissTL = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = '{',
            }
        }
    end,
    MissTR = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = '}',
            }
        }
    end,
    MissBR = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = ']',
            }
        }
    end,
    MissPL = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = '(',
            }
        }
    end,
    DirtyPR = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = ')',
            }
        }
        return pos + 1
    end,
    MissPR = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = ')',
            }
        }
    end,
    ErrEsc = function (pos)
        pushError {
            type = 'ERR_ESC',
            start = pos-1,
            finish = pos,
        }
    end,
    MustX16 = function (pos, str)
        pushError {
            type = 'MUST_X16',
            start = pos,
            finish = pos + #str - 1,
        }
    end,
    MissAssign = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = '=',
            }
        }
    end,
    MissTableSep = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = ','
            }
        }
    end,
    MissField = function (pos)
        pushError {
            type = 'MISS_FIELD',
            start = pos,
            finish = pos,
        }
    end,
    MissMethod = function (pos)
        pushError {
            type = 'MISS_METHOD',
            start = pos,
            finish = pos,
        }
    end,
    MissLabel = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = '::',
            }
        }
    end,
    MissEnd = function (pos)
        State.MissEndErr = pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = 'end',
            }
        }
    end,
    MissDo = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = 'do',
            }
        }
    end,
    MissComma = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = ',',
            }
        }
    end,
    MissIn = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = 'in',
            }
        }
    end,
    MissUntil = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = 'until',
            }
        }
    end,
    MissThen = function (pos)
        pushError {
            type = 'MISS_SYMBOL',
            start = pos,
            finish = pos,
            info = {
                symbol = 'then',
            }
        }
    end,
    ExpInAction = function (start, exp, finish)
        pushError {
            type = 'EXP_IN_ACTION',
            start = start,
            finish = finish - 1,
        }
        return exp
    end,
    AfterReturn = function (rtn, ...)
        if not ... then
            return rtn
        end
        local action = select(-1, ...)
        if not action then
            return rtn
        end
        pushError {
            type = 'ACTION_AFTER_RETURN',
            start = rtn.start,
            finish = rtn.finish,
        }
        return rtn, action
    end,
    MissIf = function (start, block)
        pushError {
            type = 'MISS_SYMBOL',
            start = start,
            finish = start,
            info = {
                symbol = 'if',
            }
        }
        return block
    end,
    MissGT = function (start)
        pushError {
            type = 'MISS_SYMBOL',
            start = start,
            finish = start,
            info = {
                symbol = '>'
            }
        }
    end,
    ErrAssign = function (start, finish)
        pushError {
            type = 'ERR_ASSIGN_AS_EQ',
            start = start,
            finish = finish - 1,
            fix = {
                title = 'FIX_ASSIGN_AS_EQ',
                {
                    start   = start,
                    finish  = finish - 1,
                    text    = '=',
                }
            }
        }
    end,
    ErrEQ = function (start, finish)
        pushError {
            type   = 'ERR_EQ_AS_ASSIGN',
            start  = start,
            finish = finish - 1,
            fix = {
                title = 'FIX_EQ_AS_ASSIGN',
                {
                    start  = start,
                    finish = finish - 1,
                    text   = '==',
                }
            }
        }
        return '=='
    end,
    ErrUEQ = function (start, finish)
        pushError {
            type   = 'ERR_UEQ',
            start  = start,
            finish = finish - 1,
            fix = {
                title = 'FIX_UEQ',
                {
                    start  = start,
                    finish = finish - 1,
                    text   = '~=',
                }
            }
        }
        return '=='
    end,
    ErrThen = function (start, finish)
        pushError {
            type = 'ERR_THEN_AS_DO',
            start = start,
            finish = finish - 1,
            fix = {
                title = 'FIX_THEN_AS_DO',
                {
                    start   = start,
                    finish  = finish - 1,
                    text    = 'then',
                }
            }
        }
    end,
    ErrDo = function (start, finish)
        pushError {
            type = 'ERR_DO_AS_THEN',
            start = start,
            finish = finish - 1,
            fix = {
                title = 'FIX_DO_AS_THEN',
                {
                    start   = start,
                    finish  = finish - 1,
                    text    = 'do',
                }
            }
        }
    end,
}

for k, v in pairs(emmy.ast) do
    Defs[k] = v
end

local function init(state)
    State = state
    pushError = state.pushError
    pushAst   = state.pushAst
    getAst    = state.getAst
    emmy.init(State)
end

return {
    defs = Defs,
    init = init,
}
