--[[
  =============================================================================
  QUANTUM LUA CALCULATOR PRO (Консольный инженерный и графический калькулятор)
  =============================================================================
  Авторский проект для колледжа (2 курс)
  Язык: Lua 5.3+ (включая Lua 5.4, 5.5 и LuaJIT)
  Особенности:
  - Рекурсивный нисходящий парсер с приоритетом операторов
  - Неявное умножение: 2x, 2(3+4), 3sin(x), 5pi
  - 2D ASCII-графики функций прямо в окне консоли
  - Решение уравнений (квадратные с комплексными корнями, СЛАУ 2х2, численный поиск корней)
  - Режим программиста с 32-битной битовой сеткой и конвертацией DEC/HEX/BIN/OCT
  - Конвертер единиц измерения (физика, данные, температура, время)
  - Матричный калькулятор (определители NxN, обратные матрицы, умножение)
  - Хранение переменных, журнал истории, экспорт сессии в файл
--]]

-- Подключение модулей
local ui = require("src.ui")
local math_engine = require("src.math_engine")
local parser = require("src.parser")
local plotter = require("src.plotter")
local solver = require("src.solver")
local programmer = require("src.programmer")
local units = require("src.units")
local matrix = require("src.matrix")
local history = require("src.history")
local help = require("src.help")
local interactive = require("src.interactive")

-- Состояние сессии
local session = {
    config = {
        angleMode = "deg", -- "deg" или "rad"
        precision = 6,
        modeName = "Научный",
    },
    vars = {},
}

-- Инициализация контекста вычислений
local function getContext()
    math_engine.config.angleMode = session.config.angleMode
    math_engine.config.precision = session.config.precision

    -- Обновляем переменные ans
    session.vars["ans"] = history.getAns(1) or 0
    session.vars["ans1"] = history.getAns(1) or 0
    session.vars["ans2"] = history.getAns(2) or 0
    session.vars["ans3"] = history.getAns(3) or 0

    return {
        funcs = math_engine.functions,
        consts = math_engine.constants,
        vars = session.vars,
    }
end

-- Подсчет количества пользовательских переменных (без ans)
local function getVarCount()
    local c = 0
    for k, _ in pairs(session.vars) do
        if not k:match("^ans%d*$") then
            c = c + 1
        end
    end
    return c
end

-- Обработка встроенных команд
local function handleCommand(cmdStr)
    local raw = cmdStr:match("^%s*(.-)%s*$")
    if #raw == 0 then return true end

    local cmd, args = raw:match("^([%a_][%w_]*)%s*(.*)$")
    cmd = (cmd or raw):lower()

    -- 1. Выход
    if cmd == "exit" or cmd == "quit" or cmd == "q" then
        print(ui.c.bright_yellow .. "\nСпасибо за использование Quantum Lua Calculator! До свидания.\n" .. ui.c.reset)
        return false

    -- 2. Очистка экрана
    elseif cmd == "clear" or cmd == "cls" then
        ui.clearScreen()
        print(ui.banner())
        print("")
        print(ui.statusBar(session.config, getVarCount(), #history.entries))
        print("")
        return true

    -- 3. Справка
    elseif cmd == "help" or cmd == "?" then
        args = (args or ""):lower():match("^%s*(.-)%s*$")
        if args == "math" then
            print(help.math())
        elseif args == "plot" then
            print(help.plot())
        elseif args == "units" then
            print(help.units())
        else
            print(help.general())
        end
        return true

    -- 4. Переключение градусов / радиан
    elseif cmd == "deg" then
        session.config.angleMode = "deg"
        print(ui.c.bright_green .. "✓ Режим тригонометрии установлен в ГРАДУСЫ (DEG)" .. ui.c.reset)
        return true
    elseif cmd == "rad" then
        session.config.angleMode = "rad"
        print(ui.c.bright_blue .. "✓ Режим тригонометрии установлен в РАДИАНЫ (RAD)" .. ui.c.reset)
        return true

    -- 5. Точность (кол-во знаков)
    elseif cmd == "prec" or cmd == "precision" then
        local p = tonumber(args)
        if p and p >= 0 and p <= 16 then
            session.config.precision = math.floor(p)
            print(ui.c.bright_green .. "✓ Точность вывода установлена на " .. session.config.precision .. " знаков" .. ui.c.reset)
        else
            print(ui.c.bright_red .. "Использование: prec <0-16>" .. ui.c.reset)
        end
        return true

    -- 6. Просмотр переменных
    elseif cmd == "vars" then
        local rows = {}
        for k, v in pairs(session.vars) do
            if not k:match("^ans%d*$") then
                table.insert(rows, { ui.c.bright_yellow .. k .. ui.c.reset, ui.c.bright_cyan .. ui.formatNumber(v, session.config.precision) .. ui.c.reset })
            end
        end
        if #rows == 0 then
            print(ui.c.bright_black .. "Нет сохраненных переменных. Пример создания: x = 42" .. ui.c.reset)
        else
            print(ui.box("ПОЛЬЗОВАТЕЛЬСКИЕ ПЕРЕМЕННЫЕ", ui.table({ "Имя", "Значение" }, rows), 45, ui.c.bright_yellow))
        end
        return true

    -- 7. История вычислений
    elseif cmd == "history" or cmd == "hist" then
        local count = tonumber(args) or 10
        print(history.show(count))
        return true

    -- 8. Экспорт сессии
    elseif cmd == "export" then
        local fName = (args and #args > 0) and args or nil
        local ok, savedPath = pcall(history.exportToFile, fName)
        if ok then
            print(ui.c.bright_green .. "✓ История успешно экспортирована в файл: " .. savedPath .. ui.c.reset)
        else
            print(ui.c.bright_red .. "Ошибка экспорта: " .. tostring(savedPath) .. ui.c.reset)
        end
        return true

    -- 9. Интерактивное меню
    elseif cmd == "menu" then
        interactive.menu(getContext())
        return true

    -- 10. Построение графика в консоли
    elseif cmd == "plot" then
        if not args or #args == 0 then
            print(ui.c.bright_red .. "Использование: plot <функция_от_x> [x_мин] [x_макс]\nПример: plot sin(x) -3.14 3.14" .. ui.c.reset)
            return true
        end
        local funcStr, minS, maxS = args:match("^(.-)%s+([%+%-]?%d*%.?%d+)%s+([%+%-]?%d*%.?%d+)%s*$")
        if not funcStr then
            funcStr = args
            minS, maxS = -10, 10
        end
        local ok, plotStr = pcall(plotter.plot, funcStr, tonumber(minS), tonumber(maxS), 65, 19, getContext())
        if ok then
            print("")
            print(plotStr)
        else
            print(ui.c.bright_red .. "Ошибка построения графика: " .. tostring(plotStr) .. ui.c.reset)
        end
        return true

    -- 11. Решение уравнений
    elseif cmd == "solve" then
        local subCmd, subArgs = (args or ""):match("^([%w_]+)%s*(.*)$")
        subCmd = (subCmd or ""):lower()

        if subCmd == "quadratic" or subCmd == "quad" then
            local a, b, c = subArgs:match("^([%+%-]?%d*%.?%d+)%s+([%+%-]?%d*%.?%d+)%s+([%+%-]?%d*%.?%d+)$")
            if not a then
                a, b = subArgs:match("^([%+%-]?%d*%.?%d+)%s+([%+%-]?%d*%.?%d+)$")
                c = 0
            end
            if a then
                local ok, res = pcall(solver.solveQuadratic, a, b, c)
                if ok then
                    print(ui.box(res.title, res.steps, 70, ui.c.bright_green))
                    if type(res.roots[1]) == "number" then
                        session.vars["ans"] = res.roots[1]
                        history.add(string.format("solve quadratic %s %s %s", a, b, c), res.roots[1])
                    end
                else
                    print(ui.c.bright_red .. "Ошибка: " .. tostring(res) .. ui.c.reset)
                end
            else
                print(ui.c.bright_red .. "Использование: solve quadratic <a> <b> <c>\nПример: solve quadratic 1 -5 6" .. ui.c.reset)
            end
            return true

        elseif subCmd == "2x2" then
            local a1, b1, c1, a2, b2, c2 = subArgs:match("^([%+%-]?%d*%.?%d+)%s+([%+%-]?%d*%.?%d+)%s+([%+%-]?%d*%.?%d+)%s+([%+%-]?%d*%.?%d+)%s+([%+%-]?%d*%.?%d+)%s+([%+%-]?%d*%.?%d+)$")
            if a1 and b1 and c1 and a2 and b2 and c2 then
                local ok, res = pcall(solver.solveLinear2x2, a1, b1, c1, a2, b2, c2)
                if ok then
                    print(ui.box(res.title, res.steps, 70, ui.c.bright_green))
                    if res.solution then
                        session.vars["x"] = res.solution.x
                        session.vars["y"] = res.solution.y
                    end
                else
                    print(ui.c.bright_red .. "Ошибка: " .. tostring(res) .. ui.c.reset)
                end
            else
                print(ui.c.bright_red .. "Использование: solve 2x2 a1 b1 c1 a2 b2 c2\nПример: solve 2x2 2 1 5 1 -1 1" .. ui.c.reset)
            end
            return true

        elseif subCmd == "root" then
            local expr, x0, x1 = subArgs:match("^(.-)%s+([%+%-]?%d*%.?%d+)%s+([%+%-]?%d*%.?%d+)$")
            if not expr then
                expr = subArgs
                x0, x1 = 0, 1
            end
            if #expr > 0 then
                local ok, res = pcall(solver.solveRoot, expr, x0, x1, 100, 1e-7, getContext())
                if ok then
                    print(ui.box(res.title, res.steps, 75, ui.c.bright_green))
                    session.vars["ans"] = res.root
                    history.add("solve root " .. expr, res.root)
                else
                    print(ui.c.bright_red .. "Ошибка: " .. tostring(res) .. ui.c.reset)
                end
            else
                print(ui.c.bright_red .. "Использование: solve root <выражение> [x0] [x1]\nПример: solve root x^3-2x-5 2 3" .. ui.c.reset)
            end
            return true
        else
            print(ui.c.bright_red .. "Неизвестный тип уравнения. Доступны: solve quadratic, solve 2x2, solve root" .. ui.c.reset)
            return true
        end

    -- 12. Режим программиста / биты
    elseif cmd == "base" or cmd == "inspect" or cmd == "bin" or cmd == "hex" then
        local num = tonumber(args)
        if not num and args then
            if args:match("^0[xX]") then num = tonumber(args:sub(3), 16)
            elseif args:match("^0[bB]") then num = tonumber(args:sub(3), 2)
            end
        end
        if num then
            print(ui.box("ИНСПЕКТОР БИТОВ", programmer.inspect(num), 75, ui.c.bright_magenta))
        else
            print(ui.c.bright_red .. "Использование: base <число>\nПример: base 255 или base 0x1A" .. ui.c.reset)
        end
        return true

    -- 13. Конвертер величин
    elseif cmd == "convert" or raw:find("%s+to%s+") or raw:find("%s+->%s+") or raw:find("%s+в%s+") then
        local ok, res = pcall(units.parseAndConvert, raw)
        if ok then
            local lines = {
                string.format("Категория : %s", res.category),
                string.format("Исходное  : %s %s", ui.c.bright_yellow .. ui.formatNumber(res.fromVal, session.config.precision) .. ui.c.reset, res.fromUnit),
                string.format("Результат : %s %s", ui.c.bold .. ui.c.bright_green .. ui.formatNumber(res.toVal, session.config.precision) .. ui.c.reset, res.toUnit),
            }
            print(ui.box("КОНВЕРТАЦИЯ ВЕЛИЧИН", lines, 60, ui.c.bright_green))
            session.vars["ans"] = res.toVal
            history.add(raw, res.toVal)
        else
            print(ui.c.bright_red .. "Ошибка конвертации: " .. tostring(res) .. ui.c.reset)
        end
        return true

    -- 14. Матричный калькулятор
    elseif cmd == "matrix" then
        if #args == 0 then
            interactive.matrixMenu()
        else
            print(ui.c.bright_cyan .. "Для работы с матрицами введите команду 'matrix' без аргументов для входа в меню." .. ui.c.reset)
        end
        return true
    end

    -- Не специальная команда: проверяем присваивание или вычисляем выражение!
    local varName, exprToEval = parser.checkAssignment(raw)
    local ctx = getContext()

    local success, result = pcall(parser.evaluate, exprToEval, ctx)
    if success then
        if varName then
            session.vars[varName] = result
            session.vars["ans"] = result
            history.add(exprToEval, result, varName)
            print(string.format("%s%s%s = %s%s%s", ui.c.bold .. ui.c.bright_yellow, varName, ui.c.reset, ui.c.bold .. ui.c.bright_green, ui.formatNumber(result, session.config.precision), ui.c.reset))
        else
            session.vars["ans"] = result
            history.add(raw, result)
            local formatted = ui.formatNumber(result, session.config.precision)
            print(string.format("%s%s%s", ui.c.bold .. ui.c.bright_green .. "➔ ", formatted, ui.c.reset))
        end
    else
        print(string.format("%s[ОШИБКА]%s %s", ui.c.bold .. ui.c.bright_red, ui.c.reset, tostring(result)))
    end

    return true
end

-- Обработка аргументов командной строки при вызове: lua main.lua "..."
local function handleCliArgs(argList)
    if not argList or #argList == 0 then
        return false -- запускаем интерактивный режим
    end

    local first = argList[1]
    if first == "-h" or first == "--help" then
        print(ui.banner())
        print(help.general())
        return true
    elseif first == "-p" or first == "--plot" then
        local expr = argList[2] or "sin(x)"
        local minVal = tonumber(argList[3]) or -10
        local maxVal = tonumber(argList[4]) or 10
        print(plotter.plot(expr, minVal, maxVal, 65, 19, getContext()))
        return true
    elseif first == "-s" or first == "--solve" then
        local rest = {}
        for i = 2, #argList do table.insert(rest, argList[i]) end
        handleCommand("solve " .. table.concat(rest, " "))
        return true
    else
        -- Простое вычисление переданного выражения
        local expr = table.concat(argList, " ")
        local ctx = getContext()
        local ok, res = pcall(parser.evaluate, expr, ctx)
        if ok then
            print(ui.formatNumber(res, session.config.precision))
        else
            io.stderr:write(string.format("Ошибка: %s\n", tostring(res)))
            os.exit(1)
        end
        return true
    end
end

-- Основной цикл REPL
local function main()
    -- Проверка CLI параметров
    if handleCliArgs(arg) then
        return
    end

    -- Запуск полноценного интерактивного калькулятора
    ui.clearScreen()
    print(ui.banner())
    print("")
    print(ui.box("БЫСТРЫЙ СТАРТ", {
        "Введите любое математическое выражение: 2 + 2, 5!, sin(45), 2(3+4)",
        "Команды: help (справка), menu (интерактивный режим), plot (график),",
        "solve (уравнения), base (программист), convert (конвертер), exit (выход)"
    }, 76, ui.c.bright_cyan))
    print("")

    local running = true
    while running do
        print(ui.statusBar(session.config, getVarCount(), #history.entries))
        io.write(ui.c.bold .. ui.c.bright_cyan .. "⚡ [calc] > " .. ui.c.reset)
        io.flush()

        local input = io.read()
        if not input then
            -- Ctrl+D или EOF
            print("")
            break
        end
        input = input:gsub("^\239\187\191", "")

        local shouldContinue = handleCommand(input)
        if not shouldContinue then
            break
        end
        print("")
    end
end

main()
