-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- SPDX-License-Identifier: MIT
--
--- @module 'minuet'
--- @description desc...
--- @author dev24hrs <asang24dev@gmail.com>

vim.pack.add({
    { src = "https://github.com/milanglacier/minuet-ai.nvim" },
})
require("minuet").setup({
    provider = "openai_fim_compatible",
    provider_options = {
        openai_fim_compatible = {
            api_key = "DEEPSEEK_API_KEY",
            name = "deepseek",
            model = "deepseek-v4-flash",
            stream = true,
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

        completion = {
            enable = false,
        },

        inline_completion = {
            enable = false,
        },
    },
    curl_extra_args = {
        "--connect-timeout",
        "5",
        "--retry",
        "1",
    },
    n_completions = 1,
    request_timeout = 2.5,
    debounce = 250,

    virtualtext = {
        auto_trigger_ft = {},
        keymap = {
            accept = nil,
            accept_line = nil,
            accept_n_lines = nil,
            next = nil,
            prev = nil,
            dismiss = nil,
        },
    },
})
