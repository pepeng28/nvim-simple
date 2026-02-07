
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

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }


-- Telescope keymaps
map("n", "<Leader>ff", "<cmd>Telescope find_files<cr>", opts)
map("n", "<Leader>fg", "<cmd>Telescope live_grep<cr>", opts)
map("n", "<Leader>fb", "<cmd>Telescope buffers<cr>", opts)
map("n", "<Leader>fh", "<cmd>Telescope help_tags<cr>", opts)




-- =========================
-- 12. Ensure HTML filetype
-- =========================
vim.cmd [[
  autocmd BufRead,BufNewFile *.html set filetype=html
]]

-- Normal mode: Ctrl+Q keluar paksa
vim.api.nvim_set_keymap('n', '<C-q>', ':q!<CR>', { noremap = true, silent = true })

-- Matikan tombol Space di normal mode
--vim.api.nvim_set_keymap('n', '<Space>', '<Nop>', { noremap = true, silent = true })


