local root_markers1 = {
    ".emmyrc.json",
    ".luarc.json",
    ".luarc.jsonc",
}
local root_markers2 = {
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
}

return {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { root_markers1, root_markers2, { ".git" } },
    settings = {
        Lua = {
            diagnostics = { globals = { "vim" } },
            codeLens = { enable = true },
            completion = { callSnippet = "Replace", keywordSnippet = "Replace" },
            hint = { enable = true, setType = false, paramName = "Literal", paramType = true, semicolon = "Disable" },
            runtime = { pathStrict = true },
            telemetry = { enable = false },
        },
    },
}
