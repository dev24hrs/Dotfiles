vim.pack.add({
    { src = "https://github.com/saecki/crates.nvim", tag = "stable" },
})
vim.api.nvim_create_autocmd("BufRead", {
    pattern = "Cargo.toml",
    once = true,
    callback = function()
        require("crates").setup({
            lsp = {
                enabled = true,
                actions = true,
                completion = true,
                hover = true,
            },
        })
    end,
})
