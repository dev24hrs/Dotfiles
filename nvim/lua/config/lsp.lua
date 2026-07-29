vim.lsp.enable({
    "lua_ls",
    "gopls",
    "pyright",
    "rust_analyzer",
    "yamlls",
    "jsonls",
    "bashls",
    "fish_lsp",
    "sqls",
    "marksman",
    "taplo",
    "sourcekit", -- swift
    "tsgo",
    "oxlint",
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("User_LspAttach", { clear = true }),
    callback = function(event)
        local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
        local bufnr = event.buf

        local fzf = require("fzf-lua")
        local keymaps = {
            { keys = "<leader>cr", func = vim.lsp.buf.rename, desc = "Rename Symbols" },
            { keys = "K", func = vim.lsp.buf.hover, desc = "Hover Documentation" },
            { keys = "gd", func = vim.lsp.buf.definition, desc = "Goto Definition" },
            { keys = "gi", func = vim.lsp.buf.implementation, desc = "Goto Implementation" },
            { keys = "gt", func = vim.lsp.buf.type_definition, desc = "Goto Type Definition" },

            {
                keys = "<leader>ca",
                func = function()
                    fzf.lsp_code_actions()
                end,
                desc = "Code Action",
            },
            {
                keys = "gr",
                func = function()
                    fzf.lsp_references()
                end,
                desc = "Goto References",
            },
            {
                keys = "gf",
                func = function()
                    fzf.lsp_finder()
                end,
                desc = "Lsp Finder",
            },
            {
                keys = "<leader>ci",
                func = function()
                    fzf.lsp_incoming_calls()
                end,
                desc = "Incoming Calls",
            },
            {
                keys = "<leader>co",
                func = function()
                    fzf.lsp_outgoing_calls()
                end,
                desc = "Outgoing Calls",
            },
            {
                keys = "<leader>dc",
                func = function()
                    fzf.diagnostics_document()
                end,
                desc = "Current Buffer Diagnostics",
            },
            {
                keys = "<leader>dw",
                func = function()
                    fzf.diagnostics_workspace()
                end,
                desc = "Workspace Diagnostics",
            },
        }
        for _, km in ipairs(keymaps) do
            vim.keymap.set("n", km.keys, km.func, { buffer = bufnr, silent = true, nowait = true, desc = "[LSP]: " .. km.desc })
        end

        local severity = vim.diagnostic.severity
        local function diag_prev(sev)
            return function()
                vim.diagnostic.jump({ count = -1, severity = sev, float = true })
            end
        end
        local function diag_next(sev)
            return function()
                vim.diagnostic.jump({ count = 1, severity = sev, float = true })
            end
        end

        local diag_keymaps = {
            { keys = "[d", func = diag_prev(), desc = "Previous Diagnostic" },
            { keys = "]d", func = diag_next(), desc = "Next Diagnostic" },
            { keys = "[e", func = diag_prev(severity.ERROR), desc = "Previous Error" },
            { keys = "]e", func = diag_next(severity.ERROR), desc = "Next Error" },
            { keys = "[w", func = diag_prev(severity.WARN), desc = "Previous WARN" },
            { keys = "]w", func = diag_next(severity.WARN), desc = "Next WARN" },
        }
        for _, km in ipairs(diag_keymaps) do
            vim.keymap.set("n", km.keys, km.func, { buffer = bufnr, silent = true, nowait = true, desc = "[LSP]: " .. km.desc })
        end

        if client:supports_method("textDocument/documentColor") then
            vim.lsp.document_color.enable(true, { bufnr = bufnr, style = "virtual" })
        end

        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
    end,
})
