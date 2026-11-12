-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- SPDX-License-Identifier: MIT
--
--- @module 'go.coverage'
--- @description test-coverage: sign column + floating stats window
--- @author dev24hrs <asang24dev@gmail.com>

local M = {}

-- =============================================================================
-- Coverage — go test -coverprofile + sign column + float window
-- =============================================================================

-- Sign group used for all coverage signs (string, not namespace).
local COVERAGE_SIGN_GROUP = "go-coverage"
local RUNNING_VAR = "go_coverage_running"
local JOB_VAR = "go_coverage_job"
local PROFILE_VAR = "go_coverage_profile"
local GENERATION_VAR = "go_coverage_generation"

--- Coverage float window state (singleton).
local coverage_float = {
    win = nil,
    buf = nil,
}

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Go Coverage" })
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

local function remove_profile(profile_path)
    if profile_path and profile_path ~= "" then
        vim.fn.delete(profile_path)
    end
end

local function append_job_output(target, data)
    for _, line in ipairs(data or {}) do
        if line ~= "" then
            target[#target + 1] = line
        end
    end
end

local function job_error_message(stdout, stderr)
    local message = vim.trim(table.concat(stderr or {}, "\n"))
    if message == "" then
        message = vim.trim(table.concat(stdout or {}, "\n"))
    end
    return message ~= "" and message or "go test failed"
end

--- Define sign text highlights and sign definitions (once).
local function define_coverage_signs()
    -- Sign text highlight groups
    vim.api.nvim_set_hl(0, "GoCoverageSignCovered", {
        fg = "#8EC07C",
        default = true,
    })
    vim.api.nvim_set_hl(0, "GoCoverageSignUncovered", {
        fg = "#FB4934",
        default = true,
    })

    vim.fn.sign_define("GoCovCovered", {
        text = "│",
        texthl = "GoCoverageSignCovered",
    })
    vim.fn.sign_define("GoCovUncovered", {
        text = "│",
        texthl = "GoCoverageSignUncovered",
    })
end

--- Walk up from start_dir until go.mod is found.
--- @param start_dir string
--- @return string|nil
local function find_module_root(start_dir)
    local dir = vim.fn.resolve(start_dir)
    while true do
        if vim.fn.filereadable(dir .. "/go.mod") == 1 then
            return dir
        end
        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then
            break
        end
        dir = parent
    end
    return nil
end

local function relative_to_root(path, root)
    if path == "" then
        return ""
    end
    if path == root then
        return "."
    end

    local prefix = root .. "/"
    if vim.startswith(path, prefix) then
        return path:sub(#prefix + 1)
    end
    return path
end

--- Parse a Go coverage profile file.
--- Returns a map: { [file_path] = { [line_num] = boolean } }
--- @param profile_path string
--- @return table|nil
local function parse_coverage(profile_path)
    local f = io.open(profile_path, "r")
    if not f then
        return nil
    end

    local first = f:read("*l")
    if not first or not first:match("^mode:") then
        f:close()
        return nil
    end

    -- result[file_path][line_num] = boolean (true = covered)
    local result = {}
    for line in f:lines() do
        -- Format: file:startLine.startCol,endLine.endCol numStatements count
        local file, sl, el, count = line:match("^(.+):(%d+)%.%d+,(%d+)%.%d+%s+%d+%s+(%d+)")
        if file then
            sl = tonumber(sl)
            el = tonumber(el)
            count = tonumber(count)
            local covered = count > 0

            if not result[file] then
                result[file] = {}
            end

            for l = sl, el do
                local prev = result[file][l]
                if prev == nil then
                    result[file][l] = covered
                elseif prev then
                    -- keep false if any block on this line is uncovered
                    result[file][l] = covered
                end
            end
        end
    end

    f:close()
    return result
end

--- Match a buffer path against coverage profile entries.
--- @param buf_path string absolute path
--- @param profile_data table parsed coverage data
--- @return table|nil line coverage data for the matching file
local function match_buffer(buf_path, profile_data)
    if buf_path == "" then
        return nil
    end

    buf_path = vim.fn.fnamemodify(buf_path, ":p")
    local best_data = nil
    local best_match_length = -1

    for profile_file, data in pairs(profile_data) do
        -- Handle command-line-arguments/ prefix (outside-module coverage)
        if vim.startswith(profile_file, "command-line-arguments/") then
            local clean = profile_file:sub(#"command-line-arguments/" + 1)
            if vim.endswith(buf_path, "/" .. clean) or buf_path == clean then
                if #clean > best_match_length then
                    best_data = data
                    best_match_length = #clean
                end
            end
        elseif profile_file:sub(1, 1) == "/" then
            local profile_path = vim.fn.fnamemodify(profile_file, ":p")
            if buf_path == profile_path then
                best_data = data
                best_match_length = #profile_path
            end
        elseif vim.endswith(buf_path, "/" .. profile_file) or buf_path == profile_file then
            if #profile_file > best_match_length then
                best_data = data
                best_match_length = #profile_file
            end
        end
    end

    return best_data
end

--- Parse go tool cover -func output.
--- Returns {funcs = {{name, pct}}, total_pct = "62.5%"} or nil.
--- @param output string
--- @return table|nil
local function parse_coverage_func_output(output)
    local funcs = {}
    local total_pct = nil

    for line in output:gmatch("[^\n]+") do
        if line == "" then
            goto continue
        end

        -- total line: "total:\t\t\t(statements)\t\t62.5%"
        if line:match("^total:") then
            total_pct = line:match("([%d.]+%%)$")
        else
            -- func line: "file:line:\tFuncName\t\t100.0%"
            local _, _, func_name, pct = line:find(":%d+:\t(.+)\t([%d.]+%%)$")
            if func_name and pct then
                -- Strip trailing tabs from alignment padding
                func_name = func_name:gsub("\t+$", "")
                table.insert(funcs, { name = func_name, pct = pct })
            end
        end

        ::continue::
    end

    -- Sort: uncovered first, then by name
    table.sort(funcs, function(a, b)
        local ap = tonumber(a.pct:match("[%d.]+"))
        local bp = tonumber(b.pct:match("[%d.]+"))
        if ap ~= bp then
            return ap < bp
        end
        return a.name < b.name
    end)

    return { funcs = funcs, total_pct = total_pct }
end

--- Run go tool cover -func without blocking Neovim.
--- @param profile_path string
--- @param cwd string
--- @param callback fun(data: table|nil, error_message: string|nil)
local function parse_coverage_func_async(profile_path, cwd, callback)
    if vim.fn.executable("go") ~= 1 then
        callback(nil, "go executable not found")
        return
    end

    local ok, err = pcall(function()
        vim.system({ "go", "tool", "cover", "-func=" .. profile_path }, { cwd = cwd, text = true }, function(result)
            vim.schedule(function()
                if result.code ~= 0 then
                    local message = vim.trim(result.stderr or "")
                    if message == "" then
                        message = vim.trim(result.stdout or "")
                    end
                    callback(nil, message ~= "" and message or "go tool cover failed")
                    return
                end

                callback(parse_coverage_func_output(result.stdout or ""), nil)
            end)
        end)
    end)

    if not ok then
        callback(nil, "Failed to start go tool cover: " .. tostring(err))
    end
end

--- Close and clean up the coverage float window.
local function close_coverage_float()
    if coverage_float.win and vim.api.nvim_win_is_valid(coverage_float.win) then
        vim.api.nvim_win_close(coverage_float.win, true)
    elseif coverage_float.buf and vim.api.nvim_buf_is_valid(coverage_float.buf) then
        pcall(vim.api.nvim_buf_delete, coverage_float.buf, { force = true })
    end
    coverage_float.win = nil
    coverage_float.buf = nil
end

--- Show coverage stats in a floating window.
--- @param stats table {pct, covered, uncovered, func_data?}
local function show_coverage_float(stats)
    close_coverage_float()

    -- Count covered / uncovered functions
    local funcs_covered, funcs_uncovered = 0, 0
    if stats.func_data and stats.func_data.funcs then
        for _, f in ipairs(stats.func_data.funcs) do
            local p = tonumber(f.pct:match("[%d.]+")) or 0
            if p > 0 then
                funcs_covered = funcs_covered + 1
            else
                funcs_uncovered = funcs_uncovered + 1
            end
        end
    end

    local lines = {}
    -- Header
    vim.list_extend(lines, {
        "",
        string.format("  %s", stats.file_path or vim.fn.expand("%:t")),
        string.format("  %d/%d funcs  Coverage  %s", funcs_covered, funcs_covered + funcs_uncovered, stats.pct_str or "N/A"),
    })

    -- Per-function breakdown
    local func_start = 0
    if stats.func_data and stats.func_data.funcs and #stats.func_data.funcs > 0 then
        vim.list_extend(lines, {
            "  " .. string.rep("─", 36),
        })
        func_start = #lines -- first function entry will be at this index

        -- Determine padding width from longest func name
        local max_name = 0
        for _, f in ipairs(stats.func_data.funcs) do
            max_name = math.max(max_name, #f.name)
        end
        local name_width = math.min(max_name, 28)

        for _, f in ipairs(stats.func_data.funcs) do
            local name = #f.name > name_width and f.name:sub(1, name_width - 1) .. "…" or f.name
            local padded = name .. string.rep(" ", name_width - #name + 2)
            table.insert(lines, string.format("  %s%s", padded, f.pct))
        end
        vim.list_extend(lines, {})
    end

    vim.list_extend(lines, {
        "  " .. string.rep("─", 36),
    })

    -- Create scratch buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].filetype = "GoCoverage"

    -- Highlight function entries: green ≥80%, yellow >0%, red 0%
    local ns = vim.api.nvim_create_namespace("go-coverage-float")
    for i, f in ipairs(stats.func_data and stats.func_data.funcs or {}) do
        local pct_val = tonumber(f.pct:match("[%d.]+")) or 0
        local hl = "GoCoverageSignCovered"
        if pct_val == 0 then
            hl = "GoCoverageSignUncovered"
        elseif pct_val < 80 then
            hl = "WarningMsg"
        end
        vim.api.nvim_buf_set_extmark(buf, ns, func_start + i - 1, 0, {
            line_hl_group = hl,
        })
    end

    -- Floating window config
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
        title = " Go Coverage ",
        title_pos = "center",
        noautocmd = true,
    })
    if not ok then
        vim.api.nvim_buf_delete(buf, { force = true })
        notify("Unable to open coverage window: " .. tostring(win), vim.log.levels.ERROR)
        return
    end

    -- Close keymaps
    vim.keymap.set("n", "q", close_coverage_float, {
        buffer = buf,
        silent = true,
        desc = "Close coverage float",
    })
    vim.keymap.set("n", "<Esc>", close_coverage_float, {
        buffer = buf,
        silent = true,
        desc = "Close coverage float",
    })

    coverage_float.win = win
    coverage_float.buf = buf
end

--- Apply parsed coverage data to all open Go buffers via sign column.
--- Returns stats table {pct, covered, uncovered}.
--- @param profile_data table
--- @return table
local function apply_coverage(profile_data)
    local covered, uncovered = 0, 0

    -- Rebuild the sign set so files not present in a newly loaded profile do
    -- not retain stale coverage markers.
    vim.fn.sign_unplace(COVERAGE_SIGN_GROUP)

    -- Coverage statistics describe the whole profile, not only open buffers.
    for _, line_data in pairs(profile_data) do
        for _, is_covered in pairs(line_data) do
            if is_covered then
                covered = covered + 1
            else
                uncovered = uncovered + 1
            end
        end
    end

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[bufnr].filetype == "go" and vim.api.nvim_buf_is_loaded(bufnr) then
            local buf_path = vim.api.nvim_buf_get_name(bufnr)
            local line_data = match_buffer(buf_path, profile_data)
            if line_data then
                for lnum, is_covered in pairs(line_data) do
                    local name = is_covered and "GoCovCovered" or "GoCovUncovered"
                    vim.fn.sign_place(0, COVERAGE_SIGN_GROUP, name, bufnr, { lnum = lnum })
                end
            end
        end
    end

    local total = covered + uncovered
    local pct = total > 0 and math.floor((covered / total) * 100 + 0.5) or 0
    return { pct = pct, covered = covered, uncovered = uncovered }
end

--- Run go test with coverage for the given package (async).
--- @param pkg string package path (default: "./...")
function M.coverage_run(pkg)
    pkg = vim.trim(pkg or "")
    if pkg == "" then
        pkg = "./..."
    end

    if is_running() then
        notify("Coverage is already running", vim.log.levels.WARN)
        return
    end

    if vim.bo.filetype ~= "go" then
        notify("Current file is not a Go file", vim.log.levels.ERROR)
        return
    end

    if vim.fn.executable("go") ~= 1 then
        notify("go executable not found", vim.log.levels.ERROR)
        return
    end

    define_coverage_signs()

    local buf_path = vim.api.nvim_buf_get_name(0)
    local buf_dir = buf_path ~= "" and vim.fs.dirname(vim.fn.fnamemodify(buf_path, ":p")) or vim.fn.getcwd()

    local module_root = find_module_root(buf_dir)
    if not module_root then
        notify("go.mod not found", vim.log.levels.ERROR)
        return
    end

    -- Clear any existing coverage before running
    M.coverage_clear()

    -- Capture current file path before async job
    local file_path = relative_to_root(vim.fn.fnamemodify(buf_path, ":p"), module_root)
    if file_path == "" then
        file_path = module_root
    end
    local profile_path = vim.fn.tempname()
    local cmd = { "go", "test", "-coverprofile=" .. profile_path, "-covermode=set", pkg }
    local token = next_generation()
    local stdout = {}
    local stderr = {}

    vim.g[PROFILE_VAR] = profile_path
    set_running(true)

    local job_id = vim.fn.jobstart(cmd, {
        cwd = module_root,
        on_stdout = function(_, data)
            append_job_output(stdout, data)
        end,
        on_stderr = function(_, data)
            append_job_output(stderr, data)
        end,
        on_exit = vim.schedule_wrap(function(_, exit_code, _)
            if token ~= current_generation() then
                remove_profile(profile_path)
                return
            end

            set_running(false)
            vim.g[JOB_VAR] = nil
            vim.g[PROFILE_VAR] = nil

            if exit_code ~= 0 then
                remove_profile(profile_path)
                notify(job_error_message(stdout, stderr), vim.log.levels.ERROR)
                return
            end

            local profile_data = parse_coverage(profile_path)
            if not profile_data then
                remove_profile(profile_path)
                notify("Failed to parse coverage profile", vim.log.levels.ERROR)
                return
            end

            -- Apply signs to buffers
            local stats = apply_coverage(profile_data)
            stats.pct_str = string.format("%d%%", stats.pct)

            -- Parse per-function coverage without blocking the UI.
            parse_coverage_func_async(profile_path, module_root, function(func_data, func_error)
                if token ~= current_generation() then
                    remove_profile(profile_path)
                    return
                end

                if func_error then
                    notify(func_error, vim.log.levels.WARN)
                end
                stats.func_data = func_data
                if func_data and func_data.total_pct then
                    stats.pct_str = func_data.total_pct
                end

                remove_profile(profile_path)
                stats.file_path = file_path
                show_coverage_float(stats)
            end)
        end),
    })

    if job_id <= 0 then
        set_running(false)
        vim.g[JOB_VAR] = nil
        vim.g[PROFILE_VAR] = nil
        remove_profile(profile_path)
        notify("Failed to start go test coverage", vim.log.levels.ERROR)
        return
    end

    vim.g[JOB_VAR] = job_id
end

--- Load coverage from an existing profile file.
--- @param profile_path string path to coverage.out
function M.coverage_load(profile_path)
    profile_path = vim.trim(profile_path or "")
    if profile_path == "" then
        notify("Coverage profile path cannot be empty", vim.log.levels.ERROR)
        return
    end

    profile_path = vim.fn.expand(profile_path)
    if vim.fn.filereadable(profile_path) == 0 then
        notify(string.format("Coverage profile not found: %s", profile_path), vim.log.levels.ERROR)
        return
    end

    local profile_data = parse_coverage(profile_path)
    if not profile_data then
        notify("Failed to parse coverage profile", vim.log.levels.ERROR)
        return
    end

    M.coverage_clear()
    local token = next_generation()
    define_coverage_signs()

    local stats = apply_coverage(profile_data)
    stats.pct_str = string.format("%d%%", stats.pct)

    local buf_path = vim.api.nvim_buf_get_name(0)
    local absolute_buf_path = buf_path ~= "" and vim.fn.fnamemodify(buf_path, ":p") or ""
    local buf_dir = absolute_buf_path ~= "" and vim.fs.dirname(absolute_buf_path) or vim.fn.getcwd()
    local module_root = find_module_root(buf_dir)
    stats.file_path = module_root and relative_to_root(absolute_buf_path, module_root) or absolute_buf_path
    local cover_cwd = module_root or vim.fs.dirname(profile_path) or "."

    parse_coverage_func_async(profile_path, cover_cwd, function(func_data, func_error)
        if token ~= current_generation() then
            return
        end

        if func_error then
            notify(func_error, vim.log.levels.WARN)
        end
        stats.func_data = func_data
        if func_data and func_data.total_pct then
            stats.pct_str = func_data.total_pct
        end
        show_coverage_float(stats)
    end)
end

--- Clear all coverage signs from all Go buffers.
function M.coverage_clear()
    local job_id = tonumber(vim.g[JOB_VAR])
    if job_id and job_id > 0 then
        vim.fn.jobstop(job_id)
    end

    remove_profile(vim.g[PROFILE_VAR])
    vim.g[JOB_VAR] = nil
    vim.g[PROFILE_VAR] = nil
    set_running(false)
    next_generation()
    vim.fn.sign_unplace(COVERAGE_SIGN_GROUP)
    close_coverage_float()
end

-- =============================================================================
-- Setup: user commands & keymap
-- =============================================================================

local function create_command(name, callback, opts)
    pcall(vim.api.nvim_del_user_command, name)
    vim.api.nvim_create_user_command(name, callback, opts)
end

create_command("GoCoverage", function(opts)
    M.coverage_run(opts.args)
end, {
    nargs = "?",
    desc = "Run Go test coverage",
})

create_command("GoCoverageLoad", function(opts)
    M.coverage_load(opts.args)
end, {
    nargs = 1,
    desc = "Load a Go coverage profile",
})

create_command("GoCoverageClear", function()
    M.coverage_clear()
end, {
    nargs = 0,
    desc = "Clear Go coverage signs and window",
})

vim.keymap.set("n", "<leader>gc", "<cmd>GoCoverage<CR>", {
    silent = true,
    buffer = true,
    desc = "[Go]: Run test coverage for package",
})

return M
