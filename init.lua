-- init.lua
-- =====================================================
-- Termux Modern Neovim Config
-- =====================================================

-- Set leader key
vim.g.mapleader = " "

-- Tambahkan path Lazy.nvim ke runtime path
vim.opt.rtp:prepend("~/.local/share/nvim/lazy/lazy.nvim")

-- Load konfigurasi plugin dan setup
require("setupEl")

