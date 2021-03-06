CHECK'a.'
{
    type   = "main",
    start  = 1,
    finish = 2,
    locals = "<IGNORE>",
    [1]    = {
        type   = "getfield",
        start  = 1,
        finish = 2,
        parent = "<IGNORE>",
        node   = "<IGNORE>",
        dot    = {
            type   = ".",
            start  = 2,
            finish = 2,
        },
    },
}

CHECK'a:'
{
    type   = "main",
    start  = 1,
    finish = 2,
    locals = "<IGNORE>",
    [1]    = {
        type   = "getmethod",
        start  = 1,
        finish = 2,
        parent = "<IGNORE>",
        node   = "<IGNORE>",
        colon  = {
            type   = ":",
            start  = 2,
            finish = 2,
        },
    },
}

CHECK [[
if true
a
]]
{
    type   = "main",
    start  = 1,
    finish = 9,
    locals = "<IGNORE>",
    [1]    = {
        type   = "if",
        start  = 1,
        finish = 9,
        parent = "<IGNORE>",
        [1]    = {
            type    = "ifblock",
            start   = 1,
            finish  = 9,
            keyword = {
                [1] = 1,
                [2] = 2,
                [3] = 8,
                [4] = 7,
            },
            parent  = "<IGNORE>",
            filter  = {
                type   = "boolean",
                start  = 4,
                finish = 7,
                parent = "<IGNORE>",
                [1]    = true,
            },
            [1]     = {
                type   = "getglobal",
                start  = 9,
                finish = 9,
                parent = "<IGNORE>",
                node   = "<IGNORE>",
                [1]    = "a",
            },
        },
    },
}

CHECK [[
if true then
a
]]
{
    type   = "main",
    start  = 1,
    finish = 14,
    locals = "<IGNORE>",
    [1]    = {
        type   = "if",
        start  = 1,
        finish = 14,
        parent = "<IGNORE>",
        [1]    = {
            type    = "ifblock",
            start   = 1,
            finish  = 14,
            keyword = {
                [1] = 1,
                [2] = 2,
                [3] = 9,
                [4] = 12,
            },
            parent  = "<IGNORE>",
            filter  = {
                type   = "boolean",
                start  = 4,
                finish = 7,
                parent = "<IGNORE>",
                [1]    = true,
            },
            [1]     = {
                type   = "getglobal",
                start  = 14,
                finish = 14,
                parent = "<IGNORE>",
                node   = "<IGNORE>",
                [1]    = "a",
            },
        },
    },
}

CHECK [[
x =
]]
{
    type   = "main",
    start  = 1,
    finish = 4,
    locals = "<IGNORE>",
    [1]    = {
        type   = "setglobal",
        start  = 1,
        finish = 1,
        parent = "<IGNORE>",
        node   = "<IGNORE>",
        [1]    = "x",
    },
}

CHECK'1 == 2'
{
    type   = "main",
    start  = 1,
    finish = 6,
    locals = "<IGNORE>",
    [1]    = {
        type   = "binary",
        start  = 1,
        finish = 6,
        parent = "<IGNORE>",
        op     = {
            type   = "==",
            start  = 3,
            finish = 4,
        },
        [1]    = {
            type   = "integer",
            start  = 1,
            finish = 1,
            parent = "<IGNORE>",
            [1]    = 1,
        },
        [2]    = {
            type   = "integer",
            start  = 6,
            finish = 6,
            parent = "<IGNORE>",
            [1]    = 2,
        },
    },
}

CHECK 'local function a'
{
    type   = "main",
    start  = 1,
    finish = 16,
    locals = "<IGNORE>",
    [1]    = {
        type   = "local",
        start  = 16,
        vstart = 7,
        finish = 16,
        effect = 16,
        range  = 16,
        parent = "<IGNORE>",
        value  = {
            type    = "function",
            start   = 7,
            finish  = 16,
            keyword = {
                [1] = 7,
                [2] = 14,
                [3] = 17,
                [4] = 16,
            },
            parent  = "<IGNORE>",
        },
        [1]    = "a",
    },
}

CHECK 'local function'
{
    type   = "main",
    start  = 1,
    finish = 14,
    locals = "<IGNORE>",
    [1]    = {
        type    = "function",
        start   = 7,
        finish  = 14,
        keyword = {
            [1] = 7,
            [2] = 14,
            [3] = 15,
            [4] = 14,
        },
        parent  = "<IGNORE>",
    },
}

CHECK 'local function a(v'
{
    type   = "main",
    start  = 1,
    finish = 18,
    locals = "<IGNORE>",
    [1]    = {
        type   = "local",
        start  = 16,
        vstart = 7,
        finish = 16,
        effect = 16,
        range  = 18,
        parent = "<IGNORE>",
        value  = {
            type    = "function",
            start   = 7,
            finish  = 18,
            keyword = {
                [1] = 7,
                [2] = 14,
                [3] = 19,
                [4] = 18,
            },
            parent  = "<IGNORE>",
            args    = {
                type   = "funcargs",
                start  = 17,
                finish = 18,
                parent = "<IGNORE>",
                [1]    = {
                    type   = "local",
                    start  = 18,
                    finish = 18,
                    effect = 18,
                    parent = "<IGNORE>",
                    [1]    = "v",
                },
            },
            locals  = "<IGNORE>",
        },
        [1]    = "a",
    },
}

CHECK 'function a'
{
    type   = "main",
    start  = 1,
    finish = 10,
    locals = "<IGNORE>",
    [1]    = {
        type   = "setglobal",
        start  = 10,
        vstart = 1,
        finish = 10,
        range  = 10,
        parent = "<IGNORE>",
        node   = "<IGNORE>",
        value  = {
            type    = "function",
            start   = 1,
            finish  = 10,
            keyword = {
                [1] = 1,
                [2] = 8,
                [3] = 11,
                [4] = 10,
            },
            parent  = "<IGNORE>",
        },
        [1]    = "a",
    },
}

CHECK 'function a:'
{
    type   = "main",
    start  = 1,
    finish = 11,
    locals = "<IGNORE>",
    [1]    = {
        type   = "setmethod",
        start  = 10,
        vstart = 1,
        finish = 11,
        range  = 11,
        parent = "<IGNORE>",
        node   = "<IGNORE>",
        colon  = {
            type   = ":",
            start  = 11,
            finish = 11,
        },
        value  = {
            type    = "function",
            start   = 1,
            finish  = 11,
            keyword = {
                [1] = 1,
                [2] = 8,
                [3] = 12,
                [4] = 11,
            },
            parent  = "<IGNORE>",
            args    = {
                type   = "funcargs",
                start  = 10,
                finish = 11,
                parent = "<IGNORE>",
                [1]    = {
                    type   = "local",
                    start  = 1,
                    finish = 1,
                    effect = 11,
                    tag    = "self",
                    parent = "<IGNORE>",
                    dummy  = true,
                    method = "<LOOP>",
                    [1]    = "self",
                },
            },
            locals  = "<IGNORE>",
        },
    },
}

CHECK 'function a:b(v'
{
    type   = "main",
    start  = 1,
    finish = 14,
    locals = "<IGNORE>",
    [1]    = {
        type   = "setmethod",
        start  = 10,
        vstart = 1,
        finish = 12,
        range  = 14,
        parent = "<IGNORE>",
        node   = "<IGNORE>",
        colon  = {
            type   = ":",
            start  = 11,
            finish = 11,
        },
        method = {
            type   = "method",
            start  = 12,
            finish = 12,
            parent = "<IGNORE>",
            [1]    = "b",
        },
        value  = {
            type    = "function",
            start   = 1,
            finish  = 14,
            keyword = {
                [1] = 1,
                [2] = 8,
                [3] = 15,
                [4] = 14,
            },
            parent  = "<IGNORE>",
            args    = {
                type   = "funcargs",
                start  = 13,
                finish = 14,
                parent = "<IGNORE>",
                [1]    = {
                    type   = "local",
                    start  = 1,
                    finish = 1,
                    effect = 12,
                    tag    = "self",
                    parent = "<IGNORE>",
                    dummy  = true,
                    method = "<LOOP>",
                    [1]    = "self",
                },
                [2]    = {
                    type   = "local",
                    start  = 14,
                    finish = 14,
                    effect = 14,
                    parent = "<IGNORE>",
                    [1]    = "v",
                },
            },
            locals  = "<IGNORE>",
        },
    },
}

CHECK 'return local a'
{
    type    = "main",
    start   = 1,
    finish  = 14,
    locals  = "<IGNORE>",
    returns = "<IGNORE>",
    [1]     = {
        type   = "return",
        start  = 1,
        finish = 12,
        parent = "<IGNORE>",
        [1]    = {
            type   = "getglobal",
            start  = 8,
            finish = 12,
            parent = "<IGNORE>",
            node   = "<IGNORE>",
            [1]    = "local",
        },
    },
    [2]     = {
        type   = "getglobal",
        start  = 14,
        finish = 14,
        parent = "<IGNORE>",
        node   = "<IGNORE>",
        [1]    = "a",
    },
}

CHECK 'end'
{
    type   = "main",
    start  = 1,
    finish = 3,
    locals = "<IGNORE>",
    [1]    = {
        type   = "getglobal",
        start  = 1,
        finish = 3,
        parent = "<IGNORE>",
        node   = "<IGNORE>",
        [1]    = "end",
    },
}

CHECK 'local x = ,'
{
    type   = "main",
    start  = 1,
    finish = 11,
    locals = "<IGNORE>",
    [1]    = {
        type   = "local",
        start  = 7,
        finish = 7,
        effect = 12,
        parent = "<IGNORE>",
        [1]    = "x",
    },
}

CHECK 'local x = (a && b)'
{
    type   = "main",
    start  = 1,
    finish = 18,
    locals = "<IGNORE>",
    [1]    = {
        type   = "local",
        start  = 7,
        finish = 7,
        effect = 19,
        range  = 18,
        parent = "<IGNORE>",
        value  = {
            type   = "paren",
            start  = 11,
            finish = 18,
            parent = "<IGNORE>",
            exp    = {
                type   = "binary",
                start  = 12,
                finish = 17,
                parent = "<IGNORE>",
                op     = {
                    type   = "and",
                    start  = 14,
                    finish = 16,
                },
                [1]    = {
                    type   = "getglobal",
                    start  = 12,
                    finish = 12,
                    parent = "<IGNORE>",
                    node   = "<IGNORE>",
                    [1]    = "a",
                },
                [2]    = {
                    type   = "getglobal",
                    start  = 17,
                    finish = 17,
                    parent = "<IGNORE>",
                    node   = "<IGNORE>",
                    [1]    = "b",
                },
            },
        },
        [1]    = "x",
    },
}

CHECK 'return 1 + + 1'
{
    type    = "main",
    start   = 1,
    finish  = 14,
    locals  = "<IGNORE>",
    returns = "<IGNORE>",
    [1]     = {
        type   = "return",
        start  = 1,
        finish = 14,
        parent = "<IGNORE>",
        [1]    = {
            type   = "binary",
            start  = 8,
            finish = 14,
            parent = "<IGNORE>",
            op     = {
                type   = "+",
                start  = 12,
                finish = 12,
            },
            [1]    = {
                type   = "integer",
                start  = 8,
                finish = 8,
                parent = "<IGNORE>",
                [1]    = 1,
            },
            [2]    = {
                type   = "integer",
                start  = 14,
                finish = 14,
                parent = "<IGNORE>",
                [1]    = 1,
            },
        },
    },
}

CHECK 'return 1 + # + 2'
{
    type    = "main",
    start   = 1,
    finish  = 16,
    locals  = "<IGNORE>",
    returns = "<IGNORE>",
    [1]     = {
        type   = "return",
        start  = 1,
        finish = 16,
        parent = "<IGNORE>",
        [1]    = {
            type   = "binary",
            start  = 8,
            finish = 16,
            parent = "<IGNORE>",
            op     = {
                type   = "+",
                start  = 14,
                finish = 14,
            },
            [1]    = {
                type   = "integer",
                start  = 8,
                finish = 8,
                parent = "<IGNORE>",
                [1]    = 1,
            },
            [2]    = {
                type   = "integer",
                start  = 16,
                finish = 16,
                parent = "<IGNORE>",
                [1]    = 2,
            },
        },
    },
}

CHECK 'return 1 + 2 + # + 3'
{
    type    = "main",
    start   = 1,
    finish  = 20,
    locals  = "<IGNORE>",
    returns = "<IGNORE>",
    [1]     = {
        type   = "return",
        start  = 1,
        finish = 20,
        parent = "<IGNORE>",
        [1]    = {
            type   = "binary",
            start  = 8,
            finish = 20,
            parent = "<IGNORE>",
            op     = {
                type   = "+",
                start  = 18,
                finish = 18,
            },
            [1]    = {
                type   = "binary",
                start  = 8,
                finish = 12,
                parent = "<IGNORE>",
                op     = {
                    type   = "+",
                    start  = 10,
                    finish = 10,
                },
                [1]    = {
                    type   = "integer",
                    start  = 8,
                    finish = 8,
                    parent = "<IGNORE>",
                    [1]    = 1,
                },
                [2]    = {
                    type   = "integer",
                    start  = 12,
                    finish = 12,
                    parent = "<IGNORE>",
                    [1]    = 2,
                },
            },
            [2]    = {
                type   = "integer",
                start  = 20,
                finish = 20,
                parent = "<IGNORE>",
                [1]    = 3,
            },
        },
    },
}

CHECK [[
-
return
]]
{
    type   = "main",
    start  = 1,
    finish = 8,
    locals = "<IGNORE>",
    [1]    = {
        type   = "unary",
        start  = 1,
        finish = 8,
        parent = "<IGNORE>",
        op     = {
            type   = "-",
            start  = 1,
            finish = 1,
        },
        [1]    = {
            type   = "getglobal",
            start  = 3,
            finish = 8,
            parent = "<IGNORE>",
            node   = "<IGNORE>",
            [1]    = "return",
        },
    },
}

CHECK [[
return;
::::
return;
]]
{
    type    = "main",
    start   = 1,
    finish  = 20,
    locals  = "<IGNORE>",
    returns = "<IGNORE>",
    [1]     = {
        type   = "return",
        start  = 1,
        finish = 6,
        parent = "<IGNORE>",
    },
    [2]     = {
        type   = "return",
        start  = 14,
        finish = 19,
        parent = "<IGNORE>",
    },
}

CHECK [[
return;
goto;
return;
]]
{
    type    = "main",
    start   = 1,
    finish  = 21,
    locals  = "<IGNORE>",
    returns = "<IGNORE>",
    [1]     = {
        type   = "return",
        start  = 1,
        finish = 6,
        parent = "<IGNORE>",
    },
    [2]     = {
        type   = "return",
        start  = 15,
        finish = 20,
        parent = "<IGNORE>",
    },
}

CHECK [[
call(,-,not,1)
]]
{
    type   = "main",
    start  = 1,
    finish = 14,
    locals = "<IGNORE>",
    [1]    = {
        type   = "call",
        start  = 1,
        finish = 14,
        parent = "<IGNORE>",
        node   = "<IGNORE>",
        args   = {
            type   = "callargs",
            start  = 5,
            finish = 14,
            parent = "<IGNORE>",
            [1]    = {
                type   = "integer",
                start  = 13,
                finish = 13,
                parent = "<IGNORE>",
                [1]    = 1,
            },
        },
    },
}

CHECK [[
{
    ;,-;,1
}
]]
{
    type   = "main",
    start  = 1,
    finish = 14,
    locals = "<IGNORE>",
    [1]    = {
        type   = "table",
        start  = 1,
        finish = 14,
        parent = "<IGNORE>",
        [1]    = {
            type   = "tableexp",
            start  = 12,
            finish = 12,
            tindex = 1,
            parent = "<IGNORE>",
            value  = {
                type   = "integer",
                start  = 12,
                finish = 12,
                parent = "<IGNORE>",
                [1]    = 1,
            },
        },
    },
}

CHECK [[
local a,b,,d
]]
{
    type   = "main",
    start  = 1,
    finish = 12,
    locals = "<IGNORE>",
    [1]    = {
        type   = "local",
        start  = 7,
        finish = 7,
        effect = 13,
        parent = "<IGNORE>",
        [1]    = "a",
    },
    [2]    = {
        type   = "local",
        start  = 9,
        finish = 9,
        effect = 13,
        parent = "<IGNORE>",
        [1]    = "b",
    },
    [3]    = {
        type   = "local",
        start  = 12,
        finish = 12,
        effect = 13,
        parent = "<IGNORE>",
        [1]    = "d",
    },
}

CHECK [[
if /**/ then
end
]]
{
    type   = "main",
    start  = 1,
    finish = 16,
    locals = "<IGNORE>",
    [1]    = {
        type   = "if",
        start  = 1,
        finish = 16,
        parent = "<IGNORE>",
        [1]    = {
            type    = "ifblock",
            start   = 1,
            finish  = 12,
            keyword = {
                [1] = 1,
                [2] = 2,
                [3] = 9,
                [4] = 12,
            },
            parent  = "<IGNORE>",
        },
    },
}

CHECK [[
f(if)
]]
{
    type   = "main",
    start  = 1,
    finish = 5,
    locals = "<IGNORE>",
    [1]    = {
        type   = "call",
        start  = 1,
        finish = 5,
        parent = "<IGNORE>",
        node   = "<IGNORE>",
        args   = {
            type   = "callargs",
            start  = 2,
            finish = 5,
            parent = "<IGNORE>",
            [1]    = {
                type   = "getglobal",
                start  = 3,
                finish = 4,
                parent = "<IGNORE>",
                node   = "<IGNORE>",
                [1]    = "if",
            },
        },
    },
}
