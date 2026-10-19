--[[
  src/math_engine.lua - Математическое ядро, функции, константы и специальные вычисления
--]]

local math_engine = {}

-- Глобальная конфигурация вычислений (по умолчанию)
math_engine.config = {
    angleMode = "deg", -- "deg" или "rad"
    precision = 6,
}

-- Константы
math_engine.constants = {
    pi   = math.pi,
    tau  = 2 * math.pi,
    e    = math.exp(1),
    phi  = (1 + math.sqrt(5)) / 2,        -- Золотое сечение
    c    = 299792458,                     -- Скорость света в вакууме (м/с)
    g    = 9.80665,                       -- Ускорение свободного падения (м/с²)
    G    = 6.67430e-11,                   -- Гравитационная постоянная (м³/(кг·с²))
    h    = 6.62607015e-34,                -- Постоянная Планка (Дж·с)
    Na   = 6.02214076e23,                 -- Число Авогадро (моль⁻¹)
    R    = 8.314462618,                   -- Универсальная газовая постоянная (Дж/(моль·К))
    kB   = 1.380649e-23,                  -- Постоянная Больцмана (Дж/К)
    inf  = math.huge,
}

-- Преобразование углов согласно режиму DEG/RAD
local function toRad(angle)
    if math_engine.config.angleMode == "deg" then
        return math.rad(angle)
    end
    return angle
end

local function fromRad(angle)
    if math_engine.config.angleMode == "deg" then
        return math.deg(angle)
    end
    return angle
end

-- Факториал
local function factorial(n)
    if n < 0 or math.floor(n) ~= n then
        error("Факториал определен только для целых неотрицательных чисел")
    end
    if n == 0 or n == 1 then return 1 end
    local res = 1
    for i = 2, n do
        res = res * i
        if res == math.huge then return math.huge end
    end
    return res
end

-- НОД и НОК
local function gcd(a, b)
    a = math.abs(math.floor(a))
    b = math.abs(math.floor(b))
    while b ~= 0 do
        a, b = b, a % b
    end
    return a
end

local function lcm(a, b)
    if a == 0 or b == 0 then return 0 end
    return math.abs(math.floor(a * b)) / gcd(a, b)
end

-- Проверка простоты
local function isPrime(n)
    n = math.floor(n)
    if n <= 1 then return 0 end
    if n <= 3 then return 1 end
    if n % 2 == 0 or n % 3 == 0 then return 0 end
    local i = 5
    while i * i <= n do
        if n % i == 0 or n % (i + 2) == 0 then
            return 0
        end
        i = i + 6
    end
    return 1
end

-- Число Фибоначчи
local function fib(n)
    n = math.floor(n)
    if n < 0 then error("Индекс Фибоначчи должен быть неотрицательным") end
    if n == 0 then return 0 end
    if n == 1 then return 1 end
    local a, b = 0, 1
    for _ = 2, n do
        a, b = b, a + b
    end
    return b
end

-- Вспомогательная функция для сбора аргументов vararg в плоский список чисел
local function unpackArgs(...)
    local args = {...}
    local flat = {}
    for _, item in ipairs(args) do
        if type(item) == "table" then
            for _, sub in ipairs(item) do
                table.insert(flat, tonumber(sub))
            end
        else
            table.insert(flat, tonumber(item))
        end
    end
    return flat
end

-- Округлитель
local function round(x, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(x * mult + 0.5) / mult
end

-- Словарь встроенных функций
math_engine.functions = {
    -- Базовая арифметика и округление
    abs    = math.abs,
    floor  = math.floor,
    ceil   = math.ceil,
    round  = round,
    sign   = function(x) return (x > 0 and 1) or (x < 0 and -1) or 0 end,
    clamp  = function(x, minVal, maxVal) return math.max(minVal, math.min(maxVal, x)) end,

    -- Степени и корни
    sqrt   = function(x)
        if x < 0 then error("Квадратный корень из отрицательного числа: " .. x) end
        return math.sqrt(x)
    end,
    cbrt   = function(x)
        if x < 0 then return -((-x) ^ (1/3)) end
        return x ^ (1/3)
    end,
    exp    = math.exp,

    -- Логарифмы
    ln     = function(x)
        if x <= 0 then error("Натуральный логарифм ln(x) требует x > 0") end
        return math.log(x)
    end,
    log10  = function(x)
        if x <= 0 then error("Десятичный логарифм log10(x) требует x > 0") end
        return math.log(x, 10)
    end,
    log2   = function(x)
        if x <= 0 then error("Двоичный логарифм log2(x) требует x > 0") end
        return math.log(x, 2)
    end,
    log    = function(x, base)
        if x <= 0 then error("Аргумент логарифма должен быть > 0") end
        base = base or math.exp(1)
        if base <= 0 or base == 1 then error("Основание логарифма должно быть > 0 и != 1") end
        return math.log(x, base)
    end,

    -- Тригонометрия
    sin    = function(x) return math.sin(toRad(x)) end,
    cos    = function(x) return math.cos(toRad(x)) end,
    tan    = function(x)
        local r = toRad(x)
        local c = math.cos(r)
        if math.abs(c) < 1e-15 then error("Тангенс не определен (деление на ноль)") end
        return math.tan(r)
    end,
    cot    = function(x)
        local r = toRad(x)
        local s = math.sin(r)
        if math.abs(s) < 1e-15 then error("Котангенс не определен (деление на ноль)") end
        return 1 / math.tan(r)
    end,
    sec    = function(x) return 1 / math.cos(toRad(x)) end,
    csc    = function(x) return 1 / math.sin(toRad(x)) end,

    -- Обратные тригонометрические
    asin   = function(x)
        if x < -1 or x > 1 then error("asin(x) требует диапазон [-1, 1]") end
        return fromRad(math.asin(x))
    end,
    acos   = function(x)
        if x < -1 or x > 1 then error("acos(x) требует диапазон [-1, 1]") end
        return fromRad(math.acos(x))
    end,
    atan   = function(x) return fromRad(math.atan(x)) end,
    atan2  = function(y, x) return fromRad(math.atan(y, x)) end,

    -- Гиперболические
    sinh   = function(x) return (math.exp(x) - math.exp(-x)) / 2 end,
    cosh   = function(x) return (math.exp(x) + math.exp(-x)) / 2 end,
    tanh   = function(x) return (math.exp(x) - math.exp(-x)) / (math.exp(x) + math.exp(-x)) end,

    -- Комбинаторика и теория чисел
    fact   = factorial,
    nCr    = function(n, r)
        n, r = math.floor(n), math.floor(r)
        if r < 0 or r > n then return 0 end
        return factorial(n) / (factorial(r) * factorial(n - r))
    end,
    nPr    = function(n, r)
        n, r = math.floor(n), math.floor(r)
        if r < 0 or r > n then return 0 end
        return factorial(n) / factorial(n - r)
    end,
    gcd    = gcd,
    lcm    = lcm,
    fib    = fib,
    isPrime= isPrime,

    -- Статистика
    sum    = function(...)
        local vals = unpackArgs(...)
        local s = 0
        for _, v in ipairs(vals) do s = s + v end
        return s
    end,
    mean   = function(...)
        local vals = unpackArgs(...)
        if #vals == 0 then return 0 end
        local s = 0
        for _, v in ipairs(vals) do s = s + v end
        return s / #vals
    end,
    avg    = function(...) return math_engine.functions.mean(...) end,
    median = function(...)
        local vals = unpackArgs(...)
        if #vals == 0 then return 0 end
        table.sort(vals)
        local mid = #vals / 2
        if #vals % 2 == 1 then
            return vals[math.ceil(mid)]
        else
            return (vals[mid] + vals[mid + 1]) / 2
        end
    end,
    min    = function(...)
        local vals = unpackArgs(...)
        if #vals == 0 then return 0 end
        return math.min(table.unpack(vals))
    end,
    max    = function(...)
        local vals = unpackArgs(...)
        if #vals == 0 then return 0 end
        return math.max(table.unpack(vals))
    end,
    var    = function(...)
        local vals = unpackArgs(...)
        if #vals <= 1 then return 0 end
        local m = math_engine.functions.mean(table.unpack(vals))
        local s = 0
        for _, v in ipairs(vals) do s = s + (v - m)^2 end
        return s / (#vals - 1)
    end,
    std    = function(...)
        return math.sqrt(math_engine.functions.var(...))
    end,

    -- Дополнительно
    hypot  = function(a, b) return math.sqrt(a * a + b * b) end,
    deg    = math.deg,
    rad    = math.rad,
    rand   = function(a, b)
        if not a then return math.random() end
        if not b then return math.random(a) end
        return math.random(a, b)
    end,
    pct    = function(val, total) return (val / total) * 100 end,

    -- Финансовые
    loan   = function(p, ratePct, months)
        -- Аннуитетный платеж: P * (r*(1+r)^n) / ((1+r)^n - 1)
        local r = (ratePct / 100) / 12
        if r == 0 then return p / months end
        local term = (1 + r) ^ months
        return p * (r * term) / (term - 1)
    end,
    compound = function(p, rPct, tYears, nPerYear)
        -- Сложные проценты: A = P*(1 + r/n)^(n*t)
        nPerYear = nPerYear or 1
        local r = rPct / 100
        return p * ((1 + r / nPerYear) ^ (nPerYear * tYears))
    end
}

return math_engine
