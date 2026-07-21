---@type vim.lsp.Config
return {
    cmd = { "taplo", "lsp", "stdio" },
    filetypes = { "toml" },
    root_markers = { ".git", "Cargo.toml", "pyproject.toml" },
    settings = {
        taplo = {
            schema = {
                enabled = true,
                associations = {
                    ["Cargo.toml"] = "taplo://cargo@Cargo.toml",
                    ["pyproject.toml"] = "https://json.schemastore.org/pyproject.json",
                    ["rust-toolchain.toml"] = "https://json.schemastore.org/rust-toolchain.json",
                    ["taplo.toml"] = "taplo://taplo.toml",
                    [".taplo.toml"] = "taplo://taplo.toml",
                },
            },
            -- Limit completion depth for large schemas (e.g., Cargo.toml dependencies)
            completion = {
                max_keys = 10,
            },
        },
    },
}
