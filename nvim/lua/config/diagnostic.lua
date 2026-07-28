vim.diagnostic.config({
    update_in_insert = false,
    severity_sort = true,
    float = { border = "single", source = true },
    underline = { severity = vim.diagnostic.severity.ERROR },
    virtual_text = {
        format = function(diagnostic)
            local msg = diagnostic.message:gsub("\n", " ")
            return string.format("%s [%s] ", msg, diagnostic.source)
        end,
        spacing = 4,
        source = "if_many",
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
        },
        numhl = {
            [vim.diagnostic.severity.ERROR] = "ErrorMsg",
            [vim.diagnostic.severity.WARN] = "WarningMsg",
        },
    },
})
