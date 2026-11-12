-- Copyright (c) 2026 x3m4g63. All rights reserved.
-- The source code is released under the MIT License.
--
--- @module 'image'
--- @author x3m4g63 <asang24dev@gmail.com>
--- @date 2026-11-09
--- @description Paste images with automatic R2 upload and URL backfill; uploads run serially and local copies live in the cache directory

vim.pack.add({
    { src = "https://github.com/3rd/image.nvim" },
    { src = "https://github.com/HakonHarnes/img-clip.nvim" },
})
-- img-clip's plugin script replaces vim.paste at startup, so apply its options at
-- startup too; otherwise text pastes hit the default verbose=true and warn
-- "Content is not an image." until the lazy setup runs.
require("img-clip").setup({
    default = {
        verbose = false,
        -- Scratch copy that feeds the R2 upload; the document only ever gets
        -- the URL, so the local image belongs in the cache, not the repository.
        dir_path = vim.fs.joinpath(vim.fn.stdpath("cache"), "img-clip"),
        -- Absolute so a failed upload still links to a readable local file.
        use_absolute_path = true,
        copy_images = true,
        prompt_for_file_name = false,
        file_name = "%Y%m%d-%H%M%S",
        extension = "png",
        -- process_cmd = "",
        process_cmd = "convert - -resize 50% -",
        formats = { "jpeg", "jpg", "png" },
        drag_and_drop = {
            insert_mode = true,
        },
    },
    filetypes = {
        markdown = {
            url_encode_path = true,
            template = "![image$CURSOR]($FILE_PATH)",
            download_images = false,
        },
        vimwiki = {
            url_encode_path = true,
            template = "![$CURSOR]($FILE_PATH)",
            download_images = false,
        },
        html = {
            template = '<img src="$FILE_PATH" alt="$CURSOR">',
        },
    },
})

local function setup_image()
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
end

--- Paste the image right away, upload it to R2 in the background, and replace the local path with the URL when the upload finishes.
--- Uploads run one at a time; a failed one keeps the local path.

---@param opts? { script?: string, filetypes?: string[], title?: string }
local function setup_r2_upload(opts)
    opts = opts or {}
    local script = opts.script or vim.fs.joinpath(vim.fs.dirname(vim.fn.resolve(vim.fn.stdpath("config"))), "r2-upload-images.sh")
    local filetypes = opts.filetypes or { "markdown" }
    local title = opts.title or "img-clip"

    local upload_ns = vim.api.nvim_create_namespace("img-clip-r2")
    local upload_sentinel = "__IMGCLIP_R2_FILE_PATH__"
    local markup = require("img-clip.markup")
    local insert_markup = markup.insert_markup

    ---The extmark range of an upload, or nil when the buffer is gone or the mark
    ---was invalidated (the path was removed while the upload ran).
    ---@return integer? start_row
    ---@return integer? start_col
    ---@return integer? end_row
    ---@return integer? end_col
    local function upload_range(buf, id)
        if not vim.api.nvim_buf_is_valid(buf) then
            return nil
        end
        local mark = vim.api.nvim_buf_get_extmark_by_id(buf, upload_ns, id, { details = true })
        local details = mark[3]
        if not details then
            return nil
        end
        return mark[1], mark[2], details.end_row, details.end_col
    end

    ---@param err string
    local function upload_failed(err)
        vim.notify("R2 upload failed, kept local path\n" .. err, vim.log.levels.WARN, { title = title })
    end

    -- One upload at a time: a paste starts a wrangler process, and a burst of
    -- pastes would otherwise run them all at once. The queue keeps the uploads,
    -- and with them the backfills, in pasting order.
    local upload_queue = {}
    local upload_running = false

    local function drain_uploads()
        local job = table.remove(upload_queue, 1)
        if not job then
            upload_running = false
            return
        end
        job(drain_uploads)
    end

    ---@param job fun(done: fun())
    local function queue_upload(job)
        upload_queue[#upload_queue + 1] = job
        if not upload_running then
            upload_running = true
            drain_uploads()
        end
    end

    ---@param buf integer
    ---@param id integer
    ---@param result vim.SystemCompleted
    local function backfill(buf, id, result)
        local start_row, start_col, end_row, end_col = upload_range(buf, id)
        if not (start_row and start_col and end_row and end_col) then
            return
        end
        local url = vim.trim(result.stdout)
        if result.code ~= 0 or not url:match("^https://") then
            vim.api.nvim_buf_del_extmark(buf, upload_ns, id)
            upload_failed(vim.trim(result.stderr):match("[^\n]*$") or "")
            return
        end
        vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, { url })
        vim.api.nvim_buf_del_extmark(buf, upload_ns, id)
    end

    markup.insert_markup = function(input, is_file_path)
        if not is_file_path or not vim.tbl_contains(filetypes, vim.bo.filetype) then
            return insert_markup(input, is_file_path)
        end

        local buf = vim.api.nvim_get_current_buf()
        local ok = insert_markup(input, is_file_path)
        if not ok then
            return ok
        end

        local probe = (markup.get_template(upload_sentinel, false):gsub("%$CURSOR", ""))
        local at = probe:find(upload_sentinel, 1, true)
        local line = vim.api.nvim_get_current_line()
        local prefix = at and probe:sub(1, at - 1) or ""
        local suffix = at and probe:sub(at + #upload_sentinel) or ""
        if not at or line:sub(1, #prefix) ~= prefix or line:sub(#line - #suffix + 1) ~= suffix then
            return ok
        end

        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        local id = vim.api.nvim_buf_set_extmark(buf, upload_ns, row, #prefix, {
            end_row = row,
            end_col = #line - #suffix,
            right_gravity = false,
        })
        -- Snapshot the image before queueing: the local file name has second
        -- resolution, so a quick second paste reuses it, and a queued upload must
        -- not read the newer image's bytes.
        local abs = vim.fn.fnamemodify(input, ":p")
        local ext = vim.fn.fnamemodify(abs, ":e")
        local snapshot = vim.fn.tempname() .. (ext ~= "" and ("." .. ext) or "")
        if not vim.uv.fs_copyfile(abs, snapshot) then
            snapshot = abs
        end

        queue_upload(function(done)
            local function finish()
                if snapshot ~= abs then
                    vim.uv.fs_unlink(snapshot)
                end
                done()
            end
            local started, spawn_err = pcall(vim.system, { script, snapshot }, { text = true }, function(result)
                vim.schedule(function()
                    backfill(buf, id, result)
                    finish()
                end)
            end)
            if not started then
                vim.api.nvim_buf_del_extmark(buf, upload_ns, id)
                upload_failed(tostring(spawn_err))
                finish()
            end
        end)
        return ok
    end
end

local configured = false

local function setup()
    if configured then
        return
    end
    configured = true

    setup_image()
    setup_r2_upload()
end

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("User_ImageInit", { clear = true }),
    pattern = { "markdown", "vimwiki", "html" },
    callback = setup,
})

vim.keymap.set("n", "<leader>mp", function()
    setup()
    vim.cmd("PasteImage")
end, { desc = "[img-clip]:Paste image from clipboard" })
