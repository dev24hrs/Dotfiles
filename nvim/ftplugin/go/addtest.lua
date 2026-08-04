-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- SPDX-License-Identifier: MIT
--
--- @module 'go.addtest'
--- @description table-driven test generation via gotests + treesitter
--- @author dev24hrs <asang24dev@gmail.com>

local M = {}

-- =============================================================================
-- Constants
-- =============================================================================

local GOTESTS = "gotests"
local REPO = "cweill/gotests/gotests"
local OPEN_TEST_FILE = false

local function is_running()
    return vim.g.go_addtest_running == true
end

local function set_running(value)
    vim.g.go_addtest_running = value
end

-- =============================================================================
-- Private helpers
-- =============================================================================

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Go Tests" })
end

--- Ensure a CLI tool is executable, notify with install hint if missing.
--- @param bin string binary name
--- @param repo string "owner/repo" for go install hint
--- @return boolean
local function ensure_bin(bin, repo)
    if vim.fn.executable(bin) == 1 then
        return true
    end
    notify(string.format("%s not found. Install: go install github.com/%s@latest", bin, repo), vim.log.levels.ERROR)
    return false
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

    if file:match("_test%.go$") then
        notify("Current file is already a test file", vim.log.levels.WARN)
        return nil
    end

    file = vim.fn.fnamemodify(file, ":p")
    if vim.fn.filereadable(file) ~= 1 then
        notify("Current Go file is not readable", vim.log.levels.ERROR)
        return nil
    end

    return file
end

local function test_file_for(source_file)
    if vim.endswith(source_file, ".go") then
        local test_file = source_file:gsub("%.go$", "_test.go")
        return test_file
    end
    return source_file .. "_test.go"
end

--- Check that a function name cannot alter gotests' Go regexp filter.
--- @param function_name string
--- @return boolean
local function valid_function_name(function_name)
    return not function_name:find("[\\%^%$%.%[%]%(%)%*%+%?{}|]")
end

--- Use tree-sitter to detect the function / method at the cursor.
--- Returns nil when the Go parser is unavailable.
--- @return string|nil
local function current_function_name()
    if not vim.treesitter or not vim.treesitter.get_parser then
        return nil
    end

    local ok, parser = pcall(vim.treesitter.get_parser, 0, "go")
    if not ok or not parser then
        return nil
    end

    local parsed, trees = pcall(parser.parse, parser)
    if not parsed then
        return nil
    end
    if not trees or not trees[1] then
        return nil
    end

    local row, col = table.unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1

    local node = trees[1]:root():named_descendant_for_range(row, col, row, col)

    while node do
        local node_type = node:type()
        if node_type == "function_declaration" or node_type == "method_declaration" then
            local name_nodes = node:field("name")
            if name_nodes and name_nodes[1] then
                local text_ok, name = pcall(vim.treesitter.get_node_text, name_nodes[1], 0)
                if text_ok then
                    return name
                end
                return nil
            end
        end
        node = node:parent()
    end

    return nil
end

--- Core: run gotests with the given flags.
--- @param flags string[]
--- @param description string human-readable scope for notifications
local function run_gotests(flags, description)
    if is_running() then
        notify("A gotests process is already running", vim.log.levels.WARN)
        return
    end

    local source_file = current_file()
    if not source_file then
        return
    end

    local test_file = test_file_for(source_file)
    local test_buf = vim.fn.bufnr(test_file)
    if test_buf ~= -1 and vim.api.nvim_get_option_value("modified", { buf = test_buf }) then
        notify("Test buffer has unsaved changes: " .. test_file, vim.log.levels.ERROR)
        return
    end

    local source_buf = vim.api.nvim_get_current_buf()
    local source_win = vim.api.nvim_get_current_win()

    -- gotests reads from disk — persist unsaved changes first.
    local updated, update_error = pcall(vim.cmd.update)
    if not updated then
        notify("Unable to save current Go file: " .. update_error, vim.log.levels.ERROR)
        return
    end

    if not ensure_bin(GOTESTS, REPO) then
        return
    end

    local command = { GOTESTS, "-w" }
    vim.list_extend(command, flags)
    table.insert(command, source_file)

    local source_dir = vim.fs.dirname(source_file) or "."

    set_running(true)

    notify("Generating " .. description .. "...")

    local ok, err = pcall(function()
        vim.system(command, {
            cwd = source_dir,
            text = true,
        }, function(result)
            vim.schedule(function()
                set_running(false)

                if result.code ~= 0 then
                    local message = vim.trim(result.stderr or "")
                    if message == "" then
                        message = vim.trim(result.stdout or "")
                    end
                    if message == "" then
                        message = result.signal and string.format("gotests terminated by signal %d", result.signal) or "gotests failed"
                    end
                    notify(message, vim.log.levels.ERROR)
                    return
                end

                -- gotests wrote to disk — tell Neovim to re-check the source buffer.
                if vim.api.nvim_buf_is_valid(source_buf) then
                    pcall(vim.api.nvim_buf_call, source_buf, vim.cmd.checktime)
                end

                if OPEN_TEST_FILE and vim.uv.fs_stat(test_file) and vim.api.nvim_win_is_valid(source_win) then
                    local generated_test_buf = vim.fn.bufadd(test_file)
                    vim.fn.bufload(generated_test_buf)
                    if vim.api.nvim_buf_is_valid(generated_test_buf) then
                        vim.api.nvim_win_set_buf(source_win, generated_test_buf)
                    end
                end

                notify(description .. " completed")
            end)
        end)
    end)

    if not ok then
        set_running(false)
        notify("Failed to start gotests: " .. tostring(err), vim.log.levels.ERROR)
    end
end

--- Schedule a test generation for a specific function name.
--- @param function_name string
local function add_test_for_function(function_name)
    if not function_name or function_name == "" then
        return
    end

    function_name = vim.trim(function_name)
    if function_name == "" or not valid_function_name(function_name) then
        notify("Invalid Go function name", vim.log.levels.ERROR)
        return
    end

    local pattern = "^" .. function_name .. "$"
    run_gotests({ "-only", pattern }, "test for " .. function_name)
end

-- =============================================================================
-- Public command handlers
-- =============================================================================

--- Handler for :GoTestAdd — generate test for function at cursor, or by name.
--- @param command_args table vim command callback argument
function M.go_test_add(command_args)
    local explicit = vim.trim(command_args.args or "")

    -- :GoTestAdd Foo  — explicit function name.
    if explicit ~= "" then
        add_test_for_function(explicit)
        return
    end

    -- Try tree-sitter auto-detection.
    local function_name = current_function_name()
    if function_name then
        add_test_for_function(function_name)
        return
    end

    -- No tree-sitter parser — ask the user interactively.
    vim.ui.input({ prompt = "Function name: " }, function(input)
        if input and vim.trim(input) ~= "" then
            add_test_for_function(vim.trim(input))
        end
    end)
end

--- Handler for :GoTestsAll — generate tests for all functions / methods.
function M.go_tests_all()
    run_gotests({ "-all" }, "tests for all functions")
end

--- Handler for :GoTestsExp — generate tests for exported functions / methods.
function M.go_tests_exp()
    run_gotests({ "-exported" }, "tests for exported functions")
end

-- =============================================================================
-- User commands & keymaps
-- =============================================================================

local function create_command(name, callback, opts)
    pcall(vim.api.nvim_del_user_command, name)
    vim.api.nvim_create_user_command(name, callback, opts)
end

create_command("GoTestAdd", M.go_test_add, {
    nargs = "?",
    desc = "Generate Go test for function under cursor",
})
create_command("GoTestsAll", M.go_tests_all, {
    desc = "Generate Go tests for all functions in the current file",
})
create_command("GoTestsExp", M.go_tests_exp, {
    desc = "Generate Go tests for exported functions only",
})

vim.keymap.set("n", "<leader>gt", "<cmd>GoTestAdd<CR>", {
    silent = true,
    buffer = true,
    desc = "[Go]: Add test for function under cursor",
})
vim.keymap.set("n", "<leader>ga", "<cmd>GoTestsAll<CR>", {
    silent = true,
    buffer = true,
    desc = "[Go]: Add tests for all functions",
})
vim.keymap.set("n", "<leader>ge", "<cmd>GoTestsExp<CR>", {
    silent = true,
    buffer = true,
    desc = "[Go]: Add tests for exported functions",
})

return M
