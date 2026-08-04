vim.pack.add({
    { src = "https://github.com/Exafunction/windsurf.nvim" },
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
})

require("codeium").setup({
    enable_cmp_source = false, -- set false to disable nvim-cmp source for blink.cmp
    virtual_text = {
        enabled = true,
        key_bindings = {
            accept = "<C-,>",
            clear = "C-x",
            next = "<C-;>",
            prev = "<C-'>",
            accept_word = false,
            accept_line = false,
        },
        filetypes = {
            markdown = false,
        },
        default_filetype_enabled = true,
    },
})
-- change the suggestion virtual_text color
vim.api.nvim_set_hl(0, "CodeiumSuggestion", { fg = "#B0B0B0", italic = true })
