-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'diagnostic'
--- @author x3m4g63 <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Diagnostic display settings (floats, virtual text and signs)

vim.diagnostic.config({
    update_in_insert = false,
    severity_sort = true,
    float = {
        focus = false,
        border = "rounded",
        max_width = 80,
        source = true,
        prefix = "",
        format = function(diagnostic)
            return diagnostic.message:match("^([^\n]*)") or diagnostic.message
        end,
    },
    underline = { severity = vim.diagnostic.severity.ERROR },
    virtual_text = {
        format = function(diagnostic)
            local msg = diagnostic.message:gsub("\n", " ")
            local parts = {}
            if diagnostic.source then
                parts[#parts + 1] = "[" .. diagnostic.source .. "]"
            end
            if diagnostic.code then
                parts[#parts + 1] = "[" .. tostring(diagnostic.code) .. "]"
            end
            return #parts > 0 and (msg .. " " .. table.concat(parts, " ")) or msg
        end,
        spacing = 4,
        source = "if_many",
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "ErrorMsg",
            [vim.diagnostic.severity.WARN] = "WarningMsg",
        },
    },
})
