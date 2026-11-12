-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'ui2'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-10-31
--- @description Center the ui2 cmdline and keep the blink.cmp menu below it.

local api = vim.api

local config = {
    width = { value = "35%", min = 40, max = 80 },
    position = { x = "50%", y = "50%" },
    menu_col_offset = 0,
    border_hl = "NoiceCmdlinePopupBorder",
    msg_margin_bottom = 1,
}

local border = vim.o.winborder ~= "" and vim.o.winborder or "rounded"
local inset = border == "none" and 0 or 1

-- 'cmdheight' is set in basic/options.lua for the ui2 cmdline
local ui = require("vim._core.ui2")
ui.enable({
    enable = true,
    msg = { targets = "msg" },
})

-- ui2 parks the message window flush on the statusline; lift it so progress
-- and other messages keep a gap above the bottom edge. Wrap set_pos because
-- ui2 re-applies its own row on every message update, resize and option change.
local messages = require("vim._core.ui2.messages")
local set_pos = messages.set_pos
messages.set_pos = function(tgt)
    set_pos(tgt)
    if tgt == nil or tgt == "msg" then
        local win = ui.wins.msg
        if api.nvim_win_is_valid(win) and api.nvim_win_get_config(win).relative ~= "" then
            api.nvim_win_set_config(win, {
                relative = "laststatus",
                anchor = "SE",
                row = -config.msg_margin_bottom,
                col = 10000,
            })
        end
    end
end

local function parse_dimension(value, available)
    if type(value) == "string" then
        return math.floor(available * tonumber(value:match("^(%d+)%%$")) / 100)
    end
    return math.floor(value)
end

local function cmd_window()
    for _, win in ipairs(api.nvim_list_wins()) do
        local floating = api.nvim_win_get_config(win).relative ~= ""
        if floating and vim.bo[api.nvim_win_get_buf(win)].filetype == "cmd" then
            return win
        end
    end
end

local last_geometry = { win = nil, row = -1, col = -1, width = -1 }

local function reposition()
    local win = cmd_window()
    if not win then
        return
    end

    local height = math.max(1, api.nvim_win_get_height(win))
    local width = math.max(config.width.min, math.min(config.width.max, parse_dimension(config.width.value, vim.o.columns)))
    width = math.min(width, vim.o.columns - inset * 2)

    -- row/col address the outer edge of the border, so reserve 2 * inset.
    local row = math.max(0, parse_dimension(config.position.y, vim.o.lines - height - inset * 2))
    local col = math.max(0, parse_dimension(config.position.x, vim.o.columns - width - inset * 2))

    if last_geometry.win ~= win or last_geometry.row ~= row or last_geometry.col ~= col or last_geometry.width ~= width then
        api.nvim_win_set_config(win, {
            relative = "editor",
            row = row,
            col = col,
            width = width,
            border = border,
        })
        last_geometry = { win = win, row = row, col = col, width = width }
    end

    -- ui2 leaves FloatBorder unmapped, so the border would follow the global
    -- group. Append a per-window mapping: ui2's Normal/search mappings survive
    -- and the check keeps this idempotent across reposition calls.
    local border_hl = vim.fn.hlexists(config.border_hl) == 1 and config.border_hl or "FloatBorder"
    local border_map = "FloatBorder:" .. border_hl
    local winhl = vim.wo[win].winhighlight
    if not winhl:find(border_map, 1, true) then
        vim.wo[win].winhighlight = (winhl == "" and "" or winhl .. ",") .. border_map
    end

    -- blink.cmp (via noice's convention) reads { 1-based row, 0-based col }.
    -- Anchor on the bottom border so the menu opens below the window instead
    -- of covering the border or staying at the bottom of the screen.
    vim.g.ui_cmdline_pos = { row + height + inset * 2, col + inset + config.menu_col_offset }
end

local function nudge_blink()
    local ok, menu = pcall(require, "blink.cmp.completion.windows.menu")
    if ok and menu.win and menu.win:is_open() then
        pcall(menu.update_position)
    end
end

local group = api.nvim_create_augroup("User_UI2", { clear = true })

api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "cmd",
    callback = function()
        vim.schedule(reposition)
    end,
    desc = "Center the ui2 cmdline window after creation",
})

api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "msg",
    callback = function()
        -- The ephemeral message window should look like fidget's notification
        -- window; other floating windows keep 'winborder'.
        api.nvim_win_set_config(0, { border = "none" })
    end,
    desc = "Remove the ui2 message window border",
})

api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineChanged" }, {
    group = group,
    callback = reposition,
    desc = "Keep the ui2 cmdline window centered",
})

api.nvim_create_autocmd({ "VimResized", "TabEnter" }, {
    group = group,
    callback = function()
        vim.schedule(function()
            reposition()
            nudge_blink()
        end)
    end,
    desc = "Re-center the ui2 cmdline and blink menu after layout changes",
})
