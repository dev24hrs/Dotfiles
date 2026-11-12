-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- SPDX-License-Identifier: MIT
--
--- @module 'go.benchmark'
--- @description Go benchmark runner with Treesitter detection and a floating result window
--- @author dev24hrs <asang24dev@gmail.com>

local M = {}

local RUNNING_VAR = "go_benchmark_running"
local JOB_VAR = "go_benchmark_job"
local GENERATION_VAR = "go_benchmark_generation"

local benchmark_float = {
    win = nil,
    buf = nil,
}

-- =============================================================================
-- Shared state and helpers
-- =============================================================================

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Go Benchmark" })
end

local function is_running()
    return vim.g[RUNNING_VAR] == true
end

local function set_running(value)
    vim.g[RUNNING_VAR] = value
end

local function current_generation()
    return tonumber(vim.g[GENERATION_VAR]) or 0
end

local function next_generation()
    local generation = current_generation() + 1
    vim.g[GENERATION_VAR] = generation
    return generation
end

local function current_file()
    local file = vim.api.nvim_buf_get_name(0)

    if file == "" then
        notify("Current buffer has no file", vim.log.levels.ERROR)
        return nil
    end

    if vim.bo.filetype ~= "go" then
        notify("Current file is not a Go file", vim.log.levels.ERROR)
        return nil
    end

    file = vim.fn.fnamemodify(file, ":p")
    if vim.fn.filereadable(file) ~= 1 then
        notify("Current Go file is not readable", vim.log.levels.ERROR)
        return nil
    end

    return file
end

local function find_module_root(start_dir)
    local dir = vim.fn.resolve(start_dir)
    while true do
        if vim.fn.filereadable(dir .. "/go.mod") == 1 then
            return dir
        end

        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then
            return nil
        end
        dir = parent
    end
end

local function relative_to_root(path, root)
    if path == root then
        return "."
    end

    local prefix = root .. "/"
    if vim.startswith(path, prefix) then
        return path:sub(#prefix + 1)
    end
    return path
end

local function valid_benchmark_name(name)
    return name:match("^Benchmark[%w_]+$") ~= nil
end

local function valid_benchtime(benchtime)
    return benchtime == nil or benchtime == "" or benchtime:match("^[%d%.][%d%.a-zA-Z]*$") ~= nil
end

local function append_output(target, data)
    for _, line in ipairs(data or {}) do
        if line ~= "" then
            target[#target + 1] = line
        end
    end
end

-- =============================================================================
-- Treesitter and output parsing
-- =============================================================================

--- Detect the Go function under the cursor.
--- @return string|nil
local function current_function_name()
    if not vim.treesitter or not vim.treesitter.get_parser then
        return nil
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, "go")
    if not parser_ok or not parser then
        return nil
    end

    local parsed, trees = pcall(parser.parse, parser)
    if not parsed or not trees or not trees[1] then
        return nil
    end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1
    local node = trees[1]:root():named_descendant_for_range(row, col, row, col)

    while node do
        if node:type() == "function_declaration" then
            local name_nodes = node:field("name")
            if name_nodes and name_nodes[1] then
                local text_ok, name = pcall(vim.treesitter.get_node_text, name_nodes[1], bufnr)
                if text_ok then
                    return name
                end
            end
            return nil
        end
        node = node:parent()
    end

    return nil
end

local function parse_benchmark_output(output)
    local rows = {}

    for line in output:gmatch("[^\r\n]+") do
        local name, iterations, metrics = line:match("^%s*(%S+)%s+(%d+)%s+(.+)$")
        if name and vim.startswith(name, "Benchmark") then
            local ns_op = metrics:match("([%d%.]+)%s+ns/op")
            local bytes_op = metrics:match("([%d%.]+)%s+B/op")
            local allocs_op = metrics:match("([%d%.]+)%s+allocs/op")
            if ns_op then
                rows[#rows + 1] = {
                    name = name,
                    iterations = iterations,
                    ns_op = ns_op,
                    bytes_op = bytes_op or "-",
                    allocs_op = allocs_op or "-",
                    raw = line,
                }
            end
        end
    end

    return rows
end

-- =============================================================================
-- Floating result window
-- =============================================================================

local function close_benchmark_float()
    if benchmark_float.win and vim.api.nvim_win_is_valid(benchmark_float.win) then
        vim.api.nvim_win_close(benchmark_float.win, true)
    elseif benchmark_float.buf and vim.api.nvim_buf_is_valid(benchmark_float.buf) then
        pcall(vim.api.nvim_buf_delete, benchmark_float.buf, { force = true })
    end

    benchmark_float.win = nil
    benchmark_float.buf = nil
end

local function show_benchmark_float(result)
    close_benchmark_float()

    local lines = {
        "",
        "  Go Benchmark",
        string.format("  Package: %s", result.package_name),
        string.format("  Benchtime: %s", result.benchtime or "default"),
        "  " .. string.rep("─", 70),
    }

    if result.rows and #result.rows > 0 then
        for _, row in ipairs(result.rows) do
            lines[#lines + 1] = string.format("  %-28s %12s ns/op  %10s B/op  %8s allocs/op", row.name, row.ns_op, row.bytes_op, row.allocs_op)
        end
    else
        lines[#lines + 1] = result.success and "  No benchmark results found" or "  Benchmark failed"
        lines[#lines + 1] = ""
        for _, line in ipairs(result.output or {}) do
            lines[#lines + 1] = "  " .. line
        end
    end

    if result.success and result.rows and #result.rows > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "  q / <Esc>  close"
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "GoBenchmark"
    vim.bo[buf].modifiable = false

    local width = math.min(45, math.max(1, vim.o.columns - 4))
    local height = math.min(math.max(1, #lines), math.max(1, vim.o.lines - 4))
    local max_row = math.max(0, vim.o.lines - height)
    local max_col = math.max(0, vim.o.columns - width)

    local ok, win = pcall(vim.api.nvim_open_win, buf, false, {
        relative = "editor",
        width = width,
        height = height,
        row = math.min(math.max(0, math.floor(vim.o.lines * 0.1)), max_row),
        col = math.min(math.max(0, vim.o.columns - width - 2), max_col),
        style = "minimal",
        border = "rounded",
        title = " Go Benchmark ",
        title_pos = "center",
        noautocmd = true,
    })

    if not ok then
        vim.api.nvim_buf_delete(buf, { force = true })
        notify("Unable to open benchmark window: " .. tostring(win), vim.log.levels.ERROR)
        return
    end

    vim.keymap.set("n", "q", close_benchmark_float, {
        buffer = buf,
        silent = true,
        desc = "Close benchmark float",
    })
    vim.keymap.set("n", "<Esc>", close_benchmark_float, {
        buffer = buf,
        silent = true,
        desc = "Close benchmark float",
    })

    benchmark_float.win = win
    benchmark_float.buf = buf
end

-- =============================================================================
-- Benchmark execution
-- =============================================================================

local function run_benchmark(benchmark_name, package_name, benchtime)
    if is_running() then
        notify("A benchmark is already running", vim.log.levels.WARN)
        return
    end

    local file = current_file()
    if not file then
        return
    end

    if benchmark_name and not valid_benchmark_name(benchmark_name) then
        notify("Invalid benchmark name: " .. benchmark_name, vim.log.levels.ERROR)
        return
    end

    if not valid_benchtime(benchtime) then
        notify("Invalid benchtime: " .. tostring(benchtime), vim.log.levels.ERROR)
        return
    end

    if vim.fn.executable("go") ~= 1 then
        notify("go executable not found", vim.log.levels.ERROR)
        return
    end

    local source_dir = vim.fs.dirname(file) or "."
    local module_root = find_module_root(source_dir)
    if not module_root then
        notify("go.mod not found", vim.log.levels.ERROR)
        return
    end

    local package_arg = vim.trim(package_name or "")
    if package_arg == "" then
        local relative_dir = relative_to_root(source_dir, module_root)
        package_arg = relative_dir == "." and "./." or "./" .. relative_dir
    end

    local updated, update_error = pcall(vim.cmd.update)
    if not updated then
        notify("Unable to save current Go file: " .. tostring(update_error), vim.log.levels.ERROR)
        return
    end

    M.clear()
    local token = next_generation()
    local stdout = {}
    local stderr = {}
    local command = {
        "go",
        "test",
        "-run=^$",
        "-bench=" .. (benchmark_name and ("^" .. benchmark_name .. "$") or "."),
        "-benchmem",
        "-count=1",
    }
    if benchtime and benchtime ~= "" then
        command[#command + 1] = "-benchtime=" .. benchtime
    end
    command[#command + 1] = package_arg

    set_running(true)
    local job_id = vim.fn.jobstart(command, {
        cwd = module_root,
        on_stdout = function(_, data)
            append_output(stdout, data)
        end,
        on_stderr = function(_, data)
            append_output(stderr, data)
        end,
        on_exit = vim.schedule_wrap(function(_, exit_code, _)
            if token ~= current_generation() then
                return
            end

            set_running(false)
            vim.g[JOB_VAR] = nil

            local output = {}
            vim.list_extend(output, stdout)
            vim.list_extend(output, stderr)
            local rows = parse_benchmark_output(table.concat(stdout, "\n"))
            local success = exit_code == 0

            show_benchmark_float({
                success = success,
                rows = rows,
                output = output,
                package_name = package_arg,
                benchtime = benchtime,
            })

            if not success then
                notify("Benchmark failed", vim.log.levels.ERROR)
            elseif #rows == 0 then
                notify("No benchmark results found", vim.log.levels.WARN)
            end
        end),
    })

    if job_id <= 0 then
        set_running(false)
        vim.g[JOB_VAR] = nil
        next_generation()
        notify("Failed to start go benchmark", vim.log.levels.ERROR)
        return
    end

    vim.g[JOB_VAR] = job_id
end

function M.run_current(benchmark_name, benchtime)
    benchmark_name = benchmark_name and vim.trim(benchmark_name) or nil
    if not benchmark_name or benchmark_name == "" then
        benchmark_name = current_function_name()
    end

    if not benchmark_name then
        notify("Place the cursor inside a Benchmark function or provide its name", vim.log.levels.ERROR)
        return
    end

    run_benchmark(benchmark_name, nil, benchtime)
end

function M.run_all(package_name, benchtime)
    run_benchmark(nil, package_name, benchtime)
end

function M.clear()
    local job_id = tonumber(vim.g[JOB_VAR])
    if job_id and job_id > 0 then
        vim.fn.jobstop(job_id)
    end

    vim.g[JOB_VAR] = nil
    set_running(false)
    next_generation()
    close_benchmark_float()
end

-- =============================================================================
-- Commands and keymaps
-- =============================================================================

local function create_command(name, callback, opts)
    pcall(vim.api.nvim_del_user_command, name)
    vim.api.nvim_create_user_command(name, callback, opts)
end

create_command("GoBench", function(opts)
    local name = vim.trim(opts.args or "")
    M.run_current(name ~= "" and name or nil, nil)
end, {
    nargs = "?",
    desc = "Run the Go benchmark under the cursor",
})

create_command("GoBenchAll", function(opts)
    M.run_all(opts.args, nil)
end, {
    nargs = "?",
    desc = "Run all Go benchmarks in the current package",
})

create_command("GoBenchTime", function(opts)
    local benchtime = vim.trim(opts.args or "")
    if benchtime == "" then
        vim.ui.input({ prompt = "Benchtime: " }, function(input)
            if input and vim.trim(input) ~= "" then
                M.run_current(nil, vim.trim(input))
            end
        end)
        return
    end
    M.run_current(nil, benchtime)
end, {
    nargs = "?",
    desc = "Run the current Go benchmark for a custom duration",
})

create_command("GoBenchClear", function()
    M.clear()
end, {
    nargs = 0,
    desc = "Stop Go benchmark and close its result window",
})

vim.keymap.set("n", "<leader>gb", "<cmd>GoBench<CR>", {
    silent = true,
    buffer = true,
    desc = "[Go]: Run benchmark under cursor",
})
vim.keymap.set("n", "<leader>gB", "<cmd>GoBenchAll<CR>", {
    silent = true,
    buffer = true,
    desc = "[Go]: Run all benchmarks in package",
})

return M
