-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'lint'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description nvim-lint linters triggered on read, write and filetype

vim.pack.add({
    { src = "https://github.com/mfussenegger/nvim-lint" },
})

local configured = false

-- BufReadPost fires before filetype detection on startup (ft is empty)
-- add FileType to load lint on startup
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "FileType" }, {
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
                sql = { "sqlfluff" },
                python = { "ruff" },
                markdown = { "markdownlint" },
                fish = { "fish" }, -- comes with Fish installation
            }

            lint.linters.sqlfluff.args = {
                "lint",
                "--format=json",
                "--dialect=mysql",
                "-",
            }
            -- markdownlint 是按 linter 进程的 cwd 查找配置文件，因此需要显式传 '--config'
            -- 指向nvim 配置目录下的 .markdownlint.json
            lint.linters.markdownlint.args = {
                "--stdin",
                "--config",
                vim.fs.joinpath(vim.fn.stdpath("config"), ".markdownlint.json"),
            }
            -- selene 也只从进程 cwd 查找 selene.toml，显式指定配置路径
            lint.linters.selene.args = {
                "--display-style",
                "json",
                "--config",
                vim.fs.joinpath(vim.fn.stdpath("config"), "selene.toml"),
                "-",
            }
            configured = true
        end

        lint.try_lint()
    end,
})
