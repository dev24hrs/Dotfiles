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

--- Coverage float window state (singleton).
local coverage_float = {
    win = nil,
    buf = nil,
}

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
    for _ = 1, 20 do
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

    for profile_file, data in pairs(profile_data) do
        -- Direct suffix match
        if vim.endswith(buf_path, profile_file) then
            return data
        end
        -- Handle command-line-arguments/ prefix (outside-module coverage)
        if vim.startswith(profile_file, "command-line-arguments/") then
            local clean = profile_file:sub(#"command-line-arguments/" + 1)
            if vim.endswith(buf_path, clean) then
                return data
            end
        end
    end

    return nil
end

--- Parse go tool cover -func output.
--- Returns {funcs = {{name, pct}}, total_pct = "62.5%"} or nil.
--- @param profile_path string
--- @return table|nil
local function parse_coverage_func(profile_path)
    local output = vim.fn.system({ "go", "tool", "cover", "-func=" .. profile_path })
    if vim.v.shell_error ~= 0 then
        return nil
    end

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

--- Close and clean up the coverage float window.
local function close_coverage_float()
    if coverage_float.win and vim.api.nvim_win_is_valid(coverage_float.win) then
        vim.api.nvim_win_close(coverage_float.win, true)
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
    local width = 42
    local height = math.min(#lines, vim.o.lines - 4)

    local win = vim.api.nvim_open_win(buf, false, {
        relative = "editor",
        width = width,
        height = height,
        row = math.max(5, math.floor(vim.o.lines * 0.1)),
        col = vim.o.columns - width - 2,
        style = "minimal",
        border = "rounded",
        title = " Go Coverage ",
        title_pos = "center",
        noautocmd = true,
    })

    -- Close keymaps
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
        callback = close_coverage_float,
        desc = "Close coverage float",
    })
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
        callback = close_coverage_float,
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

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[bufnr].filetype == "go" and vim.api.nvim_buf_is_loaded(bufnr) then
            local buf_path = vim.api.nvim_buf_get_name(bufnr)
            local line_data = match_buffer(buf_path, profile_data)
            if line_data then
                -- Clear old signs for this buffer
                vim.fn.sign_unplace(COVERAGE_SIGN_GROUP, { buffer = bufnr })
                for lnum, is_covered in pairs(line_data) do
                    local name = is_covered and "GoCovCovered" or "GoCovUncovered"
                    vim.fn.sign_place(0, COVERAGE_SIGN_GROUP, name, bufnr, { lnum = lnum })
                    if is_covered then
                        covered = covered + 1
                    else
                        uncovered = uncovered + 1
                    end
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
    pkg = pkg or "./..."
    define_coverage_signs()

    local buf_dir = vim.fn.expand("%:p:h")
    if buf_dir == "" then
        buf_dir = vim.fn.getcwd()
    end

    local module_root = find_module_root(buf_dir)
    if not module_root then
        vim.notify("[Go] go.mod not found", vim.log.levels.ERROR)
        return
    end

    -- Clear any existing coverage before running
    M.coverage_clear()

    -- Capture current file path before async job
    local buf_path = vim.api.nvim_buf_get_name(0)
    local file_path = buf_path
    if module_root and vim.startswith(buf_path, module_root) then
        file_path = buf_path:sub(#module_root + 2) -- strip module root + "/"
    end
    local profile_path = vim.fn.tempname()
    local cmd = { "go", "test", "-coverprofile=" .. profile_path, "-covermode=set", pkg }

    vim.fn.jobstart(cmd, {
        cwd = module_root,
        on_exit = vim.schedule_wrap(function(_, _, _)
            local profile_data = parse_coverage(profile_path)
            if not profile_data then
                vim.fn.delete(profile_path)
                vim.notify("[Go] Failed to parse coverage profile", vim.log.levels.ERROR)
                return
            end

            -- Apply signs to buffers
            local stats = apply_coverage(profile_data)
            stats.pct_str = string.format("%d%%", stats.pct)

            -- Parse per-function coverage
            local func_data = parse_coverage_func(profile_path)
            stats.func_data = func_data

            vim.fn.delete(profile_path)

            if func_data and func_data.total_pct then
                stats.pct_str = func_data.total_pct
            end

            -- Show float window with all stats
            stats.file_path = file_path
            show_coverage_float(stats)
        end),
    })
end

--- Load coverage from an existing profile file.
--- @param profile_path string path to coverage.out
function M.coverage_load(profile_path)
    profile_path = vim.fn.expand(profile_path)
    if vim.fn.filereadable(profile_path) == 0 then
        vim.notify(string.format("[Go] Coverage profile not found: %s", profile_path), vim.log.levels.ERROR)
        return
    end

    define_coverage_signs()

    local profile_data = parse_coverage(profile_path)
    if not profile_data then
        vim.notify("[Go] Failed to parse coverage profile", vim.log.levels.ERROR)
        return
    end

    local stats = apply_coverage(profile_data)
    stats.pct_str = string.format("%d%%", stats.pct)

    local func_data = parse_coverage_func(profile_path)
    stats.func_data = func_data

    if func_data and func_data.total_pct then
        stats.pct_str = func_data.total_pct
    end

    local buf_path = vim.api.nvim_buf_get_name(0)
    local module_root = find_module_root(vim.fn.expand("%:p:h"))
    if module_root and vim.startswith(buf_path, module_root) then
        stats.file_path = buf_path:sub(#module_root + 2)
    else
        stats.file_path = buf_path
    end
    show_coverage_float(stats)
end

--- Clear all coverage signs from all Go buffers.
function M.coverage_clear()
    vim.fn.sign_unplace(COVERAGE_SIGN_GROUP)
    close_coverage_float()
end

-- =============================================================================
-- Setup: user commands & keymap
-- =============================================================================

if vim.fn.exists(":GoCoverage") == 0 then
    vim.api.nvim_create_user_command("GoCoverage", function(opts)
        M.coverage_run(opts.args)
    end, { nargs = "?" })
end

if vim.fn.exists(":GoCoverageLoad") == 0 then
    vim.api.nvim_create_user_command("GoCoverageLoad", function(opts)
        M.coverage_load(opts.args)
    end, { nargs = 1 })
end

if vim.fn.exists(":GoCoverageClear") == 0 then
    vim.api.nvim_create_user_command("GoCoverageClear", function()
        M.coverage_clear()
    end, { nargs = 0 })
end

vim.keymap.set("n", "<leader>gc", ":GoCoverage<CR>", {
    silent = false,
    buffer = true,
    desc = "[Go]: Run test coverage for package",
})

return M
