-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- SPDX-License-Identifier: MIT
--
--- @module 'go.mock'
--- @description GoMock generation via mockgen + treesitter
--- @author dev24hrs <asang24dev@gmail.com>

local M = {}

local MOCKGEN = "mockgen"
local RUNNING_VAR = "go_mock_running"
local DEFAULT_PACKAGE = "mocks"

-- =============================================================================
-- Private helpers
-- =============================================================================

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Go Mock" })
end

local function is_running()
    return vim.g[RUNNING_VAR] == true
end

local function set_running(value)
    vim.g[RUNNING_VAR] = value
end

local function ensure_bin()
    if vim.fn.executable(MOCKGEN) == 1 then
        return true
    end

    notify("mockgen not found. Install: go install go.uber.org/mock/mockgen@latest", vim.log.levels.ERROR)
    return false
end

local function current_file()
    local file = vim.api.nvim_buf_get_name(0)

    if file == "" then
        notify("Current buffer has no file", vim.log.levels.ERROR)
        return nil
    end

    if vim.bo.filetype ~= "go" then
        notify("Current file is not a Go file", vim.log.levels.ERROR)
        return nil
    end

    file = vim.fn.fnamemodify(file, ":p")
    if vim.fn.filereadable(file) ~= 1 then
        notify("Current Go file is not readable", vim.log.levels.ERROR)
        return nil
    end

    return file
end

local function find_module_root(start_dir)
    local dir = vim.fn.resolve(start_dir)

    while true do
        if vim.fn.filereadable(dir .. "/go.mod") == 1 then
            return dir
        end

        local parent = vim.fn.fnamemodify(dir, ":h")
        if parent == dir then
            return nil
        end
        dir = parent
    end
end

local function relative_to_root(path, root)
    if path == root then
        return "."
    end

    local prefix = root .. "/"
    if vim.startswith(path, prefix) then
        return path:sub(#prefix + 1)
    end

    return path
end

local function command_error(result, command_name)
    local message = vim.trim(result.stderr or "")
    if message == "" then
        message = vim.trim(result.stdout or "")
    end
    if message == "" then
        message = result.signal and string.format("%s terminated by signal %d", command_name, result.signal) or (command_name .. " failed")
    end
    return message
end

local function current_package_dir(file)
    return vim.fs.dirname(file) or "."
end

local function destination_dir(module_root, requested_dir)
    requested_dir = vim.trim(requested_dir or "")
    if requested_dir == "" then
        return module_root .. "/mocks"
    end

    if vim.fn.isabsolutepath(requested_dir) == 1 then
        return vim.fn.fnamemodify(requested_dir, ":p")
    end

    return vim.fn.fnamemodify(module_root .. "/" .. requested_dir, ":p")
end

local function snake_case(value)
    local name = value:gsub("([a-z0-9])([A-Z])", "%1_%2")
    name = name:gsub("([A-Z]+)([A-Z][a-z])", "%1_%2")
    name = name:gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    return name:lower()
end

local function source_output_name(file)
    local stem = vim.fn.fnamemodify(file, ":t:r")
    return stem .. "_mock.go"
end

local function interface_output_name(interface_name)
    return snake_case(interface_name) .. "_mock.go"
end

local function valid_interface_name(name)
    return name:match("^[%a_][%w_]*$") ~= nil
end

local function valid_package_name(name)
    return name:match("^[%a_][%w_]*$") ~= nil
end

-- =============================================================================
-- Treesitter interface detection
-- =============================================================================

--- Find the interface declaration containing the cursor.
--- @return string|nil interface name
local function current_interface_name()
    if not vim.treesitter or not vim.treesitter.get_parser then
        return nil
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, "go")
    if not parser_ok or not parser then
        return nil
    end

    local parsed, trees = pcall(parser.parse, parser)
    if not parsed or not trees or not trees[1] then
        return nil
    end

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local node = trees[1]:root():named_descendant_for_range(row - 1, col, row - 1, col)

    while node do
        if node:type() == "interface_type" then
            local type_spec = node:parent()
            while type_spec and type_spec:type() ~= "type_spec" do
                type_spec = type_spec:parent()
            end

            if type_spec then
                local name_nodes = type_spec:field("name")
                if name_nodes and name_nodes[1] then
                    local text_ok, name = pcall(vim.treesitter.get_node_text, name_nodes[1], bufnr)
                    if text_ok and valid_interface_name(name) then
                        return name
                    end
                end
            end
            return nil
        end
        node = node:parent()
    end

    return nil
end

-- =============================================================================
-- mockgen execution
-- =============================================================================

local function prepare_destination(dir)
    if vim.fn.mkdir(dir, "p") == 0 and vim.fn.isdirectory(dir) ~= 1 then
        notify("Unable to create mock destination: " .. dir, vim.log.levels.ERROR)
        return false
    end
    return vim.fn.isdirectory(dir) == 1
end

local function run_command(command, cwd, destination, description, already_claimed)
    if is_running() and not already_claimed then
        notify("A mockgen process is already running", vim.log.levels.WARN)
        return
    end

    if not prepare_destination(vim.fs.dirname(destination) or cwd) then
        if already_claimed then
            set_running(false)
        end
        return
    end

    if not already_claimed then
        set_running(true)
    end
    notify("Generating " .. description .. "...")

    local ok, err = pcall(function()
        vim.system(command, { cwd = cwd, text = true }, function(result)
            vim.schedule(function()
                set_running(false)

                if result.code ~= 0 then
                    notify(command_error(result, MOCKGEN), vim.log.levels.ERROR)
                    return
                end

                notify(string.format("Generated %s", destination), vim.log.levels.INFO)
            end)
        end)
    end)

    if not ok then
        set_running(false)
        notify("Failed to start mockgen: " .. tostring(err), vim.log.levels.ERROR)
    end
end

local function generate_source(file, module_root, requested_dir, package_name)
    local dir = destination_dir(module_root, requested_dir)
    local destination = dir .. "/" .. source_output_name(file)
    local source = relative_to_root(file, module_root)

    run_command({
        MOCKGEN,
        "-source=" .. source,
        "-destination=" .. destination,
        "-package=" .. package_name,
    }, module_root, destination, "mocks for " .. vim.fn.fnamemodify(file, ":t"))
end

local function generate_interface(file, module_root, interface_name, requested_dir, package_name)
    local dir = destination_dir(module_root, requested_dir)
    local destination = dir .. "/" .. interface_output_name(interface_name)
    local package_dir = current_package_dir(file)

    set_running(true)

    -- Package mode needs the import path. Resolve it asynchronously so module
    -- loading and the editor UI remain responsive in large Go workspaces.
    vim.system({ "go", "list", "-f={{.ImportPath}}" }, { cwd = package_dir, text = true }, function(package_result)
        vim.schedule(function()
            if package_result.code ~= 0 then
                set_running(false)
                notify(command_error(package_result, "go list"), vim.log.levels.ERROR)
                return
            end

            local import_path = vim.trim(package_result.stdout or "")
            if import_path == "" or import_path:find("\n", 1, true) then
                set_running(false)
                notify("Unable to determine the Go package import path", vim.log.levels.ERROR)
                return
            end

            run_command({
                MOCKGEN,
                import_path,
                interface_name,
                "-destination=" .. destination,
                "-package=" .. package_name,
            }, module_root, destination, "mock for " .. interface_name, true)
        end)
    end)
end

local function save_current_file()
    local updated, update_error = pcall(vim.cmd.update)
    if not updated then
        notify("Unable to save current Go file: " .. tostring(update_error), vim.log.levels.ERROR)
        return false
    end
    return true
end

local function generate(mode, interface_name, requested_dir, package_name)
    if is_running() then
        notify("A mockgen process is already running", vim.log.levels.WARN)
        return
    end

    local file = current_file()
    if not file then
        return
    end

    if not ensure_bin() then
        return
    end

    package_name = vim.trim(package_name or DEFAULT_PACKAGE)
    if not valid_package_name(package_name) then
        notify("Invalid generated package name: " .. package_name, vim.log.levels.ERROR)
        return
    end

    local source_dir = current_package_dir(file)
    local module_root = find_module_root(source_dir)
    if not module_root then
        notify("go.mod not found", vim.log.levels.ERROR)
        return
    end

    if not save_current_file() then
        return
    end

    if mode == "source" then
        generate_source(file, module_root, requested_dir, package_name)
        return
    end

    if not interface_name or vim.trim(interface_name) == "" then
        interface_name = current_interface_name()
    end

    if not interface_name then
        notify("Place the cursor inside a Go interface or provide its name", vim.log.levels.ERROR)
        return
    end

    interface_name = vim.trim(interface_name)
    if not valid_interface_name(interface_name) then
        notify("Invalid Go interface name: " .. interface_name, vim.log.levels.ERROR)
        return
    end

    generate_interface(file, module_root, interface_name, requested_dir, package_name)
end

-- =============================================================================
-- Public API
-- =============================================================================

--- Generate mocks for all interfaces in the current Go file.
--- @param requested_dir string|nil destination directory relative to module root
function M.generate_file(requested_dir, package_name)
    generate("source", nil, requested_dir, package_name)
end

--- Generate a mock for the interface under the cursor or the given name.
--- @param interface_name string|nil interface name
--- @param requested_dir string|nil destination directory relative to module root
function M.generate_interface(interface_name, requested_dir, package_name)
    generate("interface", interface_name, requested_dir, package_name)
end

-- =============================================================================
-- User commands & keymaps
-- =============================================================================

local function create_command(name, callback, opts)
    pcall(vim.api.nvim_del_user_command, name)
    vim.api.nvim_create_user_command(name, callback, opts)
end

create_command("GoMockFile", function(opts)
    M.generate_file(opts.args)
end, {
    nargs = "?",
    desc = "Generate GoMock mocks for interfaces in the current file",
})

create_command("GoMockInterface", function(opts)
    local name = vim.trim(opts.args or "")
    M.generate_interface(name ~= "" and name or nil)
end, {
    nargs = "?",
    desc = "Generate a GoMock mock for an interface",
})

create_command("GoMockGen", function(opts)
    local mode = "interface"
    local interface_name = nil
    local requested_dir = nil
    local package_name = DEFAULT_PACKAGE
    local index = 1

    while index <= #opts.fargs do
        local arg = opts.fargs[index]
        if arg == "-s" or arg == "--source" then
            mode = "source"
        elseif arg == "-i" or arg == "--interface" then
            mode = "interface"
            index = index + 1
            interface_name = opts.fargs[index]
        elseif arg == "-d" or arg == "--dir" then
            index = index + 1
            requested_dir = opts.fargs[index]
        elseif arg == "-p" or arg == "--package" then
            index = index + 1
            package_name = opts.fargs[index]
        elseif arg:match("^%-%-dir=") then
            requested_dir = arg:sub(7)
        elseif arg:match("^%-%-package=") then
            package_name = arg:sub(11)
        elseif arg:match("^%-%-interface=") then
            mode = "interface"
            interface_name = arg:sub(13)
        elseif arg:sub(1, 1) ~= "-" then
            interface_name = arg
            mode = "interface"
        end
        index = index + 1
    end

    generate(mode, interface_name, requested_dir, package_name)
end, {
    nargs = "*",
    desc = "Generate GoMock mocks (-s source, -i interface, -p package, -d directory)",
})

vim.keymap.set("n", "<leader>gm", "<cmd>GoMockGen<CR>", {
    silent = true,
    buffer = true,
    desc = "[Go]: Generate mock for interface under cursor",
})
vim.keymap.set("n", "<leader>gM", "<cmd>GoMockFile<CR>", {
    silent = true,
    buffer = true,
    desc = "[Go]: Generate mocks for current file",
})

return M
