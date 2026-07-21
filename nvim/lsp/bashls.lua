---@type vim.lsp.Config
return {
    cmd = { "bash-language-server", "start" },
    settings = {
        bashIde = {
            -- 文件类型匹配模式（可通过环境变量 GLOB_PATTERN 覆盖）
            globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
            -- 跨文件符号搜索，dotfiles 等多脚本仓库场景实用
            includeAllWorkspaceSymbols = true,
            -- hover 到 shell 命令时显示 explainshell.com 的参数说明
            explainshellEndpoint = true,
            -- 后台分析文件数上限（默认 1000，大仓库可调大避免分析截断）
            backgroundAnalysisMaxFiles = 2000,
            -- 日志级别：warning 减少冗余输出
            logLevel = "warning",
            -- shfmt 格式化（本地已安装）
            shfmt = {
                path = "shfmt",
                spaceRedirects = true, -- cmd > file 而非 cmd>file
                indent = 2, -- 缩进宽度
                binaryNextLine = true, -- && / || 换行到下一行
                caseIndent = true, -- case 语句缩进
                funcNextLine = true, -- function 关键字后换行
                keepPadding = true, -- 保留列对齐的空格
            },
        },
    },
    filetypes = { "bash", "sh" },
    root_markers = { ".git" },
}
