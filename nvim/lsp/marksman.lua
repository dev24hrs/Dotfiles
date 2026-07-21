return {
    cmd = { "marksman", "server" },
    filetypes = { "markdown", "markdown.mdx" },
    root_markers = { ".marksman.toml", ".git" },
    single_file_support = true,
    settings = {
        marksman = {
            -- 提供"插入目录"的 Code Action，自动扫描标题生成 TOC
            code_action = { toc = { enable = true } },
        },
    },
}
