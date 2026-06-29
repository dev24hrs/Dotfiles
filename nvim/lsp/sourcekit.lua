---@brief
---
--- https://github.com/swiftlang/sourcekit-lsp
---
--- Language server for Swift and C/C++/Objective-C.

---@type vim.lsp.Config
return {
    cmd = { "xcrun", "sourcekit-lsp" },
    filetypes = { "swift", "objc", "objcpp", "c", "cpp" },
    root_dir = function(bufnr, on_dir)
        local filename = vim.api.nvim_buf_get_name(bufnr)

        -- 等价于 lspconfig.util.root_pattern,支持精确匹配和 "*.ext" 通配
        local function root_pattern(...)
            local patterns = { ... }
            return function(start_path)
                local found = vim.fs.find(function(name, _)
                    for _, pattern in ipairs(patterns) do
                        if pattern:sub(1, 1) == "*" then
                            local ext = pattern:sub(2)
                            if name:sub(-#ext) == ext then
                                return true
                            end
                        elseif name == pattern then
                            return true
                        end
                    end
                    return false
                end, { path = start_path, upward = true })[1]
                return found and vim.fs.dirname(found)
            end
        end

        local dir = root_pattern("buildServer.json", ".bsp")(filename)
            or root_pattern("*.xcodeproj", "*.xcworkspace")(filename)
            -- 放最后,因为模块化项目可能有多个 Package.swift
            or root_pattern("compile_commands.json", "Package.swift")(filename)
            or vim.fs.dirname(vim.fs.find(".git", { path = filename, upward = true })[1])

        on_dir(dir)
    end,
    get_language_id = function(_, ftype)
        local t = { objc = "objective-c", objcpp = "objective-cpp" }
        return t[ftype] or ftype
    end,
    capabilities = {
        workspace = {
            didChangeWatchedFiles = {
                dynamicRegistration = true,
            },
        },
        textDocument = {
            diagnostic = {
                dynamicRegistration = true,
                relatedDocumentSupport = true,
            },
        },
    },
}
