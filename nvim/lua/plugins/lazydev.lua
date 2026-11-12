-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'lazydev'
--- @author x3m4g63 <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description LuaLS library paths for plugin development

vim.pack.add({
    { src = "https://github.com/folke/lazydev.nvim" },
})

-- lazydev auto-discovers "start" plugins, but not "opt". Expand the glob
-- ourselves: neither lazydev nor LuaLS expands wildcards in library paths.
local opt_plugins = vim.fn.glob(vim.fn.stdpath("data") .. "/site/pack/*/opt/*", false, true)

require("lazydev").setup({
    library = vim.tbl_map(function(path)
        return { path = path }
    end, opt_plugins),
})
