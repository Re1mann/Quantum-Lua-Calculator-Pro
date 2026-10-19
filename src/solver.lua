--[[
  src/solver.lua - Модуль решения алгебраических уравнений и систем
  Поддержка:
  1. Квадратные уравнения ax² + bx + c = 0 (с шагами решения и комплексными корнями)
  2. Системы линейных уравнений 2x2 и 3x3 (Метод Крамера / Гаусса)
  3. Численный поиск корней для произвольных уравнений f(x) = 0 (Метод секущих/Ньютона)
--]]

local ui = require("src.ui")
local parser = require("src.parser")
local math_engine = require("src.math_engine")

local solver = {}

-- Решение квадратного уравнения ax² + bx + c = 0
function solver.solveQuadratic(a, b, c)
    a = tonumber(a)
    b = tonumber(b) or 0
    c = tonumber(c) or 0

    if not a or a == 0 then
        if b ~= 0 then
            local x = -c / b
            return {
                title = "Линейное уравнение (a = 0)",
                steps = {
                    string.format("Уравнение: %s*x + (%s) = 0", b, c),
                    string.format("x = -c / b = -(%s) / (%s) = %s", c, b, ui.formatNumber(x, 6))
                },
                roots = { x }
            }
        else
            error("Коэффициенты 'a' и 'b' не могут быть одновременно равны нулю!")
        end
    end

    local d = b * b - 4 * a * c
    local steps = {
        string.format("Уравнение: (%s)x² + (%s)x + (%s) = 0", a, b, c),
        string.format("Дискриминант: D = b² - 4ac = (%s)² - 4*(%s)*(%s) = %s", b, a, c, ui.formatNumber(d, 6))
    }

    local roots = {}
    if d > 0 then
        local sqrtD = math.sqrt(d)
        local x1 = (-b + sqrtD) / (2 * a)
        local x2 = (-b - sqrtD) / (2 * a)
        table.insert(steps, string.format("√D = %s", ui.formatNumber(sqrtD, 6)))
        table.insert(steps, string.format("x₁ = (-b + √D) / 2a = (-(%s) + %s) / (2*%s) = %s", b, ui.formatNumber(sqrtD, 4), a, ui.formatNumber(x1, 6)))
        table.insert(steps, string.format("x₂ = (-b - √D) / 2a = (-(%s) - %s) / (2*%s) = %s", b, ui.formatNumber(sqrtD, 4), a, ui.formatNumber(x2, 6)))
        roots = { x1, x2 }
    elseif math.abs(d) < 1e-12 then
        local x = -b / (2 * a)
        table.insert(steps, "D = 0, один действительный корень кратности 2:")
        table.insert(steps, string.format("x = -b / 2a = -(%s) / (2*%s) = %s", b, a, ui.formatNumber(x, 6)))
        roots = { x }
    else
        -- Комплексные корни
        local realPart = -b / (2 * a)
        local imagPart = math.sqrt(-d) / (2 * math.abs(a))
        table.insert(steps, "D < 0, действительных корней нет. Два комплексно-сопряженных корня:")
        local x1Str = string.format("%s + %si", ui.formatNumber(realPart, 6), ui.formatNumber(imagPart, 6))
        local x2Str = string.format("%s - %si", ui.formatNumber(realPart, 6), ui.formatNumber(imagPart, 6))
        table.insert(steps, string.format("x₁ = %s", x1Str))
        table.insert(steps, string.format("x₂ = %s", x2Str))
        roots = { x1Str, x2Str }
    end

    return {
        title = "Решение квадратного уравнения",
        d = d,
        steps = steps,
        roots = roots
    }
end

-- Решение СЛАУ 2x2:
-- a1*x + b1*y = c1
-- a2*x + b2*y = c2
function solver.solveLinear2x2(a1, b1, c1, a2, b2, c2)
    local det = a1 * b2 - a2 * b1
    local detX = c1 * b2 - c2 * b1
    local detY = a1 * c2 - a2 * c1

    local steps = {
        string.format("Система:"),
        string.format(" ┌ (%s)x + (%s)y = %s", a1, b1, c1),
        string.format(" └ (%s)x + (%s)y = %s", a2, b2, c2),
        string.format("Главный определитель: Δ = (%s)*(%s) - (%s)*(%s) = %s", a1, b2, a2, b1, ui.formatNumber(det, 6)),
        string.format("Определитель Δx = (%s)*(%s) - (%s)*(%s) = %s", c1, b2, c2, b1, ui.formatNumber(detX, 6)),
        string.format("Определитель Δy = (%s)*(%s) - (%s)*(%s) = %s", a1, c2, a2, c1, ui.formatNumber(detY, 6)),
    }

    if math.abs(det) < 1e-12 then
        if math.abs(detX) < 1e-12 and math.abs(detY) < 1e-12 then
            table.insert(steps, "Δ = 0 и Δx = Δy = 0: Система имеет бесконечно много решений")
            return { title = "СЛАУ 2x2", steps = steps, status = "infinite" }
        else
            table.insert(steps, "Δ = 0, но определители по переменным ≠ 0: Система несовместна (решений нет)")
            return { title = "СЛАУ 2x2", steps = steps, status = "none" }
        end
    end

    local x = detX / det
    local y = detY / det

    table.insert(steps, string.format("x = Δx / Δ = %s / %s = %s", ui.formatNumber(detX, 4), ui.formatNumber(det, 4), ui.formatNumber(x, 6)))
    table.insert(steps, string.format("y = Δy / Δ = %s / %s = %s", ui.formatNumber(detY, 4), ui.formatNumber(det, 4), ui.formatNumber(y, 6)))

    return {
        title = "СЛАУ 2x2 (Метод Крамера)",
        steps = steps,
        solution = { x = x, y = y }
    }
end

-- Численное нахождение корня функции f(x) = 0 методом секущих (Secant method)
function solver.solveRoot(exprStr, x0, x1, maxIter, tol, ctx)
    x0 = tonumber(x0) or 0
    x1 = tonumber(x1) or 1
    if x0 == x1 then x1 = x0 + 1 end
    maxIter = maxIter or 100
    tol = tol or 1e-7

    local evalCtx = {
        funcs = ctx and ctx.funcs or math_engine.functions,
        consts = ctx and ctx.consts or math_engine.constants,
        vars = {}
    }
    if ctx and ctx.vars then
        for k, v in pairs(ctx.vars) do evalCtx.vars[k] = v end
    end

    local function f(xVal)
        evalCtx.vars["x"] = xVal
        evalCtx.vars["X"] = xVal
        return parser.evaluate(exprStr, evalCtx)
    end

    local y0 = f(x0)
    local y1 = f(x1)

    local steps = {
        string.format("Поиск корня для: f(x) = %s = 0", exprStr),
        string.format("Метод секущих. Начальные приближения: x₀ = %s, x₁ = %s", x0, x1)
    }

    local xCur = x1
    local iter = 0

    while iter < maxIter do
        iter = iter + 1
        if math.abs(y1 - y0) < 1e-15 then
            break
        end

        local xNext = x1 - y1 * (x1 - x0) / (y1 - y0)
        local yNext = f(xNext)

        if math.abs(xNext - x1) < tol or math.abs(yNext) < tol then
            xCur = xNext
            table.insert(steps, string.format("Итерация %d: найдено решение x ≈ %s с точностью |f(x)| = %.2e", iter, ui.formatNumber(xNext, 8), math.abs(yNext)))
            return {
                title = "Численное решение уравнения f(x) = 0",
                root = xNext,
                iterations = iter,
                steps = steps,
                value = yNext
            }
        end

        x0, y0 = x1, y1
        x1, y1 = xNext, yNext
        xCur = xNext
    end

    table.insert(steps, string.format("Достигнут предел итераций (%d). Приближенное значение x ≈ %s", maxIter, ui.formatNumber(xCur, 6)))
    return {
        title = "Численное решение (достигнут лимит)",
        root = xCur,
        iterations = iter,
        steps = steps,
        value = f(xCur)
    }
end

return solver
