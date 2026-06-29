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
    "sourcekit", --swift
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("User_LspAttach", { clear = true }),
    callback = function(event)
        local client = assert(vim.lsp.get_client_by_id(event.data.client_id))

        local keymap = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
        end

        keymap("[d", "", "[Basic]: cancel [d default")
        keymap("]d", "", "[Basic]: cancel ]d default")

        keymap("<leader>r", vim.lsp.buf.rename, "[Lsp]: Rename Symbols")
        keymap("<leader>,", "<CMD>Lspsaga code_action<CR>", "[Lsp]: Code Action")
        keymap("K", "<CMD>Lspsaga hover_doc<CR>", "[Lsp]: Hover Documentation")
        keymap("gd", "<CMD>Lspsaga goto_definition<CR>", "[Lsp]: Goto Definition")
        keymap("gi", "<CMD>Lspsaga finder imp<CR>", "[Lsp]: Goto Implementation")
        keymap("gr", "<CMD>Lspsaga finder ref<CR>", "[Lsp]: Goto References")
        keymap("gt", "<CMD>Lspsaga goto_type_definition<CR>", "[Lsp]: Goto Type Definition")
        keymap("gf", "<CMD>Lspsaga finder tyd+ref+imp+def<CR>", "[Lsp]: Lsp Finder")

        keymap("<leader>li", "<CMD>Lspsaga incoming_calls<CR>", "[Lsp]: Incoming Calls")
        keymap("<leader>lo", "<CMD>Lspsaga outgoing_calls<CR>", "[Lsp]: Outgoing Calls")

        -- diagnostic keymaps
        keymap("<leader>ld", "<CMD>Lspsaga show_buf_diagnostics ++float<CR>", "[Lsp]: Show Buffer Diagnostics")
        keymap("<leader>lw", "<CMD>Lspsaga show_workspace_diagnostics ++float<CR>", "[Lsp]: Show Workspace Diagnostics")
        keymap("[d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", "[Lsp]: Previous Diagnostic")
        keymap("]d", "<cmd>Lspsaga diagnostic_jump_next<CR>", "[Lsp]: Next Diagnostic")
        keymap("[e", function()
            require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.ERROR })
        end, "[Lsp]: Previous Error")
        keymap("]e", function()
            require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.ERROR })
        end, "[Lsp]: Next Error")
        keymap("[w", function()
            require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.WARN })
        end, "[Lsp]: Previous WARN")
        keymap("]w", function()
            require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.WARN })
        end, "[Lsp]: Next WARN")
        -----------------------------------------------------------------------------------------------------
        -- keymap("K", vim.lsp.buf.hover, "[Lsp]: Hover Documentation")
        -- keymap("gd", vim.lsp.buf.definition, "[Lsp]: Goto Definition")
        -- keymap("gr", vim.lsp.buf.references, "[Lsp]: Goto References")

        -- if client and client:supports_method("textDocument/implementation") then
        --     keymap("gi", vim.lsp.buf.implementation, "Go to Implementation")
        -- end
        -- if client and client:supports_method("textDocument/typeDefinition") then
        --     keymap("gt", vim.lsp.buf.type_definition, "Go to Type Definition")
        -- end

        -- keymap("<leader>cr", vim.lsp.buf.rename, "[Lsp]: Rename Symbols")
        -- keymap("<leader>.", vim.lsp.buf.code_action, "[Lsp]: Code Action")

        if client and client:supports_method("textDocument/documentColor") then
            vim.lsp.document_color.enable(true, { event.buf, style = "virtual" })
        end

        -- [Inlay hint]
        if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
        end
    end,
})
