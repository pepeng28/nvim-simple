-- =========================================
-- Termux Modern Neovim Config
-- HTML / JS/TS / Python + Mason + LSP + Snippets + nvim-cmp + Treesitter + Lualine + Telescope
-- Fully functional, autocomplete HTML tags, snippets ready
-- =========================================
-- Set tags file untuk Neovim
vim.opt.tags = "./tags;,~/.tags"

-- =========================
-- 1. Lazy.nvim (Plugin Manager)
-- =========================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =========================
-- 2. Plugins
-- =========================
require("lazy").setup({
  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },

  -- Telescope
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- LSP
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },
  -- LSP symbols
  { "SmiteshP/nvim-navic" },

  -- Completion
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },

  -- Snippets
  { "hrsh7th/cmp-vsnip" },
  { "hrsh7th/vim-vsnip" },
  { "rafamadriz/friendly-snippets" }, -- snippet umum HTML/JS/Python

  -- Theme
 -- { "folke/tokyonight.nvim" },
{
  "navarasu/onedark.nvim",
  priority = 1000,
  config = function()
    require("onedark").setup({
      style = "deep",
    })
    require("onedark").load()
  end,
},

  -- Status line
  { "nvim-lualine/lualine.nvim" },

----------------------------------------------------------------
  -- NVIM TREE = SATU-SATUNYA FILE EXPLORER Dan Icon Global
  ----------------------------------------------------------------
 {
  'nvim-tree/nvim-tree.lua',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },

  config = function()

    vim.keymap.set('n', '<C-e>', ':NvimTreeToggle<CR>', {
      noremap = true,
      silent = true
    })

    require('nvim-tree').setup {

      view = {
        side = 'left',
        width = math.floor(vim.o.columns / 2),
        preserve_window_proportions = true,
      },

      filters = {
        dotfiles = false,
      },

      renderer = {
        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },

          -- INI CUSTOM KHUSUS NVIM-TREE SAJA
          glyphs = {
            default = " ",
            folder = {
              arrow_closed = " ",
              arrow_open   = " ",
              default      = " ",
              open         = " ",
              empty        = " ",
              empty_open   = " ",
              symlink      = " ",
              symlink_open = " ",
            },
          },
        },
      },
    }
  end,
},
-- kalau pakai lazy.nvim
{
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup{
      -- pengaturan default, bisa dikustom
      size = 15,
      open_mapping = [[<c-\>]],
      direction = "horizontal",
    }
  end
},
}) --batas nya _

-- auto ambil plugins
local plugin_path = vim.fn.stdpath("config") .. "/lua/plugins"
local plugins = {}

for _, file in ipairs(vim.fn.glob(plugin_path .. "/*.lua", true, true)) do
  local name = file:match("^.+/(.+)%.lua$")
  local ok, mod = pcall(require, "plugins." .. name)
  if ok and type(mod) == "table" then
    for _, p in ipairs(mod) do
      table.insert(plugins, p)
    end
  elseif not ok then
    print("Gagal load plugin:", name, mod)
  end
end

-- Jalankan setup untuk semua plugin yang ada setup()
for _, plugin in ipairs(plugins) do
  if plugin.setup then
    plugin.setup()
  end
end

-- panggil konfigurasi LSP
require("lsp")
require("polish")

-- =========================
-- 3. Theme
-- =========================
--vim.o.termguicolors = true
--vim.cmd([[colorscheme tokyonight-storm]])


-- =========================
-- 4. Line Numbers
-- =========================
vim.wo.number = true
vim.wo.relativenumber = true

-- =========================
-- 5. Editor Options
-- =========================
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.smartindent = true
vim.o.wrap = false
vim.o.cursorline = true
vim.o.scrolloff = 8
vim.o.showmode = false -- lualine menampilkan mode

-- Auto attach per FileType
vim.api.nvim_create_autocmd("FileType", {
  pattern = {"python","javascript","typescript","typescriptreact","html"},
  callback = function()
    local ft = vim.bo.filetype
    local clients = vim.lsp.get_clients({bufnr = 0})    
    if #clients == 0 then
      if ft == "python" then
        attach_lsp("pyright", {"pyright-langserver","--stdio"}, {"python"})
      elseif ft == "javascript" or ft == "typescript" or ft == "typescriptreact" then
        attach_lsp("ts_ls", {"typescript-language-server","--stdio"}, {ft})
      elseif ft == "html" then
        attach_lsp("html", {"vscode-html-language-server","--stdio"}, {"html"})
      end
    end
  end
})
-- =========================
-- 10. Highlight Yank
-- =========================
vim.cmd [[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  augroup END
]]

-- =========================
-- 11. Status Line
-- =========================
require('lualine').setup {
  options = {
    --theme = 'tokyonight',
    theme = 'onedark',
    section_separators = '',
    component_separators = '',
    globalstatus = true,
  },
  sections = {
    lualine_a = {'mode'},
    lualine_b = {'branch', 'diagnostics'},
    lualine_c = {'filename'},
    lualine_x = {'encoding', 'filetype'},
    lualine_y = {'progress'},
    lualine_z = {'location'}
  }
}

-- Set leader
vim.g.mapleader = " "

-- Daftar shortcut
local shortcuts = {
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
}

-- Fungsi toggle menu
local function toggle_menu()
  -- Tutup menu jika sudah terbuka
  if menu_state.win and vim.api.nvim_win_is_valid(menu_state.win) then
    vim.api.nvim_win_close(menu_state.win, true)
    menu_state.win = nil
    menu_state.buf = nil
    return
  end

  -- Buat buffer baru untuk menu
  local buf = vim.api.nvim_create_buf(false, true)
  if not buf then return end

  -- Isi menu: 1 baris per shortcut
  local lines = {}
  for _, s in ipairs(shortcuts) do
    table.insert(lines, s.icon .. " " .. s.desc)
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Tentukan ukuran popup
  local width = 40
  local height = math.min(#lines, 10) -- maksimal 10 baris, nanti bisa scroll
  local editor_height = vim.api.nvim_get_option("lines") - vim.api.nvim_get_option("cmdheight") - 1
  local row = math.max(0, editor_height - height - 2)
  local col = math.max(0, math.floor((vim.o.columns - width) / 2))

  -- Opsi window popup
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

  -- Mapping Enter untuk menjalankan shortcut
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    local choice = shortcuts[line]
    if choice then
      vim.api.nvim_win_close(win, true)
      menu_state.win = nil
      menu_state.buf = nil
      choice.cmd()
    end
  end, { buffer = buf })

  -- Scroll menu jika banyak item
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

  -- Simpan state menu
  menu_state.buf = buf
  menu_state.win = win
end

-- Mapping Space untuk toggle menu
vim.keymap.set("n", "<Space>", toggle_menu, { desc = "Toggle Shortcut Menu" })

-- Tambahkan ini di akhir init.lua
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        local ok, winbar = pcall(require, "plugins.winbarEl")
        if ok then
            winbar.setup()
        end
    end
})

