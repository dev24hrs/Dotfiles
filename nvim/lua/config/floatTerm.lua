-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'floatTerm'
--- @author x3m4g63 <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Single floating terminal (auto-resize + :FloatTerm command)

local M = {}

---@class FloatTermOpts
---@field cmd? string
---@field border? string
---@field width_ratio? number
---@field height_ratio? number
---@field min_width? number
---@field min_height? number
---@field max_width? number
---@field max_height? number

---@class FloatTermInstance
---@field buf? integer
---@field win? integer
---@field opts FloatTermOpts

---@type FloatTermInstance?
local inst = nil

-- ---------- 工具函数 ----------

---@param opts FloatTermOpts
local function compute_geometry(opts)
    local editor_w = vim.o.columns
    local editor_h = vim.o.lines

    local w_ratio = opts.width_ratio or 0.7
    local h_ratio = opts.height_ratio or 0.7

    local width = math.floor(editor_w * w_ratio)
    local height = math.floor(editor_h * h_ratio)

    local min_w = opts.min_width or 20
    local min_h = opts.min_height or 5
    local max_w = opts.max_width or editor_w - 4
    local max_h = opts.max_height or editor_h - 4

    width = math.max(min_w, math.min(width, max_w))
    height = math.max(min_h, math.min(height, max_h))

    local row = math.floor((editor_h - height) / 2)
    local col = math.floor((editor_w - width) / 2)

    return {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = opts.border or "single",
    }
end

local function win_visible()
    return inst ~= nil and inst.win ~= nil and vim.api.nvim_win_is_valid(inst.win)
end

local function buf_valid()
    return inst ~= nil and inst.buf ~= nil and vim.api.nvim_buf_is_valid(inst.buf)
end

-- ---------- 核心操作 ----------

local function hide_instance()
    if win_visible() then
        vim.api.nvim_win_hide(inst.win)
    end
    inst.win = nil
end

local function destroy_instance()
    if not inst then
        return
    end
    local cur = inst
    inst = nil
    if cur.win and vim.api.nvim_win_is_valid(cur.win) then
        vim.api.nvim_win_hide(cur.win)
    end
    if cur.buf and vim.api.nvim_buf_is_valid(cur.buf) then
        pcall(vim.api.nvim_buf_delete, cur.buf, { force = true })
    end
end

local function show_instance()
    if win_visible() then
        vim.api.nvim_set_current_win(inst.win)
        vim.cmd("startinsert")
        return
    end

    local cfg = compute_geometry(inst.opts)

    if buf_valid() then
        inst.win = vim.api.nvim_open_win(inst.buf, true, cfg)
        vim.cmd("startinsert")
        return
    end

    -- 首次创建：在 scratch buffer 中原地启动终端
    local owner = inst
    ---@cast owner FloatTermInstance
    local buf = vim.api.nvim_create_buf(false, true)
    owner.buf = buf
    owner.win = vim.api.nvim_open_win(buf, true, cfg)

    local cmd = owner.opts.cmd
    local job = vim.fn.jobstart(cmd and cmd or vim.fn.split(vim.o.shell), {
        term = true,
        on_exit = function()
            vim.schedule(function()
                -- 忽略已被 close/重建的旧实例的退出回调
                if inst ~= owner then
                    return
                end
                destroy_instance()
            end)
        end,
    })
    if job <= 0 then
        vim.notify("FloatTerm: failed to start " .. (cmd or vim.o.shell), vim.log.levels.ERROR)
        destroy_instance()
        return
    end

    pcall(vim.api.nvim_buf_set_name, buf, "float-term://main")
    vim.cmd("startinsert")
end

-- ---------- 对外 API ----------

local function default_opts()
    return {
        width_ratio = 0.7,
        height_ratio = 0.7,
        border = "single",
        cmd = nil,
    }
end

---@param opts? FloatTermOpts
function M.toggle(opts)
    opts = opts or {}
    if opts.cmd == "" then
        opts.cmd = nil
    end

    -- cmd 是实例身份：显式指定且与当前实例不同 -> 重建
    if inst and opts.cmd ~= nil and inst.opts.cmd ~= opts.cmd then
        destroy_instance()
    end

    if not inst then
        inst = { opts = vim.tbl_deep_extend("force", default_opts(), opts) }
    else
        inst.opts = vim.tbl_deep_extend("force", inst.opts, opts)
    end

    if win_visible() then
        hide_instance()
    else
        show_instance()
    end
end

function M.close()
    destroy_instance()
end

---@class FloatTermStatus
---@field visible boolean
---@field buf string
---@field cmd string

---@return FloatTermStatus?
function M.status()
    if not inst then
        return nil
    end
    return {
        visible = win_visible(),
        buf = buf_valid() and "valid" or "invalid",
        cmd = inst.opts.cmd or vim.o.shell,
    }
end

function M.resize()
    if win_visible() then
        pcall(vim.api.nvim_win_set_config, inst.win, compute_geometry(inst.opts))
    end
end

-- ---------- 自动调整大小 ----------

local resize_group = vim.api.nvim_create_augroup("FloatTermResize", { clear = true })
vim.api.nvim_create_autocmd("VimResized", {
    group = resize_group,
    callback = function()
        M.resize()
    end,
})

-- ---------- 用户命令 ----------

local OPT_SPECS = {
    { "width_ratio", "number" },
    { "height_ratio", "number" },
    { "min_width", "number" },
    { "min_height", "number" },
    { "max_width", "number" },
    { "max_height", "number" },
    { "border", "string" },
    { "cmd", "string" },
}

local opt_kind = {}
local opt_complete = {}
for _, spec in ipairs(OPT_SPECS) do
    opt_kind[spec[1]] = spec[2]
    opt_complete[#opt_complete + 1] = spec[1] .. "="
end

---@param fargs string[]
---@return FloatTermOpts
local function parse_opts(fargs)
    local opts = {}
    for _, farg in ipairs(fargs) do
        local key, val = farg:match("^([%w_]+)=(.*)$")
        local kind = key and opt_kind[key]
        if kind == "number" then
            opts[key] = tonumber(val)
        elseif kind == "string" then
            opts[key] = val
        end
    end
    return opts
end

vim.api.nvim_create_user_command("FloatTerm", function(cmd_args)
    M.toggle(parse_opts(cmd_args.fargs))
end, {
    nargs = "*",
    desc = "Toggle floating terminal (:FloatTerm [cmd=...] [width_ratio=...] [height_ratio=...] [border=...])",
    complete = function(arg_lead)
        return vim.tbl_filter(function(c)
            return c:sub(1, #arg_lead) == arg_lead
        end, opt_complete)
    end,
})

vim.api.nvim_create_user_command("FloatTermClose", M.close, { desc = "Close floating terminal" })

vim.keymap.set("n", "<leader>tt", M.toggle, { desc = "Toggle floating terminal" })
vim.keymap.set("n", "<leader>tg", function()
    M.toggle({ cmd = "lazygit", width_ratio = 0.8, height_ratio = 0.8 })
end, { desc = "Toggle floating lazygit" })
vim.keymap.set("n", "<leader>td", function()
    M.toggle({ cmd = "hunk diff", width_ratio = 0.8, height_ratio = 0.8 })
end, { desc = "Toggle floating hunk" })
vim.keymap.set("n", "<leader>tc", M.close, { desc = "Close floating terminal" })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

return M
