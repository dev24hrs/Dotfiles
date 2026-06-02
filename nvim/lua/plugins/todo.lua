vim.pack.add({
    { src = "https://github.com/folke/todo-comments.nvim" },
})

vim.api.nvim_create_autocmd({ "BufReadPre", "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("User_TodoInit", { clear = true }),
    once = true,
    callback = function()
        if package.loaded["todo-comments"] then
            return
        end

        local todo = require("todo-comments")
        todo.setup({
            signs = false,
        })

        vim.keymap.set("n", "]t", function()
            todo.jump_next()
        end, { desc = "[Todo]: Next Todo comment" })

        vim.keymap.set("n", "[t", function()
            todo.jump_prev()
        end, { desc = "[Todo]: Previous Todo comment" })

        vim.keymap.set("n", "<leader>ft", "<cmd>TodoQuickFix<CR>", { desc = "[Todo]: Show Todo comments" })
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
