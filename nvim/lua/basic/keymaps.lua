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

-- Copy file path / selection reference for pasting into AI chats
local function copy_ref(opts)
    local path = vim.fn.expand("%:.")
    local ref = path

    if opts.visual then
        local start_line = vim.fn.line("v")
        local end_line = vim.fn.line(".")
        if start_line > end_line then
            start_line, end_line = end_line, start_line
        end
        -- append the range, e.g. "lua/config/keymaps.lua:1:23"
        ref = path .. ":" .. start_line .. ":" .. end_line
    end

    local note = vim.fn.input("Prompt (optional): ")
    if note ~= "" then
        ref = ref .. " " .. note
    end

    vim.fn.setreg("+", ref)
    vim.notify("Copied: " .. ref)
end

-- normal mode: copy just the file path
vim.keymap.set("n", "<leader>cp", function()
    copy_ref({})
end, { desc = "Copy file path" })

-- visual mode: copy the file path plus the selected line range
vim.keymap.set("v", "<leader>cp", function()
    copy_ref({ visual = true })
end, { desc = "Copy file path with line range" })
