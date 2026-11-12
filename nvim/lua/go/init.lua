-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- SPDX-License-Identifier: MIT
--
--- @module 'go'
--- @description Entry point for the Go tooling modules
--- @author x3m4g63  <asang24dev@gmail.com>

local M = {}

local modules = {
    require("go.benchmark"),
    require("go.coverage"),
    require("go.mock"),
    require("go.tag"),
}

local maps = {
    { "n", "<leader>gj" },
    { "n", "<leader>gr" },
    { "n", "<leader>gm" },
    { "n", "<leader>gM" },
    { "n", "<leader>gb" },
    { "n", "<leader>gB" },
    { "n", "<leader>gc" },
}

-- The runtime undo_ftplugin string can abort before appended commands run, so
-- remove the buffer-local Go maps from the next FileType instead.
local group = vim.api.nvim_create_augroup("User_GoFtpluginMaps", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(args)
        if vim.bo[args.buf].filetype == "go" or not vim.b[args.buf].go_ftplugin_maps then
            return
        end

        for _, map in ipairs(maps) do
            pcall(vim.keymap.del, map[1], map[2], { buffer = args.buf })
        end
        vim.b[args.buf].go_ftplugin_maps = nil
    end,
})

--- Install the Go commands and buffer-local keymaps for the current buffer.
function M.setup()
    vim.b.go_ftplugin_maps = true
    for _, module in ipairs(modules) do
        module.install()
    end
end

return M
