--[[
  src/help.lua - Справочная система калькулятора с подробными примерами
--]]

local ui = require("src.ui")

local help = {}

function help.general()
    local lines = {
        ui.c.bright_yellow .. "★ ОСНОВНЫЕ ВОЗМОЖНОСТИ И СИНТАКСИС ★" .. ui.c.reset,
        "",
        ui.c.cyan .. "1. Математические выражения:" .. ui.c.reset,
        "   • Вводите формулы напрямую: " .. ui.c.bright_green .. "2 + 2 * 2" .. ui.c.reset .. ", " .. ui.c.bright_green .. "sin(45)^2 + cos(45)^2" .. ui.c.reset,
        "   • Неявное умножение: " .. ui.c.bright_green .. "2(3 + 4)" .. ui.c.reset .. ", " .. ui.c.bright_green .. "3sin(x)" .. ui.c.reset .. ", " .. ui.c.bright_green .. "5pi" .. ui.c.reset,
        "   • Факториал и степени: " .. ui.c.bright_green .. "5!" .. ui.c.reset .. ", " .. ui.c.bright_green .. "2^10" .. ui.c.reset .. ", " .. ui.c.bright_green .. "sqrt(144)" .. ui.c.reset,
        "   • Переменные: " .. ui.c.bright_green .. "r = 5" .. ui.c.reset .. ", затем " .. ui.c.bright_green .. "S = pi * r^2" .. ui.c.reset,
        "   • Последний результат: переменная " .. ui.c.bright_yellow .. "ans" .. ui.c.reset .. " (" .. ui.c.bright_green .. "ans * 2" .. ui.c.reset .. ")",
        "",
        ui.c.cyan .. "2. Специальные модули и крутые команды:" .. ui.c.reset,
        "   • " .. ui.c.bright_yellow .. "plot <expr> [min] [max]" .. ui.c.reset .. " : ASCII-график в консоли (напр: " .. ui.c.dim .. "plot sin(x) -3.14 3.14" .. ui.c.reset .. ")",
        "   • " .. ui.c.bright_yellow .. "solve quadratic <a> <b> <c>" .. ui.c.reset .. " : Квадратное уравнение ax² + bx + c = 0",
        "   • " .. ui.c.bright_yellow .. "solve root <expr> [x0] [x1]" .. ui.c.reset .. " : Численный поиск корня f(x) = 0",
        "   • " .. ui.c.bright_yellow .. "solve 2x2 a1 b1 c1 a2 b2 c2" .. ui.c.reset .. " : СЛАУ 2x2 методом Крамера",
        "   • " .. ui.c.bright_yellow .. "base <num> / inspect <num>" .. ui.c.reset .. " : Режим программиста, битовая сетка, HEX/BIN",
        "   • " .. ui.c.bright_yellow .. "convert <val> <from> to <to>" .. ui.c.reset .. " : Конвертер физических величин (100 km to mi)",
        "   • " .. ui.c.bright_yellow .. "matrix" .. ui.c.reset .. " : Меню матричной алгебры (det, inv, умножение)",
        "",
        ui.c.cyan .. "3. Управление сессией:" .. ui.c.reset,
        "   • " .. ui.c.bright_white .. "deg / rad" .. ui.c.reset .. "       : Переключение градусов / радиан",
        "   • " .. ui.c.bright_white .. "prec <число>" .. ui.c.reset .. "    : Установка количества знаков после запятой",
        "   • " .. ui.c.bright_white .. "vars" .. ui.c.reset .. "            : Список сохраненных переменных",
        "   • " .. ui.c.bright_white .. "history / hist" .. ui.c.reset .. "  : Журнал последних вычислений",
        "   • " .. ui.c.bright_white .. "export [файл]" .. ui.c.reset .. "   : Сохранить историю в текстовый файл",
        "   • " .. ui.c.bright_white .. "menu" .. ui.c.reset .. "            : Интерактивное пошаговое меню режимов",
        "   • " .. ui.c.bright_white .. "clear / cls" .. ui.c.reset .. "     : Очистить экран",
        "   • " .. ui.c.bright_white .. "exit / quit / q" .. ui.c.reset .. " : Выход из калькулятора",
        "",
        ui.c.bright_black .. "Для подробной справки по разделам введите: " .. ui.c.bright_cyan .. "help math" .. ui.c.bright_black .. ", " .. ui.c.bright_cyan .. "help plot" .. ui.c.bright_black .. ", " .. ui.c.bright_cyan .. "help units" .. ui.c.reset
    }
    return ui.box("СПРАВКА ПО КОМАНДАМ", lines, nil, ui.c.bright_yellow)
end

function help.math()
    local lines = {
        ui.c.bright_cyan .. "ВСТРОЕННЫЕ МАТЕМАТИЧЕСКИЕ ФУНКЦИИ И КОНСТАНТЫ" .. ui.c.reset,
        "",
        ui.c.yellow .. "КОНСТАНТЫ:" .. ui.c.reset,
        "  pi (3.14159), tau (2*pi), e (2.71828), phi (1.618 - золотое сечение)",
        "  c (скорость света, м/с), g (ускорение своб. падения 9.80665 м/с²)",
        "  h (постоянная Планка), G (гравитационная), Na (Авогадро), inf (бесконечность)",
        "",
        ui.c.yellow .. "ТРИГОНОМЕТРИЯ (зависит от режима DEG/RAD):" .. ui.c.reset,
        "  sin(x), cos(x), tan(x), cot(x), sec(x), csc(x)",
        "  asin(x), acos(x), atan(x), atan2(y, x)",
        "  sinh(x), cosh(x), tanh(x)",
        "",
        ui.c.yellow .. "АЛГЕБРА И ЛОГАРИФМЫ:" .. ui.c.reset,
        "  sqrt(x), cbrt(x), exp(x)",
        "  ln(x), log10(x), log2(x), log(x, [base])",
        "  abs(x), floor(x), ceil(x), round(x, [знаков]), sign(x), clamp(x, min, max)",
        "",
        ui.c.yellow .. "КОМБИНАТОРИКА И СТАТИСТИКА:" .. ui.c.reset,
        "  fact(n) или n!        : Факториал",
        "  nCr(n, r), nPr(n, r)  : Сочетания и перестановки",
        "  gcd(a, b), lcm(a, b)  : НОД и НОК чисел",
        "  fib(n), isPrime(n)    : Числа Фибоначчи и проверка простоты",
        "  mean(...), median(...) : Среднее арифметическое и медиана",
        "  min(...), max(...)    : Минимум и максимум списка чисел",
        "  std(...), var(...)    : Стандартное отклонение и дисперсия",
        "",
        ui.c.yellow .. "ФИНАНСОВЫЕ ФУНКЦИИ:" .. ui.c.reset,
        "  loan(сумма, годовая_ставка_%, месяцев) : Расчет ежемесячного платежа",
        "  compound(капитал, ставка_%, лет, [выплат_в_год]) : Сложные проценты"
    }
    return ui.box("МАТЕМАТИЧЕСКИЙ СПРАВОЧНИК", lines, nil, ui.c.cyan)
end

function help.plot()
    local lines = {
        ui.c.bright_cyan .. "КАК СТРОИТЬ ГРАФИКИ В КОНСОЛИ" .. ui.c.reset,
        "",
        "Синтаксис команды:",
        "  " .. ui.c.bright_yellow .. "plot <выражение_от_x> [x_мин] [x_макс]" .. ui.c.reset,
        "",
        "Примеры:",
        "  • " .. ui.c.bright_green .. "plot sin(x)" .. ui.c.reset .. "                      (по умолчанию от -10 до 10)",
        "  • " .. ui.c.bright_green .. "plot x^2 - 4 -5 5" .. ui.c.reset .. "              (парабола от -5 до 5)",
        "  • " .. ui.c.bright_green .. "plot cos(x) + sin(2x) -3.14 3.14" .. ui.c.reset .. " (сумма гармоник)",
        "  • " .. ui.c.bright_green .. "plot 1/x 0.1 5" .. ui.c.reset .. "                 (гипербола)",
        "",
        "Совет: Для тригонометрии установите режим " .. ui.c.bright_yellow .. "rad" .. ui.c.reset .. " командой 'rad'!"
    }
    return ui.box("ПОСТРОИТЕЛЬ ГРАФИКОВ", lines, nil, ui.c.bright_magenta)
end

function help.units()
    local unitsMod = require("src.units")
    return unitsMod.listCategories()
end

return help
