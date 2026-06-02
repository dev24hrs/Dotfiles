vim.pack.add({
    { src = "https://github.com/nvim-mini/mini.pairs" },
})
require("mini.pairs").setup()

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
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main", build = ":TSUpdate" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-context" },
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("User_TreesitterInit", { clear = true }),
    once = true,
    callback = function()
        require("nvim-treesitter").setup({})
        require("nvim-treesitter").install({
            -- default: lua vim & vimdoc & markdown & markdown_inline in 0.12 version
            "bash",
            "fish",
            "go",
            "gomod",
            "gosum",
            "gowork",
            "gotmpl",
            "rust",
            "sql",
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
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "*" },
    callback = function()
        local ok = pcall(vim.treesitter.start)
        if not ok then
            return
        end
        vim.wo[0].foldmethod = "expr"
        vim.wo[0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end,
})
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
