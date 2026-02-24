-- Daftar shortcut
local shortcuts = {
  { icon = "  ", desc = "Buat File Baru", cmd = function()
      local filename = vim.fn.input("Nama file baru: ")
      if filename ~= "" then
        vim.cmd("e " .. filename)
      end
    end, color = "Blue" },  -- warna biru
  { icon = "  ", desc = "Explore File", cmd = function() vim.cmd("NvimTreeToggle") end, color = "Yellow" },
  { icon = "  ", desc = "Save File", cmd = function() vim.cmd("write") end, color = "Green" },
  { icon = "  ", desc = "Quit Nvim", cmd = function() vim.cmd("quit") end, color = "Red" },
  { icon = "  ", desc = "Terminal Float", cmd = function() vim.cmd("ToggleTerm direction=float") end, color = "Cyan" },
  { icon = "  ", desc = "Terminal Horizontal", cmd = function() vim.cmd("ToggleTerm direction=horizontal") end, color = "Cyan" },
  { icon = "  ", desc = "Plugins", cmd = function() vim.cmd("Mason") end, color = "Green" },
}

-- State menu popup
local menu_state = { buf = nil, win = nil }

-- Warna highlight
local hl_colors = {
  Red = "ErrorMsg",
  Green = "String",
  Yellow = "WarningMsg",
  Cyan = "Question",
  Blue = "Identifier",  -- highlight untuk biru
}

-- Fungsi toggle menu
local function toggle_menu()
  if menu_state.win and vim.api.nvim_win_is_valid(menu_state.win) then
    vim.api.nvim_win_close(menu_state.win, true)
    menu_state.win = nil
    menu_state.buf = nil
    return
  end

  -- Buat buffer baru
  local buf = vim.api.nvim_create_buf(false, true)
  if not buf then return end

  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "shortcut_menu")

  -- Isi menu
  local lines = {}
  for _, s in ipairs(shortcuts) do
    table.insert(lines, s.icon .. " " .. s.desc)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- Tentukan posisi menu
  local width = 40
  local height = math.min(#lines, 10)
  local editor_height = vim.api.nvim_get_option("lines") - vim.api.nvim_get_option("cmdheight") - 1
  local row = math.max(0, editor_height - height - 2)
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))

  local opts = {
    style = "minimal",
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = "single",
  }

  local win = vim.api.nvim_open_win(buf, true, opts)
  if not win then
    print("Gagal membuka popup menu")
    return
  end

  -- Highlight tiap baris
  for i, s in ipairs(shortcuts) do
    local hl = hl_colors[s.color] or "Normal"
    vim.api.nvim_buf_add_highlight(buf, -1, hl, i-1, 0, -1)
  end

  -- Posisi kursor di awal teks setelah icon
  local first_line_text = lines[1]
  local start_col = first_line_text:find("%S", #shortcuts[1].icon + 1) - 1
  start_col = start_col or (#shortcuts[1].icon + 1)
  vim.api.nvim_win_set_cursor(win, {1, start_col})

  -- Mapping Enter untuk jalankan shortcut (dengan penanganan khusus untuk baris pertama)
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    local choice = shortcuts[line]
    if choice then
      if line == 1 then
        local filename = vim.fn.input("Nama file baru: ")
        if filename ~= "" then
          vim.api.nvim_win_close(win, true)
          menu_state.win = nil
          menu_state.buf = nil
          vim.cmd("e " .. filename)
        end
        -- Jika batal, tidak lakukan apa-apa, popup tetap terbuka
      else
        vim.api.nvim_win_close(win, true)
        menu_state.win = nil
        menu_state.buf = nil
        choice.cmd()
      end
    end
  end, { buffer = buf })

  -- Navigasi atas/bawah
  vim.keymap.set("n", "<Down>", function()
    local cur = vim.api.nvim_win_get_cursor(win)
    local next_line = math.min(cur[1] + 1, #lines)
    vim.api.nvim_win_set_cursor(win, {next_line, cur[2]})
  end, { buffer = buf })

  vim.keymap.set("n", "<Up>", function()
    local cur = vim.api.nvim_win_get_cursor(win)
    local prev_line = math.max(cur[1] - 1, 1)
    vim.api.nvim_win_set_cursor(win, {prev_line, cur[2]})
  end, { buffer = buf })

  -- Nonaktifkan tombol yang bisa memicu mode insert (agar tidak error E21)
  local disable_keys = { "i", "I", "a", "A", "o", "O" }
  for _, key in ipairs(disable_keys) do
    vim.keymap.set("n", key, "<Nop>", { buffer = buf })
  end

  -- Tombol untuk keluar dari menu
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(win, true)
    menu_state.win = nil
    menu_state.buf = nil
  end, { buffer = buf })

  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(win, true)
    menu_state.win = nil
    menu_state.buf = nil
  end, { buffer = buf })

  menu_state.buf = buf
  menu_state.win = win
end

-- Mapping Space untuk toggle menu
vim.keymap.set("n", "<Space>", toggle_menu, { desc = "Toggle Shortcut Menu" })
