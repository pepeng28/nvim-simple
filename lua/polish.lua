-- Clipboard Android Termux
vim.g.clipboard = {
  name = "termux",
  copy = { ["+"] = "termux-clipboard-set", ["*"] = "termux-clipboard-set" },
  paste = { ["+"] = "termux-clipboard-get", ["*"] = "termux-clipboard-get" },
  cache_enabled = 0,
}
vim.opt.clipboard = "unnamedplus"

-- Key mapping
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- NORMAL MODE
map("n", "yy", '"+yy', opts)     
map("n", "y", '"+y', opts)      
map("n", "p", '"+p', opts)      
map("n", "P", '"+P', opts)
map("n", "x", '"+x', opts)      
map("n", "X", '"+X', opts)

-- VISUAL MODE
map("v", "y", '"+y', opts)      
map("v", "p", '"+p', opts)      
map("v", "x", '"+x', opts)      

-- INSERT MODE
map("i", "<C-v>", '<C-r>+', opts)

local api = vim.api

-- History breadcrumb
local opened_items = {} -- { {label="init.lua", path="/home/user/.../init.lua"}, ... }
local current_index = 0

-- helper: path relatif
local function relative_path(filepath)
  local cwd = vim.loop.cwd() .. "/"
  if filepath:sub(1, #cwd) == cwd then
    return filepath:sub(#cwd + 1)
  else
    return filepath
  end
end

-- cek apakah file valid (ada di disk)
local function is_file(path)
  return vim.fn.filereadable(path) == 1
end

-- ambil nama file untuk label
local function get_label(path)
  return vim.fn.fnamemodify(path, ":t")
end

-- normalize path: export tetap pakai path asli
local function normalize_path(path)
  return path
end

-- filter file/folder yang boleh masuk history
local function should_track(path)
  -- abaikan folder internal / NvimTree / .git
  if path:match("NvimTree") then return false end
  if path:match("/%.git") then return false end
  return true -- termasuk folder export tetap di-track
end

-- highlight untuk file aktif di winbar
vim.api.nvim_set_hl(0, "WinbarActive", { fg = "#FFFF00", bold = true }) -- kuning terang

-- update history saat pindah buffer
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local fpath = vim.fn.expand("%:p")
    if fpath == "" then return end

    fpath = normalize_path(fpath)
    if not should_track(fpath) then return end

    local label = get_label(fpath)

    -- CEK: jika sudah ada di history (path sama), jangan tambah lagi
    local exists = false
    for _, item in ipairs(opened_items) do
      if item.path == fpath then
        exists = true
        break
      end
    end

    if not exists then
      table.insert(opened_items, {label = label, path = fpath})
      current_index = #opened_items
    else
      -- kalau sudah ada, update index ke posisi itu
      for i, item in ipairs(opened_items) do
        if item.path == fpath then
          current_index = i
          break
        end
      end
    end
  end,
})

-- render winbar
local function render_winbar()
  if #opened_items == 0 then
    vim.opt.winbar = nil
    return
  end

  local sep = " ┃ "
  local parts = {}
  for i, item in ipairs(opened_items) do
    if i == current_index then
      table.insert(parts, "%#WinbarActive#" .. item.label .. "%*")
    else
      table.insert(parts, item.label)
    end
  end
  vim.opt.winbar = table.concat(parts, sep)
end

vim.api.nvim_create_autocmd({"BufEnter","BufWritePost"}, {
  callback = function()
    render_winbar()
  end
})

-- fungsi pindah file/menu
local function goto_item(index)
  -- batasi supaya tidak looping
  if index < 1 or index > #opened_items then return end

  local item = opened_items[index]
  if is_file(item.path) then
    vim.cmd("edit " .. item.path)
  else
    if item.label:match("NvimTree") then
      vim.cmd("NvimTreeToggle")
    end
  end
  current_index = index
  render_winbar()
end

-- keymap Ctrl+→ / ←
vim.keymap.set('n', '<C-Right>', function()
  goto_item(current_index + 1)
end)
vim.keymap.set('n', '<C-Left>', function()
  goto_item(current_index - 1)
end)
