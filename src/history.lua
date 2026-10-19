--[[
  src/history.lua - История вычислений, хранение сессии и экспорт результатов
--]]

local ui = require("src.ui")

local history = {}
history.entries = {}

-- Добавление записи в историю
function history.add(expr, result, varAssigned)
    local entry = {
        id = #history.entries + 1,
        time = os.date("%H:%M:%S"),
        expr = expr,
        result = result,
        var = varAssigned
    }
    table.insert(history.entries, entry)
    return entry
end

-- Получение N-го предыдущего ответа (1 = самый последний, 2 = предпоследний)
function history.getAns(offset)
    offset = offset or 1
    local idx = #history.entries - offset + 1
    if idx >= 1 and history.entries[idx] then
        return history.entries[idx].result
    end
    return nil
end

-- Очистка истории
function history.clear()
    history.entries = {}
end

-- Отображение истории в виде красивой таблицы
function history.show(count)
    if #history.entries == 0 then
        return ui.c.bright_black .. "История пуста." .. ui.c.reset
    end

    count = count or 10
    local startIdx = math.max(1, #history.entries - count + 1)

    local headers = { "#", "Время", "Выражение", "Результат" }
    local rows = {}

    for i = startIdx, #history.entries do
        local e = history.entries[i]
        local resStr
        if type(e.result) == "number" then
            resStr = ui.c.bright_green .. ui.formatNumber(e.result, 6) .. ui.c.reset
        else
            resStr = tostring(e.result)
        end

        local exprStr = e.expr
        if e.var then
            exprStr = ui.c.bright_yellow .. e.var .. ui.c.reset .. " = " .. exprStr
        end

        table.insert(rows, {
            ui.c.bright_cyan .. tostring(e.id) .. ui.c.reset,
            ui.c.bright_black .. e.time .. ui.c.reset,
            exprStr,
            resStr
        })
    end

    local tbl = ui.table(headers, rows)
    return ui.box("ИСТОРИЯ ВЫЧИСЛЕНИЙ (Последние " .. tostring(#rows) .. ")", tbl, nil, ui.c.bright_magenta)
end

-- Экспорт в текстовый файл
function history.exportToFile(filename)
    filename = filename or ("calc_history_" .. os.date("%Y%m%d_%H%M%S") .. ".txt")
    local f, err = io.open(filename, "w")
    if not f then
        error("Не удалось открыть файл для записи: " .. tostring(err))
    end

    f:write("=====================================================\n")
    f:write("   ЖУРНАЛ ВЫЧИСЛЕНИЙ - QUANTUM LUA CALCULATOR PRO\n")
    f:write("   Дата экспорта: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    f:write("=====================================================\n\n")

    for _, e in ipairs(history.entries) do
        local line = string.format("[%s] #%03d : %s = %s\n", e.time, e.id, (e.var and (e.var .. " = ") or "") .. e.expr, tostring(e.result))
        f:write(line)
    end

    f:write("\nВсего операций: " .. #history.entries .. "\n")
    f:close()
    return filename
end

return history
