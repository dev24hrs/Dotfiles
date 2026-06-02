-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "highlight copying text",
    group = vim.api.nvim_create_augroup("User_HighlightYank", { clear = true }),
    callback = function()
        vim.hl.on_yank({ timeout = 500 })
    end,
})

-- don't auto comment new line
vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = "*",
    callback = function()
        vim.opt.formatoptions = vim.opt.formatoptions - { "c", "r", "o" }
    end,
})

-- go to last position when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.opt_local.textwidth = 120
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.list = false
        vim.opt_local.conceallevel = 0
    end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
    desc = "Close specific buffers with <q>",
    group = vim.api.nvim_create_augroup("User_CloseWithQ", { clear = true }),
    pattern = {
        "help",
        "lspinfo",
        "man",
        "qf",
        "notify",
        "checkhealth",
        "spectre_panel",
        "nvim-pack",
        "toggleterm",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
})

-- 创建 :H 命令，在新的竖屏中打开 help
vim.api.nvim_create_user_command("H", function(opts)
    vim.cmd("vertical help " .. (opts.args ~= "" and opts.args or ""))
end, { nargs = "*", complete = "help" })
