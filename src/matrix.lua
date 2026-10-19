--[[
  src/matrix.lua - Модуль матричной алгебры
  Поддержка:
  - Сложение, вычитание, умножение матриц
  - Умножение на скаляр
  - Транспонирование, след (Trace)
  - Определитель det(A) произвольного размера NxN
  - Обратная матрица inv(A) (метод Гаусса-Жордана)
  - Красивая псевдографическая отрисовка матриц в консоли
--]]

local ui = require("src.ui")

local matrix = {}

-- Создание новой матрицы N x M
function matrix.new(rows, cols, initVal)
    local m = { rows = rows, cols = cols }
    for r = 1, rows do
        m[r] = {}
        for c = 1, cols do
            m[r][c] = initVal or 0
        end
    end
    setmetatable(m, { __tostring = matrix.toString })
    return m
end

-- Клонирование матрицы
function matrix.clone(m)
    local res = matrix.new(m.rows, m.cols)
    for r = 1, m.rows do
        for c = 1, m.cols do
            res[r][c] = m[r][c]
        end
    end
    return res
end

-- Парсер матрицы из строки:
-- "[1 2; 3 4]" или "[[1, 2], [3, 4]]" или "1,2 ; 3,4"
function matrix.parse(str)
    -- Убираем внешние скобки [ ... ]
    local clean = str:gsub("^%s*%[%s*", ""):gsub("%s*%]%s*$", "")
    
    local rows = {}
    -- Разбиваем по строкам (разделитель ';' или вложенные скобки)
    if clean:find("%[") then
        for rowPart in clean:gmatch("%[%s*([^%]]+)%s*%]") do
            local rVals = {}
            for num in rowPart:gmatch("[^,%s]+") do
                local n = tonumber(num)
                if not n then error("Некорректное число в матрице: " .. num) end
                table.insert(rVals, n)
            end
            table.insert(rows, rVals)
        end
    else
        for rowPart in clean:gmatch("[^;]+") do
            local rVals = {}
            for num in rowPart:gmatch("[^,%s]+") do
                local n = tonumber(num)
                if not n then error("Некорректное число в матрице: " .. num) end
                table.insert(rVals, n)
            end
            if #rVals > 0 then
                table.insert(rows, rVals)
            end
        end
    end

    if #rows == 0 then error("Пустая матрица!") end
    local cols = #rows[1]
    for r = 2, #rows do
        if #rows[r] ~= cols then
            error(string.format("Несоответствие размеров: строка %d содержит %d элементов (ожидалось %d)", r, #rows[r], cols))
        end
    end

    local m = matrix.new(#rows, cols)
    for r = 1, #rows do
        for c = 1, cols do
            m[r][c] = rows[r][c]
        end
    end
    return m
end

-- Красивый вывод матрицы в консоли
function matrix.toString(m, prec)
    prec = prec or 4
    local formatted = {}
    local colWidths = {}

    for c = 1, m.cols do colWidths[c] = 0 end

    for r = 1, m.rows do
        formatted[r] = {}
        for c = 1, m.cols do
            local s = ui.formatNumber(m[r][c], prec)
            formatted[r][c] = s
            if #s > colWidths[c] then
                colWidths[c] = #s
            end
        end
    end

    local lines = {}
    for r = 1, m.rows do
        local rowParts = {}
        for c = 1, m.cols do
            local s = formatted[r][c]
            local pad = colWidths[c] - #s
            table.insert(rowParts, string.rep(" ", pad) .. s)
        end
        local content = table.concat(rowParts, "   ")
        local lChar, rChar = "│", "│"
        if m.rows == 1 then
            lChar, rChar = "[", "]"
        elseif r == 1 then
            lChar, rChar = "┌", "┐"
        elseif r == m.rows then
            lChar, rChar = "└", "┘"
        end
        table.insert(lines, ui.c.bright_cyan .. lChar .. " " .. ui.c.reset .. content .. ui.c.bright_cyan .. " " .. rChar .. ui.c.reset)
    end

    return table.concat(lines, "\n")
end

-- Сложение матриц
function matrix.add(a, b)
    if a.rows ~= b.rows or a.cols ~= b.cols then
        error(string.format("Размеры матриц для сложения должны совпадать (%dx%d != %dx%d)", a.rows, a.cols, b.rows, b.cols))
    end
    local res = matrix.new(a.rows, a.cols)
    for r = 1, a.rows do
        for c = 1, a.cols do
            res[r][c] = a[r][c] + b[r][c]
        end
    end
    return res
end

-- Вычитание матриц
function matrix.sub(a, b)
    if a.rows ~= b.rows or a.cols ~= b.cols then
        error(string.format("Размеры матриц для вычитания должны совпадать (%dx%d != %dx%d)", a.rows, a.cols, b.rows, b.cols))
    end
    local res = matrix.new(a.rows, a.cols)
    for r = 1, a.rows do
        for c = 1, a.cols do
            res[r][c] = a[r][c] - b[r][c]
        end
    end
    return res
end

-- Умножение матриц или умножение на скаляр
function matrix.mul(a, b)
    -- Если b скаляр
    if type(b) == "number" then
        local res = matrix.new(a.rows, a.cols)
        for r = 1, a.rows do
            for c = 1, a.cols do
                res[r][c] = a[r][c] * b
            end
        end
        return res
    end
    -- Если a скаляр
    if type(a) == "number" then
        return matrix.mul(b, a)
    end

    -- Матричное умножение
    if a.cols ~= b.rows then
        error(string.format("Число столбцов первой матрицы (%d) должно равняться числу строк второй (%d)", a.cols, b.rows))
    end

    local res = matrix.new(a.rows, b.cols)
    for r = 1, a.rows do
        for c = 1, b.cols do
            local s = 0
            for k = 1, a.cols do
                s = s + a[r][k] * b[k][c]
            end
            res[r][c] = s
        end
    end
    return res
end

-- Транспонирование
function matrix.transpose(m)
    local res = matrix.new(m.cols, m.rows)
    for r = 1, m.rows do
        for c = 1, m.cols do
            res[c][r] = m[r][c]
        end
    end
    return res
end

-- След матрицы (Trace)
function matrix.trace(m)
    if m.rows ~= m.cols then
        error("След определен только для квадратных матриц")
    end
    local tr = 0
    for i = 1, m.rows do
        tr = tr + m[i][i]
    end
    return tr
end

-- Определитель матрицы NxN методом прямого хода Гаусса
function matrix.det(m)
    if m.rows ~= m.cols then
        error("Определитель определен только для квадратных матриц")
    end
    local n = m.rows
    if n == 1 then return m[1][1] end
    if n == 2 then return m[1][1] * m[2][2] - m[1][2] * m[2][1] end

    -- Клон для исключения Гаусса
    local a = matrix.clone(m)
    local detVal = 1
    local sign = 1

    for col = 1, n do
        -- Поиск главного элемента
        local pivotRow = col
        local maxVal = math.abs(a[col][col])
        for r = col + 1, n do
            if math.abs(a[r][col]) > maxVal then
                maxVal = math.abs(a[r][col])
                pivotRow = r
            end
        end

        if maxVal < 1e-13 then
            return 0
        end

        if pivotRow ~= col then
            -- Перестановка строк меняет знак определителя
            a[col], a[pivotRow] = a[pivotRow], a[col]
            sign = -sign
        end

        local pivot = a[col][col]
        detVal = detVal * pivot

        for r = col + 1, n do
            local factor = a[r][col] / pivot
            for c = col, n do
                a[r][c] = a[r][c] - factor * a[col][c]
            end
        end
    end

    return sign * detVal
end

-- Обратная матрица методом Гаусса-Жордана
function matrix.inv(m)
    if m.rows ~= m.cols then
        error("Обратная матрица существует только для квадратных матриц")
    end
    local n = m.rows
    local d = matrix.det(m)
    if math.abs(d) < 1e-12 then
        error("Матрица вырождена (det = 0), обратной матрицы не существует!")
    end

    -- Расширенная матрица [A | I]
    local aug = matrix.new(n, 2 * n)
    for r = 1, n do
        for c = 1, n do
            aug[r][c] = m[r][c]
            aug[r][c + n] = (r == c) and 1 or 0
        end
    end

    -- Прямой и обратный ход Гаусса-Жордана
    for col = 1, n do
        -- Выбор ведущего элемента
        local pivotRow = col
        local maxVal = math.abs(aug[col][col])
        for r = col + 1, n do
            if math.abs(aug[r][col]) > maxVal then
                maxVal = math.abs(aug[r][col])
                pivotRow = r
            end
        end

        aug[col], aug[pivotRow] = aug[pivotRow], aug[col]

        local pivot = aug[col][col]
        for c = 1, 2 * n do
            aug[col][c] = aug[col][c] / pivot
        end

        for r = 1, n do
            if r ~= col then
                local factor = aug[r][col]
                for c = 1, 2 * n do
                    aug[r][c] = aug[r][c] - factor * aug[col][c]
                end
            end
        end
    end

    -- Извлечение правой части [I | A^-1]
    local invM = matrix.new(n, n)
    for r = 1, n do
        for c = 1, n do
            invM[r][c] = aug[r][c + n]
        end
    end

    return invM
end

return matrix
