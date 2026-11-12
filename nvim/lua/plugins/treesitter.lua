-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'treesitter'
--- @author x3m4g63 <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Install treesitter parsers and enable highlighting, textobjects and indent.

vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
        local name, kind = ev.data.spec.name, ev.data.kind
        if name == "nvim-treesitter" and kind == "update" then
            if not ev.data.active then
                vim.cmd.packadd("nvim-treesitter")
            end
            vim.cmd("TSUpdate")
        end
    end,
})

vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("User_TreesitterInit", { clear = true }),
    once = true,
    callback = function()
        require("nvim-treesitter").setup({})
        require("nvim-treesitter").install({
            -- default parsers (lua vim & vimdoc & markdown & markdown_inline) are bundled with
            -- Neovim 0.12, but their queries are not: install lua to link indents/highlights queries
            "lua",
            "bash",
            "fish",
            "go",
            "gomod",
            "gosum",
            "gowork",
            "gotmpl",
            "rust",
            "sql",
            "swift",
            "python",
            "typescript",
            "javascript",
            "tsx",
            "json",
            "toml",
            "html",
            "yaml",
            "dockerfile",
        })

        require("nvim-treesitter-textobjects").setup({
            select = {
                enable = true,
                lookahead = true,
                selection_modes = {
                    ["@parameter.outer"] = "v", -- charwise
                    ["@function.outer"] = "V", -- linewise
                    ["@class.outer"] = "<c-v>", -- blockwise
                },
                include_surrounding_whitespace = false,
            },
            move = {
                enable = true,
                set_jumps = true,
            },
        })

        local sel = require("nvim-treesitter-textobjects.select")
        for _, map in ipairs({
            { { "x", "o" }, "fo", "@function.outer" },
            { { "x", "o" }, "fi", "@function.inner" },
            { { "x", "o" }, "co", "@class.outer" },
            { { "x", "o" }, "ci", "@class.inner" },
            { { "x", "o" }, "po", "@parameter.outer" },
            { { "x", "o" }, "pi", "@parameter.inner" },
        }) do
            vim.keymap.set(map[1], map[2], function()
                sel.select_textobject(map[3], "textobjects")
            end, { desc = "Select " .. map[3] })
        end

        local mv = require("nvim-treesitter-textobjects.move")
        for _, map in ipairs({
            { { "n", "x", "o" }, "]f", mv.goto_next_start, "@function.outer" },
            { { "n", "x", "o" }, "[f", mv.goto_previous_start, "@function.outer" },
            { { "n", "x", "o" }, "]c", mv.goto_next_start, "@class.outer" },
            { { "n", "x", "o" }, "[c", mv.goto_previous_start, "@class.outer" },
            { { "n", "x", "o" }, "]]", mv.goto_next_end, "@function.outer" },
            { { "n", "x", "o" }, "[[", mv.goto_previous_end, "@function.outer" },
            { { "n", "x", "o" }, "]l", mv.goto_next_start, { "@loop.inner", "@loop.outer" } },
            { { "n", "x", "o" }, "[l", mv.goto_previous_start, { "@loop.inner", "@loop.outer" } },
        }) do
            local modes, lhs, fn, query = map[1], map[2], map[3], map[4]
            -- build a human-readable desc
            local qstr = (type(query) == "table") and table.concat(query, ",") or query
            vim.keymap.set(modes, lhs, function()
                fn(query, "textobjects")
            end, { desc = "Move to " .. qstr })
        end
    end,
})

-- User_TreesitterIndent: use treesitter indentexpr only when an indents query exists.
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("User_TreesitterIndent", { clear = true }),
    callback = function(args)
        local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
        if vim.treesitter.get_parser(args.buf, nil, { error = false }) and lang and #vim.treesitter.query.get_files(lang, "indents") > 0 then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})

-- filetype names that differ from parser names
local ts_lang = vim.treesitter.language
ts_lang.register("tsx", "typescriptreact")
ts_lang.register("javascript", "javascriptreact")
ts_lang.register("bash", "sh")

-- User_TreesitterHighlight: enable treesitter highlighting for every buffer with an available parser.
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("User_TreesitterHighlight", { clear = true }),
    callback = function(args)
        -- filetypes without an installed parser fall back to regex syntax
        pcall(vim.treesitter.start, args.buf)
    end,
})
