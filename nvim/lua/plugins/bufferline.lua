vim.pack.add({
    { src = "https://github.com/akinsho/bufferline.nvim", version = "*" },
})

-- 使bufferline的背景色与终端保持一致,无论是否终端透明
vim.api.nvim_set_hl(0, "TabLineFill", { bg = "none" })

local RED = "#FB4934"

-- 关闭 buffer 的通用逻辑：只剩最后一个普通 buffer 时先 enew，避免关闭窗口
local function close_buffer(bufnr)
    local has_other = false
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if b ~= bufnr and vim.bo[b].buflisted and vim.bo[b].buftype == "" then
            has_other = true
            break
        end
    end
    if has_other then
        vim.cmd("bdelete! " .. bufnr)
    else
        vim.cmd("enew")
        vim.cmd("bdelete! " .. bufnr)
    end
end

require("bufferline").setup({
    options = {
        mode = "buffers",
        numbers = "ordinal",
        themable = true,
        close_command = close_buffer,
        right_mouse_command = close_buffer,
        indicator = { style = "none" },
        tab_size = 10,
        padding = 1,
        left_padding = 1,
        right_padding = 1,
        show_buffer_icons = false,
        show_buffer_close_icons = false,
        show_close_icon = false,
        show_tab_indicators = false,
        separator_style = "thin",
        always_show_bufferline = true,
        modified_icon = "",
        left_mouse_command = "buffer %d",
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
