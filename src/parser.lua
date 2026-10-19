--[[
  src/parser.lua - Лексер и парсер математических выражений (Precedence Climbing)
  Поддержка:
  - Бинарные операции: +, -, *, /, //, %, ^, &, |, ~ (xor), <<, >>
  - Унарные операции: -, +, ~ (bitwise not)
  - Постфиксные: ! (факториал), % (проценты)
  - Неявное умножение: 2x, 2(3+4), (a+b)(c+d), 3sin(x), 2pi
  - Системы счисления: 0x..., 0b..., 0o...
  - Функции со множеством аргументов: min(1, 2, 3), log(8, 2)
  - Переменные и присваивание: x = 42, ans
--]]

local parser = {}

-- Токенизатор (Lexer)
local function tokenize(input)
    -- Удаление UTF-8 BOM если есть
    input = input:gsub("^\239\187\191", "")
    local tokens = {}
    local i = 1
    local n = #input

    while i <= n do
        local c = input:sub(i, i)

        if c:match("%s") then
            i = i + 1
        -- Двухсимвольные операторы
        elseif input:sub(i, i + 1) == "//" then
            table.insert(tokens, { type = "OP", value = "//", pos = i })
            i = i + 2
        elseif input:sub(i, i + 1) == "<<" then
            table.insert(tokens, { type = "OP", value = "<<", pos = i })
            i = i + 2
        elseif input:sub(i, i + 1) == ">>" then
            table.insert(tokens, { type = "OP", value = ">>", pos = i })
            i = i + 2
        elseif input:sub(i, i + 1) == "**" then
            table.insert(tokens, { type = "OP", value = "^", pos = i })
            i = i + 2
        -- Шестнадцатеричные (0x...), двоичные (0b...), восьмеричные (0o...)
        elseif c == "0" and (input:sub(i+1, i+1):lower() == "x" or input:sub(i+1, i+1):lower() == "b" or input:sub(i+1, i+1):lower() == "o") then
            local prefix = input:sub(i+1, i+1):lower()
            local start = i
            i = i + 2
            local digits = ""
            if prefix == "x" then
                digits = input:match("^%x+", i) or ""
            elseif prefix == "b" then
                digits = input:match("^[01]+", i) or ""
            elseif prefix == "o" then
                digits = input:match("^[0-7]+", i) or ""
            end
            if #digits == 0 then
                error("Некорректная запись числа с префиксом 0" .. prefix .. " на позиции " .. start)
            end
            i = i + #digits
            local val
            if prefix == "x" then
                val = tonumber(digits, 16)
            elseif prefix == "b" then
                val = tonumber(digits, 2)
            elseif prefix == "o" then
                val = tonumber(digits, 8)
            end
            table.insert(tokens, { type = "NUMBER", value = val, pos = start })
        -- Обычные числа (включая научную нотацию 1.2e-4)
        elseif c:match("%d") or (c == "." and (input:sub(i+1, i+1) or ""):match("%d")) then
            local start = i
            local numStr = input:match("^%d*%.?%d+[eE][%+%-]?%d+", i)
            if not numStr then
                numStr = input:match("^%d*%.?%d+", i)
            end
            if not numStr then
                error("Синтаксическая ошибка в числе на позиции " .. start)
            end
            i = i + #numStr
            table.insert(tokens, { type = "NUMBER", value = tonumber(numStr), pos = start })
        -- Идентификаторы (переменные, константы, функции)
        elseif c:match("[%a_]") then
            local start = i
            local id = input:match("^[%a_][%w_]*", i)
            i = i + #id
            table.insert(tokens, { type = "ID", value = id, pos = start })
        -- Односимвольные операторы и знаки
        elseif c == "+" or c == "-" or c == "*" or c == "/" or c == "%" or
               c == "^" or c == "&" or c == "|" or c == "~" or c == "!" or
               c == "(" or c == ")" or c == "," or c == "=" then
            table.insert(tokens, { type = "OP", value = c, pos = i })
            i = i + 1
        else
            error(string.format("Неизвестный символ '%s' на позиции %d", c, i))
        end
    end

    table.insert(tokens, { type = "EOF", value = "", pos = n + 1 })
    return tokens
end

-- Вставка неявного умножения:
-- e.g. "NUMBER ID", "NUMBER (", ") (", ") ID", ") NUMBER", "ID (" (где ID не функция)
local function insertImplicitMultiplication(tokens, functions)
    local out = {}
    for i = 1, #tokens do
        local cur = tokens[i]
        local nextTok = tokens[i + 1]
        table.insert(out, cur)

        if nextTok and nextTok.type ~= "EOF" then
            local shouldInsert = false
            -- 5x или 5pi
            if cur.type == "NUMBER" and nextTok.type == "ID" then
                shouldInsert = true
            -- 5(2+3)
            elseif cur.type == "NUMBER" and nextTok.type == "OP" and nextTok.value == "(" then
                shouldInsert = true
            -- (2+3)(4+5)
            elseif cur.type == "OP" and cur.value == ")" and nextTok.type == "OP" and nextTok.value == "(" then
                shouldInsert = true
            -- (2+3)5
            elseif cur.type == "OP" and cur.value == ")" and nextTok.type == "NUMBER" then
                shouldInsert = true
            -- (2+3)x
            elseif cur.type == "OP" and cur.value == ")" and nextTok.type == "ID" then
                shouldInsert = true
            -- 5! 2 или 5! x
            elseif cur.type == "OP" and cur.value == "!" and (nextTok.type == "NUMBER" or nextTok.type == "ID" or (nextTok.type == "OP" and nextTok.value == "(")) then
                shouldInsert = true
            -- x(y+1) где x НЕ является именем функции
            elseif cur.type == "ID" and not (functions and functions[cur.value]) and nextTok.type == "OP" and nextTok.value == "(" then
                shouldInsert = true
            end

            if shouldInsert then
                table.insert(out, { type = "OP", value = "*", pos = nextTok.pos, implicit = true })
            end
        end
    end
    return out
end

-- Приоритеты операторов
local PRECEDENCE = {
    ["|"]  = { prec = 1, assoc = "L" },
    ["~"]  = { prec = 2, assoc = "L" }, -- бинарный xor
    ["&"]  = { prec = 3, assoc = "L" },
    ["<<"] = { prec = 4, assoc = "L" },
    [">>"] = { prec = 4, assoc = "L" },
    ["+"]  = { prec = 5, assoc = "L" },
    ["-"]  = { prec = 5, assoc = "L" },
    ["*"]  = { prec = 6, assoc = "L" },
    ["/"]  = { prec = 6, assoc = "L" },
    ["//"] = { prec = 6, assoc = "L" },
    ["%"]  = { prec = 6, assoc = "L" },
    ["^"]  = { prec = 7, assoc = "R" }, -- правоассоциативное возведение в степень
}

-- Вычисление базовых бинарных операций
local function applyBinOp(op, a, b)
    if op == "+" then return a + b
    elseif op == "-" then return a - b
    elseif op == "*" then return a * b
    elseif op == "/" then
        if b == 0 then error("Деление на ноль!") end
        return a / b
    elseif op == "//" then
        if b == 0 then error("Целочисленное деление на ноль!") end
        return math.floor(a / b)
    elseif op == "%" then
        if b == 0 then error("Деление по модулю на ноль!") end
        return a % b
    elseif op == "^" then
        return a ^ b
    elseif op == "&" then
        return math.floor(a) & math.floor(b)
    elseif op == "|" then
        return math.floor(a) | math.floor(b)
    elseif op == "~" then
        return math.floor(a) ~ math.floor(b)
    elseif op == "<<" then
        return math.floor(a) << math.floor(b)
    elseif op == ">>" then
        return math.floor(a) >> math.floor(b)
    else
        error("Неизвестная операция: " .. tostring(op))
    end
end

-- Препроцессор присваивания (x = ...)
function parser.checkAssignment(str)
    local varName, expr = str:match("^%s*([%a_][%w_]*)%s*=%s*(.+)%s*$")
    if varName and expr then
        return varName, expr
    end
    return nil, str
end

-- Основной парсер
function parser.evaluate(exprStr, ctx)
    ctx = ctx or {}
    local vars = ctx.vars or {}
    local funcs = ctx.funcs or {}
    local consts = ctx.consts or {}

    local rawTokens = tokenize(exprStr)
    local tokens = insertImplicitMultiplication(rawTokens, funcs)
    local cursor = 1

    local function peek()
        return tokens[cursor]
    end

    local function get()
        local tok = tokens[cursor]
        cursor = cursor + 1
        return tok
    end

    local parseExpression

    -- Первичные элементы: числа, скобки, унарные знаки, вызовы функций, переменные
    local function parsePrimary()
        local tok = peek()
        if not tok or tok.type == "EOF" then
            error("Неожиданный конец выражения")
        end

        -- Унарный минус, плюс, побитовое НЕ
        if tok.type == "OP" and (tok.value == "-" or tok.value == "+" or tok.value == "~") then
            local op = get().value
            local val = parsePrimary()
            if op == "-" then
                return -val
            elseif op == "+" then
                return val
            elseif op == "~" then
                return ~math.floor(val)
            end
        end

        -- Скобки
        if tok.type == "OP" and tok.value == "(" then
            get() -- пропускаем '('
            local val = parseExpression(0)
            local closing = peek()
            if not closing or closing.type ~= "OP" or closing.value ~= ")" then
                error("Ожидалась закрывающая скобка ')' на позиции " .. (closing and closing.pos or #exprStr))
            end
            get() -- пропускаем ')'
            return val
        end

        -- Числовой литерал
        if tok.type == "NUMBER" then
            get()
            return tok.value
        end

        -- Идентификатор (функция, константа, переменная)
        if tok.type == "ID" then
            local idName = get().value
            local nextTok = peek()

            -- Вызов функции
            if nextTok and nextTok.type == "OP" and nextTok.value == "(" then
                get() -- пропускаем '('
                local args = {}
                if peek().type ~= "OP" or peek().value ~= ")" then
                    while true do
                        local argVal = parseExpression(0)
                        table.insert(args, argVal)
                        local sep = peek()
                        if sep.type == "OP" and sep.value == "," then
                            get() -- пропускаем ','
                        elseif sep.type == "OP" and sep.value == ")" then
                            break
                        else
                            error("Ожидалась запятая ',' или ')' в аргументах функции '" .. idName .. "' на позиции " .. sep.pos)
                        end
                    end
                end
                get() -- пропускаем ')'

                local fn = funcs[idName]
                if not fn then
                    error("Неизвестная функция: " .. idName)
                end
                return fn(table.unpack(args))
            end

            -- Константа
            if consts[idName] ~= nil then
                return consts[idName]
            end

            -- Пользовательская переменная
            if vars[idName] ~= nil then
                return vars[idName]
            end

            error("Неизвестная переменная или идентификатор: '" .. idName .. "' на позиции " .. tok.pos)
        end

        error("Синтаксическая ошибка возле '" .. tostring(tok.value) .. "' на позиции " .. tok.pos)
    end

    -- Обработка постфиксных операторов: ! (факториал), % (процент)
    local function parsePostfix()
        local val = parsePrimary()
        while true do
            local tok = peek()
            if tok and tok.type == "OP" and tok.value == "!" then
                get()
                if funcs.fact then
                    val = funcs.fact(val)
                else
                    error("Функция факториала недоступна")
                end
            elseif tok and tok.type == "OP" and tok.value == "%" then
                -- Проверяем следующий токен:
                -- Если следующий токен является операндом (число, переменная, скобка, унарный знак),
                -- то '%' это бинарный оператор взятия остатка (10 % 3), а НЕ постфиксный процент!
                local nextTok = tokens[cursor + 1]
                if nextTok and (nextTok.type == "NUMBER" or nextTok.type == "ID" or (nextTok.type == "OP" and (nextTok.value == "(" or nextTok.value == "-" or nextTok.value == "+"))) then
                    break -- бинарный оператор остатка от деления
                else
                    -- Постфиксный процент (например: 50%, (2+3)%)
                    get()
                    val = val / 100
                end
            else
                break
            end
        end
        return val
    end

    -- Метод восходящего приоритета (Precedence Climbing)
    parseExpression = function(minPrec)
        local left = parsePostfix()

        while true do
            local tok = peek()
            if not tok or tok.type ~= "OP" then break end

            local opInfo = PRECEDENCE[tok.value]
            if not opInfo or opInfo.prec < minPrec then
                break
            end

            local op = get().value
            local nextMinPrec = (opInfo.assoc == "L") and (opInfo.prec + 1) or opInfo.prec
            local right = parseExpression(nextMinPrec)

            left = applyBinOp(op, left, right)
        end

        return left
    end

    local result = parseExpression(0)

    local trailing = peek()
    if trailing and trailing.type ~= "EOF" then
        error("Лишние символы в выражении возле позиции " .. trailing.pos)
    end

    return result
end

return parser
