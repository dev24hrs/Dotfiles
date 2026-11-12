-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'todo'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description TODO/FIXME highlighting and quick list

vim.pack.add({
    { src = "https://github.com/folke/todo-comments.nvim" },
})

local todo = require("todo-comments")

todo.setup({
    signs = false,
})

vim.keymap.set("n", "<leader>ft", "<cmd>TodoFzfLua<CR>", { desc = "[Todo]: Show Todo comments" })

vim.api.nvim_create_autocmd({ "BufReadPre", "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("User_TodoInit", { clear = true }),
    once = true,
    callback = function()
        if package.loaded["todo-comments"] then
            return
        end

        vim.keymap.set("n", "]t", function()
            todo.jump_next()
        end, { desc = "[Todo]: Next Todo comment" })

        vim.keymap.set("n", "[t", function()
            todo.jump_prev()
        end, { desc = "[Todo]: Previous Todo comment" })
    end,
})

-- 使用
-- 关键词:
-- FIX = { FIXME, BUG, FIXIT, ISSUE }
-- TODO
-- WARN
-- NOTE = { INFO }
-- TEST = { TESTING, PASSED, FAILED }
--  以 '--' 开头+ 关键词, 紧跟: , 输入内容

-- TODO: do something
-- NOTE: note something
-- HACK: hack something
-- WARN: warn something
-- FIX: fix something
-- ISSUE: issue something
-- TEST: test something
