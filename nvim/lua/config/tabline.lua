local M = {}

local SEP = "" -- separator between tabs
local MODIFIED = "" -- indicator for buffers with unsaved changes
local NO_NAME = "[NO NAME]"
local OVERFLOW_LEFT = "«"
local OVERFLOW_RIGHT = "»"

local _tab_cache = nil
local _tab_cache_key = nil

function M.set_highlights()
    local bg = "#282828"
    local red = "#FB4934"

    vim.api.nvim_set_hl(0, "MyBufInactive", { bg = bg })
    vim.api.nvim_set_hl(0, "MyBufActive", { fg = red, bg = bg, bold = true })
    vim.api.nvim_set_hl(0, "MyBufSeparator", { bg = bg })
    vim.api.nvim_set_hl(0, "MyBufModified", { fg = red, bg = bg })
end

----------------------------------------------------------------------
-- Devicons: require once, cache at module scope
----------------------------------------------------------------------
local _devicons = nil

local function get_icon(filename, name)
    if _devicons == nil then
        local ok, mod = pcall(require, "nvim-web-devicons")
        _devicons = ok and mod or false
    end
    if _devicons == false or not name or name == "" then
        return ""
    end
    local ext = vim.fn.fnamemodify(name, ":e")
    local icon = _devicons.get_icon(filename, ext, { default = true })
    return icon and (icon .. " ") or ""
end

----------------------------------------------------------------------
-- Display helpers
----------------------------------------------------------------------
local function get_display_name(path)
    if path == "" then
        return NO_NAME
    end
    local parent = vim.fn.fnamemodify(path, ":h:t")
    local filename = vim.fn.fnamemodify(path, ":t")
    if parent == "" then
        return filename
    end
    return parent .. "/" .. filename
end

local function display_width(s)
    -- Strip all statusline % items so only visible text is measured
    local stripped = s
        :gsub("%%#[^#]*#", "") -- highlight groups %#Name#
        :gsub("%%[0-9]*@[^@]*@", "") -- click regions %N@Func@
        :gsub("%%X", "") -- click region end
        :gsub("%%%%", "%%") -- escaped percent
    return vim.api.nvim_strwidth(stripped)
end

----------------------------------------------------------------------
-- Mouse click handler (called by %<bufnr>@v:lua.tabline_click@...%X)
-- Left-click: switch to buffer   Middle-click: close buffer
----------------------------------------------------------------------
function _G.tabline_click(minwid, clicks, button, modifiers)
    _ = clicks
    _ = modifiers
    if button == "l" then
        vim.api.nvim_set_current_buf(minwid)
    end
end

----------------------------------------------------------------------
-- Buffer rendering (caller guarantees: loaded + listed)
----------------------------------------------------------------------
local function render_buf(bufnr, current)
    local name = vim.api.nvim_buf_get_name(bufnr)
    local display_name = get_display_name(name)
    local filename = (name ~= "" and vim.fn.fnamemodify(name, ":t")) or NO_NAME
    local icon = get_icon(filename, name)
    local modified = vim.bo[bufnr].modified and ("%#MyBufModified#" .. MODIFIED .. " ") or ""
    local content = icon .. display_name .. " " .. modified

    if bufnr == current then
        return table.concat({
            "%" .. bufnr .. "@v:lua.tabline_click@",
            "%#MyBufActive# ",
            content,
            "%#MyBufSeparator#",
            SEP,
        })
    else
        return table.concat({
            "%" .. bufnr .. "@v:lua.tabline_click@",
            "%#MyBufInactive# ",
            content,
            "%#MyBufSeparator#",
            SEP,
        })
    end
end

----------------------------------------------------------------------
-- Main tabline entry point (called by v:lua.tabline())
--
-- Phase 1: cheap scan — API calls only, no string building
-- Phase 2: cache hit → return; cache miss → render + layout
----------------------------------------------------------------------
function _G.tabline()
    local current = vim.api.nvim_get_current_buf()
    local columns = vim.o.columns

    -- Phase 1: collect listed buffers & build cache key (cheap — O(bufs) API calls)
    local listed = {}
    local sig = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
            listed[#listed + 1] = bufnr
            sig[#sig + 1] = bufnr .. ":" .. (vim.bo[bufnr].modified and "1" or "0") .. ":" .. vim.api.nvim_buf_get_name(bufnr)
        end
    end

    local key = current .. "|" .. columns .. "|" .. table.concat(sig, ",")
    if _tab_cache and _tab_cache_key == key then
        return _tab_cache
    end

    -- Phase 2: cache miss — render chunks
    if #listed == 0 then
        _tab_cache = ""
        _tab_cache_key = key
        return ""
    end

    local chunks = {}
    local active_idx = nil
    for i, bufnr in ipairs(listed) do
        chunks[i] = render_buf(bufnr, current)
        if bufnr == current then
            active_idx = i
        end
    end

    -- Compute display widths
    local widths = {}
    local total = 0
    for i, c in ipairs(chunks) do
        widths[i] = display_width(c)
        total = total + widths[i]
    end

    -- Fast path: everything fits (strip trailing separator)
    if total <= columns then
        local line = table.concat(chunks):gsub(vim.pesc(SEP) .. "$", "")
        _tab_cache = line
        _tab_cache_key = key
        return line
    end

    -- Sliding window: keep active buffer visible, expand outward
    active_idx = active_idx or 1

    local function marker_width(count, glyph)
        return count > 0 and (vim.api.nvim_strwidth(glyph) + #tostring(count) + 3) or 0
    end

    local first, last = active_idx, active_idx
    local used = widths[active_idx]

    while true do
        local left_count = first - 1
        local right_count = #chunks - last
        local reserved = marker_width(left_count, OVERFLOW_LEFT) + marker_width(right_count, OVERFLOW_RIGHT)
        local budget = columns - reserved

        local grew = false
        -- Prefer extending right (natural reading order)
        if last < #chunks and used + widths[last + 1] <= budget then
            last = last + 1
            used = used + widths[last]
            grew = true
        elseif first > 1 and used + widths[first - 1] <= budget then
            first = first - 1
            used = used + widths[first]
            grew = true
        end
        if not grew then
            break
        end
    end

    -- Assemble visible window with overflow markers
    local visible = {}
    local left_count = first - 1
    local right_count = #chunks - last
    if left_count > 0 then
        visible[#visible + 1] = "%#MyBufInactive# " .. left_count .. " " .. OVERFLOW_LEFT .. " "
    end
    for i = first, last do
        visible[#visible + 1] = chunks[i]
    end
    if right_count > 0 then
        visible[#visible + 1] = "%#MyBufInactive# " .. OVERFLOW_RIGHT .. " " .. right_count .. " "
    end

    local line = table.concat(visible):gsub(vim.pesc(SEP) .. "$", "")
    _tab_cache = line
    _tab_cache_key = key
    return line
end

----------------------------------------------------------------------
-- Setup
----------------------------------------------------------------------
function M.setup()
    M.set_highlights()

    vim.api.nvim_create_augroup("MyTabline", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = "MyTabline",
        callback = M.set_highlights,
    })

    vim.opt.showtabline = 2
    vim.opt.tabline = "%!v:lua.tabline()"
end

----------------------------------------------------------------------
-- Keymaps
----------------------------------------------------------------------
vim.keymap.set("n", "wl", ":bnext<CR>", { desc = "[Tabline]: Next buffer" })
vim.keymap.set("n", "wh", ":bprevious<CR>", { desc = "[Tabline]: Previous buffer" })
vim.keymap.set("n", "wd", ":bd<CR>", { desc = "[Tabline]: Delete buffer" })

vim.keymap.set("n", "wo", function()
    local cur = vim.api.nvim_get_current_buf()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= cur and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
    end
end, { desc = "[Tabline]: Close other buffers" })

-- Defer setup until first file is opened (module still loads, tabline won't appear on empty startup)
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
    once = true,
    callback = M.setup,
})

return M
