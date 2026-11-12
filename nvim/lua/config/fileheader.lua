-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'fileheader'
--- @author x3m4g63 <asang24dev@gmail.com>
--- @date 2026-11-12
--- @description Automatic copyright headers and the :FileHeader command

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
        ["${DATE}"] = os.date("%Y-%m-%d"),
        ["${FILENAME}"] = vim.fn.expand("%:t:r"),
        ["${AUTHOR}"] = git_name,
        ["${EMAIL}"] = git_email,
    }
end

-- 3. Table-driven templates: add a new filetype by adding one entry
local templates = {
    lua = {
        "-- Copyright (c) ${YEAR} ${AUTHOR}. All rights reserved.",
        "-- The source code is released under the MIT License.",
        "--",
        "--- @module '${FILENAME}'",
        "--- @author ${AUTHOR} <${EMAIL}>",
        "--- @date ${DATE}",
        "--- @description desc...",
        "",
        "",
    },
    go = {
        "// Copyright (c) ${YEAR} ${AUTHOR}. All rights reserved.",
        "// The source code is released under the MIT License.",
        "//",
        "// Package ${FILENAME_SAFE_GO} provides desc...",
        "//",
        "// author: ${AUTHOR} <${EMAIL}>",
        "// date: ${DATE}",
        "",
        "",
    },
    rust = {
        "// Copyright (c) ${YEAR} ${AUTHOR} <${EMAIL}>",
        "// The source code is released under the MIT License.",
        "//",
        "//! # ${FILENAME}",
        "//!",
        "//! author: ${AUTHOR} <${EMAIL}>",
        "//! date: ${DATE}",
        "//! desc...",
        "",
        "",
    },
    typescript = {
        "/**",
        " * Copyright (c) ${YEAR} ${AUTHOR}. All rights reserved.",
        " * The source code is released under the MIT License.",
        " *",
        " * @file ${FILENAME}",
        " * @author ${AUTHOR} <${EMAIL}>",
        " * @date ${DATE}",
        " * @description desc...",
        " */",
        "",
        "",
    },
    python = {
        '"""${FILENAME}',
        "",
        "desc...",
        "",
        "Copyright (c) ${YEAR} ${AUTHOR} <${EMAIL}>",
        "The source code is released under the MIT License.",
        "author: ${AUTHOR} <${EMAIL}>",
        "date: ${DATE}",
        '"""',
        "",
        "",
    },
}
templates.typescriptreact = templates.typescript

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
    -- BufReadPost may fire for a background buffer; only move the cursor when
    -- the buffer is actually displayed in the current window.
    if api.nvim_get_current_buf() == buf then
        api.nvim_win_set_cursor(0, { #lines, 0 })
    end
end

-- 6. Single autocmd for all filetypes
-- BufNewFile: editing a path that does not exist yet.
-- BufReadPost: files created on disk first (e.g. nvim-tree's `a` uses
-- uv.fs_open before opening the buffer), so BufNewFile never fires.
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
            -- Guard: only real file buffers (BufReadPost fires for more cases)
            if vim.bo[buf].buftype ~= "" then
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
