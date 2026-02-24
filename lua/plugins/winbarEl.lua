local M = {}

-- State persistent
M.opened_items = M.opened_items or {}
M.current_index = M.current_index or 0
M.max_history = M.max_history or 50
M.show_full_path = M.show_full_path or false
M.show_only_current = M.show_only_current or false

-- Configurable options
M.config = {
    auto_save = true,
    show_icons = true,
    enable_popup_filter = true,
    window_size = 3,
    show_quit_messages = true,
}

-- Cache
local winbar_cache = {}
local cwd = vim.fn.getcwd()
local original_content_cache = {}
local unsaved_new_files = {}

--------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------
local function normalize_content(str)
    if not str then return "" end
    return str:gsub("\r", ""):gsub("\n+$", "")
end

local function save_original_content(buf_id, file_path)
    if original_content_cache[buf_id] then return end
    if file_path == "" or vim.fn.filereadable(file_path) ~= 1 then
        original_content_cache[buf_id] = ""
        unsaved_new_files[buf_id] = true
        return
    end
    local f = io.open(file_path, "r")
    if f then
        local content = f:read("*a")
        f:close()
        original_content_cache[buf_id] = normalize_content(content)
        unsaved_new_files[buf_id] = nil
    else
        original_content_cache[buf_id] = ""
        unsaved_new_files[buf_id] = true
    end
end

local function is_buffer_modified(buf_id, file_path)
    if not buf_id or buf_id == -1 then return false end
    if not vim.api.nvim_buf_is_loaded(buf_id) then return false end
    if unsaved_new_files[buf_id] then return true end
    local buf_lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
    local current_content = table.concat(buf_lines, "\n")
    current_content = normalize_content(current_content)
    if original_content_cache[buf_id] then
        return current_content ~= original_content_cache[buf_id]
    end
    if file_path == "" or vim.fn.filereadable(file_path) ~= 1 then
        return current_content ~= ""
    end
    local f = io.open(file_path, "r")
    if not f then return current_content ~= "" end
    local disk_content = f:read("*a")
    f:close()
    disk_content = normalize_content(disk_content)
    return current_content ~= disk_content
end

local function update_original_content_after_save(buf_id, file_path)
    local f = io.open(file_path, "r")
    if f then
        local content = f:read("*a")
        f:close()
        original_content_cache[buf_id] = normalize_content(content)
        unsaved_new_files[buf_id] = nil
    else
        original_content_cache[buf_id] = ""
        unsaved_new_files[buf_id] = nil
    end
end

--------------------------------------------------------------------
-- HIGHLIGHTS & ICONS (persis versi pertama)
--------------------------------------------------------------------
local function setup_highlights()
    local bg = vim.api.nvim_get_hl_by_name("Normal", true).background
    bg = bg and string.format("#%06x", bg) or "NONE"
    vim.api.nvim_set_hl(0, "WinbarActiveFile",   { fg = "#FFFF00", bg = bg, bold = true })
    vim.api.nvim_set_hl(0, "WinbarInactiveFile", { fg = "#5F87AF", bg = bg })
    vim.api.nvim_set_hl(0, "WinbarFolder",       { fg = "#3A5F7F", bg = bg })
    vim.api.nvim_set_hl(0, "WinbarModified",     { fg = "#FF5555", bg = bg, bold = true })
    vim.api.nvim_set_hl(0, "WinbarSep",          { fg = "#444444", bg = bg })

    local icon_colors = {
        folder = "#3A5F7F",
        file   = "#5F87AF",
        lua    = "#56a0d3",
        html   = "#e34f26",
        css    = "#56B6C2",
        js     = "#f7df1e",
        json   = "#f7df1e",
        php    = "#a286c0",
        python = "#3572A5",
        java   = "#e76f51",
        cpp    = "#56B6C2",
        go     = "#00ADD8",
        rust   = "#DEA584",
        ruby   = "#701516",
    }

    M.icons = {
        folder = { icon = "  ", color = icon_colors.folder },
        file   = { icon = " 󰈔 ", color = icon_colors.file },
        lua    = { icon = "  ", color = icon_colors.lua },
        html   = { icon = "  ", color = icon_colors.html },
        css    = { icon = "  ", color = icon_colors.css },
        js     = { icon = "  ", color = icon_colors.js },
        json   = { icon = "  ", color = icon_colors.json },
        php    = { icon = "  ", color = icon_colors.php },
        python = { icon = "  ", color = icon_colors.python },
        java   = { icon = "  ", color = icon_colors.java },
        cpp    = { icon = "  ", color = icon_colors.cpp },
        go     = { icon = "  ", color = icon_colors.go },
        rust   = { icon = "  ", color = icon_colors.rust },
        ruby   = { icon = "  ", color = icon_colors.ruby },
    }

    for ext, icon_data in pairs(M.icons) do
        vim.api.nvim_set_hl(0, "WinbarIcon_" .. ext, { fg = icon_data.color, bg = bg })
    end
end

local function get_icon(path, is_folder, bufnr)
    if not M.config.show_icons then return "" end
    if not path or path == "" then return "" end
    if is_folder then
        return "%#WinbarIcon_folder#" .. (M.icons.folder.icon or "") .. "%*"
    end
    local ext = path:match("^.+%.(.+)$")
    local ft = vim.api.nvim_buf_get_option(bufnr or 0, "filetype")
    local clients = vim.lsp.get_clients({bufnr = bufnr})
    if #clients > 0 and clients[1].config.filetypes then
        ft = clients[1].config.filetypes[1] or ft
    end
    if M.icons[ext] then
        return "%#WinbarIcon_" .. ext .. "#" .. M.icons[ext].icon .. "%*"
    elseif M.icons[ft] then
        return "%#WinbarIcon_" .. ft .. "#" .. M.icons[ft].icon .. "%*"
    else
        return "%#WinbarIcon_file#" .. M.icons.file.icon .. "%*"
    end
end

--------------------------------------------------------------------
-- FILTERS
--------------------------------------------------------------------
local function should_track(path)
    if not path or path == "" then return false end
    if vim.fn.isdirectory(path) == 1 then return false end
    if path:match("NvimTree") or path:match("/%.git") or path:match("term://") or path:match("help") then return false end
    local bufnr = vim.fn.bufnr(path)
    if bufnr ~= -1 and vim.bo[bufnr].buftype ~= "" then return false end
    return true
end

local function is_window_filtered()
    if not M.config.enable_popup_filter then return false end
    local win_id = vim.api.nvim_get_current_win()
    local buf_id = vim.api.nvim_get_current_buf()
    local win_cfg = vim.api.nvim_win_get_config(win_id)
    if win_cfg.relative ~= "" or vim.bo[buf_id].buftype ~= "" or
       vim.bo[buf_id].filetype == "NvimTree" or
       vim.bo[buf_id].filetype == "lazy" or
       vim.bo[buf_id].filetype == "mason" then
        return true
    end
    return false
end

local function get_relative_path(full_path)
    if not full_path or full_path == "" then return "" end
    local current_cwd = vim.fn.getcwd()
    local abs_path = vim.fn.fnamemodify(full_path, ":p")
    if abs_path:sub(1, #current_cwd) == current_cwd then
        local relative = abs_path:sub(#current_cwd + 2)
        if relative == "" then return vim.fn.fnamemodify(abs_path, ":t") end
        return relative
    else
        return abs_path
    end
end

--------------------------------------------------------------------
-- WINBAR LOGIC (persis versi pertama)
--------------------------------------------------------------------
_G.winbarEl_logic = function()
    if is_window_filtered() or #M.opened_items == 0 or not M.opened_items[M.current_index] then
        return ""
    end
    local cache_key = string.format("%d_%d_%s_%s", M.current_index, #M.opened_items,
                                    tostring(M.show_only_current), tostring(M.show_full_path))
    if winbar_cache[cache_key] then return winbar_cache[cache_key] end

    local parts = {}
    local sep = " %#WinbarSep#┃%*"   -- spasi sebelum, tanpa spasi setelah
    local window_size = M.config.window_size

    local function build_label(item, active)
        local label = get_icon(item.path, false, vim.fn.bufnr(item.path)) .. " "
        local hl_group = active and "%#WinbarActiveFile#" or "%#WinbarInactiveFile#"
        local buf = vim.fn.bufnr(item.path)
        local modified = (buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) and is_buffer_modified(buf, item.path))
        if modified then
            label = label .. hl_group .. item.label .. "%#WinbarModified# 󱓈 %*%*"
        else
            label = label .. hl_group .. item.label .. "%*"
        end
        return label
    end

    -- Mode full path (Ctrl+Up) dengan folder_sep "  "
    if M.show_only_current and M.show_full_path then
        local item = M.opened_items[M.current_index]
        local text = build_label(item, true)
        local rel_path = get_relative_path(item.path)
        local folder_text = ""
        local folder_sep = "  "

        if rel_path ~= "" and rel_path ~= item.label then
            local dir_path = vim.fn.fnamemodify(rel_path, ":h")
            if dir_path ~= "." and dir_path ~= "" then
                local folders = {}
                for folder in dir_path:gmatch("[^/]+") do table.insert(folders, folder) end
                for i, folder in ipairs(folders) do
                    if i == 1 then
                        folder_text = get_icon(folder, true) .. " " .. "%#WinbarFolder#" .. folder .. "%*"
                    else
                        folder_text = folder_text .. folder_sep .. get_icon(folder, true) .. " " .. "%#WinbarFolder#" .. folder .. "%*"
                    end
                end
            end
            if folder_text ~= "" then
                folder_text = folder_text .. folder_sep
            end
        end
        local content = folder_text .. text
        winbar_cache[cache_key] = content
        return content

    elseif M.show_only_current then
        local item = M.opened_items[M.current_index]
        local text = build_label(item, true)
        winbar_cache[cache_key] = text
        return text

    else
        local start_index = math.max(M.current_index - 1, 1)
        local end_index = math.min(start_index + window_size - 1, #M.opened_items)
        start_index = math.max(end_index - window_size + 1, 1)

        if start_index > 1 then
            table.insert(parts, "%#WinbarInactiveFile#  %*")
        end

        for i = start_index, end_index do
            table.insert(parts, build_label(M.opened_items[i], i == M.current_index))
        end

        if end_index < #M.opened_items then
            table.insert(parts, "%#WinbarInactiveFile#  %*")
        end

        local content = table.concat(parts, sep)
        winbar_cache[cache_key] = content
        return content
    end
end

--------------------------------------------------------------------
-- TRACKING
--------------------------------------------------------------------
local function apply_tracking()
    local buf_id = vim.api.nvim_get_current_buf()
    local fpath = vim.api.nvim_buf_get_name(buf_id)
    if fpath == "" then fpath = vim.fn.expand("%:p") end
    if not should_track(fpath) or is_window_filtered() then return end

    local found = false
    for i, item in ipairs(M.opened_items) do
        if item.path == fpath then
            M.current_index = i
            found = true
            break
        end
    end
    if not found then
        table.insert(M.opened_items, { label = vim.fn.fnamemodify(fpath, ":t"), path = fpath })
        M.current_index = #M.opened_items
    end
    if M.config.auto_save then save_original_content(buf_id, fpath) end

    local max_hist = M.config.max_history or M.max_history
    if max_hist > 0 and #M.opened_items > max_hist then
        table.remove(M.opened_items, 1)
        M.current_index = math.max(1, M.current_index - 1)
    end
    winbar_cache = {}
end

--------------------------------------------------------------------
-- SMART CLOSE (dengan manipulasi history agar tercatat q/wq)
--------------------------------------------------------------------
M.smart_close = function(save_first)
    local api = vim.api
    local buf_id = api.nvim_get_current_buf()
    local is_file = (vim.bo[buf_id].buftype == "" and api.nvim_buf_get_name(buf_id) ~= "")
    local cmd_label = save_first and "wq" or "q"

    -- Jika bukan file atau hanya satu item, jalankan quit normal
    if not is_file or #M.opened_items <= 1 then
        if #M.opened_items <= 1 then M.opened_items = {}; M.current_index = 0 end
        vim.cmd(save_first and "confirm wq" or "confirm q")
        return
    end

    -- Jika buffer dimodifikasi dan kita tidak menyimpan (save_first = false),
    -- biarkan Neovim menangani dengan confirm q (akan meminta konfirmasi)
    if not save_first and vim.bo.modified then
        vim.cmd("confirm q")
        return
    end

    -- Lanjutkan dengan smart close
    if save_first and vim.bo.modified then
        vim.cmd("w")
    end

    local old_buf = buf_id
    local current_path = api.nvim_buf_get_name(buf_id)
    local removed_index = nil
    for i, item in ipairs(M.opened_items) do
        if item.path == current_path then
            removed_index = i
            table.remove(M.opened_items, i)
            break
        end
    end
    if removed_index then
        M.current_index = math.max(removed_index - 1, 1)
    else
        M.current_index = math.max(M.current_index - 1, 1)
    end
    if M.current_index > #M.opened_items then M.current_index = #M.opened_items end

    if #M.opened_items == 0 then
        M.opened_items = {}; M.current_index = 0
        vim.cmd(save_first and "confirm wq" or "confirm q")
        return
    end

    vim.cmd("edit " .. vim.fn.fnameescape(M.opened_items[M.current_index].path))
    api.nvim_buf_delete(old_buf, { force = true })

    if M.config.show_quit_messages then
        local pesan = save_first and "   Tab berhasil di simpan , Kembali ke file sebelumnya" or " 󰅖  Tab ditutup , Kembali ke file sebelumnya"
        api.nvim_echo({{ pesan, "DiagnosticOk" }}, false, {})
    end

    -- Manipulasi history: hapus entri terakhir (BarExit/BarSaveExit) dan tambahkan q/wq
    vim.fn.histdel("cmd", -1)
    vim.fn.histadd("cmd", cmd_label)

    winbar_cache = {}
end

--------------------------------------------------------------------
-- AUTO SYNC MODIFIED
--------------------------------------------------------------------
local function sync_modified_flag()
    if not M.config.auto_save then return end
    local buf_id = vim.api.nvim_get_current_buf()
    local fpath = vim.api.nvim_buf_get_name(buf_id)
    if fpath == "" or not should_track(fpath) or is_window_filtered() then return end
    if not original_content_cache[buf_id] then save_original_content(buf_id, fpath) end
    local modified = is_buffer_modified(buf_id, fpath)
    if modified then vim.cmd("setlocal modified") else vim.cmd("setlocal nomodified") end
end

--------------------------------------------------------------------
-- ABBREVIATION untuk :q dan :wq (mengarah ke :BarExit / :BarSaveExit)
--------------------------------------------------------------------
local function setup_command_abbrev()
    vim.cmd([[
        cnoreabbrev <expr> q  (getcmdtype() == ':' && getcmdline() =~ '^q *$') ? 'BarExit' : 'q'
    ]])
    vim.cmd([[
        cnoreabbrev <expr> wq (getcmdtype() == ':' && getcmdline() =~ '^wq *$') ? 'BarSaveExit' : 'wq'
    ]])
end

--------------------------------------------------------------------
-- UPDATE WINBAR
--------------------------------------------------------------------
local function update_winbar()
    if is_window_filtered() or #M.opened_items == 0 then
        vim.wo.winbar = nil
    else
        vim.wo.winbar = "%{%v:lua.winbarEl_logic()%}"
    end
end

--------------------------------------------------------------------
-- NAVIGATION
--------------------------------------------------------------------
local function goto_item(index)
    if index < 1 or index > #M.opened_items then return end
    local item = M.opened_items[index]
    vim.cmd("edit " .. vim.fn.fnameescape(item.path))
    M.current_index = index
    winbar_cache = {}
    update_winbar()
end

--------------------------------------------------------------------
-- SETUP
--------------------------------------------------------------------
function M.setup(user_config)
    cwd = vim.fn.getcwd()
    if user_config then
        for k, v in pairs(user_config) do M.config[k] = v end
    end

    local api = vim.api
    setup_highlights()
    setup_command_abbrev()

    local group = api.nvim_create_augroup("WinbarEl", { clear = true })

    api.nvim_create_autocmd("BufNewFile", {
        group = group,
        callback = function(args)
            local buf_id = args.buf
            local fpath = vim.api.nvim_buf_get_name(buf_id)
            if should_track(fpath) and not is_window_filtered() then
                unsaved_new_files[buf_id] = true
                original_content_cache[buf_id] = ""
                local found = false
                for i, item in ipairs(M.opened_items) do
                    if item.path == fpath then M.current_index = i; found = true; break end
                end
                if not found then
                    table.insert(M.opened_items, { label = vim.fn.fnamemodify(fpath, ":t"), path = fpath })
                    M.current_index = #M.opened_items
                end
                winbar_cache = {}
                update_winbar()
            end
        end
    })

    api.nvim_create_autocmd({ "BufEnter", "WinEnter", "BufWinEnter" }, {
        group = group,
        callback = function() apply_tracking(); update_winbar() end
    })

    api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function() setup_highlights(); winbar_cache = {}; update_winbar() end
    })

    api.nvim_create_autocmd({ "BufAdd", "BufNew" }, {
        group = group,
        callback = function() vim.defer_fn(function() apply_tracking(); update_winbar() end, 10) end
    })

    api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertEnter" }, {
        group = group,
        callback = function()
            winbar_cache = {}
            update_winbar()
            if M.config.auto_save then vim.defer_fn(sync_modified_flag, 50) end
        end
    })

    api.nvim_create_autocmd("BufWritePost", {
        group = group,
        callback = function(args)
            if M.config.auto_save then
                local buf_id = args.buf
                local fpath = vim.api.nvim_buf_get_name(buf_id)
                update_original_content_after_save(buf_id, fpath)
                winbar_cache = {}
                update_winbar()
            end
        end
    })

    api.nvim_create_autocmd("DirChanged", {
        group = group,
        callback = function() cwd = vim.fn.getcwd(); winbar_cache = {}; update_winbar() end
    })

    api.nvim_create_autocmd("BufLeave", {
        group = group,
        callback = function() if M.config.auto_save then sync_modified_flag() end end
    })

    api.nvim_create_autocmd("InsertLeave", {
        group = group,
        callback = function() if M.config.auto_save then vim.defer_fn(sync_modified_flag, 50) end end
    })

    api.nvim_create_autocmd("BufWipeout", {
        group = group,
        callback = function(args) original_content_cache[args.buf] = nil; unsaved_new_files[args.buf] = nil end
    })

    local opts = { silent = true, noremap = true }
    vim.keymap.set('n', '<C-Right>', function() goto_item(M.current_index + 1) end, opts)
    vim.keymap.set('n', '<C-Left>',  function() goto_item(M.current_index - 1) end, opts)
    vim.keymap.set('n', '<C-Up>', function()
        M.show_full_path = not M.show_full_path
        M.show_only_current = true
        winbar_cache = {}
        update_winbar()
    end, opts)
    vim.keymap.set('n', '<C-Down>', function()
        M.show_only_current = not M.show_only_current
        M.show_full_path = false
        winbar_cache = {}
        update_winbar()
    end, opts)

    vim.keymap.set('n', 'qq', function() M.smart_close(false) end, opts)
    vim.keymap.set('n', 'qw', function() M.smart_close(true) end, opts)

    vim.api.nvim_create_user_command("BarExit", function() M.smart_close(false) end, {})
    vim.api.nvim_create_user_command("BarSaveExit", function() M.smart_close(true) end, {})
    vim.api.nvim_create_user_command("Q", function() M.smart_close(false) end, {})
    vim.api.nvim_create_user_command("WQ", function() M.smart_close(true) end, {})

    vim.defer_fn(function() apply_tracking(); update_winbar() end, 100)
end

return M
