-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'langIndent'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Per-language tab, shiftwidth and expandtab settings

-- this file is for indent settings

local indent_configs = {
    -- 2 空格缩进组
    {
        size = 2,
        expand = true,
        fts = {
            "json",
            "jsonc",
            "yaml",
            "yaml.docker-compose",
            "markdown",
            "sh",
            "toml",
            "sql",
            "gitcommit",
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
        },
    },
    -- 4 空格缩进组
    {
        size = 4,
        expand = true,
        fts = { "c", "cpp", "python", "lua", "rust", "swift" },
    },
    -- 4 物理 Tab 组
    {
        size = 4,
        expand = false,
        fts = { "go" },
    },
}
-- 全局默认值
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

local indent_group = vim.api.nvim_create_augroup("User_LanguagesIndent", { clear = true })
for _, config in ipairs(indent_configs) do
    vim.api.nvim_create_autocmd("FileType", {
        pattern = config.fts, -- Neovim 的 pattern 原生支持直接传入 table: { 'json', 'yaml' }
        group = indent_group,
        callback = function()
            vim.opt_local.tabstop = config.size
            vim.opt_local.shiftwidth = config.size
            vim.opt_local.softtabstop = config.size
            vim.opt_local.expandtab = config.expand
        end,
    })
end
