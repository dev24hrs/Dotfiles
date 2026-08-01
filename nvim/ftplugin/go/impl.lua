-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- SPDX-License-Identifier: MIT
--
--- @module 'go.impl'
--- @description interface-implementation stub generation via impl
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
-- Interface implementation — https://github.com/josharian/impl
-- =============================================================================

--- Search backwards from cursor for a struct type declaration using treesitter.
--- @return string|nil struct name, or nil if not found
local function detect_struct()
    local bufnr = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(bufnr, "go")
    if not parser then
        return nil
    end

    local tree = parser:parse()[1]
    if not tree then
        return nil
    end

    local cursor_row = vim.fn.line(".") - 1 -- 0-indexed

    local query = vim.treesitter.query.parse(
        "go",
        [[
      (type_declaration
        (type_spec
          name: (type_identifier) @name
          type: (struct_type)))
    ]]
    )

    local closest_name = nil
    local closest_row = -1

    for id, node in query:iter_captures(tree:root(), bufnr, 0, cursor_row) do
        if query.captures[id] == "name" then
            local start_row = node:start()
            if start_row <= cursor_row and start_row > closest_row then
                closest_row = start_row
                closest_name = vim.treesitter.get_node_text(node, bufnr)
            end
        end
    end

    return closest_name
end

--- Generate a receiver expression from a struct name.
--- e.g. "File" -> "'f *File'"
--- @param struct_name string
--- @return string
local function struct_to_receiver(struct_name)
    local first_char = struct_name:sub(1, 1):lower()
    return string.format("'%s *%s'", first_char, struct_name)
end

--- Generate method stubs implementing iface for the struct at cursor.
--- @param iface string the interface to implement (e.g. "io.Reader")
function M.impl(iface)
    if not ensure_bin("impl", "josharian/impl") then
        return
    end

    local struct_name = detect_struct()
    if not struct_name then
        vim.notify("[Go] No struct declaration found before cursor", vim.log.levels.ERROR)
        return
    end

    local receiver = struct_to_receiver(struct_name)
    local cmd = string.format("impl %s %s", receiver, vim.fn.shellescape(iface))
    local output = vim.fn.system(cmd)

    if vim.v.shell_error ~= 0 then
        local err_msg = vim.trim(output)
        if err_msg == "" then
            err_msg = "interface not found or not in module directory?"
        end
        vim.notify(string.format("[Go] impl failed for %q: %s", iface, err_msg), vim.log.levels.ERROR)
        return
    end

    local lines = vim.split(output, "\n", { trimempty = true })
    if #lines > 0 then
        vim.api.nvim_put(lines, "l", true, true)
        vim.notify(string.format("[Go] Generated %d method(s) for %s to implement %q", #lines, struct_name, iface), vim.log.levels.INFO)
    else
        vim.notify("[Go] impl produced no output", vim.log.levels.WARN)
    end
end

-- =============================================================================
-- Setup: user commands & keymaps
-- =============================================================================

if vim.fn.exists(":GoImpl") == 0 then
    vim.api.nvim_create_user_command("GoImpl", function(opts)
        M.impl(opts.args)
    end, { nargs = 1 })
end

vim.keymap.set("n", "<leader>gi", ":GoImpl ", {
    silent = false,
    buffer = true,
    desc = "[Go]: Generate interface implementation",
})

return M
