vim.pack.add({
    { src = "https://github.com/mfussenegger/nvim-lint" },
})

local configured = false

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = vim.api.nvim_create_augroup("User_LintInit", { clear = true }),
    callback = function()
        local lint = require("lint")

        if not configured then
            lint.linters_by_ft = {
                go = { "golangcilint" },
                lua = { "selene" },
                sh = { "shellcheck" },
                yaml = { "yamllint" },
                json = { "jsonlint" },
                jsonc = { "jsonlint" },
                sql = { "sqlfluff" },
                python = { "ruff" },
                markdown = { "markdownlint" },
                fish = { "fish" }, -- comes with Fish installation
            }

            lint.linters.sqlfluff.args = {
                "lint",
                "--format=json",
                "--dialect=mysql",
            }
            configured = true
        end

        lint.try_lint()
    end,
})
