-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'minuet'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-10
--- @description minuet: AI code completion plugin for Neovim.

vim.pack.add({
    { src = "https://github.com/milanglacier/minuet-ai.nvim" },
})

local minuet_ok, minuet = pcall(require, "minuet")
if minuet_ok then
    minuet.setup({
        virtualtext = {
            auto_trigger_ft = { "lua", "typescript", "go", "rust" },
            keymap = {
                accept = "<C-,>",
                prev = "<C-;>",
                next = "<C-'>",
                dismiss = "C-x",
            },
        },
        provider = "openai_fim_compatible",
        provider_options = {
            openai_fim_compatible = {
                api_key = "DEEPSEEK_API_KEY",
                name = "deepseek",
                optional = {
                    max_tokens = 256,
                    top_p = 0.9,
                },
            },
        },
        cmp = {
            enable_auto_complete = false,
        },
        blink = {
            enable_auto_complete = true,
        },
        lsp = {
            enabled_ft = {},
            disabled_ft = {},
            completion = {
                enable = false,
            },
            inline_completion = {
                enable = false,
            },
        },
    })
end
