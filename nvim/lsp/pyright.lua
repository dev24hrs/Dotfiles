---@brief
--- https://github.com/microsoft/pyright
--- `pyright`, a static type checker and language server for python

local function set_python_path(command)
    local path = command.args
    local clients = vim.lsp.get_clients({
        bufnr = vim.api.nvim_get_current_buf(),
        name = "pyright",
    })
    for _, client in ipairs(clients) do
        if client.settings then
            client.settings.python = vim.tbl_deep_extend("force", client.settings.python --[[@as table]], { pythonPath = path })
        else
            client.config.settings = vim.tbl_deep_extend("force", client.config.settings, { python = { pythonPath = path } })
        end
        client:notify("workspace/didChangeConfiguration", { settings = nil })
    end
end

---@type vim.lsp.Config
return {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = {
        "pyrightconfig.json",
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        ".git",
    },
    settings = {
        pyright = {
            -- Using Ruff's import organizer
            disableOrganizeImports = true,
        },
        python = {
            analysis = {
                -- Ignore all files for analysis to use Ruff for linting
                ignore = { "*" },
                typeCheckingMode = "standard",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                autoImportCompletions = true,
                stubPath = "typings",
                diagnosticMode = "openFilesOnly",
                inlayHints = {
                    variableTypes = true,
                    functionReturnTypes = true,
                },
                exclude = {
                    "**/__pycache__", -- Python 字节码缓存
                    "**/.git", -- Git 元数据
                    "**/.eggs", -- egg 包缓存
                    "**/*.egg-info", -- egg 元数据
                    "**/.mypy_cache", -- mypy 缓存（如有共存）
                    "**/.pytest_cache", -- pytest 缓存
                    "**/.venv", -- venv 虚拟环境
                    "**/.venv*", -- 命名变体（.venv38 等）
                    "**/venv", -- 传统 venv 目录
                    "**/.tox", -- tox 测试环境
                    "**/build", -- 构建中间产物
                    "**/dist", -- 分发包目录
                    "**/htmlcov", -- coverage 报告
                    "**/node_modules", -- 前端依赖（某些 Python 项目也包含）
                },
            },
        },
    },
    on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, "LspPyrightOrganizeImports", function()
            local params = {
                command = "pyright.organizeimports",
                arguments = { vim.uri_from_bufnr(bufnr) },
            }

            ---@diagnostic disable-next-line: param-type-mismatch
            client.request("workspace/executeCommand", params, nil, bufnr)
        end, {
            desc = "Organize Imports",
        })
        vim.api.nvim_buf_create_user_command(bufnr, "LspPyrightSetPythonPath", set_python_path, {
            desc = "Reconfigure pyright with the provided python path",
            nargs = 1,
            complete = "file",
        })
    end,
}
