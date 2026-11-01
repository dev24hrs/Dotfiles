-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'notify'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-01
--- @description Borderless top-right notifications, replacing nvim-notify.
--
--- vim.notify() is rendered in a dedicated floating window so notifications do
--- not share ui2's msg window with the LSP progress in lsp_progress.lua. Each
--- notification has its own timer, newest first, and the window hides when the
--- last one expires. Messages are not added to |:messages|: echoing them would
--- also display them in the ui2 msg window.

local api = vim.api
local levels = vim.log.levels

local config = {
    max_width = 60,
    max_notes = 10,
    margin_top = 1,
    min_level = levels.TRACE,
    default_timeout = 3000,
    timeout = {
        [levels.ERROR] = 5000,
        [levels.WARN] = 4000,
    },
    -- Same Nerd Font codepoints as nvim-notify's defaults.
    icons = {
        [levels.ERROR] = vim.fn.nr2char(0xf057), --
        [levels.WARN] = vim.fn.nr2char(0xf06a), --
        [levels.INFO] = vim.fn.nr2char(0xf05a), --
        [levels.DEBUG] = vim.fn.nr2char(0xf188), --
        [levels.TRACE] = vim.fn.nr2char(0x270e), -- ✎
    },
    hl = {
        [levels.ERROR] = "DiagnosticError",
        [levels.WARN] = "DiagnosticWarn",
        [levels.INFO] = "DiagnosticInfo",
        [levels.DEBUG] = "DiagnosticHint",
        [levels.TRACE] = "Comment",
    },
}

local notes = {}
local win ---@type integer?
local buf ---@type integer?
local ns = api.nvim_create_namespace("User_Notify")

local function level_icon(level)
    return config.icons[level] or config.icons[levels.INFO]
end

local function level_hl(level)
    return config.hl[level] or "DiagnosticInfo"
end

local function level_timeout(level)
    return config.timeout[level] or config.default_timeout
end

local function ensure_window()
    if win and api.nvim_win_is_valid(win) and buf and api.nvim_buf_is_valid(buf) then
        return win, buf
    end

    buf = api.nvim_create_buf(false, true)
    win = api.nvim_open_win(buf, false, {
        relative = "editor",
        anchor = "NE",
        row = config.margin_top,
        col = vim.o.columns,
        width = 1,
        height = 1,
        style = "minimal",
        border = "none",
        focusable = false,
        mouse = false,
        noautocmd = true,
        zindex = 250,
        hide = true,
    })
    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
    vim.wo[win].winhighlight = "Normal:NormalFloat"
    return win, buf
end

--- Split a notification into buffer lines and byte-range highlights.
local function build(note)
    local icon = note.icon or level_icon(note.level)
    local title = note.title or ""
    local label = title ~= "" and (title .. ": ") or ""
    local prefix = icon .. (icon ~= "" and " " or "") .. label

    local lines, marks = {}, {}
    for i, part in ipairs(vim.split(note.msg, "\n", { plain = true })) do
        local text = i == 1 and (prefix .. part) or ((" "):rep(vim.fn.strdisplaywidth(prefix)) .. part)
        lines[#lines + 1] = text

        if i == 1 then
            if icon ~= "" then
                marks[#marks + 1] = { 0, 0, #icon, level_hl(note.level) }
            end
            if title ~= "" then
                local start = #icon + (icon ~= "" and 1 or 0)
                marks[#marks + 1] = { 0, start, start + #title, level_hl(note.level) }
            end
        end
    end
    return lines, marks
end

local function set_config(w, width, hide)
    api.nvim_win_set_config(w, {
        relative = "editor",
        anchor = "NE",
        row = config.margin_top,
        col = vim.o.columns,
        width = width,
        hide = hide,
    })
end

local function render()
    if #notes == 0 then
        if win and api.nvim_win_is_valid(win) then
            pcall(api.nvim_win_set_config, win, { hide = true })
        end
        return
    end

    local w, b = ensure_window()

    local lines, marks = {}, {}
    for _, note in ipairs(notes) do
        local note_lines, note_marks = build(note)
        for _, mark in ipairs(note_marks) do
            marks[#marks + 1] = { #lines + mark[1], mark[2], mark[3], mark[4] }
        end
        vim.list_extend(lines, note_lines)
    end

    local width = 1
    for _, line in ipairs(lines) do
        width = math.max(width, vim.fn.strdisplaywidth(line))
    end
    width = math.max(1, math.min(width, config.max_width, vim.o.columns))

    for i, line in ipairs(lines) do
        local line_width = vim.fn.strdisplaywidth(line)
        if line_width < width then
            local pad = (" "):rep(width - line_width)
            lines[i] = pad .. line
            for _, mark in ipairs(marks) do
                if mark[1] == i - 1 then
                    mark[2], mark[3] = mark[2] + #pad, mark[3] + #pad
                end
            end
        end
    end

    api.nvim_buf_set_lines(b, 0, -1, false, lines)
    api.nvim_buf_clear_namespace(b, ns, 0, -1)
    for _, mark in ipairs(marks) do
        api.nvim_buf_set_extmark(b, ns, mark[1], mark[2], {
            end_col = mark[3],
            hl_group = mark[4],
        })
    end

    set_config(w, width, false)
    local height = api.nvim_win_text_height(w, {}).all
    api.nvim_win_set_config(w, {
        relative = "editor",
        anchor = "NE",
        row = config.margin_top,
        col = vim.o.columns,
        width = width,
        height = math.max(1, math.min(height, vim.o.lines - 1 - config.margin_top)),
        hide = false,
    })

    if api.nvim__redraw then
        api.nvim__redraw({ win = w, flush = true })
    end
end

local function remove(note)
    local timer = note.timer
    note.timer = nil
    if timer and not timer:is_closing() then
        timer:stop()
        timer:close()
    end

    for i, item in ipairs(notes) do
        if item == note then
            table.remove(notes, i)
            break
        end
    end
    render()
end

local default_notify = vim.notify

local function notify(msg, level, opts)
    if vim.in_fast_event() then
        vim.schedule(function()
            notify(msg, level, opts)
        end)
        return
    end
    if #api.nvim_list_uis() == 0 then
        return default_notify(msg, level, opts)
    end

    opts = type(opts) == "table" and opts or {}
    level = level or levels.INFO
    if level < config.min_level then
        return
    end

    local note = {
        msg = tostring(msg),
        level = level,
        title = type(opts.title) == "string" and opts.title or nil,
        icon = type(opts.icon) == "string" and opts.icon or nil,
        timeout = type(opts.timeout) == "number" and math.max(1, opts.timeout) or level_timeout(level),
    }

    table.insert(notes, 1, note)
    if #notes > config.max_notes then
        local oldest = table.remove(notes)
        if oldest and oldest.timer and not oldest.timer:is_closing() then
            oldest.timer:stop()
            oldest.timer:close()
        end
    end

    render()
    note.timer = vim.defer_fn(function()
        remove(note)
    end, note.timeout)
end

vim.notify = notify

local group = api.nvim_create_augroup("User_Notify", { clear = true })

api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
        if #notes > 0 then
            render()
        end
    end,
    desc = "Reposition notifications after a resize",
})

api.nvim_create_autocmd("TabEnter", {
    group = group,
    callback = function()
        if #notes > 0 and win and api.nvim_win_is_valid(win) then
            api.nvim_win_set_config(win, {
                win = api.nvim_tabpage_get_win(0),
                relative = "editor",
                anchor = "NE",
                row = config.margin_top,
                col = vim.o.columns,
            })
            render()
        end
    end,
    desc = "Move notifications to the current tabpage",
})
