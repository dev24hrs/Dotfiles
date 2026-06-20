vim.pack.add({
    { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
    { src = "https://github.com/rafamadriz/friendly-snippets" },
    { src = "https://github.com/Exafunction/windsurf.nvim" },
})
vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter", "LspAttach" }, {
    pattern = "*",
    group = vim.api.nvim_create_augroup("User_BlinkCmpInit", { clear = true }),
    once = true,
    callback = function()
        local blink = require("blink.cmp")
        blink.setup({
            appearance = { nerd_font_variant = "normal" },
            keymap = {
                preset = "none",
                ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
                ["<CR>"] = { "accept", "fallback" },
                ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
                ["<Up>"] = { "select_prev", "fallback" },
                ["<Down>"] = { "select_next", "fallback" },
                ["<C-j>"] = { "select_next", "fallback" },
                ["<C-k>"] = { "select_prev", "fallback" },
                ["<Esc>"] = { "cancel", "fallback" },
            },
            completion = {
                keyword = { range = "full" },
                list = { selection = { preselect = false, auto_insert = true } },
                ghost_text = { enabled = true },
                menu = {
                    winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
                    -- winhighlight = 'Normal:Normal,FloatBorder:Normal,CursorLine:Normal,Search:None',
                    scrolloff = 1,
                    scrollbar = false,
                    draw = {
                        columns = {
                            { "label", "label_description", gap = 1 },
                            { "kind_icon" },
                            { "kind" },
                            { "source_name" },
                        },
                        treesitter = { "lsp" },
                    },
                },
                documentation = {
                    window = {
                        scrollbar = false,
                        winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
                    },
                    auto_show = true,
                    treesitter_highlighting = true,
                },
            },
            signature = { enabled = true },
            sources = {
                default = { "lsp", "snippets", "buffer", "path", "codeium" },
                providers = {
                    codeium = { name = "Codeium", module = "codeium.blink", async = true },
                    buffer = {
                        module = "blink.cmp.sources.buffer",
                        score_offset = -3,
                        opts = {
                            get_bufnrs = function()
                                return vim.tbl_filter(function(bufnr)
                                    return vim.bo[bufnr].buftype == ""
                                end, vim.api.nvim_list_bufs())
                            end,
                        },
                    },
                    snippets = {
                        module = "blink.cmp.sources.snippets",
                        score_offset = -3,
                        -- For `snippets.preset == 'luasnip'`
                        opts = {
                            use_show_condition = true,
                            show_autosnippets = true,
                            prefer_doc_trig = false,
                            use_label_description = false,
                        },
                    },
                    path = {
                        module = "blink.cmp.sources.path",
                        score_offset = 3,
                        fallbacks = { "buffer" },
                        opts = {
                            trailing_slash = true,
                            label_trailing_slash = true,
                            get_cwd = function(context)
                                return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
                            end,
                            show_hidden_files_by_default = false,
                            ignore_root_slash = false,
                            max_entries = 500,
                        },
                    },
                    cmdline = {
                        module = "blink.cmp.sources.cmdline",
                        min_keyword_length = function(ctx)
                            -- when typing a command, only show when the keyword is 3 characters or longer
                            if ctx.mode == "cmdline" and string.find(ctx.line, " ") == nil then
                                return 3
                            end
                            return 0
                        end,
                    },
                },
            },
            cmdline = {
                completion = {
                    menu = {
                        auto_show = function()
                            return vim.fn.getcmdtype() == ":"
                        end,
                    },
                    ghost_text = { enabled = false },
                },
                keymap = {
                    ["<CR>"] = { "select_and_accept", "fallback" },
                    ["<Space>"] = { "select_and_accept", "fallback" },
                },
            },
            fuzzy = {
                implementation = "prefer_rust_with_warning",
                sorts = { "score", "sort_text" },
            },
        })
    end,
})
