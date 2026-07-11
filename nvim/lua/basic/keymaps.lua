vim.g.mapleader = " "
vim.g.maplocalleader = " "

local function keymap(mode, lhs, rhs, desc)
    local options = { noremap = true, silent = true, desc = desc }
    vim.keymap.set(mode, lhs, rhs, options)
end

keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", "[Basic]: clear search highlight")

keymap("i", "<S-Tab>", "<C-d>", "[Basic]: Outdent code in insert mode")

-- Indent code in visual mode
keymap("v", "<", "<gv", "[Basic]: Indent code in visual mode")
keymap("v", ">", ">gv", "[Basic]: Indent code in visual mode")

keymap("v", "J", ":m '>+1<CR>gv=gv", "[Basic]: move selected line down")
keymap("v", "K", ":m '<-2<CR>gv=gv", "[Basic]: move selected line up")

keymap({ "n", "v" }, "W", "^", "[Basic]: move cursor to line head")
keymap({ "n", "v" }, "E", "$", "[Basic]: move cursor to line end")

keymap("n", "wq", "<cmd>wq<CR>", "[Basic]: quit in normal mode")

-- Move between soft-wrapped lines with
keymap("n", "j", "gj", "[Basic]: move cursor down")
keymap("n", "k", "gk", "[Basic]: move cursor up")
