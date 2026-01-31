-- =========================================
-- Termux Modern Neovim Config
-- HTML / JS/TS / Python + Mason + LSP + Snippets + nvim-cmp + Treesitter + Lualine + Telescope
-- Fully functional, autocomplete HTML tags, snippets ready
-- =========================================

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


require("polish")
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

  -- Completion
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },

  -- Snippets
  { "hrsh7th/cmp-vsnip" },
  { "hrsh7th/vim-vsnip" },
  { "rafamadriz/friendly-snippets" }, -- snippet umum HTML/JS/Python

  -- Theme
  { "folke/tokyonight.nvim" },

  -- Status line
  { "nvim-lualine/lualine.nvim" },

----------------------------------------------------------------
  -- NVIM TREE = SATU-SATUNYA FILE EXPLORER
  ----------------------------------------------------------------
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },

    config = function()
      -- Override ikon file
      require('nvim-web-devicons').set_icon {
        lua  = { icon = " ", color = "#51a0cf", name = "Lua" },
        txt  = { icon = "󰈙 ", color = "#89e051", name = "Text" },
        json = { icon = " ", color = "#cbcb41", name = "Json" },
        js   = { icon = " ", color = "#f1e05a", name = "Javascript" },
        html = { icon = " ", color = "#e34c26", name = "Html" },
        css  = { icon = " ", color = "#563d7c", name = "Css" },
        md   = { icon = " ", color = "#519aba", name = "Markdown" },
        sh   = { icon = " ", color = "#89e051", name = "Shell" },
      }

      -- Shortcut utama
      vim.keymap.set('n', '<C-e>', ':NvimTreeToggle<CR>', {
        noremap = true,
        silent = true
      })

      require('nvim-tree').setup {
        view = {
          side = 'left',
          width = math.floor(vim.o.columns / 2),  -- setengah layar
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

            glyphs = {
              default = " ",
              symlink = " ",
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

  {
  "utilyre/barbecue.nvim",
  name = "barbecue",
  version = "*",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- ikon file
    "SmiteshP/nvim-navic",         -- optional untuk LSP symbols
  },
  config = function()
    require("barbecue").setup({
      show_modified = false,      -- tanda file berubah
      kinds = {
        File      = " ",         -- ikon file + spasi
        Module    = " ",
        Namespace = " ",
        Package   = " ",
        Class     = " ",
        Method    = " ",
        Property  = " ",
        Field     = " ",
        Constructor = " ",
        Enum      = " ",
        Interface = " ",
        Function  = " ",
        Variable  = " ",
        Constant  = " ",
        String    = " ",
        Number    = " ",
        Boolean   = " ",
        Array     = " ",
        Object    = " ",
        Key       = " ",
        Null      = " ",
        EnumMember= " ",
        Struct    = " ",
        Event     = " ",
        Operator  = " ",
        TypeParameter = " ",
      },
      symbols = {
        separator = "┃",          -- pemisah bar
      },
    })
  end,
},
}) --batas nya

-- =========================
-- 3. Theme
-- =========================
vim.o.termguicolors = true
vim.cmd([[colorscheme tokyonight-storm]])

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
-- 6. Keymaps
-- =========================
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }


-- Telescope keymaps
map("n", "<Leader>ff", "<cmd>Telescope find_files<cr>", opts)
map("n", "<Leader>fg", "<cmd>Telescope live_grep<cr>", opts)
map("n", "<Leader>fb", "<cmd>Telescope buffers<cr>", opts)
map("n", "<Leader>fh", "<cmd>Telescope help_tags<cr>", opts)

-- =========================
-- 7. Mason Setup
-- =========================
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "pyright", "ts_ls", "html" },
  automatic_installation = true,
})

-- =========================
-- 8. LSP Setup Modern
-- =========================
-- Helper function: attach LSP if executable tersedia
local function attach_lsp(name, cmd, ft)
  if vim.fn.executable(cmd[1]) == 1 then
    vim.lsp.start({
      name = name,
      cmd = cmd,
      filetypes = ft,
    })
  end
end

-- Auto attach per FileType
vim.api.nvim_create_autocmd("FileType", {
  pattern = {"python","javascript","typescript","typescriptreact","html"},
  callback = function()
    local ft = vim.bo.filetype
    local clients = vim.lsp.get_active_clients({bufnr = 0})
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
-- 9. nvim-cmp + vsnip setup
-- =========================
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-n>"] = cmp.mapping.select_next_item(),
    ["<C-p>"] = cmp.mapping.select_prev_item(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "vsnip" },
  })
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
    theme = 'tokyonight',
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

-- =========================
-- 12. Ensure HTML filetype
-- =========================
vim.cmd [[
  autocmd BufRead,BufNewFile *.html set filetype=html
]]

-- Normal mode: Ctrl+Q keluar paksa
vim.api.nvim_set_keymap('n', '<C-q>', ':q!<CR>', { noremap = true, silent = true })
