-- Basic
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.have_nerd_font = true
vim.opt.termguicolors = true

-- Performance improvements
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.swapfile = false
vim.opt.backup = false

-- UI &
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.showmode = false
vim.opt.laststatus = 3
vim.opt.cmdheight = 1

vim.opt.wrap = true
vim.opt.list = true

vim.opt.conceallevel = 2
vim.opt.winborder = "single"
vim.opt.signcolumn = "number"
vim.opt.inccommand = "nosplit"
vim.opt.completeopt = "menu,menuone,noselect,noinsert"

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5
vim.opt.jumpoptions = "stack"
vim.opt.iskeyword:append("-")
vim.opt.grepprg = "rg --vimgrep --no-heading"
vim.opt.grepformat = "%f:%l:%c:%m,%f:%l:%m"

-- Indent
-- NOTE: tabstop & shiftwidth & expandtab & softtabstop refer to langIndent.lua to different languages settings
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.opt.autoindent = true
vim.opt.smartindent = false
-- require('basic.langIndent')

-- UTF8
vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- Others
vim.opt.splitright = true
vim.g.bigfile_size = 1024 * 1024 * 1.5
vim.g.markdown_folding = 1

-- 文件类型映射
vim.filetype.add({
    extension = {
        mdx = "markdown",
    },
    filename = {
        ["LICENSE"] = "license",
        ["docker-compose.yaml"] = "yaml",
        ["docker-compose.yml"] = "yaml",
        ["go.work"] = "gowork",
        [".yamllint"] = "yaml",
        [".yamlfmt"] = "yaml",
    },
    pattern = {
        ["docker%-compose%..*%.ya?ml"] = "yaml",
        [".*%.gotmpl"] = "gotmpl",
        [".*%.yamllint"] = "yaml",
    },
})
