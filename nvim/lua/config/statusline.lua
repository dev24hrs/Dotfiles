local M = {}

local colors = {
    MAGENTA = "#A89984",
    RED = "#FB4934",
    CYAN = "#8EC07C",
    GREEN = "#B8BB26",
    YELLOW = "#E5C07B",
    ORANGE = "#FE8019",
    BLUE = "#83A598",
    BG = "#282828",
}

-- Disabled filetypes (statusline hidden on these)
local disabled_ft = { alpha = true, dashboard = true }

-- Devicons cache
local _devicons = nil
local function get_icon(name, ext)
    if _devicons == nil then
        local ok, mod = pcall(require, "nvim-web-devicons")
        _devicons = ok and mod or false
    end
    if _devicons == false or not name or name == "" then
        return ""
    end
    local icon = _devicons.get_icon(name, ext, { default = true })
    return icon and (icon .. " ") or ""
end

----------------------------------------------------------------------
-- Highlight groups
----------------------------------------------------------------------
function M.set_highlights()
    -- a: mode
    vim.api.nvim_set_hl(0, "StatusMode", { fg = colors.RED, bg = colors.BG, bold = true })
    vim.api.nvim_set_hl(0, "StatusModeTerm", { fg = colors.RED, bg = colors.BG, bold = true })
    -- b: git
    vim.api.nvim_set_hl(0, "StatusGit", { fg = colors.CYAN, bg = colors.BG, bold = true })
    -- b: diff
    vim.api.nvim_set_hl(0, "StatusDiffAdd", { fg = colors.CYAN, bg = colors.BG })
    vim.api.nvim_set_hl(0, "StatusDiffChange", { fg = colors.ORANGE, bg = colors.BG })
    vim.api.nvim_set_hl(0, "StatusDiffRemove", { fg = colors.RED, bg = colors.BG })
    -- b: diagnostics (per-severity colors)
    vim.api.nvim_set_hl(0, "DiagError", { fg = colors.RED, bg = colors.BG })
    vim.api.nvim_set_hl(0, "DiagWarn", { fg = colors.YELLOW, bg = colors.BG })
    vim.api.nvim_set_hl(0, "DiagInfo", { fg = colors.BLUE, bg = colors.BG })
    vim.api.nvim_set_hl(0, "DiagHint", { fg = colors.MAGENTA, bg = colors.BG })
    -- c: filename
    vim.api.nvim_set_hl(0, "StatusFile", { fg = colors.MAGENTA, bg = colors.BG, bold = true })
    -- x: indent, encoding, fileformat
    vim.api.nvim_set_hl(0, "StatusInfo", { fg = colors.MAGENTA, bg = colors.BG, bold = true })
    -- y: filetype
    vim.api.nvim_set_hl(0, "StatusFiletype", { fg = colors.BLUE, bg = colors.BG, bold = true })
    -- z: lsp
    vim.api.nvim_set_hl(0, "StatusLSP", { fg = colors.RED, bg = colors.BG, bold = true })
end

----------------------------------------------------------------------
-- Mode mapping
----------------------------------------------------------------------
local mode_map = {
    n = "NORMAL",
    i = "INSERT",
    v = "VISUAL",
    V = "V-LINE",
    ["\22"] = "V-BLOCK",
    s = "SELECT",
    S = "S-LINE",
    c = "COMMAND",
    R = "REPLACE",
    t = "TERMINAL",
}

local function mode_component()
    local mode = vim.api.nvim_get_mode().mode
    local name = mode_map[mode] or mode:upper()
    local hl = (mode == "t") and "%#StatusModeTerm#" or "%#StatusMode#"
    return hl .. " " .. name
end

----------------------------------------------------------------------
-- Git branch (gitsigns → Fugitive fallback)
----------------------------------------------------------------------
local function git_branch()
    local ok, head = pcall(function()
        return vim.b.gitsigns_head
    end)
    if ok and head and head ~= "" then
        return " " .. head
    end
    local ok2, fugitive_head = pcall(vim.fn.FugitiveHead)
    if ok2 and fugitive_head and fugitive_head ~= "" then
        return " " .. fugitive_head
    end
    return nil
end

----------------------------------------------------------------------
-- Git diff (gitsigns)
----------------------------------------------------------------------
local function git_diff()
    local ok, gs = pcall(function()
        return vim.b.gitsigns_status_dict
    end)
    if not ok or not gs then
        return nil
    end
    local a, c, r = (gs.added or 0), (gs.changed or 0), (gs.removed or 0)
    if a == 0 and c == 0 and r == 0 then
        return nil
    end
    local parts = {}
    if a > 0 then
        parts[#parts + 1] = "%#StatusDiffAdd#+" .. a
    end
    if c > 0 then
        parts[#parts + 1] = "%#StatusDiffChange#~" .. c
    end
    if r > 0 then
        parts[#parts + 1] = "%#StatusDiffRemove#-" .. r
    end
    return table.concat(parts, " ")
end

----------------------------------------------------------------------
-- Diagnostics
----------------------------------------------------------------------
local diag_severity = vim.diagnostic.severity
local diag_symbols = {
    [diag_severity.ERROR] = "󰅚",
    [diag_severity.WARN] = "󰀪",
    [diag_severity.INFO] = "󰋽",
    [diag_severity.HINT] = "󰌶",
}
local diag_hl = {
    [diag_severity.ERROR] = "%#DiagError#",
    [diag_severity.WARN] = "%#DiagWarn#",
    [diag_severity.INFO] = "%#DiagInfo#",
    [diag_severity.HINT] = "%#DiagHint#",
}

local function diagnostics()
    -- Use vim.diagnostic.count() on Neovim >= 0.10 for O(1) performance
    -- (lualine's nvim_diagnostic source does the same)
    local counts
    if vim.diagnostic.count ~= nil then
        counts = vim.diagnostic.count(0)
    else
        -- Fallback for Neovim < 0.10
        counts = { 0, 0, 0, 0 }
        for _, d in ipairs(vim.diagnostic.get(0)) do
            counts[d.severity] = (counts[d.severity] or 0) + 1
        end
    end

    local parts = {}
    for _, sev in ipairs({ diag_severity.ERROR, diag_severity.WARN, diag_severity.INFO, diag_severity.HINT }) do
        local n = counts[sev] or 0
        if n > 0 then
            parts[#parts + 1] = diag_hl[sev] .. diag_symbols[sev] .. n
        end
    end
    return #parts > 0 and table.concat(parts, " ") or nil
end

----------------------------------------------------------------------
-- Filename
----------------------------------------------------------------------
local function filename()
    local bufname = vim.api.nvim_buf_get_name(0)
    local name
    if bufname == "" then
        name = "[No Name]"
    else
        name = vim.fn.fnamemodify(bufname, ":t")
    end
    return name
end

----------------------------------------------------------------------
-- Indent style
----------------------------------------------------------------------
local function indent_info()
    local expandtab = vim.bo.expandtab
    local sw = vim.bo.shiftwidth
    if expandtab then
        return "Spaces: " .. sw
    else
        return "Tab Size: " .. sw
    end
end

----------------------------------------------------------------------
-- File format
----------------------------------------------------------------------
local ff_map = { unix = "LF", dos = "CRLF", mac = "CR" }
local function fileformat()
    return ff_map[vim.bo.fileformat] or vim.bo.fileformat
end

----------------------------------------------------------------------
-- Filetype
----------------------------------------------------------------------
local function filetype()
    local ft = vim.bo.filetype
    if ft == "" then
        return "no ft"
    end
    local name = vim.api.nvim_buf_get_name(0)
    local fname = name ~= "" and vim.fn.fnamemodify(name, ":t") or nil
    local ext = vim.fn.fnamemodify(name, ":e")
    return get_icon(fname, ext) .. ft
end

----------------------------------------------------------------------
-- LSP status (attached client names)
----------------------------------------------------------------------
local function lsp_status()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
        return nil
    end
    local names = {}
    for _, c in ipairs(clients) do
        names[#names + 1] = c.name
    end
    return table.concat(names, ", ")
end

----------------------------------------------------------------------
-- Main statusline (called by v:lua.statusline)
----------------------------------------------------------------------
function _G.statusline()
    if disabled_ft[vim.bo.filetype] then
        return ""
    end

    local left = {}

    -- a: mode
    left[#left + 1] = mode_component()

    -- b: branch + diff + diagnostics
    local branch = git_branch()
    if branch then
        left[#left + 1] = "%#StatusGit#" .. branch
    end

    -- c: filename
    left[#left + 1] = "%#StatusFile#" .. filename()

    local diff = git_diff()
    if diff then
        left[#left + 1] = diff
    end
    local diags = diagnostics()
    if diags then
        left[#left + 1] = diags
    end

    -- right side
    local right = {}

    -- x: indent + encoding + fileformat
    right[#right + 1] = "%#StatusInfo#" .. indent_info() .. " "
    right[#right + 1] = "%#StatusInfo# " .. (vim.bo.fileencoding or vim.o.encoding) .. " "
    right[#right + 1] = "%#StatusInfo# " .. fileformat() .. " "

    -- y: filetype
    right[#right + 1] = "%#StatusFiletype# " .. filetype() .. " "

    -- z: lsp + position
    local lsp = lsp_status()
    if lsp then
        right[#right + 1] = "%#StatusLSP# " .. lsp .. " "
    end

    return table.concat(left, "  ") .. " %=" .. table.concat(right, "")
end

----------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------
function M.setup()
    M.set_highlights()

    local statusline_group = vim.api.nvim_create_augroup("User_Statusline", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = statusline_group,
        callback = M.set_highlights,
    })

    vim.opt.laststatus = 3
    vim.opt.statusline = "%!v:lua.statusline()"
end

-- Start with no statusline; activate on first buffer backed by a real file
vim.opt.laststatus = 0

local setup_group = vim.api.nvim_create_augroup("StatuslineDefer", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
    group = setup_group,
    callback = function()
        if vim.fn.filereadable(vim.api.nvim_buf_get_name(0)) ~= 1 then
            return
        end
        M.setup()
        vim.api.nvim_del_augroup_by_name("StatuslineDefer")
    end,
})

return M
