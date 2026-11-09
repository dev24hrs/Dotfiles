-- Copyright (c) 2026 dev24hrs. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'markdown'
--- @author dev24hrs <asang24dev@gmail.com>
--- @date 2026-11-06
--- @description Treesitter-based markdown renderer (headings, bullets, quotes, callouts, tables, links) with inline images via image.nvim

vim.pack.add({
    { src = "https://github.com/3rd/image.nvim" },
})
require("image").setup({
    backend = "kitty",
    kitty_method = "normal",
    processor = "magick_cli",
    ignore_download_error = true, -- don't throw on remote image download failures
    integrations = {
        markdown = {
            enabled = true,
            clear_in_insert_mode = true,
            download_remote_images = true,
        },
    },
})

local function npcall(fn, ...)
    local ok, res = pcall(fn, ...)
    if ok then
        return res
    end
end

local api = vim.api
local ns = api.nvim_create_namespace("md-render")
local enabled = true

local hl_links = {
    H1 = "@markup.heading.1.markdown",
    H2 = "@markup.heading.2.markdown",
    H3 = "@markup.heading.3.markdown",
    H4 = "@markup.heading.4.markdown",
    H5 = "@markup.heading.5.markdown",
    H6 = "@markup.heading.6.markdown",
    H1Bg = "DiffText",
    H2Bg = "DiffChange",
    H3Bg = "DiffChange",
    H4Bg = "DiffChange",
    H5Bg = "DiffChange",
    H6Bg = "DiffChange",
    Bullet = "Normal",
    Dash = "LineNr",
    Quote = "@markup.quote",
    Link = "@markup.link.label.markdown_inline",
    WikiLink = "RenderMarkdownLink",
    Unchecked = "@markup.list.unchecked",
    Checked = "@markup.list.checked",
    Todo = "@markup.raw",
    TableHead = "@markup.heading",
    TableRow = "Normal",
    Success = "DiagnosticOk",
    Info = "DiagnosticInfo",
    Hint = "DiagnosticHint",
    Warn = "DiagnosticWarn",
    Error = "DiagnosticError",
}

local function set_hls()
    for name, link in pairs(hl_links) do
        api.nvim_set_hl(0, "RenderMarkdown" .. name, { link = link, default = true })
    end
    -- The concealed heading marker is drawn as its own cell highlight, which
    -- replaces the line highlight; fold the heading background into it so the
    -- icon sits inside the band instead of next to it.
    for level = 1, 6 do
        local text = api.nvim_get_hl(0, { name = "RenderMarkdownH" .. level, link = false })
        local bg = api.nvim_get_hl(0, { name = "RenderMarkdownH" .. level .. "Bg", link = false })
        api.nvim_set_hl(0, "RenderMarkdownH" .. level .. "Icon", vim.tbl_extend("force", text, bg))
    end
end

local heading_icons = { "󰬺 ", "󰬻 ", "󰬼 ", "󰬽 ", "󰬾 ", "󰬿 " }
local heading_sign = "󰫎"
local bullets = { "", "", "", "" }
local checkboxes = {
    [" "] = { "󰄱", "RenderMarkdownUnchecked" },
    x = { "󰱒", "RenderMarkdownChecked" },
    X = { "󰱒", "RenderMarkdownChecked" },
    ["-"] = { "󰥔", "RenderMarkdownTodo" },
}
-- key -> { icon, highlight suffix }, the title is the capitalized key
local callouts = {
    note = { "󰋽", "Info" },
    tip = { "󰌶", "Success" },
    important = { "󰅾", "Hint" },
    warning = { "󰀪", "Warn" },
    caution = { "󰳦", "Error" },
    abstract = { "󰨸", "Info" },
    summary = { "󰨸", "Info" },
    tldr = { "󰨸", "Info" },
    info = { "󰋽", "Info" },
    todo = { "󰗡", "Info" },
    hint = { "󰌶", "Success" },
    success = { "󰄬", "Success" },
    check = { "󰄬", "Success" },
    done = { "󰄬", "Success" },
    question = { "󰘥", "Warn" },
    help = { "󰘥", "Warn" },
    faq = { "󰘥", "Warn" },
    attention = { "󰀪", "Warn" },
    failure = { "󰅖", "Error" },
    fail = { "󰅖", "Error" },
    missing = { "󰅖", "Error" },
    danger = { "󱐌", "Error" },
    error = { "󱐌", "Error" },
    bug = { "󰨰", "Error" },
    example = { "󰉹", "Hint" },
    quote = { "󱆨", "Quote" },
    cite = { "󱆨", "Quote" },
}
-- first match on the link destination wins
local link_icons = {
    { "youtube%.com", "󰗃 " },
    { "github%.com", "󰊤 " },
    { "neovim%.io", "NEOVIM_ICON" },
    { "stackoverflow%.com", "󰓌 " },
    { "discord%.com", "󰙯 " },
    { "reddit%.com", "󰑍 " },
    { "^http", "󰖟 " },
}
local link_default = "󰌹 "
local link_image = "󰥶 "
local link_email = "󰀓 "
local link_wiki = "󱗖 "

local queries = nil
local function get_queries()
    if queries == nil then
        local ok_md, md = pcall(
            vim.treesitter.query.parse,
            "markdown",
            [[
			(atx_heading) @heading
			(fenced_code_block) @code
			(thematic_break) @dash
			[(list_marker_minus) (list_marker_plus) (list_marker_star)] @bullet
			(block_quote) @quote
			(pipe_table) @table
			]]
        )
        local ok_inline, inline = pcall(
            vim.treesitter.query.parse,
            "markdown_inline",
            [[
			[(inline_link) (full_reference_link) (image) (email_autolink) (uri_autolink)] @link
			(shortcut_link) @wiki
			]]
        )
        queries = { markdown = ok_md and md or nil, markdown_inline = ok_inline and inline or nil }
    end
    return queries
end

local fence_conceal_disabled

local function fence_conceal_off()
    if fence_conceal_disabled ~= nil then
        return fence_conceal_disabled
    end
    local ok, query = pcall(vim.treesitter.query.get, "markdown", "highlights")
    if not ok or not query then
        return false
    end
    local total = 0
    for pattern, directives in pairs(query.info.patterns) do
        if vim.iter(directives):any(function(meta)
            return meta[1] == "set!" and meta[2] == "conceal_lines"
        end) then
            total = total + 1
            npcall(query.query.disable_pattern, query.query, pattern)
        end
    end
    fence_conceal_disabled = total > 0
    return fence_conceal_disabled
end

local function line(ctx, row)
    local text = ctx.lines[row]
    if not text then
        text = api.nvim_buf_get_lines(ctx.buf, row, row + 1, false)[1] or ""
        ctx.lines[row] = text
    end
    return text
end

-- Marks are collected here and written by the display pass, which decides
-- which of them are visible for the cursor row, the mode and the selection.
-- A handler therefore never has to ask where the cursor is.
--
-- anti is the filter category: false or nil keeps the mark on a row shown as
-- source, a string can be exempted through anti_ignore, and anything else is
-- hidden on such a row.
local function mark(ctx, row, col, opts, anti)
    -- Handlers can be handed a node that straddles the built range, so a row
    -- outside it is dropped rather than written.
    if ctx.top and (row < ctx.top or row > ctx.bot) then
        return
    end
    ctx.marks[#ctx.marks + 1] = {
        row = row,
        col = col,
        opts = opts,
        anti = anti,
    }
end

local function conceal(ctx, row, col, len, char, hl, anti)
    if anti == nil then
        anti = true
    end
    mark(ctx, row, col, { end_col = col + len, conceal = char, hl_group = hl }, anti)
end

-- Last row a block node covers: block nodes end at column 0 of the next row.
local function last_row(node)
    local _, _, erow, ecol = node:range()
    return ecol == 0 and erow - 1 or erow
end

local function depth(node, type)
    local n, p = 0, node:parent()
    while p do
        if p:type() == type then
            n = n + 1
        end
        p = p:parent()
    end
    return n
end

local handlers = {}

function handlers.heading(ctx, node)
    local row, col = node:start()
    local marker = node:child(0)
    local level = marker and tonumber(marker:type():match("^atx_h(%d)_marker$"))
    if not level then
        return
    end
    local hl = "RenderMarkdownH" .. level
    mark(ctx, row, col, {
        end_col = col + level,
        conceal = heading_icons[level],
        hl_group = hl .. "Icon",
    }, "head_icon")
    -- The line background and sign are decoration rather than replaced source,
    -- so they stay while the row is shown as source.
    mark(ctx, row, col, {
        line_hl_group = hl .. "Bg",
        sign_text = heading_sign,
        sign_hl_group = hl,
    }, "sign")
end

-- Fenced code blocks are intentionally left as source, so this capture has
-- nothing to draw. The fence rows stay visible because fence_conceal_off()
-- disables the query patterns that hide them when 'conceallevel' is positive.
function handlers.code() end

function handlers.dash(ctx, node)
    local row, col = node:start()
    mark(ctx, row, col, {
        virt_text = { { string.rep("─", ctx.width - col), "RenderMarkdownDash" } },
        virt_text_pos = "overlay",
    }, "dash")
end

function handlers.bullet(ctx, node)
    local row, col = node:start()
    local _, mend = node:end_()
    local text = line(ctx, row)
    -- task box right after the marker: "- [ ] ", "- [x] ", "- [-] ";
    -- the marker node can include trailing spaces
    local rest = text:sub(mend + 1)
    local bs, be, key = rest:find("%[(.)%]")
    local box = checkboxes[key or ""]
    local after = be and rest:sub(be + 1, be + 1)
    if box and bs and rest:sub(1, bs - 1):match("^%s*$") and (after == "" or after == " ") then
        return conceal(ctx, row, col, mend + be - col, box[1], box[2], "bullet")
    end
    local level = depth(node, "list")
    conceal(ctx, row, col, 1, bullets[(level - 1) % #bullets + 1], "RenderMarkdownBullet", "bullet")
end

function handlers.quote(ctx, node)
    local srow, erow = node:start(), last_row(node)
    local level = depth(node, "block_quote") + 1
    local hl = "RenderMarkdownQuote"
    local first = line(ctx, srow)
    local prefix, key = first:match("^([%s>]*)%[!(%a+)%]")
    local callout = key and callouts[key:lower()]
    if callout then
        hl = "RenderMarkdown" .. callout[2]
        conceal(ctx, srow, #prefix, #key + 3, "", hl, "callout")
        local title = key:sub(1, 1):upper() .. key:sub(2):lower()
        mark(ctx, srow, #prefix, { virt_text = { { callout[1] .. " " .. title, hl } }, virt_text_pos = "inline" }, "callout")
    end
    -- replace the ">" belonging to this quote level on every row
    for row = srow, erow do
        local n = 0
        for col in line(ctx, row):match("^[%s>]*"):gmatch("()>") do
            n = n + 1
            if n == level then
                conceal(ctx, row, col - 1, 1, "▋", hl, "quote")
                break
            end
        end
    end
end

local function strip_boundary_marker(s, marker)
    while s:sub(1, #marker) == marker do
        s = s:sub(#marker + 1)
    end
    while #s >= #marker and s:sub(-#marker) == marker do
        s = s:sub(1, -#marker - 1)
    end
    return s
end

local function strip_paired_marker(s, marker)
    local pattern = vim.pesc(marker)
    local previous
    repeat
        previous = s
        s = s:gsub(pattern .. "([^%s].-)" .. pattern, "%1")
    until s == previous
    return s
end

local function protect_code_spans(s, escaped)
    local parts, pos = {}, 1
    while true do
        local first, last = s:find("`+", pos)
        if not first then
            parts[#parts + 1] = s:sub(pos)
            break
        end
        parts[#parts + 1] = s:sub(pos, first - 1)
        local fence = s:sub(first, last)
        local close_start, close_end = s:find(fence, last + 1, true)
        if not close_start then
            parts[#parts + 1] = s:sub(first)
            break
        end
        escaped[#escaped + 1] = s:sub(last + 1, close_start - 1)
        parts[#parts + 1] = "\1" .. #escaped .. "\2"
        pos = close_end + 1
    end
    return table.concat(parts)
end

local function decode_html_entities(s)
    local named = {
        amp = "&",
        apos = "'",
        gt = ">",
        lt = "<",
        nbsp = " ",
        quot = '"',
    }
    return (
        s:gsub("&([^;]+);", function(entity)
            local hex = entity:match("^#[xX](%x+)$")
            local decimal = entity:match("^#(%d+)$")
            local code = hex and tonumber(hex, 16) or decimal and tonumber(decimal, 10)
            if code then
                local ok, char = pcall(vim.fn.nr2char, code, 1)
                return ok and char or "&" .. entity .. ";"
            end
            return named[entity] or ("&" .. entity .. ";")
        end)
    )
end

-- Convert a Markdown cell to the text shown by the renderer.
local function plain_text(s)
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    local escaped = {}
    local escape_count = 0
    s = s:gsub("\\(.)", function(char)
        escape_count = escape_count + 1
        escaped[escape_count] = char
        return "\1" .. escape_count .. "\2"
    end)
    s = protect_code_spans(s, escaped)
    s = s:gsub("%s+", " ")
    s = s:gsub("!?%[([^%]]*)%]%b()", "%1")
    s = s:gsub("%[%[([^%]]+)%]%]", "%1")
    s = s:gsub("!?%[([^%]]*)%]%[([^%]]*)%]", "%1")
    s = s:gsub("!?%[([^%]]*)%]", "%1")
    s = s:gsub("<!--.-%-%->", " ")
    s = s:gsub("<([^<>]+)>", function(inner)
        if inner:match("^%a[%w+.-]*://") or inner:match("^[^%s@]+@[^%s@]+$") then
            return inner
        end
        if inner:match("^%s*img%s") then
            return inner:match('^%s*img%s+.-alt%s*=%s*"([^"]*)"') or inner:match("^%s*img%s+.-alt%s*=%s*'([^']*)'") or ""
        end
        return inner:lower():match("^%s*br%s*/?%s*$") and " " or ""
    end)
    s = decode_html_entities(s)
    for _, marker in ipairs({ "*", "_", "~~" }) do
        s = strip_paired_marker(s, marker)
        s = strip_boundary_marker(s, marker)
    end
    s = s:gsub("\1(%d+)\2", function(index)
        return escaped[tonumber(index)]
    end)
    return (s:gsub("\t", " "))
end

local function visible_width(s)
    return vim.fn.strdisplaywidth(plain_text(s))
end

local function cell_alignment(cell, buf)
    local text = vim.treesitter.get_node_text(cell, buf)
    if text:match(":%s*$") then
        return text:match("^%s*:") and "center" or "right"
    end
    return "left"
end

---A cell padded to its column width. The rendered text is made once and
---measured from that, rather than stripping the markers a second time to measure
---what was just stripped.
local function pad_cell(text, width, alignment)
    local cell = plain_text(text)
    local pad = math.max(width - vim.fn.strdisplaywidth(cell), 0)
    local left, right
    if alignment == "right" then
        left, right = pad, 0
    elseif alignment == "center" then
        left = math.floor(pad / 2)
        right = pad - left
    else
        left, right = 0, pad
    end
    return (" "):rep(left) .. cell .. (" "):rep(right)
end

function handlers.table(ctx, node)
    local rows = {}
    for child in node:iter_children() do
        local type = child:type()
        if type == "pipe_table_header" or type == "pipe_table_delimiter_row" or type == "pipe_table_row" then
            local cells, alignments = {}, {}
            for cell in child:iter_children() do
                if cell:type() == "pipe_table_cell" or cell:type() == "pipe_table_delimiter_cell" then
                    cells[#cells + 1] = vim.treesitter.get_node_text(cell, ctx.buf)
                    if type == "pipe_table_delimiter_row" then
                        alignments[#alignments + 1] = cell_alignment(cell, ctx.buf)
                    end
                end
            end
            local row, col = child:start()
            col = math.max(col, line(ctx, row):match("^%s*"):len())
            rows[#rows + 1] = { row = row, col = col, type = type, cells = cells, alignments = alignments }
        end
    end
    if #rows == 0 then
        return
    end

    -- A table is renderable when its header has at least one cell. Outer pipes are
    -- optional in Markdown, so they must not decide whether columns can align.
    local column_count = #rows[1].cells
    local widths = {}
    for _, r in ipairs(rows) do
        if r.type ~= "pipe_table_delimiter_row" then
            for i, cell in ipairs(r.cells) do
                if i <= column_count then
                    widths[i] = math.max(widths[i] or 0, visible_width(cell))
                end
            end
        end
    end
    if column_count == 0 or not ctx.conceal then
        return
    end
    local table_col = rows[1].col
    ---The first row that says how its columns line up decides for the table.
    local alignments = {}
    for _, r in ipairs(rows) do
        if r.alignments[1] then
            alignments = r.alignments
            break
        end
    end
    ctx.table_rows = ctx.table_rows or {}
    for _, r in ipairs(rows) do
        ctx.table_rows[r.row] = true
    end
    ---A ruled line of box drawing: a piece, the run of every column, a closing piece.
    local function ruled(left, mid, right)
        local parts = {}
        for i, width in ipairs(widths) do
            parts[i] = string.rep("─", width + 2)
        end
        return left .. table.concat(parts, mid) .. right
    end

    ---The grid line that replaces one row of the table.
    local function row_text(r)
        if r.type == "pipe_table_delimiter_row" then
            return ruled("├", "┼", "┤")
        end
        local pieces = { "│" }
        for i, width in ipairs(widths) do
            pieces[#pieces + 1] = " " .. pad_cell(r.cells[i] or "", width, alignments[i] or "left") .. " │"
        end
        return table.concat(pieces)
    end

    for _, r in ipairs(rows) do
        local group = r.type == "pipe_table_row" and "RenderMarkdownTableRow" or "RenderMarkdownTableHead"
        local text = line(ctx, r.row)
        conceal(ctx, r.row, table_col, #text - table_col, "", group, "table")
        mark(ctx, r.row, table_col, {
            virt_text = { { row_text(r), group } },
            virt_text_pos = "overlay",
            hl_mode = "replace",
        }, "table")
    end

    -- The border belongs to the row it is drawn against; the filter drops it
    -- together with that row when the row is shown as source.
    mark(ctx, rows[1].row, table_col, { virt_lines = { { { ruled("┌", "┬", "┐"), "RenderMarkdownTableHead" } } }, virt_lines_above = true }, "table_border")
    mark(ctx, rows[#rows].row, table_col, { virt_lines = { { { ruled("└", "┴", "┘"), "RenderMarkdownTableRow" } } } }, "table_border")
end

function handlers.link(ctx, node)
    local row, col = node:start()
    if ctx.table_rows and ctx.table_rows[row] then
        return
    end
    local type, icon = node:type(), link_default
    if type == "image" then
        icon = link_image
    elseif type == "email_autolink" then
        icon = link_email
    else
        local dest = node
        for child in node:iter_children() do
            if child:type() == "link_destination" then
                dest = child
            end
        end
        local url = vim.treesitter.get_node_text(dest, ctx.buf):gsub("^<", "")
        for _, custom in ipairs(link_icons) do
            if url:find(custom[1]) then
                icon = custom[2]
                break
            end
        end
    end
    mark(ctx, row, col, { virt_text = { { icon, "RenderMarkdownLink" } }, virt_text_pos = "inline" }, "link")
end

-- [[page]] parses as a shortcut link wrapped in one more pair of brackets
function handlers.wiki(ctx, node)
    local row, col = node:start()
    if ctx.table_rows and ctx.table_rows[row] then
        return
    end
    local _, ecol = node:end_()
    local text = line(ctx, row)
    if col == 0 or text:sub(col, col) ~= "[" or text:sub(ecol + 1, ecol + 1) ~= "]" then
        return
    end
    conceal(ctx, row, col - 1, 1, "", "RenderMarkdownWikiLink", "link")
    conceal(ctx, row, ecol, 1, "", "RenderMarkdownWikiLink", "link")
    mark(ctx, row, col - 1, { virt_text = { { link_wiki, "RenderMarkdownWikiLink" } }, virt_text_pos = "inline" }, "link")
end

---The letter 'concealcursor' and the renderer both spell a selection with: all
---four selection modes share "v", and select mode (^S, ^O) is a selection too.
---@return string|nil the letter, or nil when the mode is not a selection
local function selection_mode()
    local mode = api.nvim_get_mode().mode
    if mode == "\19" or mode == "\20" then
        return "v"
    end
    local first = mode:sub(1, 1)
    return first:find("[vV\22sS]") and "v" or nil
end

-- The rows a visual or select mode selection covers, 0 indexed, or nil when no
-- selection is active. A selection is anchored at the 'v mark and ends at the
-- cursor, whichever order they are in; 'v' is unset outside a selection, and
-- then line() answers 0.
--
-- This is what makes a selection visible at all: a cell covered by a conceal
-- extmark and an overlay is never given the Visual highlight, so a rendered
-- row hides the selection drawn over it. Measured on a table, every cell of a
-- selected row wore the row highlight and none the Visual one, while the plain
-- lines around it showed the selection. Nothing on the extmark recovers it:
-- hl_mode = "combine" on the overlay and dropping the highlight from the
-- conceal both leave the row exactly as it was. The row has to be drawn as
-- source, which is what the display filter does for a selection and for the
-- cursor row in a mode where 'concealcursor' reveals it.
---@return integer[]? rows the first and last selected row, 0 indexed
local function selected_rows()
    if not selection_mode() then
        return nil
    end
    local anchor = vim.fn.line("v")
    if anchor == 0 then
        return nil
    end
    local cur = api.nvim_win_get_cursor(0)[1]
    return { math.min(anchor, cur) - 1, math.max(anchor, cur) - 1 }
end

-- 'concealcursor' lists the modes in which the cursor line is concealed too
local function conceals_cursor_line(win)
    local cocu = vim.wo[win].concealcursor
    if cocu == "" then
        return false
    end
    local selected = selection_mode()
    local mode = selected or api.nvim_get_mode().mode:sub(1, 1)
    return cocu:find(mode, 1, true) ~= nil
end

-- The rows shown as source. In a mode where 'concealcursor' keeps the cursor
-- line concealed the whole buffer is rendered, so there is nothing to reveal.
-- Otherwise (insert, visual, select) the cursor line is shown as source, and a
-- selection takes its whole range with it.
---@return integer[]? range first and last row shown as source, 0 indexed
local function reveal_range(ctx)
    if ctx.selection then
        return ctx.selection
    end
    if ctx.cur < 0 or ctx.conceal_cur then
        return nil
    end
    return { ctx.cur, ctx.cur }
end

-- Categories that stay visible even on a row shown as source.
local anti_ignore = {
    sign = true,
}

local function hidden(m, range)
    if not range or m.row < range[1] or m.row > range[2] then
        return false
    end
    local anti = m.anti
    if anti == nil or anti == false then
        return false
    end
    return not (type(anti) == "string" and anti_ignore[anti])
end

---@param a integer[]?
---@param b integer[]?
local function same_range(a, b)
    if a == nil or b == nil then
        return a == b
    end
    return a[1] == b[1] and a[2] == b[2]
end

-- Marks are kept between renders with the id of their extmark, so a cursor move
-- only deletes and re-adds the handful whose visibility changed. Clearing the
-- namespace on every move would work, but it throws away the ids and rewrites
-- every mark in the visible range for no reason.
local function apply_marks(buf, marks, range)
    for _, m in ipairs(marks) do
        if hidden(m, range) then
            if m.id then
                npcall(api.nvim_buf_del_extmark, buf, ns, m.id)
                m.id = nil
            end
        elseif not m.id then
            m.opts.strict = false
            local id = npcall(api.nvim_buf_set_extmark, buf, ns, m.row, m.col, m.opts)
            if id then
                m.id = id
            end
        end
    end
end

-- Walk every capture that touches [top, bot] and let its handler add marks to
-- the context. Nothing is written to the buffer here.
local function draw(parser, buf, top, bot, ctx)
    local qs = get_queries()
    parser:for_each_tree(function(tree, ltree)
        local query = qs[ltree:lang()]
        local root = tree:root()
        local srow, _, erow = root:range()
        if not query or erow < top or srow > bot then
            return
        end
        for id, node in query:iter_captures(root, buf, top, bot) do
            npcall(handlers[query.captures[id]], ctx, node)
        end
    end)
end

---@return integer? win the window the cursor row is read from, or nil when the
---buffer is not on screen
---@return integer[] wins every window the buffer is on screen in, empty when
---there is no win
local function window_of(buf)
    local wins = vim.fn.win_findbuf(buf)
    if not enabled or #wins == 0 then
        return nil, {}
    end
    local cur_win = api.nvim_get_current_win()
    return vim.tbl_contains(wins, cur_win) and cur_win or wins[1], wins
end

local cache = {}

local function visible_range(wins)
    local top, bot = math.huge, 0
    for _, w in ipairs(wins) do
        local info = vim.fn.getwininfo(w)[1]
        top, bot = math.min(top, info.topline - 1), math.max(bot, info.botline)
    end
    -- only the visible rows of every window showing the buffer, plus a margin
    return math.max(top - 100, 0), bot + 100
end

---The context a build runs with: line cache, mark list, the cursor and the
---selection the filter will use, and the range the marks are built for.
local function context(buf, win, top, bot)
    local info = vim.fn.getwininfo(win)[1]
    local cur_win = api.nvim_get_current_win()
    return {
        buf = buf,
        lines = {},
        marks = {},
        top = top,
        bot = bot,
        cur = win == cur_win and api.nvim_win_get_cursor(win)[1] - 1 or -1,
        selection = win == cur_win and selected_rows() or nil,
        width = info.width - info.textoff,
        conceal = vim.wo[win].conceallevel > 0,
        conceal_cur = win == cur_win and conceals_cursor_line(win),
    }
end

---Only what the filter needs: no line cache and no marks.
local function filter_context(buf, win)
    local cur_win = api.nvim_get_current_win()
    return {
        buf = buf,
        cur = win == cur_win and api.nvim_win_get_cursor(win)[1] - 1 or -1,
        selection = win == cur_win and selected_rows() or nil,
        conceal_cur = win == cur_win and conceals_cursor_line(win),
    }
end

local function needs_build(buf, win, wins, entry)
    if entry.tick ~= api.nvim_buf_get_changedtick(buf) then
        return true
    end
    if entry.conceallevel ~= vim.wo[win].conceallevel then
        return true
    end
    local info = vim.fn.getwininfo(win)[1]
    if entry.width ~= info.width - info.textoff then
        return true
    end
    local top, bot = visible_range(wins)
    return top < entry.top or bot > entry.bot
end

local function build(buf)
    if not api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" then
        return
    end
    local win, wins = window_of(buf)
    if not win then
        api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        cache[buf] = nil
        return
    end
    local parser = vim.treesitter.get_parser(buf, "markdown", { error = false })
    if not parser then
        api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        cache[buf] = nil
        return
    end
    local top, bot = visible_range(wins)
    parser:parse({ top, bot })
    local ctx = context(buf, win, top, bot)
    draw(parser, buf, top, bot, ctx)
    api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local range = reveal_range(ctx)
    cache[buf] = {
        marks = ctx.marks,
        top = top,
        bot = bot,
        width = ctx.width,
        conceallevel = vim.wo[win].conceallevel,
        tick = api.nvim_buf_get_changedtick(buf),
        range = range,
    }
    apply_marks(buf, ctx.marks, range)
end

-- A display pass reuses the marks of the last build and only toggles the ones
-- whose visibility changed, which is what a cursor move, a mode change and a
-- selection need. Anything that changes the text, the visible range or the
-- layout needs a build instead, which needs_build() recognizes.
local function display(buf)
    if not api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" then
        return
    end
    local win, wins = window_of(buf)
    if not win then
        api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        cache[buf] = nil
        return
    end
    local entry = cache[buf]
    if not entry or needs_build(buf, win, wins, entry) then
        build(buf)
        return
    end
    local range = reveal_range(filter_context(buf, win))
    if same_range(entry.range, range) then
        return
    end
    entry.range = range
    apply_marks(buf, entry.marks, range)
end

local pending_timers = {}
local pending_build = {}
local pending_display = {}

-- A build reparses the visible range and rewrites the mark list; a display
-- only filters the cached marks. A build makes a queued display redundant, so
-- a display is skipped while one is pending, and two events in one tick are
-- coalesced into one pass.
local function schedule_build(buf, delay)
    if not api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" then
        return
    end
    local timer = pending_timers[buf]
    if timer then
        timer:stop()
        timer:close()
        pending_timers[buf] = nil
    end
    pending_build[buf] = true
    pending_display[buf] = nil
    if delay and delay > 0 then
        pending_timers[buf] = vim.defer_fn(function()
            pending_timers[buf] = nil
            pending_build[buf] = nil
            build(buf)
        end, delay)
        return
    end
    vim.schedule(function()
        if not pending_build[buf] then
            return
        end
        pending_build[buf] = nil
        build(buf)
    end)
end

local function schedule_display(buf)
    if not api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "markdown" then
        return
    end
    if pending_build[buf] or pending_display[buf] then
        return
    end
    pending_display[buf] = true
    vim.schedule(function()
        pending_display[buf] = nil
        if pending_build[buf] then
            return
        end
        display(buf)
    end)
end

local render_group = api.nvim_create_augroup("md-render", { clear = true })

set_hls()
api.nvim_create_autocmd("ColorScheme", { group = render_group, callback = set_hls })

-- FileType is where a markdown buffer is built for the first time, and where
-- the treesitter patterns that hide code fences are disabled. The empty buffer
-- nvim starts with raises BufWinEnter before any file has been read, so the
-- filetype is what says there is a markdown buffer to compile a query for.
api.nvim_create_autocmd("FileType", {
    group = render_group,
    callback = function(ev)
        if vim.bo[ev.buf].filetype == "markdown" then
            fence_conceal_off()
            schedule_build(ev.buf, 0)
        end
    end,
})

-- Entering a window changes which buffer has the cursor, but the marks are
-- already built: re-filtering is enough.
api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    group = render_group,
    callback = function(ev)
        schedule_display(ev.buf)
    end,
})

api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = render_group,
    callback = function(ev)
        schedule_build(ev.buf, 150)
    end,
})

api.nvim_create_autocmd({ "WinScrolled", "WinResized", "OptionSet" }, {
    group = render_group,
    callback = function(ev)
        if ev.event == "OptionSet" then
            if ev.match ~= "conceallevel" and ev.match ~= "concealcursor" then
                return
            end
        elseif ev.event == "WinScrolled" then
            -- Only the window that scrolled can be showing different rows now.
            -- WinScrolled names it: <amatch> and <afile> are both the window id
            -- and the pattern is matched against it. A window id that is not in
            -- this tabpage means nothing here changed, so that is the end of it
            -- rather than a fallback to every window: a scroll in another
            -- tabpage cannot move a row in this one. The display pass turns
            -- into a build if the new rows fall outside the cached range.
            local id = tonumber(ev.match)
            local win = id and api.nvim_win_is_valid(id) and id or nil
            if not win or vim.fn.win_id2win(win) == 0 then
                return
            end
            schedule_display(api.nvim_win_get_buf(win))
            return
        end
        -- WinResized and a change to conceallevel or concealcursor: every window
        -- is a different size or every row is drawn differently, so all of them.
        for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
            schedule_display(api.nvim_win_get_buf(win))
        end
    end,
})

-- A cursor move changes which row is the cursor row, and a mode change starts
-- or ends a selection or changes whether the cursor line is concealed. All of
-- that is decided by the filter over the cached marks, so neither event needs
-- a tree parse or a rewrite of the namespace.
api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged" }, {
    group = render_group,
    callback = function(ev)
        schedule_display(ev.buf)
    end,
})

api.nvim_create_autocmd("BufWipeout", {
    group = render_group,
    callback = function(ev)
        cache[ev.buf] = nil
        pending_build[ev.buf] = nil
        pending_display[ev.buf] = nil
        local timer = pending_timers[ev.buf]
        if timer then
            timer:stop()
            timer:close()
            pending_timers[ev.buf] = nil
        end
    end,
})

-- Markdown preview use cli mdserve
local mdserve_job = nil
vim.keymap.set("n", "<leader>mp", function()
    if mdserve_job then
        vim.fn.jobstop(mdserve_job) -- stop previous mdserve
    end

    local file = vim.fn.expand("%:p")
    if file == "" then
        vim.notify("No file to preview", vim.log.levels.WARN)
        return
    end
    mdserve_job = vim.fn.jobstart({ "mdserve", file, "--port", "1337", "--open" }, { detach = true })
end, { desc = "Markdown preview (mdserve)" })

-- Clean up mdserve process when exiting nvim
vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        if mdserve_job then
            vim.fn.jobstop(mdserve_job)
        end
    end,
})

vim.keymap.set("n", "<leader>um", function()
    enabled = not enabled
    for _, buf in ipairs(api.nvim_list_bufs()) do
        api.nvim_buf_clear_namespace(buf, ns, 0, -1)
        cache[buf] = nil
        schedule_build(buf, 0)
    end
    vim.notify("Markdown rendering " .. (enabled and "on" or "off"))
end, { desc = "Toggle render markdown" })
