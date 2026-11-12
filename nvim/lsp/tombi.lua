-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- SPDX-License-Identifier: MIT

---@brief
---
--- https://tombi-toml.github.io/tombi/
--- Language server for Tombi, a TOML toolkit.

---@type vim.lsp.Config
return {
    cmd = { "tombi", "lsp" },
    filetypes = { "toml" },
    root_markers = { "tombi.toml", "pyproject.toml", ".git" },
}
