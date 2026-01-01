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
