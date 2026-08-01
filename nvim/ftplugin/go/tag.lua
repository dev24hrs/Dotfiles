-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- SPDX-License-Identifier: MIT
--
--- @module 'go.tag'
--- @description struct-tag manipulation via gomodifytags
--- @author dev24hrs <asang24dev@gmail.com>

local M = {}

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

-- =============================================================================
-- Tag manipulation — https://github.com/fatih/gomodifytags
-- =============================================================================

--- Add or remove a struct tag at the current cursor position.
--- @param action string "add" | "remove"
--- @param tag_name string tag name (e.g. "json", "yaml", "xml")
function M.modify_tag(action, tag_name)
    if not ensure_bin("gomodifytags", "fatih/gomodifytags") then
        return
    end

    local line_byte = vim.fn.line2byte(vim.fn.line("."))
    if line_byte < 0 then
        vim.notify("[Go] Cannot determine cursor byte offset", vim.log.levels.ERROR)
        return
    end

    local file = vim.api.nvim_buf_get_name(0)
    local offset = line_byte + vim.fn.col(".") - 1

    local cmd = string.format(
        "gomodifytags -file %s -offset %d -%s-tags %s -transform camelcase -w",
        vim.fn.shellescape(file),
        offset,
        action,
        vim.fn.shellescape(tag_name)
    )

    vim.fn.system(cmd)
    if vim.v.shell_error == 0 then
        vim.cmd("edit!")
        vim.notify(string.format("[Go] %s tag %q succeeded", action, tag_name), vim.log.levels.INFO)
    else
        vim.notify(string.format("[Go] %s tag %q failed (is the cursor on a struct field?)", action, tag_name), vim.log.levels.ERROR)
    end
end

-- =============================================================================
-- Setup: user commands & keymaps
-- =============================================================================

if vim.fn.exists(":GoAddTag") == 0 then
    vim.api.nvim_create_user_command("GoAddTag", function(opts)
        M.modify_tag("add", opts.args ~= "" and opts.args or "json")
    end, { nargs = "?" })
end

if vim.fn.exists(":GoRemoveTag") == 0 then
    vim.api.nvim_create_user_command("GoRemoveTag", function(opts)
        M.modify_tag("remove", opts.args ~= "" and opts.args or "json")
    end, { nargs = "?" })
end

vim.keymap.set("n", "<leader>gj", ":GoAddTag<CR>", {
    silent = false,
    buffer = true,
    desc = "[Go]: Add struct tag (default: json)",
})
vim.keymap.set("n", "<leader>gr", ":GoRemoveTag<CR>", {
    silent = false,
    buffer = true,
    desc = "[Go]: Remove struct tag (default: json)",
})

return M
