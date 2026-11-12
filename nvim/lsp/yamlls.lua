---@type vim.lsp.Config
return {
    cmd = function(dispatchers, config)
        local cmd = "yaml-language-server"
        if (config or {}).root_dir then
            local local_cmd = vim.fs.joinpath(config.root_dir, "node_modules/.bin", cmd)
            if vim.fn.executable(local_cmd) == 1 then
                cmd = local_cmd
            end
        end
        return vim.lsp.rpc.start({ cmd, "--stdio" }, dispatchers)
    end,
    filetypes = { "yaml", "yaml.docker-compose" },
    root_markers = { ".git" },
    settings = {
        -- https://github.com/redhat-developer/vscode-redhat-telemetry#how-to-disable-telemetry-reporting
        redhat = { telemetry = { enabled = false } },
        yaml = {
            format = { enable = true },
            validate = true,
            hover = true,
            completion = true,
            -- Schema Store auto-detects schemas by filename. Manual schemas below take priority.
            schemaStore = { enable = true },
            schemas = {
                -- Kubernetes: use built-in keyword for auto version matching
                kubernetes = {
                    "k8s/**/*.yaml",
                    "kubernetes/**/*.yaml",
                },
                -- Docker Compose
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = {
                    "docker-compose*.yaml",
                    "docker-compose*.yml",
                    "compose*.yaml",
                    "compose*.yml",
                },
                -- GitHub Actions
                ["https://json.schemastore.org/github-workflow.json"] = ".github/workflows/*.yaml",
                ["https://json.schemastore.org/github-action.json"] = ".github/actions/*/action.yaml",
                -- GitLab CI
                ["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = ".gitlab-ci.yml",
            },
        },
    },
}
