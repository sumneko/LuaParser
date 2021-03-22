local parser = require 'parser'
local fs = require 'bee.filesystem'
local utility = require 'utility'

EXISTS = {}

local function eq(a, b)
    local tp1, tp2 = type(a), type(b)
    if tp1 ~= tp2 then
        return false
    end
    if a == '<LOOP>' and tp1 == 'table' then
        return true
    end
    if b == '<LOOP>' and tp2 == 'table' then
        return true
    end
    if tp1 == 'table' then
        local checked = {}
        for k in pairs(a) do
            if not eq(a[k], b[k]) then
                return false
            end
            checked[k] = true
        end
        for k in pairs(b) do
            if not checked[k] then
                return false
            end
        end
        return true
    end
    if tp1 == 'number' then
        return ('%q'):format(a) == ('%q'):format(b)
    end
    return a == b
end

local sortList = {
    'specials',
    'type', 'start', 'bstart', 'vstart', 'finish', 'effect', 'range',
    'tag', 'special', 'keyword',
    'parent', 'extParent', 'child',
    'filter',
    'node',
    'op', 'args',
    'loc', 'max', 'step', 'keys', 'exps', 'call', 'func',
    'dot', 'colon',
    'vararg',
    'field', 'index', 'method',
    'exp', 'value', 'vref',
    'attrs',
    'locals', 'ref', 'returns', 'breaks',
}
for i, v in ipairs(sortList) do
    sortList[v] = i
end
local ignoreList = {
    'specials', 'locals', 'ref', 'node', 'parent', 'extParent', 'returns', 'state',
}

local option = {
    alignment = true,
    sorter = function (keys, keymap)
        table.sort(keys, function (a, b)
            local tp1 = type(a)
            local tp2 = type(b)
            if tp1 == 'number' and tp2 ~= 'number' then
                return false
            end
            if tp1 ~= 'number' and tp2 == 'number' then
                return true
            end
            if tp1 == 'number' and tp2 == 'number' then
                return a < b
            end
            local s1 = sortList[a]
            local s2 = sortList[b]
            if s1 and not s2 then
                return false
            end
            if s2 and not s1 then
                return true
            end
            if s1 and s2 then
                return s1 < s2
            end
            return a < b
        end)
    end,
    loop = ('%q'):format('<LOOP>'),
    number = function (n)
        return ('%q'):format(n)
    end,
    format = {},
}

for _, key in ipairs(ignoreList) do
    option.format[key] = function ()
        return '"<IGNORE>"'
    end
end

OPTION = option

local function autoFix(myBuf, targetBuf)
    local info = debug.getinfo(3, 'Sl')
    local filename = info.source:sub(2)
    local fileBuf = utility.loadFile(filename)
    local pos = fileBuf:find(targetBuf, 1, true)
    local newFileBuf = fileBuf:sub(1, pos-1) .. myBuf .. fileBuf:sub(pos + #targetBuf)
    utility.saveFile(filename, newFileBuf)
    return
end

local function test(type)
    CHECK = function (buf)
        return function (target_ast)
            local state, err = parser:compile(buf, type, 'Lua 5.4')
            if not state then
                error(('语法树生成失败：%s'):format(err))
            end
            state.ast.state = nil
            local result = utility.dump(state.ast, option)
            local expect = utility.dump(target_ast, option)
            if result ~= expect then
                fs.create_directory(ROOT / 'test' / 'log')
                utility.saveFile((ROOT / 'test' / 'log' / 'my_ast.ast'):string(), result)
                utility.saveFile((ROOT / 'test' / 'log' / 'target_ast.ast'):string(), expect)
                autoFix(result, expect)
                error(('语法树不相等：%s\n%s'):format(type, buf))
            end
        end
    end
    LuaDoc = function (buf)
        return function (target_doc)
            local state, err = parser:compile(buf, 'type', 'Lua 5.4')
            if not state then
                error(('语法树生成失败：%s'):format(err))
            end
            parser:luadoc(state)
            for _, doc in ipairs(state.ast.docs) do
                doc.bindGroup = nil
                doc.bindSources = nil
            end
            state.ast.docs.groups = nil
            local result = utility.dump(state.ast.docs, option)
            local expect = utility.dump(target_doc, option)
            if result ~= expect then
                fs.create_directory(ROOT / 'test' / 'log')
                utility.saveFile((ROOT / 'test' / 'log' / 'my_doc.ast'):string(), result)
                utility.saveFile((ROOT / 'test' / 'log' / 'target_doc.ast'):string(), expect)
                --autoFix(state.ast.luadocs, target_doc)
                error(('语法树不相等：%s\n%s'):format(type, buf))
            end
        end
    end
    require('ast.' .. type)
end

test 'Nil'
test 'Boolean'
test 'String'
test 'Number'
test 'Exp'
test 'Action'
test 'Lua'
test 'Dirty'
--test 'LuaDoc'
