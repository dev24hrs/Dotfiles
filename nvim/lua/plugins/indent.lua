-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'indent'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description hlchunk indent guides and chunk highlights

vim.pack.add({
    { src = "https://github.com/shellRaining/hlchunk.nvim" },
})

require("hlchunk").setup({
    chunk = {
        enable = true,
        style = { { fg = "#806d9c" } },
    },
    indent = {
        enable = true,
        chars = {
            "│",
        },
    },
    line_num = { enable = false },
    blank = { enable = false },
})
