vim.pack.add({
    { src = "https://github.com/akinsho/toggleterm.nvim" },
})
require("toggleterm").setup({
    -- open_mapping = [[<c-t>]],
    open_mapping = [[<leader>lt]],
    autochdir = true,
    shading_factor = "1",
    direction = "float",
    float_opts = {
        width = function()
            return math.floor(vim.o.columns * 0.6)
        end,
        height = function()
            return math.floor(vim.o.lines * 0.6)
        end,

        border = "single",
    },
})
local terminal_group = vim.api.nvim_create_augroup("User_ToggleTerm", { clear = true })

vim.api.nvim_create_autocmd("TermOpen", {
    group = terminal_group,
    pattern = "term://*toggleterm#*",
    callback = function()
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], { buffer = 0 })
    end,
})

-- lazygit
local Terminal = require("toggleterm.terminal").Terminal
local lazygit = Terminal:new({
    cmd = "lazygit",
    dir = "git_dir",
    direction = "float",
    float_opts = {
        width = function()
            return math.floor(vim.o.columns * 0.8)
        end,
        height = function()
            return math.floor(vim.o.lines * 0.8)
        end,
        border = "single",
    },
    -- function to run on opening the terminal
    on_open = function(term)
        vim.cmd("startinsert!")
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = term.bufnr, noremap = true, silent = true })
    end,
    -- function to run on closing the terminal
    on_close = function()
        vim.cmd("startinsert!")
    end,
})

vim.keymap.set("n", "<leader>lg", function()
    lazygit:toggle()
end, { desc = "[ToggleTerm]: Toggle Lazygit" })
