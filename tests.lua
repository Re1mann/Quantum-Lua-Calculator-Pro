--[[
  tests.lua - Набор модульных тестов для проверки всех компонентов калькулятора
--]]

local ui = require("src.ui")
local parser = require("src.parser")
local math_engine = require("src.math_engine")
local solver = require("src.solver")
local matrix = require("src.matrix")
local units = require("src.units")

local passed = 0
local failed = 0

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        passed = passed + 1
        print(string.format("  %s✓ PASS%s : %s", ui.c.bright_green, ui.c.reset, name))
    else
        failed = failed + 1
        print(string.format("  %s✗ FAIL%s : %s\n      %s%s%s", ui.c.bright_red, ui.c.reset, name, ui.c.bright_black, tostring(err), ui.c.reset))
    end
end

local function assertEqual(a, b, eps)
    eps = eps or 1e-6
    if type(a) == "number" and type(b) == "number" then
        if math.abs(a - b) > eps then
            error(string.format("Ожидалось %s, получено %s", tostring(b), tostring(a)))
        end
    elseif a ~= b then
        error(string.format("Ожидалось '%s', получено '%s'", tostring(b), tostring(a)))
    end
end

local ctx = {
    funcs = math_engine.functions,
    consts = math_engine.constants,
    vars = { x = 10, y = 5 }
}

print(ui.c.bold .. ui.c.bright_cyan .. "\n=== ЗАПУСК АВТОМАТИЧЕСКИХ ТЕСТОВ (QUANTUM LUA CALCULATOR) ===" .. ui.c.reset .. "\n")

-- 1. Базовые арифметические операции
test("Базовая арифметика и приоритеты", function()
    assertEqual(parser.evaluate("2 + 2 * 2", ctx), 6)
    assertEqual(parser.evaluate("(2 + 2) * 2", ctx), 8)
    assertEqual(parser.evaluate("2^3^2", ctx), 512) -- 2^(3^2) = 2^9 = 512
    assertEqual(parser.evaluate("10 // 3", ctx), 3)
    assertEqual(parser.evaluate("10 % 3", ctx), 1)
    assertEqual(parser.evaluate("50%", ctx), 0.5)
    assertEqual(parser.evaluate("200 * 15%", ctx), 30)
end)

-- 2. Неявное умножение и факториал
test("Неявное умножение и оператор факториала (!)", function()
    assertEqual(parser.evaluate("2(3 + 4)", ctx), 14)
    assertEqual(parser.evaluate("5!", ctx), 120)
    assertEqual(parser.evaluate("3! + 4!", ctx), 30)
    assertEqual(parser.evaluate("2x", ctx), 20)
    assertEqual(parser.evaluate("2(x + y)", ctx), 30)
end)

-- 3. Системы счисления
test("Шестнадцатеричные и двоичные литералы", function()
    assertEqual(parser.evaluate("0xFF", ctx), 255)
    assertEqual(parser.evaluate("0b1010", ctx), 10)
    assertEqual(parser.evaluate("0o77", ctx), 63)
    assertEqual(parser.evaluate("0x10 + 0b10", ctx), 18)
end)

-- 4. Тригонометрия и функции
test("Тригонометрия и математические функции", function()
    math_engine.config.angleMode = "deg"
    assertEqual(parser.evaluate("sin(30)", ctx), 0.5)
    assertEqual(parser.evaluate("cos(60)", ctx), 0.5)
    assertEqual(parser.evaluate("sqrt(144)", ctx), 12)
    assertEqual(parser.evaluate("log10(1000)", ctx), 3)
    assertEqual(parser.evaluate("nCr(5, 2)", ctx), 10)
    assertEqual(parser.evaluate("gcd(24, 36)", ctx), 12)
end)

-- 5. Решение уравнений
test("Решение квадратного уравнения", function()
    local res = solver.solveQuadratic(1, -5, 6)
    assertEqual(res.roots[1], 3)
    assertEqual(res.roots[2], 2)
end)

test("Решение СЛАУ 2x2 методом Крамера", function()
    -- 2x + y = 5
    -- x - y = 1  => x = 2, y = 1
    local res = solver.solveLinear2x2(2, 1, 5, 1, -1, 1)
    assertEqual(res.solution.x, 2)
    assertEqual(res.solution.y, 1)
end)

-- 6. Матричная алгебра
test("Матрицы: определитель и обратная матрица", function()
    local a = matrix.parse("[1 2; 3 4]")
    assertEqual(matrix.det(a), -2)
    local invA = matrix.inv(a)
    local prod = matrix.mul(a, invA)
    assertEqual(prod[1][1], 1)
    assertEqual(prod[1][2], 0)
    assertEqual(prod[2][1], 0)
    assertEqual(prod[2][2], 1)
end)

-- 7. Конвертер величин
test("Конвертер величин", function()
    local res1 = units.convert(100, "km", "m")
    assertEqual(res1.toVal, 100000)
    local res2 = units.convert(1024, "kib", "mib")
    assertEqual(res2.toVal, 1)
    local res3 = units.convert(0, "c", "f")
    assertEqual(res3.toVal, 32)
end)

print("")
local statusCol = (failed == 0) and ui.c.bright_green or ui.c.bright_red
print(string.format("ИТОГИ ТЕСТИРОВАНИЯ: Пройдено: %s%d%s | Провалено: %s%d%s", ui.c.bright_green, passed, ui.c.reset, statusCol, failed, ui.c.reset))
print("===============================================================\n")
