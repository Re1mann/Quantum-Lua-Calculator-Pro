--[[
  src/plotter.lua - Консольный ASCII/Unicode 2D построитель графиков функций
  Позволяет строить графики f(x) прямо в терминале с осями, сеткой и значениями!
--]]

local ui = require("src.ui")
local parser = require("src.parser")
local math_engine = require("src.math_engine")

local plotter = {}

function plotter.plot(funcExpr, xMin, xMax, width, height, ctx)
    xMin = tonumber(xMin) or -10
    xMax = tonumber(xMax) or 10
    if xMin >= xMax then
        error("xMin должен быть меньше xMax")
    end

    width = width or 65
    height = height or 21

    -- Контекст вычислений
    local evalCtx = {
        funcs = ctx and ctx.funcs or math_engine.functions,
        consts = ctx and ctx.consts or math_engine.constants,
        vars = {}
    }
    if ctx and ctx.vars then
        for k, v in pairs(ctx.vars) do evalCtx.vars[k] = v end
    end

    -- Вычисление функции в точках x
    local xs = {}
    local ys = {}
    local dx = (xMax - xMin) / (width - 1)
    local yMin, yMax = math.huge, -math.huge

    for col = 1, width do
        local x = xMin + (col - 1) * dx
        evalCtx.vars["x"] = x
        evalCtx.vars["X"] = x

        local success, val = pcall(parser.evaluate, funcExpr, evalCtx)
        if success and type(val) == "number" and val == val and math.abs(val) ~= math.huge then
            ys[col] = val
            if val < yMin then yMin = val end
            if val > yMax then yMax = val end
        else
            ys[col] = nil
        end
        xs[col] = x
    end

    if yMin == math.huge or yMax == -math.huge then
        error("Не удалось вычислить значения функции в заданном диапазоне (возможно, деление на ноль или вне области определения)")
    end

    -- Небольшой отступ по Y, если функция константа
    if yMin == yMax then
        yMin = yMin - 1
        yMax = yMax + 1
    else
        local pad = (yMax - yMin) * 0.05
        yMin = yMin - pad
        yMax = yMax + pad
    end

    -- Подготовка холста (сетка символов)
    local grid = {}
    for r = 1, height do
        grid[r] = {}
        for c = 1, width do
            grid[r][c] = " "
        end
    end

    -- Находим строки и столбцы для осей X (y=0) и Y (x=0)
    local zeroRow = nil
    if yMin <= 0 and yMax >= 0 then
        local ratio = (0 - yMin) / (yMax - yMin)
        zeroRow = height - math.floor(ratio * (height - 1))
    end

    local zeroCol = nil
    if xMin <= 0 and xMax >= 0 then
        local ratio = (0 - xMin) / (xMax - xMin)
        zeroCol = 1 + math.floor(ratio * (width - 1))
    end

    -- Рисуем ось X (горизонтальная)
    if zeroRow and zeroRow >= 1 and zeroRow <= height then
        for c = 1, width do
            grid[zeroRow][c] = "─"
        end
    end

    -- Рисуем ось Y (вертикальная)
    if zeroCol and zeroCol >= 1 and zeroCol <= width then
        for r = 1, height do
            if grid[r][zeroCol] == "─" then
                grid[r][zeroCol] = "┼"
            else
                grid[r][zeroCol] = "│"
            end
        end
    end

    -- Наносим точки функции
    for c = 1, width do
        local y = ys[c]
        if y ~= nil then
            local ratio = (y - yMin) / (yMax - yMin)
            local r = height - math.floor(ratio * (height - 1))
            if r >= 1 and r <= height then
                grid[r][c] = "●"
            end
        end
    end

    -- Формируем вывод в терминал с метками оси Y и цветным оформлением
    local lines = {}
    local labelWidth = 9

    table.insert(lines, ui.c.bright_magenta .. string.format("   График: y = %s", funcExpr) .. ui.c.reset)
    table.insert(lines, ui.c.bright_black .. string.format("   Диапазон X: [%.2f; %.2f] | Диапазон Y: [%.2f; %.2f]", xMin, xMax, yMin, yMax) .. ui.c.reset)
    table.insert(lines, "")

    for r = 1, height do
        -- Вычисление соответствующего значения Y для текущей строки
        local yVal = yMax - ((r - 1) / (height - 1)) * (yMax - yMin)
        local yLabel = ""
        if r == 1 or r == height or (zeroRow and r == zeroRow) or r == math.floor(height / 2) then
            yLabel = string.format("%8.2f ", yVal)
        else
            yLabel = string.rep(" ", labelWidth)
        end

        local rowChars = {}
        for c = 1, width do
            local ch = grid[r][c]
            if ch == "●" then
                table.insert(rowChars, ui.c.bright_yellow .. ui.c.bold .. "●" .. ui.c.reset)
            elseif ch == "┼" or ch == "│" or ch == "─" then
                table.insert(rowChars, ui.c.bright_black .. ch .. ui.c.reset)
            else
                table.insert(rowChars, ch)
            end
        end

        table.insert(lines, ui.c.cyan .. yLabel .. ui.c.reset .. table.concat(rowChars))
    end

    -- Метки по оси X
    local xLabelLine = string.rep(" ", labelWidth)
    local minXStr = string.format("%.2f", xMin)
    local maxXStr = string.format("%.2f", xMax)
    local midXStr = string.format("%.2f", (xMin + xMax) / 2)

    local spacing1 = math.floor(width / 2) - #minXStr - math.floor(#midXStr / 2)
    local spacing2 = width - #minXStr - spacing1 - #midXStr - #maxXStr
    if spacing1 < 1 then spacing1 = 1 end
    if spacing2 < 1 then spacing2 = 1 end

    xLabelLine = xLabelLine .. ui.c.bright_cyan .. minXStr .. string.rep(" ", spacing1) .. midXStr .. string.rep(" ", spacing2) .. maxXStr .. ui.c.reset
    table.insert(lines, xLabelLine)

    return table.concat(lines, "\n")
end

return plotter
