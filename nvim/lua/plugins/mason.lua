-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'mason'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Mason installer for LSP servers, DAP and linters

vim.pack.add({
    { src = "https://github.com/mason-org/mason.nvim" },
})

local opts = {
    ui = {
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
        },
    },
    ensure_installed = {
        -- LSP servers (matching your vim.lsp.enable() config)

        --[[
            use brew install
            "lua-language-server", -- Lua LSP lua_ls
            "gopls", -- Go LSP
            "golangci-lint", -- Go
            "rust-analyzer", -- Rust LSP
        ]]
        "yaml-language-server", -- YAML LSP yamlls
        "json-lsp", -- JSON LSP  jsonls
        "bash-language-server", -- Bash LSP bashls
        "fish-lsp", -- Fish LSP fish
        "sqls", -- SQL LSP
        "marksman", -- Markdown LSP
        "pyright", -- Python LSP

        -- Formatters (for conform.nvim and general use)
        "stylua", -- Lua
        "goimports", --Golang
        "gofumpt", --Golang
        "oxfmt", -- TypeScript
        "sqlfmt", -- 'Sql
        "ruff", -- Python
        "shfmt", -- Shell
        "yamlfmt", -- YAML
        "tombi", -- Formatters & LSP

        -- -- Linters
        "oxlint", -- TypeScript
        "selene", -- Lua
        "shellcheck", -- Shell
        "yamllint", -- YAML
        "jsonlint", -- JSON
        "sqlfluff", -- SQL
        "markdownlint", -- Markdown

        -- Debuggers--
        "delve", -- Go debugger
    },
}

require("mason").setup({ ui = opts.ui })

-- Auto-install ensure_installed tools with better error handling
local registry = require("mason-registry")
local function ensure_installed()
    for _, tool in ipairs(opts.ensure_installed) do
        if registry.has_package(tool) then
            local p = registry.get_package(tool)
            if not p:is_installed() then
                vim.notify("Mason: Installing " .. tool .. "...", vim.log.levels.INFO)
                p:install():once("closed", function()
                    if p:is_installed() then
                        vim.notify("Mason: Successfully installed " .. tool, vim.log.levels.INFO)
                    else
                        vim.notify("Mason: Failed to install " .. tool, vim.log.levels.ERROR)
                    end
                end)
            end
        else
            vim.notify("Mason: Package '" .. tool .. "' not found", vim.log.levels.WARN)
        end
    end
end

local function install_missing()
    if registry.refresh then
        registry.refresh(ensure_installed)
    else
        ensure_installed()
    end
end

-- Registry refresh hits the network; keep it off the startup path.
vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
        vim.schedule(install_missing)
    end,
})
