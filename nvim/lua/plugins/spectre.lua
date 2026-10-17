vim.pack.add({
    { src = "https://github.com/nvim-pack/nvim-spectre" },
})

require("spectre").setup({
    -- 固定宽度60
    -- options.lua:51 : vim.opt.splitright = true
    -- (默认false),在右侧打开
    open_cmd = function()
        vim.cmd("vnew")
        vim.api.nvim_win_set_width(0, 60)
        vim.opt_local.winfixwidth = true
    end,
    color_devicons = true,
    live_update = false,
    lnum_for_results = true,
    line_sep_start = "┌-----------------------------------------",
    result_padding = "¦  ",
    line_sep = "└-----------------------------------------",
    highlight = {
        ui = "String",
        search = "DiffChange",
        replace = "DiffDelete",
    },
    mapping = {
        ["tab"] = {
            map = "<Tab>",
            cmd = "<cmd>lua require('spectre').tab()<cr>",
            desc = "next query",
        },
        ["shift-tab"] = {
            map = "<S-Tab>",
            cmd = "<cmd>lua require('spectre').tab_shift()<cr>",
            desc = "previous query",
        },
        ["enter_file"] = {
            map = "o",
            cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
            desc = "open file",
        },
        ["run_current_replace"] = {
            map = "<cr>",
            cmd = "<cmd>lua require('spectre.actions').run_current_replace()<CR>",
            desc = "[Spectre]: replace current line",
        },
        ["run_replace"] = {
            map = "<S-cr>",
            cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
            desc = "[Spectre]: replace all",
        },
    },
    is_block_ui_break = true,
})
vim.keymap.set("n", "<leader>sw", '<cmd>lua require("spectre").open_visual({select_word=true})<CR>', {
    desc = "[Spectre]: Search word on project",
})
vim.keymap.set("v", "<leader>sw", '<esc><cmd>lua require("spectre").open_visual()<CR>', {
    desc = "[Spectre]: Search current word on project",
})
vim.keymap.set("n", "<leader>sp", '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>', {
    desc = "[Spectre]: Search on current file",
})
