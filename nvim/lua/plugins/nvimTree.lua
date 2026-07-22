vim.pack.add({
    { src = "https://github.com/nvim-tree/nvim-tree.lua" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
})

local tree_group = vim.api.nvim_create_augroup("User_NvimTreeInit", { clear = true })

local function open_nvim_tree_smart()
    if not package.loaded["nvim-tree"] then
        vim.api.nvim_exec_autocmds("BufReadPost", { group = tree_group })
    end

    local status, api = pcall(require, "nvim-tree.api")
    if status then
        local buftype = vim.bo.buftype
        local filename = vim.api.nvim_buf_get_name(0)

        if buftype == "" and filename ~= "" then
            api.tree.toggle({ find_file = true, focus = true })
        else
            api.tree.toggle({ focus = true })
        end
    end
end

-- 2. 全局映射：Neovim 启动即生效，不受 BufReadPost 限制
vim.keymap.set("n", "<leader>e", open_nvim_tree_smart, { desc = "[NvimTree]: Smart Toggle" })

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
                -- expand or collapse folder
                api.node.open.edit()
            else
                -- open file
                api.node.open.edit()
                -- Close the tree if file was opened
                api.tree.close()
            end
        end
        local HEIGHT_RATIO = 0.6
        local WIDTH_RATIO = 0.3

        -- float window config
        local function open_win_config_func()
            local screen_w = vim.opt.columns:get()
            local screen_h = vim.opt.lines:get()
            local window_w = screen_w * WIDTH_RATIO
            local window_h = screen_h * HEIGHT_RATIO
            local window_w_int = math.floor(window_w)
            local window_h_int = math.floor(window_h)
            local center_x = (screen_w - window_w) / 2
            local center_y = ((vim.opt.lines:get() - window_h) / 2)
            return {
                border = "single",
                relative = "editor",
                row = center_y,
                col = center_x,
                width = window_w_int,
                height = window_h_int,
            }
        end

        nvim_tree.setup({
            update_focused_file = {
                enable = true, -- 开启聚焦当前文件功能
                update_root = {
                    enable = false,
                    ignore_list = {},
                },
                ignore_list = {},
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
                    open_win_config = open_win_config_func(),
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
