-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- SPDX-License-Identifier: MIT
--
--- @module 'go.impl'
--- @description interface-implementation stub generation via impl
--- @author dev24hrs <asang24dev@gmail.com>

local M = {}

local RUNNING_VAR = "go_impl_running"

-- =============================================================================
-- Private helpers
-- =============================================================================

--- Ensure a CLI tool is executable, notify with install hint if missing.
--- @param bin string binary name
--- @param repo string "owner/repo" for go install hint
--- @return boolean
local function ensure_bin(bin, repo)
    if vim.fn.executable(bin) == 1 then
        return true
    end
    vim.notify(string.format("[Go] %s not found. Install: go install github.com/%s@latest", bin, repo), vim.log.levels.ERROR)
    return false
end

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Go Impl" })
end

local function is_running()
    return vim.g[RUNNING_VAR] == true
end

local function set_running(value)
    vim.g[RUNNING_VAR] = value
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

    if not vim.api.nvim_get_option_value("modifiable", { buf = 0 }) then
        notify("Current Go buffer is not modifiable", vim.log.levels.ERROR)
        return nil
    end

    return file
end

local function command_error(result)
    local message = vim.trim(result.stderr or "")
    if message == "" then
        message = vim.trim(result.stdout or "")
    end
    if message == "" then
        message = result.signal and string.format("impl terminated by signal %d", result.signal) or "impl failed"
    end
    return message
end

-- =============================================================================
-- Interface implementation — https://github.com/josharian/impl
-- =============================================================================

--- Search backwards from cursor for a struct type declaration using treesitter.
--- @return string|nil struct name, or nil if not found
local function detect_struct()
    local bufnr = vim.api.nvim_get_current_buf()
    if not vim.treesitter or not vim.treesitter.get_parser then
        return nil
    end

    local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, "go")
    if not parser_ok or not parser then
        return nil
    end

    local parsed, trees = pcall(parser.parse, parser)
    if not parsed or not trees or not trees[1] then
        return nil
    end

    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
    cursor_row = cursor_row - 1

    if not vim.treesitter.query or not vim.treesitter.query.parse then
        return nil
    end

    local query_ok, query = pcall(
        vim.treesitter.query.parse,
        "go",
        [[
      (type_declaration
        (type_spec
          name: (type_identifier) @name
          type: (struct_type)))
    ]]
    )
    if not query_ok or not query then
        return nil
    end

    local closest_name = nil
    local closest_row = -1
    local closest_col = -1

    local iter_ok = pcall(function()
        for id, node in query:iter_captures(trees[1]:root(), bufnr, 0, cursor_row + 1) do
            if query.captures[id] == "name" then
                local start_row, start_col = node:start()
                local before_cursor = start_row < cursor_row or (start_row == cursor_row and start_col <= cursor_col)
                local closer = start_row > closest_row or (start_row == closest_row and start_col > closest_col)

                if before_cursor and closer then
                    local text_ok, name = pcall(vim.treesitter.get_node_text, node, bufnr)
                    if text_ok then
                        closest_row = start_row
                        closest_col = start_col
                        closest_name = name
                    end
                end
            end
        end
    end)

    if not iter_ok then
        return nil
    end

    return closest_name
end

--- Generate a receiver expression from a struct name.
--- e.g. "File" -> "f *File"
--- @param struct_name string
--- @return string
local function struct_to_receiver(struct_name)
    local first_char = struct_name:sub(1, 1):lower()
    return string.format("%s *%s", first_char, struct_name)
end

--- Generate method stubs implementing iface for the struct at cursor.
--- @param iface string the interface to implement (e.g. "io.Reader")
function M.impl(iface)
    iface = vim.trim(iface or "")
    if iface == "" then
        notify("Interface name cannot be empty", vim.log.levels.ERROR)
        return
    end

    if is_running() then
        notify("An impl process is already running", vim.log.levels.WARN)
        return
    end

    local file = current_file()
    if not file then
        return
    end

    if not ensure_bin("impl", "josharian/impl") then
        return
    end

    local struct_name = detect_struct()
    if not struct_name then
        notify("No struct declaration found before cursor", vim.log.levels.ERROR)
        return
    end

    local updated, update_error = pcall(vim.cmd.update)
    if not updated then
        notify("Unable to save current Go file: " .. tostring(update_error), vim.log.levels.ERROR)
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local source_row = vim.api.nvim_win_get_cursor(0)
    source_row = source_row[1] - 1
    local receiver = struct_to_receiver(struct_name)
    local command = { "impl", receiver, iface }
    local source_dir = vim.fs.dirname(file) or "."

    set_running(true)
    local ok, err = pcall(function()
        vim.system(command, {
            cwd = source_dir,
            text = true,
        }, function(result)
            vim.schedule(function()
                set_running(false)

                if result.code ~= 0 then
                    notify(string.format("impl failed for %q: %s", iface, command_error(result)), vim.log.levels.ERROR)
                    return
                end

                local lines = vim.split(result.stdout or "", "\n", { trimempty = true })
                if #lines == 0 then
                    notify("impl produced no output", vim.log.levels.WARN)
                    return
                end

                if not vim.api.nvim_buf_is_valid(bufnr) then
                    notify("Generated methods, but the source buffer is no longer available", vim.log.levels.WARN)
                    return
                end

                if vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
                    notify("Go buffer changed while impl was running; generated methods were not inserted", vim.log.levels.WARN)
                    return
                end

                if not vim.api.nvim_get_option_value("modifiable", { buf = bufnr }) then
                    notify("Go buffer is no longer modifiable", vim.log.levels.ERROR)
                    return
                end

                local line_count = vim.api.nvim_buf_line_count(bufnr)
                local insert_row = math.min(source_row + 1, line_count)
                vim.api.nvim_buf_set_lines(bufnr, insert_row, insert_row, false, lines)
                notify(string.format("Generated %d method(s) for %s to implement %q", #lines, struct_name, iface), vim.log.levels.INFO)
            end)
        end)
    end)

    if not ok then
        set_running(false)
        notify("Failed to start impl: " .. tostring(err), vim.log.levels.ERROR)
    end
end

-- =============================================================================
-- Setup: user commands & keymaps
-- =============================================================================

local function create_command(name, callback, opts)
    pcall(vim.api.nvim_del_user_command, name)
    vim.api.nvim_create_user_command(name, callback, opts)
end

create_command("GoImpl", function(opts)
    local iface = vim.trim(opts.args or "")
    if iface ~= "" then
        M.impl(iface)
        return
    end

    vim.ui.input({ prompt = "Interface: " }, function(input)
        if input and vim.trim(input) ~= "" then
            M.impl(vim.trim(input))
        end
    end)
end, { nargs = "?" })

vim.keymap.set("n", "<leader>gi", "<cmd>GoImpl<CR>", {
    silent = true,
    buffer = true,
    desc = "[Go]: Generate interface implementation",
})

return M
