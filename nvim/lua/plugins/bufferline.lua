vim.pack.add({
    { src = "https://github.com/akinsho/bufferline.nvim" },
})

-- 使bufferline的背景色与终端保持一致,无论是否终端透明
vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none" })

local RED = "#FB4934"
require("bufferline").setup({
    options = {
        -- 数字显示：none（简洁）或 ordinal（1,2,3）
        numbers = "ordinal",
        themable = true,
        close_command = function(bufnr)
            local listed_bufs = vim.tbl_filter(function(b)
                return vim.bo[b].buflisted and vim.bo[b].buftype == ""
            end, vim.api.nvim_list_bufs())
            if #listed_bufs > 1 then
                vim.cmd("bdelete! " .. bufnr)
            else
                vim.cmd("enew")
                vim.cmd("bdelete! " .. bufnr)
            end
        end,

        right_mouse_command = function(bufnr)
            local listed_bufs = vim.tbl_filter(function(b)
                return vim.bo[b].buflisted and vim.bo[b].buftype == ""
            end, vim.api.nvim_list_bufs())
            if #listed_bufs > 1 then
                vim.cmd("bdelete! " .. bufnr)
            else
                vim.cmd("enew")
                vim.cmd("bdelete! " .. bufnr)
            end
        end,
        indicator = { style = "none" },
        tab_size = 16,
        padding = 0,
        left_padding = 1,
        right_padding = 1,
        -- 彻底关闭所有图标占位
        show_buffer_icons = false,
        show_buffer_close_icons = false,
        show_close_icon = false,
        show_tab_indicators = false,
        separator_style = "thin",
        always_show_bufferline = true,
        modified_icon = "",
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        diagnostics = "nvim_lsp",
    },
    highlights = {
        buffer_selected = { fg = RED, bold = true, italic = true },
        modified = { fg = RED },
        modified_visible = { fg = RED },
        modified_selected = { fg = RED },
    },
})

vim.keymap.set("n", "wl", ":BufferLineCycleNext<CR>", { noremap = true, silent = true, desc = "[Bufferline]: Next Buffer" })
vim.keymap.set("n", "wh", ":BufferLineCyclePrev<CR>", { noremap = true, silent = true, desc = "[Bufferline]: Previous Buffer" })
vim.keymap.set("n", "wd", ":bdelete<CR>", { noremap = true, silent = true, desc = "[Bufferline]: Close Buffer" })
vim.keymap.set("n", "wc", ":BufferLineCloseOthers<CR>", { noremap = true, silent = true, desc = "[Bufferline]: Close Other Buffer" })
