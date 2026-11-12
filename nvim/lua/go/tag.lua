-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'tag'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description struct-tag manipulation via gomodifytags

local M = {}

local util = require("go.util")

local ACTION_FLAGS = {
    add = "-add-tags",
    remove = "-remove-tags",
}

local RUNNING_VAR = "go_tag_running"

-- =============================================================================
-- Private helpers
-- =============================================================================

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Go Tags" })
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

    return file
end

-- =============================================================================
-- Tag manipulation — https://github.com/fatih/gomodifytags
-- =============================================================================

--- Add or remove a struct tag at the current cursor position.
--- @param action string "add" | "remove"
--- @param tag_name string tag name (e.g. "json", "yaml", "xml")
function M.modify_tag(action, tag_name)
    local action_flag = ACTION_FLAGS[action]
    if not action_flag then
        notify("Invalid tag action: " .. tostring(action), vim.log.levels.ERROR)
        return
    end

    tag_name = vim.trim(tag_name or "")
    if tag_name == "" then
        notify("Tag name cannot be empty", vim.log.levels.ERROR)
        return
    end

    if is_running() then
        notify("A gomodifytags process is already running", vim.log.levels.WARN)
        return
    end

    local file = current_file()
    if not file then
        return
    end

    local bin_ok, bin_error = util.ensure_bin("gomodifytags", "fatih/gomodifytags")
    if not bin_ok then
        notify(bin_error, vim.log.levels.ERROR)
        return
    end

    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
    local line_byte = vim.fn.line2byte(cursor_row)
    if line_byte < 0 or cursor_col < 0 then
        vim.notify("[Go] Cannot determine cursor byte offset", vim.log.levels.ERROR)
        return
    end

    -- gomodifytags expects a zero-based byte offset.
    local offset = line_byte + cursor_col - 1

    -- gomodifytags reads from disk, so save before starting it.
    local updated, update_error = pcall(vim.cmd.update)
    if not updated then
        notify("Unable to save current Go file: " .. tostring(update_error), vim.log.levels.ERROR)
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local command = {
        "gomodifytags",
        "-file",
        file,
        "-offset",
        tostring(offset),
        action_flag,
        tag_name,
        "-transform",
        "camelcase",
        "-w",
    }

    set_running(true)
    local ok, err = pcall(function()
        vim.system(command, { text = true }, function(result)
            vim.schedule(function()
                set_running(false)

                if result.code ~= 0 then
                    notify(util.command_error(result, "gomodifytags"), vim.log.levels.ERROR)
                    return
                end

                if not vim.api.nvim_buf_is_valid(bufnr) then
                    notify(string.format("[Go] %s tag %q succeeded", action, tag_name), vim.log.levels.INFO)
                    return
                end

                if vim.api.nvim_get_option_value("modified", { buf = bufnr }) then
                    notify("Go buffer changed while gomodifytags was running; reload manually", vim.log.levels.WARN)
                    return
                end

                pcall(vim.api.nvim_buf_call, bufnr, vim.cmd.checktime)
                notify(string.format("[Go] %s tag %q succeeded", action, tag_name), vim.log.levels.INFO)
            end)
        end)
    end)

    if not ok then
        set_running(false)
        notify("Failed to start gomodifytags: " .. tostring(err), vim.log.levels.ERROR)
    end
end

-- =============================================================================
-- Setup: user commands & keymaps
-- =============================================================================

--- Install this module's commands and buffer-local keymaps.
function M.install()
    local create_command = util.create_command

    create_command("GoAddTag", function(opts)
        M.modify_tag("add", opts.args ~= "" and opts.args or "json")
    end, { nargs = "?" })

    create_command("GoRemoveTag", function(opts)
        M.modify_tag("remove", opts.args ~= "" and opts.args or "json")
    end, { nargs = "?" })

    vim.keymap.set("n", "<leader>gj", "<cmd>GoAddTag<CR>", {
        silent = true,
        buffer = true,
        desc = "[Go]: Add struct tag (default: json)",
    })
    vim.keymap.set("n", "<leader>gr", "<cmd>GoRemoveTag<CR>", {
        silent = true,
        buffer = true,
        desc = "[Go]: Remove struct tag (default: json)",
    })
end

return M
