-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'lsp_progress'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-10-31
--- @description Show LSP progress as native progress-messages in the ui2 msg window.
--
--- LspProgress is mapped to nvim_echo(..., { kind = 'progress', id = ... }):
--- messages with a stable id are updated in place, and ui2 renders them in its
--- bottom-right message window. The spinner timer animates running tasks and
--- re-emits them so ui2's message timeout (4s by default) never expires an
--- unfinished task. Finished tasks are emitted once and expire on their own,
--- mirroring fidget.nvim's `done_ttl`.
---
--- Rendering happens only on the spinner tick, so tasks that begin and end
--- between two ticks (e.g. lua_ls sends an instant "Loading workspace" token
--- alongside the real one) are dropped like fidget's `ignore_done_already`.

local api = vim.api

local config = {
    spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    interval = 100,
    max_tasks = 16,
    done_icon = "✔",
    failed_icon = "✘",
    running_hl = "DiagnosticInfo",
    done_hl = "DiagnosticOk",
    failed_hl = "DiagnosticError",
}

-- This module drives ui2's message window. Without it, the repeated echo calls
-- would append to the classic cmdline instead of replacing a message in place.
local ui2 = package.loaded["vim._core.ui2"]
if not (ui2 and ui2.cfg.enable and ui2.msg) then
    return
end

local tasks = {}
local order = {}
local timer
local frame = 0

local function client_name(client_id)
    local client = vim.lsp.get_client_by_id(client_id)
    return client and client.name or ("lsp[%d]"):format(client_id)
end

local function message_id(client_id, token)
    return ("lsp.progress.%d.%s"):format(client_id, tostring(token))
end

local function spinner_icon()
    return config.spinner[(frame % #config.spinner) + 1]
end

local function remove(key)
    tasks[key] = nil
    for i, value in ipairs(order) do
        if value == key then
            table.remove(order, i)
            break
        end
    end
end

--- ui2 keeps the message window at the widest width it has seen and never
--- shrinks it until the window hides, so a short `done` line keeps the gap on
--- its right. Fit the window to the visible lines so the text hugs the right
--- edge (the window is anchored to the bottom-right corner).
local function fit_width()
    local win, buf = ui2.wins.msg, ui2.bufs.msg
    if not (api.nvim_win_is_valid(win) and api.nvim_buf_is_valid(buf)) then
        return
    end
    if api.nvim_win_get_config(win).hide then
        return
    end

    local width = 1
    for _, line in ipairs(api.nvim_buf_get_lines(buf, 0, -1, false)) do
        width = math.max(width, vim.fn.strdisplaywidth(line))
    end

    if width ~= api.nvim_win_get_width(win) then
        api.nvim_win_set_width(win, width)
        if api.nvim__redraw then
            api.nvim__redraw({ win = win, flush = true })
        end
    end

    -- Keep ui2's sticky maximum in sync, otherwise the next message update
    -- widens the window back and the spinner tick causes flicker.
    if type(ui2.msg) == "table" and type(ui2.msg.msg) == "table" then
        ui2.msg.msg.width = width
    end
end

-- Core renders progress messages as "title: percent% <content>", so only add
-- the spinner and the task's own message here to avoid duplicated metadata.
local function emit(task, glyph, hl, status, with_percent)
    local text = status == "running" and (task.message or "") or ""
    if text == task.title then
        text = ""
    end

    local chunks = { { text == "" and glyph or glyph .. " ", hl } }
    if text ~= "" then
        chunks[#chunks + 1] = { text }
    end

    api.nvim_echo(chunks, false, {
        id = task.id,
        kind = "progress",
        source = "vim.lsp",
        title = task.title,
        status = status,
        percent = with_percent and task.percentage or nil,
    })
end

local function render()
    local glyph = spinner_icon()
    local first = math.max(1, #order - config.max_tasks + 1)
    for i = first, #order do
        local task = tasks[order[i]]
        if task then
            emit(task, glyph, config.running_hl, "running", true)
            task.shown = true
        end
    end
    fit_width()
end

--- LspDetach fires when a client detaches from a buffer, not when it exits, so
--- check client liveness while tasks are running instead.
local function prune_dead_clients()
    local keys = {}
    for key, task in pairs(tasks) do
        if not vim.lsp.get_client_by_id(task.client_id) then
            keys[#keys + 1] = key
        end
    end
    for _, key in ipairs(keys) do
        local task = tasks[key]
        if task.shown then
            emit(task, config.failed_icon, config.failed_hl, "failed", false)
        end
        remove(key)
    end
    if #keys > 0 then
        fit_width()
    end
end

local function tick()
    if #order == 0 then
        if timer then
            timer:stop()
        end
        return
    end
    prune_dead_clients()
    frame = frame + 1
    render()
end

local function ensure_timer()
    timer = timer or vim.uv.new_timer()
    if not timer:is_active() then
        timer:start(config.interval, config.interval, vim.schedule_wrap(tick))
    end
end

local function update(client_id, token, value, kind)
    local key = ("%d:%s"):format(client_id, tostring(token))
    local task = tasks[key]
    if not task and kind ~= "end" then
        task = {
            id = message_id(client_id, token),
            client_id = client_id,
            token = token,
            title = client_name(client_id),
        }
        tasks[key] = task
        order[#order + 1] = key
    end
    if not task then
        return
    end

    -- JSON null is vim.NIL in Nvim 0.12, so accept strings only.
    if type(value.title) == "string" and value.title ~= "" then
        task.title = value.title
    end
    if type(value.message) == "string" then
        task.message = value.message
    end
    if type(value.percentage) == "number" then
        task.percentage = math.floor(value.percentage)
    end

    if kind == "end" then
        if task.shown then
            emit(task, config.done_icon, config.done_hl, "success", false)
            fit_width()
        end
        remove(key)
    else
        ensure_timer()
    end
end

local group = api.nvim_create_augroup("User_LspProgress", { clear = true })

api.nvim_create_autocmd("LspProgress", {
    group = group,
    callback = function(ev)
        local client_id = ev.data.client_id
        local params = ev.data.params
        local value = params and params.value
        if type(value) ~= "table" or type(value.kind) ~= "string" then
            return
        end

        local token, kind = params.token, value.kind
        if vim.in_fast_event() then
            vim.schedule(function()
                update(client_id, token, value, kind)
            end)
        else
            update(client_id, token, value, kind)
        end
    end,
    desc = "Render LSP progress as native progress messages",
})

api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
        if timer then
            timer:stop()
            if not timer:is_closing() then
                timer:close()
            end
        end
    end,
    desc = "Stop the LSP progress spinner timer",
})
