local M = {}

-- 1. 状态跟踪变量
local expanded_plugins = {} -- 跟踪单个插件的展开状态 (URL/Commit)
local sections_expanded = { -- 默认不展开分区
    active = false,
    inactive = false,
}

-- 2. 核心数据提取（严格基于 p.spec 和 p.active 结构）
local function get_pack_data_via_api()
    local pack = rawget(vim, "pack")
    if not pack or not pack.get then
        return nil, nil, "未找到 vim.pack.get 接口"
    end

    -- 使用 or {} 消除 LSP 的 table|nil 警告
    local all_packs = pack.get() or {}

    local active_plugins = {}
    local inactive_plugins = {}

    for _, p in ipairs(all_packs) do
        if type(p) == "table" and p.spec and p.spec.name then
            local src_url = p.spec.url or p.spec.src or p.url or p.src or "未知源"
            local commit_rev = p.commit or p.rev or p.spec.commit or p.spec.rev or "已锁定"
            if type(commit_rev) == "string" then
                commit_rev = commit_rev:sub(1, 7)
            end

            local item = {
                name = p.spec.name,
                src = src_url,
                rev = tostring(commit_rev),
                is_loaded = p.active or false,
                has_update = p.outdated or false,
            }

            if item.is_loaded then
                table.insert(active_plugins, item)
            else
                table.insert(inactive_plugins, item)
            end
        end
    end

    table.sort(active_plugins, function(a, b)
        return a.name:lower() < b.name:lower()
    end)
    table.sort(inactive_plugins, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    return active_plugins, inactive_plugins, nil
end

-- 3. 动态 UI 渲染
local function render_ui(buf)
    local active, inactive, err = get_pack_data_via_api()
    local lines = {}

    active = active or {}
    inactive = inactive or {}

    -- 顶部装饰与操作提示区
    table.insert(lines, "")
    table.insert(
        lines,
        "  [Enter]: 展开详情    [u]: 更新当前   [U]: 更新全部   [d]: 删除当前   [r]: 同步lockfile   [q]: 关闭面板"
    )
    table.insert(lines, "")

    -- 行号追踪映射表
    local line_to_plugin = {}
    for i = 1, 7 do
        line_to_plugin[i] = { type = "header" }
    end

    if err ~= nil then
        table.insert(lines, "  错误: " .. err)
    else
        -- ==================== 分区 1：Active 插件 ====================
        local active_arrow = sections_expanded.active and "▼" or "▶"
        table.insert(lines, string.format("  %s Active 插件 (%d)", active_arrow, #active))
        line_to_plugin[#lines] = { type = "section_header", section = "active" }
        table.insert(lines, "")
        line_to_plugin[#lines] = { type = "header" }

        if sections_expanded.active then
            for _, p in ipairs(active) do
                local status_icon = p.has_update and "⏳" or "✔"
                local arrow = expanded_plugins[p.name] and "▼" or "▶"
                local update_tag = p.has_update and " [有新版本!]" or ""

                table.insert(lines, string.format("    %s %s %-28s%s", status_icon, arrow, p.name, update_tag))
                line_to_plugin[#lines] = { type = "main", name = p.name, list = "active" }

                if expanded_plugins[p.name] then
                    table.insert(lines, string.format("         URL:    %s", p.src))
                    line_to_plugin[#lines] = { type = "detail", name = p.name }
                    table.insert(lines, string.format("         Commit: %s", p.rev))
                    line_to_plugin[#lines] = { type = "detail", name = p.name }
                end
            end
        end

        -- ==================== 分区 2：Unused 插件 ====================
        table.insert(lines, "")
        line_to_plugin[#lines] = { type = "header" }

        local inactive_arrow = sections_expanded.inactive and "▼" or "▶"
        table.insert(lines, string.format("  %s Inactive 插件 (%d)", inactive_arrow, #inactive))
        line_to_plugin[#lines] = { type = "section_header", section = "inactive" }
        table.insert(lines, "")
        line_to_plugin[#lines] = { type = "header" }

        if sections_expanded.inactive then
            for _, p in ipairs(inactive) do
                local arrow = expanded_plugins[p.name] and "▼" or "▶"
                table.insert(lines, string.format("    󰛑 %s %-28s", arrow, p.name))
                line_to_plugin[#lines] = { type = "main", name = p.name, list = "inactive" }

                if expanded_plugins[p.name] then
                    table.insert(lines, string.format("         URL:    %s", p.src))
                    line_to_plugin[#lines] = { type = "detail", name = p.name }
                    table.insert(lines, string.format("         Commit: %s", p.rev))
                    line_to_plugin[#lines] = { type = "detail", name = p.name }
                end
            end
        end
    end

    table.insert(lines, "")
    line_to_plugin[#lines] = { type = "header" }

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false

    vim.b[buf].line_to_plugin = line_to_plugin
end

-- 4. 创建居中 Floating 浮动面板
function M.toggle_panel()
    local width = math.floor(vim.o.columns * 0.65)
    local height = math.floor(vim.o.lines * 0.6)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)

    local opts = {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = " Vim Pack Manager ",
        title_pos = "center",
    }

    local win = vim.api.nvim_open_win(buf, true, opts)

    vim.bo[buf].filetype = "vim-pack-ui"
    vim.bo[buf].buftype = "nofile"

    render_ui(buf)

    -- ==================== 5. 键盘映射与核心重构区 ====================

    -- [q] 退出面板
    vim.keymap.set("n", "q", function()
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end, { buffer = buf, silent = true })

    -- [Enter] 折叠切换
    vim.keymap.set("n", "<CR>", function()
        local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
        local line_info = vim.b[buf].line_to_plugin and vim.b[buf].line_to_plugin[cursor_line]

        if line_info then
            if line_info.type == "section_header" then
                sections_expanded[line_info.section] = not sections_expanded[line_info.section]
                render_ui(buf)
                pcall(vim.api.nvim_win_set_cursor, win, { cursor_line, 2 })
            elseif line_info.type == "main" then
                expanded_plugins[line_info.name] = not expanded_plugins[line_info.name]
                render_ui(buf)
                pcall(vim.api.nvim_win_set_cursor, win, { cursor_line, 4 })
            end
        end
    end, { buffer = buf, silent = true })

    -- [u] 【全新重构】：更新单插件
    vim.keymap.set("n", "u", function()
        local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
        local line_info = vim.b[buf].line_to_plugin and vim.b[buf].line_to_plugin[cursor_line]

        if line_info and line_info.name then
            local pack = rawget(vim, "pack")
            if pack and pack.update then
                vim.notify("⚡ [vim.pack] 开始更新: " .. line_info.name, vim.log.levels.INFO)

                -- 传入 { force = true } 阻止原生 UI 唤起
                pack.update({ line_info.name }, { force = true })

                vim.notify("✨ [vim.pack] " .. line_info.name .. " 更新已完成！", vim.log.levels.INFO)
                render_ui(buf)
            end
        end
    end, { buffer = buf, silent = true })

    -- [U] 【全新重构】：更新全部插件
    vim.keymap.set("n", "U", function()
        local pack = rawget(vim, "pack")
        if pack and pack.update then
            vim.notify("⚡ [vim.pack] 更新全部插件，请稍候...", vim.log.levels.INFO)

            -- 同理，全局更新也禁止原生 UI
            pack.update(nil, { force = true })

            vim.notify("✨ [vim.pack] 全部插件更新完毕！", vim.log.levels.INFO)
            render_ui(buf)
        end
    end, { buffer = buf, silent = true })

    -- [r] 【同步lockfile】: 同步lockfile
    vim.keymap.set("n", "r", function()
        vim.notify("⚡ [vim.pack] 开始同步lockfile ", vim.log.levels.INFO)
        vim.pack.update(nil, { force = true, target = "lockfile" })

        vim.notify("✨ [vim.pack] 同步lockfile完毕！", vim.log.levels.INFO)
        render_ui(buf)
    end, { buffer = buf, silent = true })

    -- [d] 删除 Unused 插件
    vim.keymap.set("n", "d", function()
        local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
        local line_info = vim.b[buf].line_to_plugin and vim.b[buf].line_to_plugin[cursor_line]

        if line_info and line_info.name then
            if line_info.list == "active" then
                vim.notify("警告：该插件正处于激活状态，无法直接清除。", vim.log.levels.WARN)
                return
            end

            local choice = vim.fn.input("确认要删除插件 [" .. line_info.name .. "] 吗？(y/n): ")
            if choice:lower() ~= "y" then
                print(" 已取消删除")
                return
            end

            local pack = rawget(vim, "pack")
            if pack and pack.del then
                pack.del({ line_info.name })
                -- 删除后立即就地重绘面板
                render_ui(buf)
                vim.notify("✨ [vim.pack]" .. line_info.name .. "删除成功", vim.log.levels.INFO)
            end
        end
    end, { buffer = buf, silent = true })
end

vim.api.nvim_create_user_command("PackUI", M.toggle_panel, {})

return M
