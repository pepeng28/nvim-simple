-- ~/.config/nvim/lua/plugins/winbarEl.lua
local M = {}

function M.setup()
    local api = vim.api

    --------------------------------------------------------------------
    -- GLOBAL VARIABLES
    --------------------------------------------------------------------
    local opened_items = {}
    local current_index = 0
    local max_history = 50

    local show_full_path = false
    local show_only_current = false

    local buffer_roots = {}

    --------------------------------------------------------------------
    -- HIGHLIGHT COLORS
    --------------------------------------------------------------------
    local function setup_highlights()
        vim.api.nvim_set_hl(0, "WinbarActiveFile",   { fg = "#FFFF00", bold = true })
        vim.api.nvim_set_hl(0, "WinbarInactiveFile", { fg = "#5F87AF" })
        vim.api.nvim_set_hl(0, "WinbarFolder",       { fg = "#3A5F7F" })
        vim.api.nvim_set_hl(0, "WinbarModified",     { fg = "#FF5555", bold = true })

        --------------------------------------------------------------------
        -- ICON CONFIG
        --------------------------------------------------------------------
        local icon_colors = {
            folder = "#3A5F7F",
            file   = "#5F87AF",
            lua    = "#339933",
            html   = "#FFA500",
            css    = "#56B6C2",
            js     = "#E5C07B",
            json   = "#C678DD",
            php    = "#61AFEF",
        }

        local icons = {
            folder = { icon = " ", color = icon_colors.folder },
            file   = { icon = "󰈔 ", color = icon_colors.file },
            lua    = { icon = " ", color = icon_colors.lua },
            html   = { icon = " ", color = icon_colors.html },
            css    = { icon = " ", color = icon_colors.css },
            js     = { icon = " ", color = icon_colors.js },
            json   = { icon = " ", color = icon_colors.json },
            php    = { icon = " ", color = icon_colors.php },
        }

        -- set highlight untuk setiap icon
        for ext, icon_data in pairs(icons) do
            vim.api.nvim_set_hl(0, "WinbarIcon_" .. ext, { fg = icon_data.color })
        end

        return icons
    end

    -- Setup highlights awal
    local icons = setup_highlights()

    --------------------------------------------------------------------
    -- SAFE SET WINBAR
    --------------------------------------------------------------------
    local function safe_winbar_set(text)
        if not text or text:match("^%s*$") then
            vim.opt.winbar = nil
            return
        end
        vim.opt.winbar = text
    end

    --------------------------------------------------------------------
    -- GET ICON (SUPPORT LSP)
    --------------------------------------------------------------------
    local function get_icon(path, is_folder, bufnr)
        if not path or path == "" then return "" end
        if is_folder then
            return "%#WinbarIcon_folder#" .. (icons.folder.icon or "") .. "%*"
        end

        local ext = path:match("^.+%.(.+)$")
        local ft = vim.api.nvim_buf_get_option(bufnr or 0, "filetype")

        -- cek LSP clients untuk buffer ini
        local clients = vim.lsp.get_active_clients({bufnr = bufnr})
        if #clients > 0 then
            local lsp_ft = clients[1].config.filetypes and clients[1].config.filetypes[1]
            if lsp_ft then ft = lsp_ft end
        end

        if icons[ext] then
            return "%#WinbarIcon_" .. ext .. "#" .. icons[ext].icon .. "%*"
        elseif icons[ft] then
            return "%#WinbarIcon_" .. ft .. "#" .. icons[ft].icon .. "%*"
        else
            return "%#WinbarIcon_file#" .. icons.file.icon .. "%*"
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
        return true
    end

    --------------------------------------------------------------------
    -- BUFFER ROOT
    --------------------------------------------------------------------
    local function set_buffer_root(fpath)
        if not buffer_roots[fpath] then
            buffer_roots[fpath] = vim.fn.getcwd()
        end
    end

    local function relative_path_from_root(fpath)
        local root = buffer_roots[fpath]
        if not root then return "" end
        local rel = vim.fn.fnamemodify(fpath, ":h"):sub(#root + 2)
        return rel
    end

    --------------------------------------------------------------------
    -- NORMALIZE CONTENT
    --------------------------------------------------------------------
    local function normalize_content(str)
        return str:gsub("\r", ""):gsub("\n+$", "")
    end

    --------------------------------------------------------------------
    -- CHECK MODIFIED (vs disk) FOR WINBAR X
    --------------------------------------------------------------------
    local function is_file_modified(item_path)
        local buf = vim.fn.bufnr(item_path, false)
        if buf == -1 then return false end
        if not vim.api.nvim_buf_is_loaded(buf) then return false end

        local f = io.open(item_path, "r")
        local disk_content = ""
        if f then
            disk_content = f:read("*a")
            f:close()
        end

        local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local buf_content = table.concat(buf_lines, "\n")

        buf_content = normalize_content(buf_content)
        disk_content = normalize_content(disk_content)

        return buf_content ~= disk_content
    end

    --------------------------------------------------------------------
    -- RENDER WINBAR
    --------------------------------------------------------------------
    local function render_winbar()
        if #opened_items == 0 or not opened_items[current_index] then
            vim.opt.winbar = nil
            return
        end

        local parts = {}
        local sep = " ┃ "
        local window_size = 3

        local function build_label(item, active)
            local label = get_icon(item.path, false, vim.fn.bufnr(item.path)) .. " "
            local hl_group = active and "%#WinbarActiveFile#" or "%#WinbarInactiveFile#"
            label = label .. hl_group .. item.label

            if is_file_modified(item.path) then
                label = label .. " %#WinbarModified# %*"
            end

            label = label .. "%*" -- reset hl
            return label
        end

        if show_only_current then
            local item = opened_items[current_index]
            local text = build_label(item, true)
            if show_full_path then
                local rel_path = relative_path_from_root(item.path)
                local folder_text = ""
                if rel_path ~= "" then
                    local folders = vim.split(rel_path, "/")
                    for _, f in ipairs(folders) do
                        if f ~= "" and f ~= "." then
                            folder_text = folder_text .. sep .. get_icon(f, true) .. " " ..
                                          "%#WinbarFolder#" .. f .. "%*"
                        end
                    end
                end
                text = folder_text .. sep .. text
            end
            table.insert(parts, text)
        else
            local start_index = math.max(current_index - 1, 1)
            local end_index = math.min(start_index + window_size - 1, #opened_items)
            start_index = math.max(end_index - window_size + 1, 1)

            if start_index > 1 then table.insert(parts, "%#WinbarInactiveFile#…%*") end

            for i = start_index, end_index do
                local item = opened_items[i]
                local text = build_label(item, i == current_index)
                table.insert(parts, text)
            end

            if end_index < #opened_items then table.insert(parts, "%#WinbarInactiveFile#…%*") end
        end

        local content = table.concat(parts, sep)
        if not show_full_path then content = " " .. content .. " " end
        safe_winbar_set(content)
    end

    --------------------------------------------------------------------
    -- AUTOCMD UNTUK MEMPERTAHANKAN WARNA SAAT COLORSCHEME BERUBAH
    --------------------------------------------------------------------
    vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
            setup_highlights()
            -- Render ulang winbar setelah colorscheme berubah
            vim.schedule(function()
                render_winbar()
            end)
        end,
    })

    --------------------------------------------------------------------
    -- AUTOCMD ADD TO HISTORY
    --------------------------------------------------------------------
    vim.api.nvim_create_autocmd({"BufEnter","BufNewFile"}, {
        callback = function()
            local fpath = vim.fn.expand("%:p")
            if not should_track(fpath) then return end
            set_buffer_root(fpath)
            for i, item in ipairs(opened_items) do
                if item.path == fpath then
                    current_index = i
                    return
                end
            end
            table.insert(opened_items, {
                label = vim.fn.fnamemodify(fpath, ":t"),
                path = fpath,
                base_folder = vim.fn.fnamemodify(fpath, ":h")
            })
            current_index = #opened_items
            if #opened_items > max_history then
                table.remove(opened_items, 1)
                current_index = current_index - 1
            end
        end,
    })

    --------------------------------------------------------------------
    -- AUTOCMD RENDER REALTIME
    --------------------------------------------------------------------
    vim.api.nvim_create_autocmd({"BufEnter","BufWritePost","BufNewFile","TextChanged","TextChangedI"}, {
        callback = render_winbar
    })

    --------------------------------------------------------------------
    -- AUTO SAVE JIKA X TIDAK ADA
    --------------------------------------------------------------------
    vim.api.nvim_create_autocmd({"BufEnter","TextChanged","TextChangedI"}, {
        callback = function()
            local fpath = vim.fn.expand("%:p")
            if not should_track(fpath) then return end
            if not is_file_modified(fpath) and vim.bo.modified then
                vim.cmd("write")  -- simpan otomatis
            end
        end
    })

    --------------------------------------------------------------------
    -- HISTORY NAVIGATION
    --------------------------------------------------------------------
    local function goto_item(index)
        if index < 1 or index > #opened_items then return end
        local item = opened_items[index]
        vim.cmd("edit " .. item.path)
        current_index = index
        render_winbar()
    end

    vim.keymap.set('n', '<C-Right>', function() goto_item(current_index + 1) end)
    vim.keymap.set('n', '<C-Left>',  function() goto_item(current_index - 1) end)

    --------------------------------------------------------------------
    -- TOGGLE MODE
    --------------------------------------------------------------------
    vim.keymap.set('n', '<C-Up>', function()
        show_full_path = true
        show_only_current = true
        render_winbar()
    end)

    vim.keymap.set('n', '<C-Down>', function()
        show_full_path = false
        show_only_current = false
        render_winbar()
    end)

    --------------------------------------------------------------------
    -- FUNGSI UTAMA UNTUK QUIT CUSTOM
    --------------------------------------------------------------------
    local function smart_quit_func(save_first, force)
        local fpath = vim.fn.expand("%:p")
        local modified = vim.bo.modified or is_file_modified(fpath)

        if modified and not force then
            print("⚠️ File has unsaved changes! Gunakan :w atau :q! untuk paksa keluar")
            return
        end

        -- Simpan jika menggunakan :wq
        if save_first and modified then
            vim.cmd("write")
        end

        -- Cari index file saat ini di history
        local removed_index = nil
        for i, item in ipairs(opened_items) do
            if item.path == fpath then
                removed_index = i
                table.remove(opened_items, i)
                break
            end
        end

        -- JIKA TINGGAL 0 FILE DI HISTORY, KELUAR DARI NVIM
        if #opened_items == 0 then
            current_index = 0
            vim.opt.winbar = nil
            
            -- Hapus buffer saat ini
            local curbuf = vim.api.nvim_get_current_buf()
            if vim.api.nvim_buf_is_valid(curbuf) then
                vim.api.nvim_buf_delete(curbuf, { force = true })
            end
            
            -- Keluar dari Neovim jika ini file terakhir
            vim.cmd("quit")
            return
        end

        -- Tentukan history mana yang akan dibuka
        local target_index
        if removed_index then
            -- Jika file yang ditutup ada di history
            if removed_index <= current_index then
                current_index = math.max(current_index - 1, 1)
            end
            
            if current_index > #opened_items then
                current_index = #opened_items
            end
            
            target_index = current_index
        else
            -- Jika file yang ditutup tidak ada di history
            target_index = current_index
            if target_index > #opened_items then
                target_index = #opened_items
            end
        end

        -- Hapus buffer saat ini (tutup file)
        local curbuf = vim.api.nvim_get_current_buf()
        
        -- Buka file berikutnya dari history
        vim.cmd("edit " .. opened_items[target_index].path)
        
        -- Hapus buffer lama jika masih ada
        if vim.api.nvim_buf_is_valid(curbuf) then
            vim.api.nvim_buf_delete(curbuf, { force = true })
        end
        
        current_index = target_index
        render_winbar()
    end

    --------------------------------------------------------------------
    -- SIMPLE SOLUTION: KEY MAPPING SAJA
    --------------------------------------------------------------------
    -- Gunakan key mapping untuk :q dan :wq yang tidak tercatat di history
    vim.keymap.set('n', 'qq', function()
        -- Hitung jumlah file di history
        local history_count = #opened_items
        local tracked_count = 0
        for _, item in ipairs(opened_items) do
            if vim.fn.bufexists(item.path) == 1 then
                tracked_count = tracked_count + 1
            end
        end
        
        if tracked_count <= 1 then
            vim.cmd("q")
        else
            smart_quit_func(false, false)
        end
    end, { silent = true, desc = "Smart quit without history" })

    vim.keymap.set('n', 'qw', function()
        -- Hitung jumlah file di history
        local history_count = #opened_items
        local tracked_count = 0
        for _, item in ipairs(opened_items) do
            if vim.fn.bufexists(item.path) == 1 then
                tracked_count = tracked_count + 1
            end
        end
        
        if tracked_count <= 1 then
            vim.cmd("wq")
        else
            smart_quit_func(true, false)
        end
    end, { silent = true, desc = "Smart write-quit without history" })

    --------------------------------------------------------------------
    -- CARA PALING SIMPLE: PAKAI AUTOCMD UNTUK INTERCEPT :q DAN :wq
    --------------------------------------------------------------------
    local function intercept_quit_command()
        -- Ambil command line yang sedang diketik
        local cmdline = vim.fn.getcmdline()
        
        -- Cek jika command adalah :q atau :wq
        if cmdline == "q" or cmdline == "wq" or cmdline == "q!" or cmdline == "wq!" then
            -- Parse apakah ada ! dan apakah ini wq atau q
            local force = cmdline:match("!$") ~= nil
            local save_first = cmdline:match("^w") ~= nil
            
            -- Hitung jumlah file di history
            local tracked_count = 0
            for _, item in ipairs(opened_items) do
                if vim.fn.bufexists(item.path) == 1 then
                    tracked_count = tracked_count + 1
                end
            end
            
            -- Jika hanya 1 file atau kurang, biarkan default
            -- Jika lebih dari 1, gunakan fungsi custom
            if tracked_count > 1 then
                -- Clear command line
                vim.fn.setcmdline("")
                -- Jalankan fungsi custom
                vim.schedule(function()
                    smart_quit_func(save_first, force)
                end)
                return true  -- Intercept sukses
            end
        end
        return false  -- Tidak di-intercept
    end

    -- Setup autocmd untuk intercept command
    vim.api.nvim_create_autocmd("CmdlineEnter", {
        pattern = ":",
        callback = function()
            -- Simpan command line saat masuk
            vim.w.last_cmdline = vim.fn.getcmdline()
        end
    })

    vim.api.nvim_create_autocmd("CmdlineLeave", {
        pattern = ":",
        callback = function()
            local cmdline = vim.w.last_cmdline
            if cmdline then
                -- Coba intercept
                if intercept_quit_command() then
                    -- Jika di-intercept, hapus dari history
                    vim.fn.histdel(":", -1)
                end
            end
        end
    })

    --------------------------------------------------------------------
    -- TAMBAHKAN COMMAND SEDERHANA TANPA HISTORY
    --------------------------------------------------------------------
    -- Command yang langsung execute tanpa simpan history
    vim.api.nvim_create_user_command("Q", function(opts)
        local tracked_count = 0
        for _, item in ipairs(opened_items) do
            if vim.fn.bufexists(item.path) == 1 then
                tracked_count = tracked_count + 1
            end
        end
        
        if tracked_count <= 1 then
            vim.cmd("q" .. (opts.bang and "!" or ""))
        else
            smart_quit_func(false, opts.bang)
        end
    end, { bang = true })

    vim.api.nvim_create_user_command("WQ", function(opts)
        local tracked_count = 0
        for _, item in ipairs(opened_items) do
            if vim.fn.bufexists(item.path) == 1 then
                tracked_count = tracked_count + 1
            end
        end
        
        if tracked_count <= 1 then
            vim.cmd("wq" .. (opts.bang and "!" or ""))
        else
            smart_quit_func(true, opts.bang)
        end
    end, { bang = true })

    --------------------------------------------------------------------
    -- OVERRIDE DENGAN CARA SEDERHANA
    --------------------------------------------------------------------
    -- Gunakan ini jika mapping tidak cukup
    vim.cmd([[
        " Mapping untuk mensimulasikan :q dan :wq tanpa history
        nnoremap <silent> :q :call v:lua.require('plugins.winbarEl').execute_smart_quit(0, 0)<CR>
        nnoremap <silent> :wq :call v:lua.require('plugins.winbarEl').execute_smart_quit(1, 0)<CR>
        nnoremap <silent> :q! :call v:lua.require('plugins.winbarEl').execute_smart_quit(0, 1)<CR>
        nnoremap <silent> :wq! :call v:lua.require('plugins.winbarEl').execute_smart_quit(1, 1)<CR>
    ]])

    -- Export fungsi ke global
    _G.winbarEl_smart_quit = smart_quit_func
    
    _G.execute_smart_quit = function(save_first, force)
        local tracked_count = 0
        for _, item in ipairs(opened_items) do
            if vim.fn.bufexists(item.path) == 1 then
                tracked_count = tracked_count + 1
            end
        end
        
        if tracked_count <= 1 then
            if save_first == 1 then
                vim.cmd("wq" .. (force == 1 and "!" or ""))
            else
                vim.cmd("q" .. (force == 1 and "!" or ""))
            end
        else
            smart_quit_func(save_first == 1, force == 1)
        end
    end

    -- Render winbar pertama kali
    vim.schedule(function()
        render_winbar()
    end)

end

return { M }
