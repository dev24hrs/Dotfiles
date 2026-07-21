return {
    init_options = { hostInfo = "neovim" },
    settings = {
        typescript = {
            inlayHints = {
                -- 调用处显示参数名提示，如 `foo(name, age)`
                -- "none" = 关闭, "literals" = 仅字面量参数, "all" = 全部参数
                includeInlayParameterNameHints = "literals",
                -- 实参名与形参相同时隐藏提示
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                -- 推断的函数参数类型提示，如 `x: number`
                includeInlayFunctionParameterTypeHints = true,
                -- 推断的变量声明类型提示
                includeInlayVariableTypeHints = true,
                -- 推断的对象/类属性声明类型提示
                includeInlayPropertyDeclarationTypeHints = true,
                -- 推断的函数/方法返回类型提示
                includeInlayFunctionLikeReturnTypeHints = true,
                -- 枚举成员值内联提示，如 `Color.Red = 0`
                includeInlayEnumMemberValueHints = true,
            },
        },
        javascript = {
            inlayHints = {
                includeInlayParameterNameHints = "literals",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
            },
        },
    },
    cmd = { "tsc", "--lsp", "--stdio" },
    filetypes = {
        "javascript",
        "javascript.jsx",
        "javascriptreact",
        "typescript",
        "typescript.tsx",
        "typescriptreact",
    },
    root_dir = function(bufnr, on_dir)
        -- The project root is where the LSP can be started from
        -- As stated in the documentation above, this LSP supports monorepos and simple projects.
        -- We select then from the project root, which is identified by the presence of a package
        -- manager lock file.
        local root_markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
        -- Give the root markers equal priority by wrapping them in a table.
        -- Use feature detection instead of exact version check: vim.fs.root supports nested marker tables since 0.10.
        -- tsconfig.json / jsconfig.json take highest priority to match the project boundary (official tsgo behavior).
        local ok, _ = pcall(vim.fs.root, bufnr, { { "package.json" }, { ".git" } })
        if ok then
            root_markers = { { "tsconfig.json", "jsconfig.json" }, root_markers, { ".git" } }
        else
            root_markers = vim.list_extend({ "tsconfig.json", "jsconfig.json" }, root_markers)
            vim.list_extend(root_markers, { ".git" })
        end
        -- exclude deno: compare by directory depth, not string length
        local function path_depth(p)
            if not p then
                return 0
            end
            local count = 0
            for _ in p:gmatch("/") do
                count = count + 1
            end
            return count
        end
        local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
        local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })
        local project_root = vim.fs.root(bufnr, root_markers)
        if deno_lock_root and (not project_root or path_depth(deno_lock_root) > path_depth(project_root)) then
            -- deno lock is closer than package manager lock, abort
            return
        end
        if deno_root and (not project_root or path_depth(deno_root) >= path_depth(project_root)) then
            -- deno config is closer than or equal to package manager lock, abort
            return
        end
        -- project is standard TS, not deno
        -- We fallback to the current working directory if no project root is found
        on_dir(project_root or vim.fn.getcwd())
    end,
    handlers = {
        -- handle rename request for certain code actions like extracting functions / types
        ["_typescript.rename"] = function(_, result, ctx)
            local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
            vim.lsp.util.show_document({
                uri = result.textDocument.uri,
                range = {
                    start = result.position,
                    ["end"] = result.position,
                },
            }, client.offset_encoding)
            vim.lsp.buf.rename()
            return vim.NIL
        end,
    },
    commands = {
        ["editor.action.showReferences"] = function(command, ctx)
            local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
            local file_uri, position, references = unpack(command.arguments)

            local quickfix_items = vim.lsp.util.locations_to_items(references --[[@as any]], client.offset_encoding)
            vim.fn.setqflist({}, " ", {
                title = command.title,
                items = quickfix_items,
                context = {
                    command = command,
                    bufnr = ctx.bufnr,
                },
            })

            vim.lsp.util.show_document({
                uri = file_uri,
                range = {
                    start = position,
                    ["end"] = position,
                },
            }, client.offset_encoding)
            ---@diagnostic enable: assign-type-mismatch

            vim.cmd("botright copen")
        end,
    },
    on_attach = function(client, bufnr)
        -- Helper: create buffer command, handling re-attach by silently replacing existing command
        local function buf_create_cmd(name, opts, fn)
            pcall(vim.api.nvim_buf_del_user_command, bufnr, name)
            vim.api.nvim_buf_create_user_command(bufnr, name, fn, opts)
        end

        -- ts_ls provides `source.*` code actions that apply to the whole file. These only appear in
        -- `vim.lsp.buf.code_action()` if specified in `context.only`.
        buf_create_cmd("LspTypescriptSourceAction", {}, function()
            local source_actions = vim.tbl_filter(function(action)
                return vim.startswith(action, "source.")
            end, client.server_capabilities.codeActionProvider.codeActionKinds)

            vim.lsp.buf.code_action({
                context = {
                    only = source_actions,
                    diagnostics = {},
                },
            })
        end)

        -- Go to source definition command
        buf_create_cmd("LspTypescriptGoToSourceDefinition", { desc = "Go to source definition" }, function()
            local win = vim.api.nvim_get_current_win()
            local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
            client:exec_cmd({
                command = "_typescript.goToSourceDefinition",
                title = "Go to source definition",
                arguments = { params.textDocument.uri, params.position },
            }, { bufnr = bufnr }, function(err, result)
                if err then
                    vim.notify("Go to source definition failed: " .. err.message, vim.log.levels.ERROR)
                    return
                end
                if not result or vim.tbl_isempty(result) then
                    vim.notify("No source definition found", vim.log.levels.INFO)
                    return
                end
                vim.lsp.util.show_document(result[1], client.offset_encoding, { focus = true })
            end)
        end)
    end,
}
