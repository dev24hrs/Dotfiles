vim.pack.add({
    { src = "https://github.com/j-hui/fidget.nvim" },
    { src = "https://github.com/rcarriga/nvim-notify" },
    { src = "https://github.com/folke/noice.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
})

-- vim.api.nvim_set_hl(0, "NotifyBackground", { bg = "#000000" })
require("notify").setup({
    stages = "fade_in_slide_out",
    render = "wrapped-compact",
    timeout = 3000,
    background_colour = "#000000",
    merge_duplicates = true,
})
-- Route all vim.notify() calls through nvim-notify for styled notifications
vim.notify = require("notify")

vim.keymap.set("n", "<leader>fn", function()
    -- Try Telescope/fzf-lua picker first, fall back to plain history command
    local ok = pcall(require("notify.integrations").pick)
    if not ok then
        vim.cmd("Notifications")
    end
end, { desc = "[Notify]: Show Notification History" })

require("noice").setup({
    cmdline = {
        enabled = true,
        view = "cmdline_popup",
        format = {
            cmdline = { pattern = "^:", icon = "", lang = "vim" },
            search_down = { pattern = "^/", icon = "", lang = "regex" },
            search_up = { pattern = "^%?", icon = "", lang = "regex" },
            lua = { pattern = "^:%s*lua%s+", icon = "", lang = "lua" },
        },
    },
    lsp = {
        progress = { enabled = false }, -- 使用 fidget 处理进度
        hover = { enabled = false },
        signature = { enabled = false },
        message = { enabled = false },
    },
})
require("fidget").setup({
    progress = {
        poll_rate = 0,
        suppress_on_insert = true,
        ignore_done_already = true,
        display = {
            render_limit = 16,
            done_ttl = 3,
            done_icon = "✔",
            progress_icon = { pattern = "dots", period = 1 },
        },
        lsp = {
            progress_ringbuf_size = 1024,
        },
    },
    notification = {
        poll_rate = 10,
        filter = vim.log.levels.INFO,
        history_size = 128,
        override_vim_notify = false,
        window = {
            winblend = 0,
            zindex = 45,
            tabstop = 15,
            border = "none",
            align = "bottom",
            avoid = { "aerial", "NvimTree", "neotest-summary" },
        },
    },
})
