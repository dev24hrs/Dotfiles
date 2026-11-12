-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'util'
--- @author x3m4g63 <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Shared helpers for lua/go/*.lua.

local M = {}

--- Define (or redefine) a global user command.
function M.create_command(name, callback, opts)
    pcall(vim.api.nvim_del_user_command, name)
    vim.api.nvim_create_user_command(name, callback, opts)
end

--- Turn a vim.SystemCompleted result into a user-facing error message.
function M.command_error(result, command_name)
    local message = vim.trim(result.stderr or "")
    if message == "" then
        message = vim.trim(result.stdout or "")
    end
    if message == "" then
        message = result.signal and string.format("%s terminated by signal %d", command_name, result.signal) or (command_name .. " failed")
    end
    return message
end

--- Ensure a CLI tool is executable.
--- @return boolean ok
--- @return string? message install hint when the binary is missing
function M.ensure_bin(bin, repo)
    if vim.fn.executable(bin) == 1 then
        return true
    end
    return false, string.format("%s not found. Install: go install github.com/%s@latest", bin, repo)
end

--- Walk up from start_dir until go.mod is found.
--- @param start_dir string
--- @return string|nil
function M.find_module_root(start_dir)
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

--- Floating-window state shared by the benchmark and coverage modules. Both
--- require this module once, so clearing a float from either side closes the
--- same window regardless of which buffer is current.
M.floats = {
    benchmark = { win = nil, buf = nil },
    coverage = { win = nil, buf = nil },
}

--- Path relative to the module root, without a leading "./".
--- @param path string
--- @param root string
--- @return string
function M.relative_to_root(path, root)
    if path == "" then
        return ""
    end
    if path == root then
        return "."
    end

    local prefix = root .. "/"
    if vim.startswith(path, prefix) then
        return path:sub(#prefix + 1)
    end
    return path
end

return M
