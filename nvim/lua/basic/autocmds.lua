-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "highlight copying text",
    group = vim.api.nvim_create_augroup("User_HighlightYank", { clear = true }),
    callback = function()
        vim.hl.on_yank({ timeout = 500 })
    end,
})

-- don't auto comment new line
vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = "*",
    callback = function()
        vim.opt.formatoptions = vim.opt.formatoptions - { "c", "r", "o" }
    end,
})

-- go to last position when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        vim.opt_local.textwidth = 120
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.list = false
        vim.opt_local.conceallevel = 0
    end,
})

-- 注册 :PackClean
vim.api.nvim_create_user_command("PackClean", function()
    local unused_plugins = {}

    for _, p in ipairs(vim.pack.get()) do
        if not p.active then
            table.insert(unused_plugins, p.spec.name)
        end
    end

    if #unused_plugins == 0 then
        return vim.notify("No unused plugins found.", vim.log.levels.INFO)
    end

    vim.notify("Detected unused plugins: " .. table.concat(unused_plugins, ", "), vim.log.levels.INFO)

    if vim.fn.confirm("Delete these plugins from disk?", "&Yes\n&No", 2) == 1 then
        vim.pack.del(unused_plugins)
        vim.notify("Cleaned successfully.", vim.log.levels.INFO)
    else
        vim.notify("Cleaned canceled.", vim.log.levels.INFO)
    end
end, {})

-- 注册 :PackUpdate
vim.api.nvim_create_user_command("PackUpdate", function()
    local plugins_to_update = {}

    for _, p in ipairs(vim.pack.get()) do
        if p.active then
            table.insert(plugins_to_update, p.spec.name)
        end
    end

    if #plugins_to_update == 0 then
        return vim.notify("No active plugins to update...", vim.log.levels.INFO)
    end

    vim.notify("Checking updates for all plugins...", vim.log.levels.INFO)
    vim.pack.update(plugins_to_update)
end, {})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
    desc = "Close specific buffers with <q>",
    group = vim.api.nvim_create_augroup("User_CloseWithQ", { clear = true }),
    pattern = {
        "help",
        "lspinfo",
        "man",
        "qf",
        "notify",
        "checkhealth",
        "spectre_panel",
        "nvim-pack",
        "toggleterm",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
})

-- 创建 :H 命令，在新的竖屏中打开 help
vim.api.nvim_create_user_command("H", function(opts)
    vim.cmd("vertical help " .. (opts.args ~= "" and opts.args or ""))
end, { nargs = "*", complete = "help" })
