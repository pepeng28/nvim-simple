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
    local force_yellow = false

    local buffer_roots = {}

    --------------------------------------------------------------------
    -- HIGHLIGHT COLORS
    --------------------------------------------------------------------
    vim.api.nvim_set_hl(0, "WinbarActiveFile",   { fg = "#FFFF00" })
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

    for ext, icon_data in pairs(icons) do
        vim.api.nvim_set_hl(0, "WinbarIcon_" .. ext, { fg = icon_data.color })
    end
    vim.api.nvim_set_hl(0, "WinbarIcon_file", { fg = icons.file.color })
    vim.api.nvim_set_hl(0, "WinbarIcon_folder", { fg = icons.folder.color })

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
    -- GET ICON
    --------------------------------------------------------------------
    local function get_icon(path, is_folder)
        if not path or path == "" then return "" end
        if is_folder then
            return "%#WinbarIcon_folder#" .. (icons.folder.icon or "") .. "%*"
        end
        local ext = path:match("^.+%.(.+)$")
        if icons[ext] then
            return "%#WinbarIcon_" .. ext .. "#" .. icons[ext].icon .. "%*"
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
            local label = get_icon(item.path, false) .. " "
            local hl_group = active and "%#WinbarActiveFile#" or "%#WinbarInactiveFile#"
            label = label .. hl_group .. item.label

            if is_file_modified(item.path) then
                label = label .. " %#WinbarModified#X%*"
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
        force_yellow = true
        render_winbar()
    end)

    vim.keymap.set('n', '<C-Down>', function()
        show_full_path = false
        show_only_current = false
        force_yellow = false
        render_winbar()
    end)

    --------------------------------------------------------------------
    -- OVERRIDE COMMANDS
    --------------------------------------------------------------------
    local function move_to_nearest_history(save_file, force)
        local fpath = vim.fn.expand("%:p")
        local modified = vim.bo.modified or is_file_modified(fpath)

        if modified and not force then
            print("⚠️ File has unsaved changes! Gunakan :w atau :Q! untuk paksa keluar")
            return
        end

        local removed_index = nil
        for i, item in ipairs(opened_items) do
            if item.path == fpath then
                removed_index = i
                table.remove(opened_items, i)
                break
            end
        end

        if #opened_items == 0 then
            current_index = 0
            vim.cmd("enew")
            return
        end

        if removed_index <= current_index then
            current_index = math.max(current_index - 1, 1)
        end

        if current_index > #opened_items then
            current_index = #opened_items
        end

        vim.cmd("edit " .. opened_items[current_index].path)
        render_winbar()
    end

    vim.api.nvim_create_user_command("WQ", function(opts)
        move_to_nearest_history(true, opts.bang)
    end, { bang = true })

    vim.api.nvim_create_user_command("Q", function(opts)
        move_to_nearest_history(false, opts.bang)
    end, { bang = true })

end

return { M }
