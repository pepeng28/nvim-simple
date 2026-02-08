local M = {}

-- State persistent
M.opened_items = M.opened_items or {}
M.current_index = M.current_index or 0
M.max_history = M.max_history or 50
M.show_full_path = M.show_full_path or false
M.show_only_current = M.show_only_current or false

-- Configurable options
M.config = {
    auto_save = true,  -- Hanya untuk indikator modifikasi
    show_icons = true,
    enable_popup_filter = true,
    window_size = 3,
    show_quit_messages = true,
}

-- Cache untuk performance
local winbar_cache = {}
-- Working directory tracking
local cwd = vim.fn.getcwd()
-- Store original content for comparison
local original_content_cache = {}
-- Track new files that haven't been saved yet
local unsaved_new_files = {}

--------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------
local function normalize_content(str)
    if not str then return "" end
    return str:gsub("\r", ""):gsub("\n+$", "")
end

-- Simpan konten asli saat pertama kali buffer dibuka
local function save_original_content(buf_id, file_path)
    if original_content_cache[buf_id] then return end
    
    -- Untuk file baru yang belum ada di disk, tandai sebagai file baru
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
        -- Untuk file baru yang belum ada di disk
        original_content_cache[buf_id] = ""
        unsaved_new_files[buf_id] = true
    end
end

-- Cek apakah buffer sama dengan konten asli (disk atau awal)
local function is_buffer_modified(buf_id, file_path)
    if not buf_id or buf_id == -1 then return false end
    if not vim.api.nvim_buf_is_loaded(buf_id) then return false end
    
    -- File baru yang belum disimpan selalu dianggap modified
    if unsaved_new_files[buf_id] then
        return true
    end
    
    -- Dapatkan konten buffer saat ini
    local buf_lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
    local current_content = table.concat(buf_lines, "\n")
    current_content = normalize_content(current_content)
    
    -- Cek vs konten asli yang disimpan
    if original_content_cache[buf_id] then
        return current_content ~= original_content_cache[buf_id]
    end
    
    -- Jika tidak ada cache dan file belum ada di disk
    if file_path == "" or vim.fn.filereadable(file_path) ~= 1 then
        return current_content ~= ""
    end
    
    -- Cek vs disk untuk file yang sudah ada
    local f = io.open(file_path, "r")
    if not f then
        return current_content ~= ""
    end
    
    local disk_content = f:read("*a")
    f:close()
    disk_content = normalize_content(disk_content)
    
    return current_content ~= disk_content
end

-- Update konten asli setelah save
local function update_original_content_after_save(buf_id, file_path)
    local f = io.open(file_path, "r")
    if f then
        local content = f:read("*a")
        f:close()
        original_content_cache[buf_id] = normalize_content(content)
        unsaved_new_files[buf_id] = nil
    else
        -- File mungkin baru dibuat, update dengan konten kosong
        original_content_cache[buf_id] = ""
        unsaved_new_files[buf_id] = nil
    end
end

--------------------------------------------------------------------
-- SETUP HIGHLIGHTS
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
        lua    = "#339933",
        html   = "#FFA500",
        css    = "#56B6C2",
        js     = "#E5C07B",
        json   = "#C678DD",
        php    = "#61AFEF",
        python = "#3572A5",
        java   = "#B07219",
        cpp    = "#F34B7D",
        go     = "#00ADD8",
        rust   = "#DEA584",
        ruby   = "#701516",
    }

    M.icons = {
        folder = { icon = " ", color = icon_colors.folder },
        file   = { icon = "󰈔 ", color = icon_colors.file },
        lua    = { icon = " ", color = icon_colors.lua },
        html   = { icon = " ", color = icon_colors.html },
        css    = { icon = " ", color = icon_colors.css },
        js     = { icon = " ", color = icon_colors.js },
        json   = { icon = " ", color = icon_colors.json },
        php    = { icon = " ", color = icon_colors.php },
        python = { icon = " ", color = icon_colors.python },
        java   = { icon = " ", color = icon_colors.java },
        cpp    = { icon = " ", color = icon_colors.cpp },
        go     = { icon = " ", color = icon_colors.go },
        rust   = { icon = " ", color = icon_colors.rust },
        ruby   = { icon = " ", color = icon_colors.ruby },
    }

    for ext, icon_data in pairs(M.icons) do
        vim.api.nvim_set_hl(0, "WinbarIcon_" .. ext, { fg = icon_data.color, bg = bg })
    end
end

--------------------------------------------------------------------
-- GET ICON
--------------------------------------------------------------------
local function get_icon(path, is_folder, bufnr)
    if not M.config.show_icons then return "" end
    if not path or path == "" then return "" end
    if is_folder then
        return "%#WinbarIcon_folder#" .. (M.icons.folder.icon or "") .. "%*"
    end

    local ext = path:match("^.+%.(.+)$")
    local ft = vim.api.nvim_buf_get_option(bufnr or 0, "filetype")

    local clients = vim.lsp.get_clients({bufnr = bufnr})
    if #clients > 0 then
        local lsp_ft = clients[1].config.filetypes and clients[1].config.filetypes[1]
        if lsp_ft then ft = lsp_ft end
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
-- FILTER FILE
--------------------------------------------------------------------
local function should_track(path)
    if not path or path == "" then return false end
    if vim.fn.isdirectory(path) == 1 then return false end
    if path:match("NvimTree") then return false end
    if path:match("/%.git") then return false end
    if path:match("term://") then return false end
    if path:match("help") then return false end
    -- Tambahkan pengecualian untuk buftype khusus
    local bufnr = vim.fn.bufnr(path)
    if bufnr ~= -1 and vim.bo[bufnr].buftype ~= "" then return false end
    return true
end

--------------------------------------------------------------------
-- WINDOW FILTER
--------------------------------------------------------------------
local function is_window_filtered()
    if not M.config.enable_popup_filter then return false end
    
    local win_id = vim.api.nvim_get_current_win()
    local buf_id = vim.api.nvim_get_current_buf()
    local win_cfg = vim.api.nvim_win_get_config(win_id)

    if win_cfg.relative ~= "" or 
       vim.bo[buf_id].buftype ~= "" or 
       vim.bo[buf_id].filetype == "NvimTree" or
       vim.bo[buf_id].filetype == "lazy" or
       vim.bo[buf_id].filetype == "mason" then
        return true
    end
    return false
end

--------------------------------------------------------------------
-- GET RELATIVE PATH
--------------------------------------------------------------------
local function get_relative_path(full_path)
    if not full_path or full_path == "" then return "" end
    
    local current_cwd = vim.fn.getcwd()
    local abs_path = vim.fn.fnamemodify(full_path, ":p")
    
    if abs_path:sub(1, #current_cwd) == current_cwd then
        local relative = abs_path:sub(#current_cwd + 2)
        if relative == "" then
            return vim.fn.fnamemodify(abs_path, ":t")
        end
        return relative
    else
        return abs_path
    end
end

--------------------------------------------------------------------
-- WINBAR LOGIC dengan indikator modifikasi yang benar
--------------------------------------------------------------------
_G.winbarEl_logic = function()
    if is_window_filtered() then
        return ""
    end

    if #M.opened_items == 0 or not M.opened_items[M.current_index] then
        return ""
    end

    local cache_key = string.format("%d_%d_%s_%s", 
        M.current_index, #M.opened_items, 
        tostring(M.show_only_current), 
        tostring(M.show_full_path))
    
    if winbar_cache[cache_key] then
        return winbar_cache[cache_key]
    end

    local parts = {}
    local sep = " %#WinbarSep#┃%* "
    local window_size = M.config.window_size

    local function build_label(item, active)
        local label = get_icon(item.path, false, vim.fn.bufnr(item.path)) .. " "
        local hl_group = active and "%#WinbarActiveFile#" or "%#WinbarInactiveFile#"
        
        -- Cek modifikasi dengan sistem baru
        local buf = vim.fn.bufnr(item.path)
        local modified = false
        
        if buf ~= -1 and vim.api.nvim_buf_is_loaded(buf) then
            -- Cek apakah buffer berbeda dengan konten asli
            modified = is_buffer_modified(buf, item.path)
        end
        
        if modified then
            label = label .. hl_group .. item.label .. " %#WinbarModified#*%*%*"
        else
            label = label .. hl_group .. item.label .. "%*"
        end
        return label
    end

    -- Mode Toggle
    if M.show_only_current and M.show_full_path then
        local item = M.opened_items[M.current_index]
        local text = build_label(item, true)
        
        local rel_path = get_relative_path(item.path)
        local folder_text = ""
        
        if rel_path ~= "" and rel_path ~= item.label then
            local dir_path = vim.fn.fnamemodify(rel_path, ":h")
            
            if dir_path ~= "." and dir_path ~= "" then
                local folders = {}
                for folder in dir_path:gmatch("[^/]+") do
                    table.insert(folders, folder)
                end
                
                for _, folder in ipairs(folders) do
                    folder_text = folder_text .. sep .. get_icon(folder, true) .. " " ..
                                  "%#WinbarFolder#" .. folder .. "%*"
                end
            end
            
            if folder_text ~= "" then
                folder_text = folder_text .. sep
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
            table.insert(parts, "%#WinbarInactiveFile#…%*") 
        end

        for i = start_index, end_index do
            local item = M.opened_items[i]
            local text = build_label(item, i == M.current_index)
            table.insert(parts, text)
        end

        if end_index < #M.opened_items then 
            table.insert(parts, "%#WinbarInactiveFile#…%*") 
        end

        local content = table.concat(parts, sep)
        winbar_cache[cache_key] = content
        return content
    end
end

--------------------------------------------------------------------
-- TRACKING LOGIC dengan penyimpanan konten asli
--------------------------------------------------------------------
local function apply_tracking()
    local buf_id = vim.api.nvim_get_current_buf()
    local fpath = vim.api.nvim_buf_get_name(buf_id)
    if fpath == "" then 
        fpath = vim.fn.expand("%:p") 
    end

    if not should_track(fpath) then
        return
    end

    if is_window_filtered() then
        return
    end

    local found = false
    for i, item in ipairs(M.opened_items) do
        if item.path == fpath then
            M.current_index = i
            found = true
            break
        end
    end

    -- TIDAK memeriksa filereadable() untuk file baru
    if not found then
        table.insert(M.opened_items, {
            label = vim.fn.fnamemodify(fpath, ":t"),
            path = fpath
        })
        M.current_index = #M.opened_items
    end

    -- Simpan konten asli untuk file baru (kosong) atau file yang sudah ada
    if M.config.auto_save then
        save_original_content(buf_id, fpath)
    end

    local max_hist = M.config.max_history or M.max_history
    if #M.opened_items > max_hist then
        table.remove(M.opened_items, 1)
        M.current_index = math.max(1, M.current_index - 1)
    end

    winbar_cache = {}
end

--------------------------------------------------------------------
-- SMART CLOSE SYSTEM
--------------------------------------------------------------------
M.smart_close = function(save_first)
    local api = vim.api
    local buf_id = api.nvim_get_current_buf()
    local is_file = (vim.bo[buf_id].buftype == "" and api.nvim_buf_get_name(buf_id) ~= "")
    local cmd_label = save_first and "wq" or "q"

    -- Jika bukan file atau riwayat habis, keluar normal
    if not is_file or #M.opened_items <= 1 then
        if #M.opened_items <= 1 then 
            M.opened_items = {} 
            M.current_index = 0
        end
        vim.cmd(save_first and "confirm wq" or "confirm q")
        return
    end

    -- Proses simpan jika :wq
    if save_first then 
        if vim.bo.modified then
            vim.cmd("w")
        end
    end

    -- Proses pindah riwayat
    local old_buf = buf_id
    local current_path = api.nvim_buf_get_name(buf_id)
    
    -- Cari dan hapus file saat ini dari history
    local removed_index = nil
    for i, item in ipairs(M.opened_items) do
        if item.path == current_path then
            removed_index = i
            table.remove(M.opened_items, i)
            break
        end
    end
    
    -- Update current_index
    if removed_index then
        M.current_index = math.max(removed_index - 1, 1)
    else
        M.current_index = math.max(M.current_index - 1, 1)
    end
    
    -- Pastikan current_index valid
    if M.current_index > #M.opened_items then
        M.current_index = #M.opened_items
    end
    
    if #M.opened_items == 0 then
        M.opened_items = {}
        M.current_index = 0
        vim.cmd(save_first and "confirm wq" or "confirm q")
        return
    end
    
    -- Buka file berikutnya dari history
    vim.cmd("edit " .. vim.fn.fnameescape(M.opened_items[M.current_index].path))
    api.nvim_buf_delete(old_buf, { force = true })

    -- PESAN KUSTOM
    if M.config.show_quit_messages then
        local pesan = ""
        if save_first then
            pesan = "   Tab berhasil di simpan , Kembali ke file sebelumnya"
        else
            pesan = " 󰅖  Tab ditutup , Kembali ke file sebelumnya"
        end
        api.nvim_echo({{ pesan, "DiagnosticOk" }}, false, {})
    end

    -- Manipulasi history command
    vim.fn.histdel("cmd", -1)
    vim.fn.histadd("cmd", cmd_label)
    
    winbar_cache = {}
end

--------------------------------------------------------------------
-- AUTO CLEAR MODIFIED FLAG (FITUR BARU)
--------------------------------------------------------------------
local function sync_modified_flag()
    if not M.config.auto_save then return end
    
    local buf_id = vim.api.nvim_get_current_buf()
    local fpath = vim.api.nvim_buf_get_name(buf_id)
    
    if fpath == "" or not should_track(fpath) then return end
    if is_window_filtered() then return end
    
    -- Pastikan konten asli tersimpan
    if not original_content_cache[buf_id] then
        save_original_content(buf_id, fpath)
    end
    
    -- Cek apakah buffer sama dengan konten asli
    local modified = is_buffer_modified(buf_id, fpath)
    
    -- Sync modified flag dengan status sebenarnya
    if modified then
        vim.cmd("setlocal modified")
    else
        vim.cmd("setlocal nomodified")
    end
end

--------------------------------------------------------------------
-- COMMAND LINE HIJACK
--------------------------------------------------------------------
local function setup_command_hijack()
    local api = vim.api
    
    api.nvim_set_keymap('c', '<CR>', 
        [[getcmdtype() == ':' && getcmdline() == 'q' ? '<C-u>lua require("plugins.winbarEl").smart_close(false)<CR>' : (getcmdtype() == ':' && getcmdline() == 'wq' ? '<C-u>lua require("plugins.winbarEl").smart_close(true)<CR>' : '<CR>')]], 
        { expr = true, noremap = true }
    )
end

--------------------------------------------------------------------
-- WINBAR UPDATE FUNCTION
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
-- MAIN SETUP FUNCTION
--------------------------------------------------------------------
function M.setup(user_config)
    -- Update working directory
    cwd = vim.fn.getcwd()
    
    -- Merge config
    if user_config then
        for k, v in pairs(user_config) do
            M.config[k] = v
        end
    end
    
    local api = vim.api
    
    setup_highlights()

    -- COMMAND LINE HIJACK
    setup_command_hijack()

    local group = api.nvim_create_augroup("WinbarEl", { clear = true })
    
    -- Handle new files immediately
    api.nvim_create_autocmd("BufNewFile", {
        group = group,
        callback = function(args)
            local buf_id = args.buf
            local fpath = vim.api.nvim_buf_get_name(buf_id)
            
            if should_track(fpath) and not is_window_filtered() then
                -- Simpan sebagai file baru yang belum disimpan
                unsaved_new_files[buf_id] = true
                original_content_cache[buf_id] = ""
                
                -- Tambahkan ke opened_items jika belum ada
                local found = false
                for i, item in ipairs(M.opened_items) do
                    if item.path == fpath then
                        M.current_index = i
                        found = true
                        break
                    end
                end
                
                if not found then
                    table.insert(M.opened_items, {
                        label = vim.fn.fnamemodify(fpath, ":t"),
                        path = fpath
                    })
                    M.current_index = #M.opened_items
                end
                
                winbar_cache = {}
                update_winbar()
            end
        end
    })
    
    api.nvim_create_autocmd({ "BufEnter", "WinEnter", "BufWinEnter" }, {
        group = group,
        callback = function()
            apply_tracking()
            update_winbar()
        end
    })

    api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
            setup_highlights()
            winbar_cache = {}
            update_winbar()
        end,
    })

    -- Trigger untuk update winbar saat membuat buffer baru
    api.nvim_create_autocmd({ "BufAdd", "BufNew" }, {
        group = group,
        callback = function()
            vim.defer_fn(function()
                apply_tracking()
                update_winbar()
            end, 10)
        end
    })

    -- Real-time modification detection
    api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertEnter" }, {
        group = group,
        callback = function()
            winbar_cache = {}
            update_winbar()
            
            -- Cek dan sync modified flag
            if M.config.auto_save then
                vim.defer_fn(function()
                    sync_modified_flag()
                end, 50)
            end
        end
    })

    -- Update original content setelah save
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

    -- Update working directory saat berubah
    api.nvim_create_autocmd("DirChanged", {
        group = group,
        callback = function()
            cwd = vim.fn.getcwd()
            winbar_cache = {}
            update_winbar()
        end
    })

    -- Sync modified flag saat buffer leave
    api.nvim_create_autocmd("BufLeave", {
        group = group,
        callback = function()
            if M.config.auto_save then
                sync_modified_flag()
            end
        end
    })

    -- Sync modified flag saat keluar insert mode
    api.nvim_create_autocmd("InsertLeave", {
        group = group,
        callback = function()
            if M.config.auto_save then
                vim.defer_fn(function()
                    sync_modified_flag()
                end, 50)
            end
        end
    })

    -- Clean up cache saat buffer dihapus
    api.nvim_create_autocmd("BufWipeout", {
        group = group,
        callback = function(args)
            original_content_cache[args.buf] = nil
            unsaved_new_files[args.buf] = nil
        end
    })

    -- KEY BINDINGS
    local opts = { silent = true, noremap = true }
    
    -- Navigasi History
    vim.keymap.set('n', '<C-Right>', function() goto_item(M.current_index + 1) end, opts)
    vim.keymap.set('n', '<C-Left>', function() goto_item(M.current_index - 1) end, opts)

    -- Toggle Display Mode
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

    -- Smart Quit shortcuts
    vim.keymap.set('n', 'qq', function() M.smart_close(false) end, opts)
    vim.keymap.set('n', 'qw', function() M.smart_close(true) end, opts)

    -- Custom commands
    vim.api.nvim_create_user_command("Q", function() M.smart_close(false) end, {})
    vim.api.nvim_create_user_command("WQ", function() M.smart_close(true) end, {})

    -- Initial setup
    vim.defer_fn(function()
        apply_tracking()
        update_winbar()
    end, 100)
end

return M
