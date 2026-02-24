

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

vim.g.mapleader = " "
vim.opt.rtp:prepend(lazypath)

-- =========================================
-- Termux Modern Neovim Config
-- HTML / JS/TS / Python + Mason + LSP + Snippets + nvim-cmp + Treesitter + Lualine + Telescope
-- Fully functional, autocomplete HTML tags, snippets ready
-- =========================================
-- Set tags file untuk Neovim
-- -- Set leader
-- =========================
-- 2. Plugins
-- =========================
require("lazy").setup({

	{ import = "plugins.lazy" },
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

-- panggil konfigurasi LSP
require("lsp")
require("plugins")

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


