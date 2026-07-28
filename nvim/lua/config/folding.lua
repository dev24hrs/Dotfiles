local M = {}

vim.o.foldcolumn = "0"
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true
vim.o.foldmethod = "expr"
vim.o.fillchars = "eob: ,fold: ,foldopen:,foldsep: ,foldclose:"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Build a single-highlight segment for the given line text.
-- Queries treesitter once per line (not per-character) and applies the
-- highest-priority capture to the entire fold text.
local function fold_virt_text(result, start_text, lnum)
    local hl = nil
    local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, lnum, 0)

    if ok and captures and #captures > 0 then
        local top = captures[1]
        local top_prio = (top.metadata and tonumber(top.metadata.priority)) or 0
        for j = 2, #captures do
            local prio = (captures[j].metadata and tonumber(captures[j].metadata.priority)) or 0
            if prio > top_prio then
                top = captures[j]
                top_prio = prio
            end
        end
        hl = "@" .. top.capture
    end

    table.insert(result, { start_text, hl })
end

function M.foldtext()
    local start_text = vim.fn.getline(vim.v.foldstart):gsub("\t", string.rep(" ", vim.o.tabstop))
    local nline = vim.v.foldend - vim.v.foldstart
    local result = {}

    fold_virt_text(result, start_text, vim.v.foldstart - 1)
    table.insert(result, { "  ", nil })
    table.insert(result, { "    ...... 󰁂  " .. nline .. " lines folded", "Character" })

    return result
end

vim.keymap.set("n", "zf", "za", { desc = "[Folding]: Toggle code block", noremap = true, silent = true })
vim.keymap.set("n", "zr", "zR", { desc = "[Folding]: Unfold all code blocks", noremap = true, silent = true })
vim.keymap.set("n", "zm", "zM", { desc = "[Folding]: Fold all code blocks", noremap = true, silent = true })

vim.opt.foldtext = "v:lua.require'config.folding'.foldtext()"

return M
