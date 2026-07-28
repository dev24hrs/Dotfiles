vim.pack.add({
    { src = "https://github.com/nvim-tree/nvim-tree.lua" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
})

local tree_group = vim.api.nvim_create_augroup("User_NvimTreeInit", { clear = true })

local function toggle_nvim_tree()
    -- Lazy-load: BufReadPost autocmd handles normal file open, but from
    -- dashboard (alpha) or empty buffers we must trigger setup explicitly
    if not package.loaded["nvim-tree"] then
        vim.api.nvim_exec_autocmds("BufReadPost", { group = tree_group })
    end

    local status, api = pcall(require, "nvim-tree.api")
    if not status then
        return
    end

    local buftype = vim.bo.buftype
    local filename = vim.api.nvim_buf_get_name(0)

    if buftype == "" and filename ~= "" then
        api.tree.toggle({ find_file = true, focus = true })
    else
        api.tree.toggle({ focus = true })
    end
end

vim.keymap.set("n", "<leader>e", toggle_nvim_tree, { desc = "[NvimTree]: Toggle" })

vim.api.nvim_create_autocmd("BufReadPost", {
    group = tree_group,
    once = true,
    callback = function()
        local status, nvim_tree = pcall(require, "nvim-tree")
        if not status then
            return
        end

        local api = require("nvim-tree.api")
        local function edit_or_open()
            local node = api.tree.get_node_under_cursor()
            if node ~= nil then
                api.node.open.edit()
            else
                api.tree.close()
            end
        end
        local HEIGHT_RATIO = 0.6
        local WIDTH_RATIO = 0.3

        nvim_tree.setup({
            update_focused_file = {
                enable = true, -- 开启聚焦当前文件功能
                update_root = { enable = false },
            },
            actions = {
                open_file = {
                    quit_on_open = true,
                },
            },
            view = {
                float = {
                    enable = true,
                    quit_on_focus_loss = true,
                    open_win_config = function()
                        local screen_w = vim.o.columns
                        local screen_h = vim.o.lines
                        local window_w = math.floor(screen_w * WIDTH_RATIO)
                        local window_h = math.floor(screen_h * HEIGHT_RATIO)
                        return {
                            border = "single",
                            relative = "editor",
                            row = (screen_h - window_h) / 2,
                            col = (screen_w - window_w) / 2,
                            width = window_w,
                            height = window_h,
                        }
                    end,
                },
                signcolumn = "yes",
                cursorline = false,
            },
            renderer = {
                indent_markers = {
                    enable = true,
                },
                icons = {
                    symlink_arrow = "󱦰",
                    glyphs = {
                        folder = {
                            arrow_closed = "󱦰",
                            arrow_open = "󱦳",
                        },
                        git = {
                            unstaged = "",
                            staged = "",
                            unmerged = "",
                            renamed = "",
                            untracked = "",
                            deleted = "",
                            ignored = "",
                        },
                    },
                },
            },
            filters = {
                enable = true,
                git_ignored = true,
            },
            git = {
                enable = true,
                show_on_dirs = true,
                show_on_open_dirs = true,
                timeout = 1200,
            },
            on_attach = function(bufnr)
                local function opts(desc)
                    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
                end
                -- api.config.mappings.default_on_attach(bufnr)
                api.map.on_attach.default(bufnr)

                vim.keymap.set("n", "l", edit_or_open, opts("[NvimTree]: Edit Or Open"))
                vim.keymap.set("n", "e", edit_or_open, opts("[NvimTree]: Edit Or Open"))
                vim.keymap.set("n", "h", api.node.navigate.parent_close, opts("[NvimTree]: Close"))
                -- del map for '-' and 's'
                vim.keymap.set("n", "-", "", opts("[NvimTree]: cancel - "))
                vim.keymap.set("n", "s", "", opts("[NvimTree]: cancel s "))
            end,
        })
    end,
})
