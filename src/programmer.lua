--[[
  src/programmer.lua - Режим программиста / Калькулятор систем счисления и битов
  Поддержка:
  - Перевод DEC, HEX, BIN, OCT
  - Инспектор битов (Bit Board) с подсветкой активных битов
  - Знаковые и беззнаковые типы (8, 16, 32, 64 бит)
  - Побитовые операции: AND, OR, XOR, NOT, SHL, SHR, POPCNT, ASCII
--]]

local ui = require("src.ui")

local programmer = {}

-- Перевод числа в двоичную строку заданной разрядности
local function toBinaryString(num, bits)
    bits = bits or 32
    local res = {}
    local n = math.floor(num)
    for i = bits - 1, 0, -1 do
        local bitVal = (n >> i) & 1
        table.insert(res, tostring(bitVal))
    end
    return table.concat(res)
end

-- Подсчет единичных битов (Population count / Hamming weight)
local function popcount(num)
    local count = 0
    local n = math.floor(num)
    for i = 0, 63 do
        if ((n >> i) & 1) == 1 then
            count = count + 1
        end
    end
    return count
end

-- Отрисовка инспектора битов (Bit Board)
function programmer.inspect(val)
    local n = math.floor(tonumber(val) or 0)
    local hexStr = string.format("0x%X", n)
    local octStr = string.format("0o%o", n)
    local decStr = tostring(n)

    local lines = {}
    table.insert(lines, ui.c.bold .. ui.c.bright_cyan .. "ИНСПЕКТОР СИСТЕМ СЧИСЛЕНИЯ И БИТОВ" .. ui.c.reset)
    table.insert(lines, "")

    -- Таблица основных представлений
    local repTable = {
        { ui.c.bright_yellow .. "DEC (Десятичный)" .. ui.c.reset, decStr },
        { ui.c.bright_magenta .. "HEX (Шестнадцатеричный)" .. ui.c.reset, hexStr },
        { ui.c.bright_green .. "OCT (Восьмеричный)" .. ui.c.reset, octStr },
        { ui.c.cyan .. "Бит установлено (POPCNT)" .. ui.c.reset, tostring(popcount(n)) },
    }

    if n >= 32 and n <= 126 then
        table.insert(repTable, { ui.c.bright_white .. "ASCII Символ" .. ui.c.reset, string.format("'%c'", n) })
    end

    for _, row in ipairs(repTable) do
        table.insert(lines, string.format("  %-30s : %s", row[1], row[2]))
    end

    table.insert(lines, "")
    table.insert(lines, ui.c.bold .. ui.c.bright_blue .. "── 32-БИТНАЯ БИТОВАЯ СЕТКА (BIT BOARD) ──" .. ui.c.reset)

    -- Разбивка 32-битного представления по 8 бит (байты) и по 4 бита (тетрады)
    local bin32 = toBinaryString(n, 32)
    local nibbles = {}
    for i = 1, 32, 4 do
        table.insert(nibbles, bin32:sub(i, i + 3))
    end

    -- Линейка номеров битов
    local headerLine = "  Биты : "
    local valueLine  = "  Знач : "

    for idx, nib in ipairs(nibbles) do
        local topBit = 32 - (idx - 1) * 4 - 1
        headerLine = headerLine .. ui.c.bright_black .. string.format("%2d..%-2d", topBit, topBit - 3) .. ui.c.reset .. " "
        
        local coloredNib = ""
        for b = 1, 4 do
            local ch = nib:sub(b, b)
            if ch == "1" then
                coloredNib = coloredNib .. ui.c.bright_green .. ui.c.bold .. "1" .. ui.c.reset
            else
                coloredNib = coloredNib .. ui.c.bright_black .. "0" .. ui.c.reset
            end
        end
        valueLine = valueLine .. "  " .. coloredNib .. "  "
    end

    table.insert(lines, headerLine)
    table.insert(lines, valueLine)

    -- Знаковые типы: Int8, Int16, Int32
    table.insert(lines, "")
    table.insert(lines, ui.c.bold .. ui.c.bright_blue .. "── ЗНАКОВЫЕ ПРЕДСТАВЛЕНИЯ ──" .. ui.c.reset)

    local int8Val  = (n & 0xFF)
    if int8Val >= 0x80 then int8Val = int8Val - 0x100 end

    local int16Val = (n & 0xFFFF)
    if int16Val >= 0x8000 then int16Val = int16Val - 0x10000 end

    local int32Val = (n & 0xFFFFFFFF)
    if int32Val >= 0x80000000 then int32Val = int32Val - 0x100000000 end

    table.insert(lines, string.format("  Int8  : %-12d | UInt8  : %d", int8Val, (n & 0xFF)))
    table.insert(lines, string.format("  Int16 : %-12d | UInt16 : %d", int16Val, (n & 0xFFFF)))
    table.insert(lines, string.format("  Int32 : %-12d | UInt32 : %d", int32Val, (n & 0xFFFFFFFF)))

    return table.concat(lines, "\n")
end

return programmer
