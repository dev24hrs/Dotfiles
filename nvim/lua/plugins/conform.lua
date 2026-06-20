vim.pack.add({
    { src = "https://github.com/stevearc/conform.nvim" },
})

local conform = require("conform")
conform.setup({
    formatters_by_ft = {
        lua = { "stylua" },
        go = { "goimports", "gofumpt" },
        yaml = { "yamlfmt" },

        -- JavaScript/TypeScript 生态
        javascript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },

        -- 其他前端格式
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        scss = { "prettierd", "prettier", stop_after_first = true },

        -- Python: ruff_format 已包含格式化，ruff_fix 处理 lint 修复
        python = { "ruff_organize_imports", "ruff_format" },

        sql = { "sqlfmt" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        toml = { "taplo" },
        rust = { "rustfmt", lsp_format = "fallback" }, -- comes with Rust installation
        fish = { "fish_indent" }, -- comes with Fish installation
        ["_"] = { "trim_whitespace" },
    },
    default_format_opts = {
        lsp_format = "fallback",
    },
    format_on_save = function(bufnr)
        -- 排除 node_modules 和其他不需要格式化的目录
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match("/node_modules/") or bufname:match("/%.git/") or bufname:match("/vendor/") then
            return
        end
        return { timeout_ms = 500, lsp_format = "fallback" }
    end,
})
vim.keymap.set({ "n", "v" }, "<leader>w", function()
    conform.format({
        async = true,
        lsp_format = "fallback",
    }, function(err)
        if err then
            vim.notify("Format error: " .. err, vim.log.levels.ERROR, { title = "Conform" })
            return
        end
        vim.schedule(function()
            if vim.bo.modified then
                vim.cmd("update")
                vim.notify("Formatted & Saved", vim.log.levels.INFO, { title = "Conform" })
            else
                vim.cmd("update")
            end
        end)
    end)
end, { desc = "[Conform]: Format and Saved" })

-- 保存时自动删除行尾空格
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = { "*" },
    callback = function()
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.setpos(".", vim.fn.getpos("."))
    end,
})
