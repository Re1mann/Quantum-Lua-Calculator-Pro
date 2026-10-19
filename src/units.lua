--[[
  src/units.lua - Модуль конвертации физических величин и единиц измерения
  Категории: Длина, Масса, Температура, Данные (Байты), Время, Скорость, Давление, Энергия
--]]

local ui = require("src.ui")

local units = {}

-- Таблица базовых единиц и коэффициентов перевода в базовую единицу
local registry = {
    length = {
        name = "Длина",
        base = "m",
        rates = {
            m     = 1.0,
            km    = 1000.0,
            cm    = 0.01,
            mm    = 0.001,
            um    = 1e-6,
            nm    = 1e-9,
            ["in"]= 0.0254,
            ft    = 0.3048,
            yd    = 0.9144,
            mi    = 1609.344,
            nmi   = 1852.0, -- морская миля
        }
    },
    mass = {
        name = "Масса",
        base = "kg",
        rates = {
            kg    = 1.0,
            g     = 0.001,
            mg    = 1e-6,
            ug    = 1e-9,
            t     = 1000.0,
            lb    = 0.45359237,
            oz    = 0.028349523125,
            ct    = 0.0002, -- карат
        }
    },
    data = {
        name = "Объем данных",
        base = "B",
        rates = {
            b     = 0.125,
            B     = 1.0,
            kb    = 1000.0,
            mb    = 1e6,
            gb    = 1e9,
            tb    = 1e12,
            pb    = 1e15,
            kib   = 1024.0,
            mib   = 1024.0^2,
            gib   = 1024.0^3,
            tib   = 1024.0^4,
            pib   = 1024.0^5,
        }
    },
    time = {
        name = "Время",
        base = "s",
        rates = {
            s     = 1.0,
            ms    = 0.001,
            us    = 1e-6,
            ns    = 1e-9,
            min   = 60.0,
            h     = 3600.0,
            d     = 86400.0,
            week  = 604800.0,
            year  = 31536000.0, -- 365 дней
        }
    },
    speed = {
        name = "Скорость",
        base = "mps",
        rates = {
            mps   = 1.0,        -- м/с
            kmh   = 1 / 3.6,    -- км/ч
            mph   = 0.44704,    -- миль/ч
            knot  = 0.514444,   -- узлы
        }
    },
    pressure = {
        name = "Давление",
        base = "pa",
        rates = {
            pa    = 1.0,
            kpa   = 1000.0,
            bar   = 100000.0,
            atm   = 101325.0,
            psi   = 6894.75729,
            mmhg  = 133.322,
        }
    },
    energy = {
        name = "Энергия",
        base = "j",
        rates = {
            j     = 1.0,
            kj    = 1000.0,
            cal   = 4.184,
            kcal  = 4184.0,
            wh    = 3600.0,
            kwh   = 3.6e6,
            ev    = 1.602176634e-19,
        }
    }
}

-- Специальная обработка температуры (сдвиг шкалы)
local function convertTemperature(val, fromU, toU)
    fromU = fromU:lower()
    toU = toU:lower()

    -- Сначала в Кельвины
    local k
    if fromU == "c" then
        k = val + 273.15
    elseif fromU == "f" then
        k = (val - 32) * 5 / 9 + 273.15
    elseif fromU == "k" then
        k = val
    else
        error("Неизвестная единица температуры: " .. fromU)
    end

    -- Из Кельвинов в целевую шкалу
    if toU == "c" then
        return k - 273.15
    elseif toU == "f" then
        return (k - 273.15) * 9 / 5 + 32
    elseif toU == "k" then
        return k
    else
        error("Неизвестная единица температуры: " .. toU)
    end
end

-- Поиск категории для заданной единицы измерения
local function findCategory(unit)
    local u = unit:lower()
    if u == "c" or u == "f" or u == "k" then
        return "temperature"
    end
    for catKey, catData in pairs(registry) do
        for k, _ in pairs(catData.rates) do
            if k:lower() == u then
                return catKey, k
            end
        end
    end
    return nil
end

-- Основная функция конвертации
function units.convert(value, fromUnit, toUnit)
    value = tonumber(value)
    if not value then
        error("Некорректное числовое значение для конвертации")
    end

    local fromCat, fKey = findCategory(fromUnit)
    local toCat, tKey = findCategory(toUnit)

    if not fromCat then
        error(string.format("Неизвестная исходная единица измерения: '%s'", fromUnit))
    end
    if not toCat then
        error(string.format("Неизвестная целевая единица измерения: '%s'", toUnit))
    end
    if fromCat ~= toCat then
        error(string.format("Нельзя перевести '%s' (%s) в '%s' (%s)!", fromUnit, fromCat, toUnit, toCat))
    end

    if fromCat == "temperature" then
        local res = convertTemperature(value, fromUnit, toUnit)
        return {
            category = "Температура",
            fromVal = value,
            fromUnit = fromUnit:upper(),
            toVal = res,
            toUnit = toUnit:upper()
        }
    end

    local cat = registry[fromCat]
    local baseValue = value * cat.rates[fKey]
    local result = baseValue / cat.rates[tKey]

    return {
        category = cat.name,
        fromVal = value,
        fromUnit = fromUnit,
        toVal = result,
        toUnit = toUnit
    }
end

-- Парсинг строки вида "100 km to mi" или "convert 50 c to f" или "100 km -> mi"
function units.parseAndConvert(str)
    -- Убираем ключевое слово convert если есть
    local s = str:gsub("^%s*convert%s+", "")
    
    -- Пробуем различные разделители: to, ->, в или просто пробел
    local valStr, fromU, toU = s:match("^%s*([%+%-]?%d*%.?%d+[eE]?[%+%-]?%d*)%s*([%a_]+)%s+to%s+([%a_]+)%s*$")
    if not valStr then
        valStr, fromU, toU = s:match("^%s*([%+%-]?%d*%.?%d+[eE]?[%+%-]?%d*)%s*([%a_]+)%s*%->%s*([%a_]+)%s*$")
    end
    if not valStr then
        valStr, fromU, toU = s:match("^%s*([%+%-]?%d*%.?%d+[eE]?[%+%-]?%d*)%s*([%a_]+)%s+в%s+([%a_]+)%s*$")
    end
    if not valStr then
        valStr, fromU, toU = s:match("^%s*([%+%-]?%d*%.?%d+[eE]?[%+%-]?%d*)%s*([%a_]+)%s+([%a_]+)%s*$")
    end

    if not valStr or not fromU or not toU then
        error("Формат команды конвертации: '100 km to mi', '36.6 C -> F' или 'convert 1024 MB to GB'")
    end

    return units.convert(valStr, fromU, toU)
end

-- Форматированный список доступных единиц
function units.listCategories()
    local lines = {}
    table.insert(lines, ui.c.bold .. ui.c.bright_yellow .. "СПИСОК ДОСТУПНЫХ ЕДИНИЦ ИЗМЕРЕНИЯ:" .. ui.c.reset)
    table.insert(lines, "")

    table.insert(lines, ui.c.bright_cyan .. "  • Температура : " .. ui.c.reset .. "C, F, K")
    for _, catData in pairs(registry) do
        local uList = {}
        for k, _ in pairs(catData.rates) do
            table.insert(uList, k)
        end
        table.sort(uList)
        table.insert(lines, ui.c.bright_cyan .. string.format("  • %-12s : ", catData.name) .. ui.c.reset .. table.concat(uList, ", "))
    end

    return table.concat(lines, "\n")
end

return units
