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

local function only_empty()
  return vim.fn.argc() == 0
end

-- Saat start: jika tanpa argumen, sembunyikan semua dekorasi
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if only_empty() then
      vim.opt.laststatus = 0   -- 0 = hilangkan status line
      vim.opt.showmode = false
      vim.opt.ruler = false
      vim.opt.showcmd = false
    end
  end,
})

-- Segera setelah ada file dibaca atau dibuat, kembalikan ke normal
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  callback = function()
    vim.opt.laststatus = 3     -- tampilkan status line global
    vim.opt.showmode = true
    vim.opt.ruler = true
    vim.opt.showcmd = true
  end,
})

-- Opsional: jika semua buffer ditutup dan kembali ke keadaan kosong,
-- kita bisa mengembalikan keadaan seperti startup.
-- Tapi biasanya tidak terlalu diperlukan.
