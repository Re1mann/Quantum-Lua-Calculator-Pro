--[[
  src/ui.lua - UI, ANSI стили, оформление терминала и визуальные эффекты
--]]

local ui = {}

-- Включаем UTF-8 в Windows консоли
if package.config:sub(1, 1) == "\\" then
    os.execute("chcp 65001 >nul 2>nul")
end

-- Цветовая палитра ANSI (24-bit / 256 / 16 color совместимость)
ui.c = {
    reset       = "\27[0m",
    bold        = "\27[1m",
    dim         = "\27[2m",
    italic      = "\27[3m",
    underline   = "\27[4m",
    
    -- Основные цвета
    black       = "\27[30m",
    red         = "\27[31m",
    green       = "\27[32m",
    yellow      = "\27[33m",
    blue        = "\27[34m",
    magenta     = "\27[35m",
    cyan        = "\27[36m",
    white       = "\27[37m",
    
    -- Яркие цвета
    bright_black   = "\27[90m",  -- серый
    bright_red     = "\27[91m",
    bright_green   = "\27[92m",
    bright_yellow  = "\27[93m",
    bright_blue    = "\27[94m",
    bright_magenta = "\27[95m",
    bright_cyan    = "\27[96m",
    bright_white   = "\27[97m",
    
    -- Фоновые цвета
    bg_dark        = "\27[40m",
    bg_cyan        = "\27[46;30m",
    bg_magenta     = "\27[45;30m",
    bg_blue        = "\27[44;97m",
    bg_green       = "\27[42;30m",
}

-- Хелперы для быстрой раскраски
function ui.colorize(text, colorCode)
    return (colorCode or "") .. tostring(text) .. ui.c.reset
end

function ui.cyan(text)    return ui.colorize(text, ui.c.cyan) end
function ui.magenta(text) return ui.colorize(text, ui.c.bright_magenta) end
function ui.green(text)   return ui.colorize(text, ui.c.bright_green) end
function ui.yellow(text)  return ui.colorize(text, ui.c.bright_yellow) end
function ui.red(text)     return ui.colorize(text, ui.c.bright_red) end
function ui.gray(text)    return ui.colorize(text, ui.c.bright_black) end
function ui.bold(text)    return ui.colorize(text, ui.c.bold) end
function ui.accent(text)  return ui.colorize(text, ui.c.bold .. ui.c.bright_cyan) end

-- Подсчет видимой длины строки (без ANSI escape-последовательностей и с учетом UTF-8)
function ui.visibleLen(str)
    if not str then return 0 end
    -- Удаляем ANSI escape последовательности
    local clean = str:gsub("\27%[[%d;]*[mK]", "")
    -- Подсчет UTF-8 символов (каждый символ UTF-8 начинается не с байта 10xxxxxx)
    local len = 0
    for _ in clean:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        len = len + 1
    end
    return len
end

-- Очистка экрана
function ui.clearScreen()
    io.write("\27[2J\27[H")
end

-- Красивый баннер калькулятора
function ui.banner()
    local b = {
        ui.c.bright_cyan .. "  ██████╗  ██╗   ██╗ █████╗ ███╗   ██╗████████╗██╗   ██╗███╗   ███╗" .. ui.c.reset,
        ui.c.bright_cyan .. " ██╔═══██╗ ██║   ██║██╔══██╗████╗  ██║╚══██╔══╝██║   ██║████╗ ████║" .. ui.c.reset,
        ui.c.bright_blue .. " ██║   ██║ ██║   ██║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║" .. ui.c.reset,
        ui.c.bright_blue .. " ██║▄▄ ██║ ██║   ██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║" .. ui.c.reset,
        ui.c.bright_magenta .. " ╚██████╔╝ ╚██████╔╝██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║" .. ui.c.reset,
        ui.c.bright_magenta .. "  ╚══▀▀═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝" .. ui.c.reset,
        ui.c.bright_yellow .. "           ★  L U A   A D V A N C E D   C A L C U L A T O R  ★" .. ui.c.reset,
        ui.c.bright_black ..  "               Версия 2.5 Pro • Научный • Графический • СУР" .. ui.c.reset,
    }
    return table.concat(b, "\n")
end

-- Рисование рамки вокруг текста (rounded box)
function ui.box(title, lines, customWidth, borderColor)
    local col = borderColor or ui.c.cyan
    local reset = ui.c.reset
    
    if type(lines) == "string" then
        local split = {}
        for line in lines:gmatch("[^\r\n]+") do
            table.insert(split, line)
        end
        lines = split
    end

    local maxLen = ui.visibleLen(title or "") + 4
    for _, l in ipairs(lines) do
        local lLen = ui.visibleLen(l)
        if lLen > maxLen then maxLen = lLen end
    end
    local w = customWidth or (maxLen + 4)
    if w < maxLen + 4 then w = maxLen + 4 end

    local out = {}
    
    -- Верхняя граница
    if title and #title > 0 then
        local tLen = ui.visibleLen(title)
        local leftDashes = 2
        local rightDashes = w - 4 - leftDashes - tLen
        if rightDashes < 1 then rightDashes = 1 end
        table.insert(out, col .. "╭" .. string.rep("─", leftDashes) .. reset ..
            " " .. ui.c.bold .. ui.c.bright_yellow .. title .. reset .. " " ..
            col .. string.rep("─", rightDashes) .. "╮" .. reset)
    else
        table.insert(out, col .. "╭" .. string.rep("─", w - 2) .. "╮" .. reset)
    end

    -- Содержимое
    for _, l in ipairs(lines) do
        local vis = ui.visibleLen(l)
        local pad = w - 4 - vis
        if pad < 0 then pad = 0 end
        table.insert(out, col .. "│ " .. reset .. l .. string.rep(" ", pad) .. col .. " │" .. reset)
    end

    -- Нижняя граница
    table.insert(out, col .. "╰" .. string.rep("─", w - 2) .. "╯" .. reset)

    return table.concat(out, "\n")
end

-- Информационная строка состояния (HUD)
function ui.statusBar(cfg, varCount, histCount)
    local angleStr = (cfg.angleMode == "deg") and (ui.c.bg_green .. " DEG " .. ui.c.reset) or (ui.c.bg_blue .. " RAD " .. ui.c.reset)
    local precStr = ui.c.bright_black .. "Точность: " .. ui.c.bright_cyan .. tostring(cfg.precision) .. ui.c.reset
    local varsStr = ui.c.bright_black .. "Переменных: " .. ui.c.bright_yellow .. tostring(varCount or 0) .. ui.c.reset
    local histStr = ui.c.bright_black .. "История: " .. ui.c.bright_magenta .. tostring(histCount or 0) .. ui.c.reset
    local modeStr = ui.c.bold .. ui.c.bright_white .. "[РЕЖИМ: " .. (cfg.modeName or "Стандарт") .. "]" .. ui.c.reset

    local sep = ui.c.bright_black .. " │ " .. ui.c.reset
    return angleStr .. " " .. modeStr .. sep .. precStr .. sep .. varsStr .. sep .. histStr
end

-- Вывод таблицы данных
function ui.table(headers, rows)
    local colWidths = {}
    for i, h in ipairs(headers) do
        colWidths[i] = ui.visibleLen(h)
    end

    for _, row in ipairs(rows) do
        for i, cell in ipairs(row) do
            local vLen = ui.visibleLen(tostring(cell))
            if not colWidths[i] or vLen > colWidths[i] then
                colWidths[i] = vLen
            end
        end
    end

    local out = {}
    local borderCol = ui.c.bright_blue
    local r = ui.c.reset

    -- Верхний разделитель
    local topParts = {}
    for _, w in ipairs(colWidths) do
        table.insert(topParts, string.rep("─", w + 2))
    end
    table.insert(out, borderCol .. "┌" .. table.concat(topParts, "┬") .. "┐" .. r)

    -- Заголовки
    local hParts = {}
    for i, h in ipairs(headers) do
        local pad = colWidths[i] - ui.visibleLen(h)
        table.insert(hParts, " " .. ui.c.bold .. ui.c.bright_cyan .. h .. r .. string.rep(" ", pad) .. " ")
    end
    table.insert(out, borderCol .. "│" .. r .. table.concat(hParts, borderCol .. "│" .. r) .. borderCol .. "│" .. r)

    -- Средний разделитель
    local midParts = {}
    for _, w in ipairs(colWidths) do
        table.insert(midParts, string.rep("─", w + 2))
    end
    table.insert(out, borderCol .. "├" .. table.concat(midParts, "┼") .. "┤" .. r)

    -- Строки
    for _, row in ipairs(rows) do
        local rParts = {}
        for i, w in ipairs(colWidths) do
            local cell = tostring(row[i] or "")
            local pad = w - ui.visibleLen(cell)
            if pad < 0 then pad = 0 end
            table.insert(rParts, " " .. cell .. string.rep(" ", pad) .. " ")
        end
        table.insert(out, borderCol .. "│" .. r .. table.concat(rParts, borderCol .. "│" .. r) .. borderCol .. "│" .. r)
    end

    -- Нижний разделитель
    local botParts = {}
    for _, w in ipairs(colWidths) do
        table.insert(botParts, string.rep("─", w + 2))
    end
    table.insert(out, borderCol .. "└" .. table.concat(botParts, "┴") .. "┘" .. r)

    return table.concat(out, "\n")
end

-- Красивый прогресс-бар
function ui.progressBar(current, total, width, label)
    width = width or 30
    local pct = math.min(1, math.max(0, current / total))
    local filled = math.floor(pct * width)
    local empty = width - filled
    local bar = ui.c.bright_green .. string.rep("█", filled) .. ui.c.bright_black .. string.rep("░", empty) .. ui.c.reset
    local percentStr = string.format("%3.0f%%", pct * 100)
    return string.format("%s [%s] %s%s%s", label or "", bar, ui.c.bright_yellow, percentStr, ui.c.reset)
end

-- Форматирование чисел
function ui.formatNumber(num, precision)
    if type(num) ~= "number" then return tostring(num) end
    if num ~= num then return "NaN (Не число)" end
    if num == math.huge then return "∞ (Плюс бесконечность)" end
    if num == -math.huge then return "-∞ (Минус бесконечность)" end
    
    -- Целые числа без лишней точки
    if math.floor(num) == num and math.abs(num) < 1e14 then
        return string.format("%d", num)
    end

    precision = precision or 6
    local str = string.format("%." .. precision .. "f", num)
    -- Убираем хвостовые нули после запятой/точки
    str = str:gsub("(%..-)0+$", "%1")
    str = str:gsub("%.$", "")
    return str
end

return ui
