-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'aerial'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Symbol outline sidebar with lazy loading

vim.pack.add({
    { src = "https://github.com/stevearc/aerial.nvim" },
})

local configured = false

local function setup()
    if configured then
        return
    end
    configured = true

    require("aerial").setup({
        attach_mode = "global",
        backends = { "treesitter", "lsp", "markdown", "man", "asciidoc" },
        disable_max_lines = 5000,
        filter_kind = {
            "Class",
            "Constructor",
            "Enum",
            "Function",
            "Interface",
            "Module",
            "Method",
            "Struct",
        },
        highlight_on_hover = true,
        ignore = { filetypes = { "gomod" } },
        layout = { min_width = 20, width = 30, default_direction = "prefer_right", resize_to_content = true },
        show_guides = true,
        autojump = true,
        lazy_load = true,
        close_on_select = false,
        keymaps = {
            ["o"] = "actions.jump",
            ["{"] = "actions.prev",
            ["}"] = "actions.next",
            ["q"] = "actions.close",
            ["l"] = "actions.tree_open",
            ["h"] = "actions.tree_close",
        },
    })
end

vim.keymap.set("n", "<leader>ot", function()
    setup()
    vim.cmd("AerialToggle")
end, { desc = "[Aerial]: Toggle Outline" })
