---@brief
---
--- https://github.com/golang/tools/tree/master/gopls
---
--- Google's lsp server for golang.
--- [Settings documentation](https://go.dev/gopls/settings)

--- @class go_dir_custom_args

local mod_cache = nil
local std_lib = nil

---@param custom_args go_dir_custom_args
---@param on_complete fun(dir: string | nil)
local function identify_go_dir(custom_args, on_complete)
    local cmd = { "go", "env", custom_args.envvar_id }
    vim.system(cmd, { text = true }, function(output)
        local res = vim.trim(output.stdout or "")
        if output.code == 0 and res ~= "" then
            if custom_args.custom_subdir and custom_args.custom_subdir ~= "" then
                res = res .. custom_args.custom_subdir
            end
            on_complete(res)
        else
            vim.schedule(function()
                vim.notify(
                    ("[gopls] identify " .. custom_args.envvar_id .. " dir cmd failed with code %d: %s\n%s"):format(
                        output.code,
                        vim.inspect(cmd),
                        output.stderr
                    )
                )
            end)
            on_complete(nil)
        end
    end)
end

---@return string?
local function get_std_lib_dir()
    if std_lib and std_lib ~= "" then
        return std_lib
    end

    identify_go_dir({ envvar_id = "GOROOT", custom_subdir = "/src" }, function(dir)
        if dir then
            std_lib = dir
        end
    end)
    return std_lib
end

---@return string?
local function get_mod_cache_dir()
    if mod_cache and mod_cache ~= "" then
        return mod_cache
    end

    identify_go_dir({ envvar_id = "GOMODCACHE" }, function(dir)
        if dir then
            mod_cache = dir
        end
    end)
    return mod_cache
end

---@param fname string
---@return string?
local function get_root_dir(fname)
    if mod_cache and fname:sub(1, #mod_cache) == mod_cache then
        local clients = vim.lsp.get_clients({ name = "gopls" })
        if #clients > 0 then
            return clients[#clients].config.root_dir
        end
    end
    if std_lib and fname:sub(1, #std_lib) == std_lib then
        local clients = vim.lsp.get_clients({ name = "gopls" })
        if #clients > 0 then
            return clients[#clients].config.root_dir
        end
    end
    return vim.fs.root(fname, "go.work") or vim.fs.root(fname, "go.mod") or vim.fs.root(fname, ".git")
end

return {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_dir = function(bufnr, on_dir)
        local fname = vim.api.nvim_buf_get_name(bufnr)
        get_mod_cache_dir()
        get_std_lib_dir()
        -- see: https://github.com/neovim/nvim-lspconfig/issues/804
        on_dir(get_root_dir(fname))
    end,
    settings = {
        gopls = {
            -- 排除不需要索引的目录，减少内存占用
            directoryFilters = { "-**/node_modules", "-**/.git", "-**/vendor" },
            -- 启用 gofumpt 格式化（比 gofmt 更严格）
            gofumpt = true,
            -- 补全时使用占位符，方便跳转编辑
            usePlaceholders = true,
            -- 补全未 import 的包，选中后自动添加 import
            completeUnimported = true,
            -- 启用 staticcheck 静态分析（SA 系列检查）
            staticcheck = true,
            -- 语义级语法高亮（比 Tree-sitter 更精确的类型着色）
            semanticTokens = true,
            -- 额外处理的独立构建标签（不影响默认文件的分析）
            standaloneTags = { "integration" },
            -- 符号匹配风格：Dynamic 自适应模糊/精确匹配（Go 1.23+）
            symbolStyle = "Dynamic",
            -- 代码透镜：在函数/包上方显示的可点击操作
            codelenses = {
                generate = true,            -- 显示 go:generate 入口
                regenerate_cgo = true,      -- 重新生成 cgo 定义
                run_govulncheck = true,     -- 运行 govulncheck 漏洞扫描
                test = true,                -- 显示 run test / benchmark 入口
                tidy = true,                -- 运行 go mod tidy
                upgrade_dependency = true,  -- 检查依赖升级
                vendor = true,              -- 运行 go mod vendor
            },
            -- 内联提示：编辑器内显示的虚拟文本注解
            hints = {
                assignVariableTypes = false,     -- 不显示 := 变量的推断类型（较吵）
                compositeLiteralFields = true,   -- 显示复合字面量的字段名
                compositeLiteralTypes = false,   -- 不显示复合字面量的类型（较吵）
                constantValues = true,           -- 显示常量的计算结果值
                fillReturns = true,              -- 提示填充 return 语句的零值
                functionTypeParameters = true,   -- 显示泛型函数的类型参数
                parameterNames = true,           -- 显示函数调用时的参数名
                rangeVariableTypes = false,      -- 不显示 range 循环变量的类型（较吵）
            },
            -- 静态分析器：编码时实时检查代码问题
            analyses = {
                useany = true,              -- 建议用 any 替代 interface{}
                unusedparams = true,        -- 检测未使用的函数参数
                unusedwrite = true,         -- 检测写入但从未读取的变量
                unusedfunc = true,          -- 检测未使用的函数/方法
                unusedvariable = true,      -- 检测未使用的局部变量
                timeformat = true,          -- 检测 time.Format/Sprintf 格式字符串错误
                shadow = true,              -- 检测变量遮蔽（短声明意外覆盖外层变量）
                nilness = true,             -- 检测可能的 nil 指针解引用
                unusedresult = true,        -- 检测被忽略的函数返回值（如未处理的 error）
                infertypeargs = true,       -- 建议移除可推断的泛型类型参数（Go 1.21+）
            },
        },
    },
}
