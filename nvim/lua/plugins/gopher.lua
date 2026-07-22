vim.pack.add({
    { src = "https://github.com/olexsmir/gopher.nvim" },
})
---@diagnostic disable-next-line: missing-fields
require("gopher").setup({
    log_level = vim.log.levels.INFO,
    timeout = 2000,
    installer_timeout = 999999,
    commands = {
        go = "go",
        gomodifytags = "gomodifytags",
        gotests = "gotests",
        impl = "impl",
        iferr = "iferr",
    },
    gotests = {
        template = "default",
        template_dir = nil,
        named = false,
    },
    gotag = {
        transform = "snakecase",
        default_tag = "json",
        option = nil,
    },
    iferr = {
        message = nil,
    },
    json2go = {
        interactive_cmd = "vsplit",
        type_name = nil,
    },
})

vim.keymap.set("n", "<leader>gj", "<cmd>GoTagAdd json<cr>", { desc = "[Gopher]: Add JSON tags" })
vim.keymap.set("n", "<leader>gy", "<cmd>GoTagAdd yaml<cr>", { desc = "[Gopher]: Add YAML tags" })
vim.keymap.set("n", "<leader>gr", "<cmd>GoTagRm json<cr>", { desc = "[Gopher]: Remove JSON tags" })
