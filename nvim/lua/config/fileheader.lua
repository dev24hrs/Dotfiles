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
    },
    go = {
        "// Package ${FILENAME_SAFE_GO} provides desc...",
        "//",
        "// Copyright (c) ${YEAR} ${AUTHOR}. All rights reserved.",
        "// SPDX-License-Identifier: MIT",
        "",
        -- Go package names allow only [a-zA-Z0-9_] and must not start with a digit
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
local function do_insert(lines, buf)
    buf = buf or 0
    local ph = build_placeholders()
    add_go_safe_placeholder(ph)

    for i, line in ipairs(lines) do
        lines[i] = line:gsub("%$%{[A-Z_]+%}", ph)
    end

    api.nvim_buf_set_lines(buf, 0, 0, false, lines)
    api.nvim_win_set_cursor(0, { #lines, 0 })
end

-- 6. Single autocmd for all filetypes
local header_group = vim.api.nvim_create_augroup("User_FileHeader", { clear = true })

api.nvim_create_autocmd({ "BufNewFile", "BufReadPost" }, {
    group = header_group,
    callback = function(args)
        local buf = args.buf
        vim.schedule(function()
            -- Guard: buffer may have been closed before schedule fires
            if not api.nvim_buf_is_valid(buf) then
                return
            end
            -- Use vim.bo.filetype (consistent with :FileHeader) — at schedule
            -- time filetype detection has already run, so this is reliable.
            local ft = vim.bo[buf].filetype
            local template = templates[ft]
            if not template then
                return
            end
            -- Guard: don't overwrite content added by other plugins or templates
            local first_line = api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
            if first_line ~= "" or api.nvim_buf_line_count(buf) > 1 then
                return
            end
            do_insert(vim.deepcopy(template), buf)
        end)
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
