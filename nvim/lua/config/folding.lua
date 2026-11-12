-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'folding'
--- @author x3m4g63 <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Fold options, foldtext and toggle mappings

local M = {}

vim.o.foldcolumn = "0"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.foldmethod = "indent"
vim.o.fillchars = "eob: ,fold: ,foldopen:,foldsep: ,foldclose:"

-- Don't let horizontal cursor movement open folds
vim.opt.foldopen:remove("hor")

function M.foldtext()
    -- Align the marker with the line above the folded block.
    local indentation = vim.v.foldstart > 1 and vim.fn.indent(vim.v.foldstart - 1) or 0
    local nline = 1 + vim.v.foldend - vim.v.foldstart
    return string.rep(" ", indentation) .. "  +-- " .. nline .. " lines "
end

vim.keymap.set("n", "zf", "za", { desc = "[Folding]: Toggle code block", noremap = true, silent = true })

vim.opt.foldtext = "v:lua.require'config.folding'.foldtext()"

-- Keep the fold label's fg/italic, drop the background block
local function clear_folded_bg()
    vim.cmd("highlight Folded guibg=NONE ctermbg=NONE")
end

clear_folded_bg()
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("User_FoldHighlight", { clear = true }),
    callback = clear_folded_bg,
})

return M
