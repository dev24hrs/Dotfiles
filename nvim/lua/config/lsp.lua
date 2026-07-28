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
    "ts_ls",
    "marksman",
    "taplo",
    "sourcekit", -- swift
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("User_LspAttach", { clear = true }),
    callback = function(event)
        local client = assert(vim.lsp.get_client_by_id(event.data.client_id))
        local bufnr = event.buf

        local fzf = require("fzf-lua")

        local function buf_map(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end

        -- Code actions & rename
        buf_map("<leader>,", function()
            fzf.lsp_code_actions()
        end, "[Lsp]: Code Action")
        buf_map("<leader>r", vim.lsp.buf.rename, "[Lsp]: Rename Symbols")

        -- Hover & navigation
        buf_map("K", vim.lsp.buf.hover, "[Lsp]: Hover Documentation")
        buf_map("gd", vim.lsp.buf.definition, "[Lsp]: Goto Definition")
        buf_map("gi", vim.lsp.buf.implementation, "[Lsp]: Goto Implementation")
        buf_map("gt", vim.lsp.buf.type_definition, "[Lsp]: Goto Type Definition")

        -- Fuzzy search
        buf_map("gr", function()
            fzf.lsp_references()
        end, "[Lsp]: Goto References")
        buf_map("gf", function()
            fzf.lsp_finder()
        end, "[Lsp]: Lsp Finder")
        buf_map("<leader>li", function()
            fzf.lsp_incoming_calls()
        end, "[Lsp]: Incoming Calls")
        buf_map("<leader>lo", function()
            fzf.lsp_outgoing_calls()
        end, "[Lsp]: Outgoing Calls")

        -- Diagnostics: list
        buf_map("<leader>ld", function()
            fzf.diagnostics_document()
        end, "[Lsp]: Buffer Diagnostics")
        buf_map("<leader>lw", function()
            fzf.diagnostics_workspace()
        end, "[Lsp]: Workspace Diagnostics")

        -- Diagnostics: jump
        local severity = vim.diagnostic.severity
        local function diag_prev(sev)
            return function()
                vim.diagnostic.jump({ count = -1, severity = sev })
            end
        end
        local function diag_next(sev)
            return function()
                vim.diagnostic.jump({ count = 1, severity = sev })
            end
        end

        buf_map("[d", diag_prev(), "[Lsp]: Previous Diagnostic")
        buf_map("]d", diag_next(), "[Lsp]: Next Diagnostic")
        buf_map("[e", diag_prev(severity.ERROR), "[Lsp]: Previous Error")
        buf_map("]e", diag_next(severity.ERROR), "[Lsp]: Next Error")
        buf_map("[w", diag_prev(severity.WARN), "[Lsp]: Previous WARN")
        buf_map("]w", diag_next(severity.WARN), "[Lsp]: Next WARN")

        if client:supports_method("textDocument/documentColor") then
            vim.lsp.document_color.enable(true, { bufnr, style = "virtual" })
        end

        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
    end,
})
