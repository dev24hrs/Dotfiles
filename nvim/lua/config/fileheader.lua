local api = vim.api

-- 1. Cache git user info (stable within a session)
local cached_name, cached_email

local function get_git_info()
    if cached_name then
        return cached_name, cached_email
    end

    local name, email = "Developer", "Developer@example.com"
    local lines = vim.fn.systemlist({ "git", "config", "--get-regexp", "^user\\.(name|email)$" })

    if vim.v.shell_error == 0 then
        for _, line in ipairs(lines) do
            local key, val = line:match("^user%.(%w+) (.+)$")
            if key == "name" then
                name = val
            elseif key == "email" then
                email = val
            end
        end
    end

    cached_name, cached_email = name, email
    return name, email
end

-- 2. Single-pass placeholder substitution via gsub table
local function build_placeholders()
    local git_name, git_email = get_git_info()
    return {
        ["${YEAR}"] = os.date("%Y"),
        ["${FILENAME}"] = vim.fn.expand("%:t:r"),
        ["${AUTHOR}"] = git_name,
        ["${EMAIL}"] = git_email,
    }
end

-- 3. Table-driven templates: add a new filetype by adding one entry
local templates = {
    lua = {
        "-- Copyright (c) ${YEAR} ${AUTHOR}. All rights reserved.",
        "-- SPDX-License-Identifier: MIT",
        "--",
        "--- @module '${FILENAME}'",
        "--- @description desc...",
        "--- @author ${AUTHOR} <${EMAIL}>",
        "",
        "local M = {}",
        "",
        "return M",
    },
    go = {
        "// Package ${FILENAME_SAFE_GO} provides desc...",
        "//",
        "// Copyright (c) ${YEAR} ${AUTHOR}. All rights reserved.",
        "// SPDX-License-Identifier: MIT",
        "",
        -- Go package names allow only [a-zA-Z0-9_] and must not start with a digit
        "package ${FILENAME_SAFE_GO}",
        "",
    },
    rust = {
        "//! # ${FILENAME}",
        "//! ",
        "//! desc...",
        "",
        "// Copyright (c) ${YEAR} ${AUTHOR} <${EMAIL}>",
        "// SPDX-License-Identifier: MIT",
        "",
    },
    typescript = {
        "/**",
        " * @file ${FILENAME}",
        " * @description desc...",
        " * @author ${AUTHOR} <${EMAIL}>",
        " * @copyright Copyright (c) ${YEAR} ${AUTHOR}. All rights reserved.",
        " * @license SPDX-License-Identifier: MIT",
        " */",
        "",
    },
    python = {
        '"""${FILENAME}',
        "",
        "desc...",
        "",
        "Copyright (c) ${YEAR} ${AUTHOR} <${EMAIL}>",
        "SPDX-License-Identifier: MIT",
        '"""',
        "",
    },
}

-- 4. Sanitize Go package name: replace illegal chars with _, prefix _ if starts with digit
local function add_go_safe_placeholder(ph)
    local raw = ph["${FILENAME}"]
    local safe = raw:gsub("[^%w_]", "_")
    if safe:match("^%d") then
        safe = "_" .. safe
    end
    ph["${FILENAME_SAFE_GO}"] = safe
end

-- 5. Shared insert logic
local function do_insert(lines)
    local ph = build_placeholders()
    add_go_safe_placeholder(ph)

    for i, line in ipairs(lines) do
        lines[i] = line:gsub("%$%{[A-Z_]+%}", ph)
    end

    api.nvim_buf_set_lines(0, 0, 0, false, lines)
    api.nvim_win_set_cursor(0, { #lines, 0 })
end

-- 6. Single autocmd for all filetypes
local header_group = vim.api.nvim_create_augroup("User_FileHeader", { clear = true })

api.nvim_create_autocmd("BufNewFile", {
    group = header_group,
    callback = function(args)
        local ft = vim.filetype.match({ buf = args.buf })
        local template = templates[ft]
        if not template then
            return
        end
        do_insert(vim.deepcopy(template))
    end,
})

-- 7. Manual trigger via :FileHeader
vim.api.nvim_create_user_command("FileHeader", function()
    local ft = vim.bo.filetype
    local template = templates[ft]
    if not template then
        vim.notify("No header template for filetype: " .. ft, vim.log.levels.WARN)
        return
    end

    do_insert(vim.deepcopy(template))
    vim.notify("File header inserted", vim.log.levels.INFO)
end, {})
