---@type vim.lsp.Config
return {
    cmd = function(dispatchers, config)
        local cmd = "vscode-json-language-server"
        if (config or {}).root_dir then
            local local_cmd = vim.fs.joinpath(config.root_dir, "node_modules/.bin", cmd)
            if vim.fn.executable(local_cmd) == 1 then
                cmd = local_cmd
            end
        end
        return vim.lsp.rpc.start({ cmd, "--stdio" }, dispatchers)
    end,
    filetypes = { "json", "jsonc" },
    root_markers = { ".git" },
    settings = {
        json = {
            -- JSON Schema 校验（检查 JSON 结构合法性）
            validate = { enable = true },
            -- 格式化（替代 init_options.provideFormatter 的新写法）
            format = { enable = true },
            -- 补全/折叠/大纲等结果的返回上限
            resultLimit = 5000,
            -- 自动从 schemastore.org 下载常见文件的 schema，按需缓存到本地
            schemaDownload = {
                enable = true,
                cachePath = vim.fn.stdpath("cache") .. "/jsonls-schemas",
            },
            -- 手动映射文件匹配模式到自定义 schema URL
            schemas = {
                {
                    -- .luarc.json 使用 lua-language-server 的 schema
                    fileMatch = { ".luarc.json" },
                    url = "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
                },
            },
        },
    },
}
