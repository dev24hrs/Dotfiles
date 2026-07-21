vim.pack.add({
    { src = "https://github.com/folke/lazydev.nvim" },
})

require("lazydev").setup({
    library = {
        -- lazydev auto-discovers "start" plugins, but not "opt".
        -- Add explicit paths so lua_ls can resolve .
        { path = vim.fn.stdpath("data") .. "/site/pack/*/opt/*" },
    },
})
