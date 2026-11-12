-- Basic
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
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
-- vim.opt.laststatus = 3   -- set in lua/config/statusline.lua:293
vim.opt.cmdheight = 0

vim.opt.wrap = true
vim.opt.list = true
-- 用两个空格渲染 Tab（省略 tab: 会显示 ^I）；行尾空格/不断行空格仍可见
vim.opt.listchars = "tab:  ,trail:-,nbsp:+"

vim.opt.autoread = true
vim.opt.conceallevel = 0
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

-- Others
vim.opt.splitright = true
vim.g.markdown_folding = 1

-- 文件类型映射
vim.filetype.add({
    extension = {
        gotmpl = "gotmpl",
        mdx = "markdown",
    },
    filename = {
        ["LICENSE"] = "license",
        [".yamllint"] = "yaml",
        [".yamlfmt"] = "yaml",
    },
    pattern = {
        [".*/docker%-compose[^/]*%.yml"] = "yaml.docker-compose",
        [".*/docker%-compose[^/]*%.yaml"] = "yaml.docker-compose",
        [".*/compose[^/]*%.yml"] = "yaml.docker-compose",
        [".*/compose[^/]*%.yaml"] = "yaml.docker-compose",
    },
})
