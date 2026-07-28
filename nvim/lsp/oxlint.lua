local function oxlint_conf_mentions_typescript(root_dir)
    local fn = vim.fs.joinpath(root_dir, ".oxlintrc.json")
    local ok, lines = pcall(io.lines, fn)
    if not ok then
        return false
    end
    for line in lines do
        if line:find("typescript") then
            return true
        end
    end
    return false
end

---@type vim.lsp.Config
return {
    cmd = function(dispatchers, config)
        local cmd = "oxlint"
        if (config or {}).root_dir then
            local local_cmd = vim.fs.joinpath(config.root_dir, "node_modules/.bin", cmd)
            if vim.fn.executable(local_cmd) == 1 then
                cmd = local_cmd
            end
        end
        return vim.lsp.rpc.start({ cmd, "--lsp" }, dispatchers)
    end,
    filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "vue",
        "svelte",
        "astro",
    },
    root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        local root_markers = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts", "package.json", ".git" }
        on_dir(vim.fs.dirname(vim.fs.find(root_markers, { path = fname, upward = true })[1]))
    end,
    workspace_required = true,
    on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, "LspOxlintFixAll", function()
            client:exec_cmd({
                title = "Apply Oxlint automatic fixes",
                command = "oxc.fixAll",
                arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
            })
        end, {
            desc = "Apply Oxlint automatic fixes",
        })
    end,
    settings = {
        -- run = 'onType',
        -- configPath = nil,
        -- tsConfigPath = nil,
        unusedDisableDirectives = "warn", -- 警告过时的 oxlint-disable 注释
        -- typeAware = false,             -- 由 before_init 自动检测 tsgolint
        -- disableNestedConfig = false,
        -- fixKind = 'safe_fix',
    },
    before_init = function(init_params, config)
        local settings = config.settings or {}
        local has_tsgolint = vim.fn.executable("tsgolint") == 1
        if not has_tsgolint and (config or {}).root_dir then
            local local_cmd = vim.fs.joinpath(config.root_dir, "node_modules/.bin", "tsgolint")
            has_tsgolint = vim.fn.executable(local_cmd) == 1
        end
        if settings.typeAware == nil and has_tsgolint then
            local ok, res = pcall(oxlint_conf_mentions_typescript, config.root_dir)
            if ok and res then
                settings = vim.tbl_extend("force", settings, { typeAware = true })
            end
        end
        local init_options = config.init_options or {}
        init_options.settings = vim.tbl_extend("force", init_options.settings or {} --[[@as table]], settings)

        init_params.initializationOptions = init_options
    end,
}
