-- setupEl.lua
-- =====================================================
-- Plugin Manager & Plugins Setup
-- =====================================================

-- Path Lazy.nvim
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

-- Setup plugins
require("lazy").setup({

  -- Import custom plugin configs
  { import = "plugins.lazy" },
  -- LSP Symbols / Navic
  { "SmiteshP/nvim-navic" },
  { "famiu/feline.nvim" },
  -- Telescope
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- LSP
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },

  -- Completion
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },

  -- Snippets
  { "hrsh7th/vim-vsnip" },
  { "rafamadriz/friendly-snippets" },

  -- Theme
  {
    "navarasu/onedark.nvim",
    priority = 1000,
    config = function()
      require("onedark").setup({ style = "deep" })
      require("onedark").load()
    end,
  },

  -- NVIM TREE
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      vim.keymap.set("n", "<C-e>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })
      require("nvim-tree").setup({
        view = {
          side = "left",
          width = math.floor(vim.o.columns / 2),
          preserve_window_proportions = true,
        },
        filters = { dotfiles = false },
      })
    end,
  },

  -- ToggleTerm
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 15,
        open_mapping = [[<c-\>]],
        direction = "horizontal",
      })
    end,
  },

  -- Lualine (commented supaya gak konflik sama Feline)
  -- {
  --   "nvim-lualine/lualine.nvim",
  --   config = function()
  --     require('lualine').setup {
  --       options = {
  --         theme = 'onedark',
  --         section_separators = '',
  --         component_separators = '',
  --         globalstatus = true,
  --       },
  --       sections = {
  --         lualine_a = {'mode'},
  --         lualine_b = {'branch', 'diagnostics'},
  --         lualine_c = {'filename'},
  --         lualine_x = {'encoding', 'filetype'},
  --         lualine_y = {'progress'},
  --         lualine_z = {'location'}
  --       }
  --     }
  --   end
  -- }

})

-- panggil konfigurasi LSP
require("lsp")
require("plugins")
require("statusline")  -- <-- panggil statusline Feline
require('polish')
-- =========================
-- Editor Options
-- =========================
vim.wo.number = true
vim.wo.relativenumber = true
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.smartindent = true
vim.o.wrap = false
vim.o.cursorline = true
vim.o.scrolloff = 8
vim.o.showmode = false -- Feline menampilkan mode

-- =========================
-- Highlight Yank
-- =========================
vim.cmd [[
  augroup YankHighlight
    autocmd!
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
  augroup END
]]


