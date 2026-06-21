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
function _Set_terminal_keymaps()
    local opts = { buffer = 0 }
    vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
end
vim.cmd("autocmd! TermOpen term://*toggleterm#* lua _Set_terminal_keymaps()")

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
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
    end,
    -- function to run on closing the terminal
    on_close = function()
        vim.cmd("startinsert!")
    end,
})

function _Lazygit_toggle()
    lazygit:toggle()
end

vim.api.nvim_set_keymap("n", "<leader>lg", "<cmd>lua _Lazygit_toggle()<CR>", { noremap = true, silent = true })
