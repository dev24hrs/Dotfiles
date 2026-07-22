vim.pack.add({
    { src = "https://github.com/nvim-lualine/lualine.nvim" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
})

local function diff_source()
    local gitsigns = vim.b.gitsigns_status_dict
    if gitsigns then
        return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed,
        }
    end
end

vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })

local colors = {
    MAGENTA = "#A89984",
    RED = "#FB4934",
    CYAN = "#8EC07C",
}
local custom_gruvbox = {
    normal = {
        a = { fg = colors.RED },
        b = { fg = colors.CYAN },
        c = { fg = colors.MAGENTA },
        x = { fg = colors.MAGENTA },
        y = { fg = colors.MAGENTA },
        z = { fg = colors.RED },
    },
}
require("lualine").setup({
    options = {
        theme = custom_gruvbox,
        section_separators = "",
        component_separators = "",
        always_divide_middle = false,
        always_show_tabline = false,
        globalstatus = true,
        disabled_filetypes = { statusline = { "alpha" } },
    },
    sections = {
        lualine_a = { "mode" },
        lualine_b = {
            { "branch", icon = "" },
            { "diff", symbols = { added = "+", modified = "~", removed = "-" }, source = diff_source },
            { "diagnostics" },
        },
        lualine_c = { "filename" },
        lualine_x = {
            {
                -- 自定义组件：显示当前的缩进风格
                function()
                    local space = vim.api.nvim_get_option_value("expandtab", { scope = "local" })
                    local size = vim.api.nvim_get_option_value("shiftwidth", { scope = "local" })
                    if space then
                        return "Spaces: " .. size
                    else
                        return "Tab Size: " .. size
                    end
                end,
            },
            "encoding",
            { "fileformat", icons_enabled = true, symbols = { unix = "LF", dos = "CRLF", mac = "CR" } },
        },
        lualine_y = { "filetype" },
        lualine_z = {
            {
                "lsp_status",
                icon = false,
                symbols = {
                    spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
                    done = "✓",
                    separator = " ",
                },
                ignore_lsp = {},
                show_name = true,
            },
        },
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = {},
})
