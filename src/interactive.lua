--[[
  src/interactive.lua - Интерактивные меню и пошаговые диалоги с пользователем
--]]

local ui = require("src.ui")
local solver = require("src.solver")
local units = require("src.units")
local matrix = require("src.matrix")
local plotter = require("src.plotter")
local programmer = require("src.programmer")
local math_engine = require("src.math_engine")

local interactive = {}

local function prompt(msg)
    io.write(ui.c.bright_cyan .. msg .. " " .. ui.c.reset)
    local line = io.read()
    return line and line:match("^%s*(.-)%s*$") or ""
end

function interactive.menu(ctx)
    while true do
        print("")
        local items = {
            "1. Решение квадратного уравнения (ax² + bx + c = 0)",
            "2. Решение СЛАУ 2x2 (Метод Крамера)",
            "3. Численный поиск корня f(x) = 0",
            "4. Построение 2D графика функции в консоли",
            "5. Конвертер единиц измерения (физика, данные, температура)",
            "6. Калькулятор матриц (Определитель, Обратная, Умножение)",
            "7. Режим программиста (HEX, BIN, OCT, битовая сетка)",
            "8. Финансовый калькулятор (Кредит / Сложные проценты)",
            "0. Вернуться в режим командной строки"
        }
        print(ui.box("ГЛАВНОЕ ИНТЕРАКТИВНОЕ МЕНЮ", items, 70, ui.c.bright_yellow))
        
        local choice = prompt("Выберите пункт [0-8]:")

        if choice == "1" then
            interactive.quadratic()
        elseif choice == "2" then
            interactive.slae2x2()
        elseif choice == "3" then
            interactive.rootFinder(ctx)
        elseif choice == "4" then
            interactive.plotMenu(ctx)
        elseif choice == "5" then
            interactive.unitConverter()
        elseif choice == "6" then
            interactive.matrixMenu()
        elseif choice == "7" then
            interactive.programmerMenu()
        elseif choice == "8" then
            interactive.financialMenu()
        elseif choice == "0" or choice == "q" or choice == "exit" or choice == "" then
            print(ui.c.bright_green .. "Возврат в основной режим." .. ui.c.reset)
            break
        else
            print(ui.c.bright_red .. "Неверный пункт меню, попробуйте еще раз." .. ui.c.reset)
        end
    end
end

-- 1. Квадратное уравнение
function interactive.quadratic()
    print(ui.c.bold .. ui.c.bright_cyan .. "\n[РЕШЕНИЕ КВАДРАТНОГО УРАВНЕНИЯ ax² + bx + c = 0]" .. ui.c.reset)
    local a = tonumber(prompt("Введите коэффициент a:"))
    local b = tonumber(prompt("Введите коэффициент b:"))
    local c = tonumber(prompt("Введите коэффициент c:"))

    if not a then
        print(ui.c.bright_red .. "Ошибка: коэффициент 'a' должен быть числом!" .. ui.c.reset)
        return
    end

    local ok, res = pcall(solver.solveQuadratic, a, b, c)
    if ok then
        print("")
        print(ui.box(res.title, res.steps, 70, ui.c.bright_green))
    else
        print(ui.c.bright_red .. "Ошибка: " .. tostring(res) .. ui.c.reset)
    end
end

-- 2. СЛАУ 2x2
function interactive.slae2x2()
    print(ui.c.bold .. ui.c.bright_cyan .. "\n[РЕШЕНИЕ СИСТЕМЫ 2x2: a1*x + b1*y = c1 | a2*x + b2*y = c2]" .. ui.c.reset)
    local a1 = tonumber(prompt("a1 (коэф. x в ур. 1):"))
    local b1 = tonumber(prompt("b1 (коэф. y в ур. 1):"))
    local c1 = tonumber(prompt("c1 (свободный член 1):"))
    local a2 = tonumber(prompt("a2 (коэф. x в ур. 2):"))
    local b2 = tonumber(prompt("b2 (коэф. y в ур. 2):"))
    local c2 = tonumber(prompt("c2 (свободный член 2):"))

    if not (a1 and b1 and c1 and a2 and b2 and c2) then
        print(ui.c.bright_red .. "Ошибка: все коэффициенты должны быть числами!" .. ui.c.reset)
        return
    end

    local ok, res = pcall(solver.solveLinear2x2, a1, b1, c1, a2, b2, c2)
    if ok then
        print("")
        print(ui.box(res.title, res.steps, 70, ui.c.bright_green))
    else
        print(ui.c.bright_red .. "Ошибка: " .. tostring(res) .. ui.c.reset)
    end
end

-- 3. Численный корень
function interactive.rootFinder(ctx)
    print(ui.c.bold .. ui.c.bright_cyan .. "\n[ЧИСЛЕННЫЙ ПОИСК КОРНЯ f(x) = 0]" .. ui.c.reset)
    local expr = prompt("Введите функцию f(x) (например: x^3 - 2x - 5):")
    if #expr == 0 then return end
    local x0 = tonumber(prompt("Начальное приближение x0 [0]:")) or 0
    local x1 = tonumber(prompt("Второе приближение x1 [1]:")) or 1

    local ok, res = pcall(solver.solveRoot, expr, x0, x1, 100, 1e-7, ctx)
    if ok then
        print("")
        print(ui.box(res.title, res.steps, 75, ui.c.bright_green))
    else
        print(ui.c.bright_red .. "Ошибка: " .. tostring(res) .. ui.c.reset)
    end
end

-- 4. График
function interactive.plotMenu(ctx)
    print(ui.c.bold .. ui.c.bright_cyan .. "\n[ПОСТРОЕНИЕ 2D ГРАФИКА В ТЕРМИНАЛЕ]" .. ui.c.reset)
    local expr = prompt("Введите выражение y = f(x) (например: sin(x) или x^2 - 4):")
    if #expr == 0 then return end
    local xMin = tonumber(prompt("Минимальный X [-10]:")) or -10
    local xMax = tonumber(prompt("Максимальный X [10]:")) or 10

    local ok, res = pcall(plotter.plot, expr, xMin, xMax, 65, 19, ctx)
    if ok then
        print("")
        print(res)
    else
        print(ui.c.bright_red .. "Ошибка построения графика: " .. tostring(res) .. ui.c.reset)
    end
end

-- 5. Конвертер
function interactive.unitConverter()
    print(ui.c.bold .. ui.c.bright_cyan .. "\n[КОНВЕРТЕР ВЕЛИЧИН]" .. ui.c.reset)
    print(units.listCategories())
    print("")
    local val = tonumber(prompt("Числовое значение:"))
    if not val then return end
    local fromU = prompt("Из единицы (например, km, kg, c, mib):")
    local toU = prompt("В единицу (например, mi, lb, f, gib):")

    local ok, res = pcall(units.convert, val, fromU, toU)
    if ok then
        local lines = {
            string.format("Категория : %s", res.category),
            string.format("Исходное  : %s %s", ui.c.bright_yellow .. ui.formatNumber(res.fromVal, 6) .. ui.c.reset, res.fromUnit),
            string.format("Результат : %s %s", ui.c.bold .. ui.c.bright_green .. ui.formatNumber(res.toVal, 6) .. ui.c.reset, res.toUnit),
        }
        print("")
        print(ui.box("РЕЗУЛЬТАТ КОНВЕРТАЦИИ", lines, 60, ui.c.bright_green))
    else
        print(ui.c.bright_red .. "Ошибка: " .. tostring(res) .. ui.c.reset)
    end
end

-- 6. Матрицы
function interactive.matrixMenu()
    print(ui.c.bold .. ui.c.bright_cyan .. "\n[МАТРИЧНЫЙ КАЛЬКУЛЯТОР]" .. ui.c.reset)
    print("Формат ввода матриц: [1 2; 3 4] или [[1, 2], [3, 4]]")
    print("Операции:")
    print("  1. Определитель матрицы det(A)")
    print("  2. Обратная матрица inv(A)")
    print("  3. Умножение матриц A * B")
    print("  4. Сложение / Вычитание матриц (A + B / A - B)")
    print("  5. Транспонирование матриц Aᵀ")

    local op = prompt("Выберите операцию [1-5]:")
    if op == "1" then
        local sA = prompt("Введите матрицу A:")
        local ok, mA = pcall(matrix.parse, sA)
        if not ok then print(ui.c.bright_red .. "Ошибка: " .. tostring(mA) .. ui.c.reset); return end
        local d = matrix.det(mA)
        print("\nМатрица A:")
        print(mA)
        print(ui.c.bold .. ui.c.bright_green .. "det(A) = " .. ui.formatNumber(d, 6) .. ui.c.reset)
    elseif op == "2" then
        local sA = prompt("Введите квадратную матрицу A:")
        local ok, mA = pcall(matrix.parse, sA)
        if not ok then print(ui.c.bright_red .. "Ошибка: " .. tostring(mA) .. ui.c.reset); return end
        local invOk, mInv = pcall(matrix.inv, mA)
        if invOk then
            print("\nМатрица A:")
            print(mA)
            print("\nОбратная матрица A⁻¹:")
            print(mInv)
        else
            print(ui.c.bright_red .. "Ошибка: " .. tostring(mInv) .. ui.c.reset)
        end
    elseif op == "3" then
        local sA = prompt("Матрица A:")
        local sB = prompt("Матрица B:")
        local ok1, mA = pcall(matrix.parse, sA)
        local ok2, mB = pcall(matrix.parse, sB)
        if not (ok1 and ok2) then print(ui.c.bright_red .. "Ошибка парсинга матриц!" .. ui.c.reset); return end
        local mulOk, mRes = pcall(matrix.mul, mA, mB)
        if mulOk then
            print("\nРезультат умножения A * B:")
            print(mRes)
        else
            print(ui.c.bright_red .. "Ошибка: " .. tostring(mRes) .. ui.c.reset)
        end
    elseif op == "4" then
        local sA = prompt("Матрица A:")
        local sB = prompt("Матрица B:")
        local sign = prompt("Знак (+ или -):")
        local ok1, mA = pcall(matrix.parse, sA)
        local ok2, mB = pcall(matrix.parse, sB)
        if not (ok1 and ok2) then print(ui.c.bright_red .. "Ошибка парсинга!" .. ui.c.reset); return end
        local fn = (sign == "-") and matrix.sub or matrix.add
        local ok, mRes = pcall(fn, mA, mB)
        if ok then
            print("\nРезультат:")
            print(mRes)
        else
            print(ui.c.bright_red .. "Ошибка: " .. tostring(mRes) .. ui.c.reset)
        end
    elseif op == "5" then
        local sA = prompt("Матрица A:")
        local ok, mA = pcall(matrix.parse, sA)
        if not ok then print(ui.c.bright_red .. "Ошибка!" .. ui.c.reset); return end
        print("\nТранспонированная матрица Aᵀ:")
        print(matrix.transpose(mA))
    end
end

-- 7. Режим программиста
function interactive.programmerMenu()
    print(ui.c.bold .. ui.c.bright_cyan .. "\n[РЕЖИМ ПРОГРАММИСТА / ИНСПЕКТОР БИТОВ]" .. ui.c.reset)
    local s = prompt("Введите число (десятичное, 0xHEX, 0bBIN):")
    local n = tonumber(s)
    if not n then
        if s:match("^0[xX]") then n = tonumber(s:sub(3), 16)
        elseif s:match("^0[bB]") then n = tonumber(s:sub(3), 2)
        end
    end
    if not n then
        print(ui.c.bright_red .. "Некорректное число!" .. ui.c.reset)
        return
    end
    print("")
    print(ui.box("РЕЗУЛЬТАТ ИНСПЕКЦИИ БИТОВ", programmer.inspect(n), 75, ui.c.bright_magenta))
end

-- 8. Финансовый калькулятор
function interactive.financialMenu()
    print(ui.c.bold .. ui.c.bright_cyan .. "\n[ФИНАНСОВЫЙ КАЛЬКУЛЯТОР]" .. ui.c.reset)
    print("1. Расчет кредита (аннуитетный ежемесячный платеж)")
    print("2. Сложные проценты (депозит / инвестиции)")
    local sub = prompt("Выберите вариант [1-2]:")
    if sub == "1" then
        local sum = tonumber(prompt("Сумма кредита (руб.):"))
        local rate = tonumber(prompt("Годовая ставка (%):"))
        local months = tonumber(prompt("Срок (в месяцах):"))
        if sum and rate and months then
            local pmt = math_engine.functions.loan(sum, rate, months)
            local total = pmt * months
            local overpay = total - sum
            local lines = {
                string.format("Ежемесячный платеж : %s руб.", ui.c.bold .. ui.c.bright_green .. ui.formatNumber(pmt, 2) .. ui.c.reset),
                string.format("Общая сумма выплат : %s руб.", ui.formatNumber(total, 2)),
                string.format("Переплата          : %s руб. (%.1f%%)", ui.c.bright_yellow .. ui.formatNumber(overpay, 2) .. ui.c.reset, (overpay / sum) * 100),
            }
            print("")
            print(ui.box("РАСЧЕТ КРЕДИТА", lines, 60, ui.c.bright_green))
        end
    elseif sub == "2" then
        local p = tonumber(prompt("Начальный капитал (руб.):"))
        local r = tonumber(prompt("Годовая ставка (%):"))
        local t = tonumber(prompt("Срок инвестиций (лет):"))
        local n = tonumber(prompt("Капитализаций в год (12 = ежемесячно, 1 = ежегодно) [12]:")) or 12
        if p and r and t then
            local total = math_engine.functions.compound(p, r, t, n)
            local profit = total - p
            local lines = {
                string.format("Итоговая сумма : %s руб.", ui.c.bold .. ui.c.bright_green .. ui.formatNumber(total, 2) .. ui.c.reset),
                string.format("Чистая прибыль : %s руб. (%.1f%%)", ui.c.bright_green .. ui.formatNumber(profit, 2) .. ui.c.reset, (profit / p) * 100)
            }
            print("")
            print(ui.box("СЛОЖНЫЕ ПРОЦЕНТЫ", lines, 60, ui.c.bright_green))
        end
    end
end

return interactive
