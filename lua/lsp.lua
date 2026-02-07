
local navic = require("nvim-navic")

local on_attach = function(client, bufnr)
  if client.server_capabilities.documentSymbolProvider then
    navic.attach(client, bufnr)
  end
end

-- Setup Lua LSP menggunakan API baru
vim.lsp.start({
  name = "lua_ls",
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_dir = vim.loop.cwd,
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = { library = vim.api.nvim_get_runtime_file("", true) },
      telemetry = { enable = false },
    },
  },
  on_attach = on_attach,
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

-- =========================
-- 7. Mason Setup
-- =========================
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "pyright", "ts_ls", "html" },
  automatic_installation = true,
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


-- Setup completion first (if using nvim-cmp)
local cmp = require('cmp')
cmp.setup({
  snippet = { expand = function(args) vim.snippet.expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'buffer' },
  })
})

-- Get capabilities from nvim-cmp (if installed)
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Common on_attach function
local on_attach = function(client, bufnr)
  local opts = { buffer = bufnr, remap = false }
  
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, opts)
  vim.keymap.set('n', '<leader>vd', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_next, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<leader>rr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help, opts)
end

-- Configure and enable LSP servers using the new API
vim.lsp.config('tsserver', {
  on_attach = on_attach,
  capabilities = capabilities,
})
vim.lsp.enable('tsserver')

vim.lsp.config('lua_ls', {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace = { library = vim.api.nvim_get_runtime_file("", true) },
      telemetry = { enable = false }
    }
  }
})
vim.lsp.enable('lua_ls')

-- Add more servers as needed
-- vim.lsp.config('pyright', { ... })
-- vim.lsp.enable('pyright')

-- To check if a config exists before enabling
if vim.lsp.config['tsserver'] then
  vim.lsp.enable('tsserver')
end

-- To get all available configs
local all_configs = vim.lsp.config
for name, config in pairs(all_configs) do
  print(name, config)
end

-- To get active clients (NOT deprecated - use this instead of get_active_clients)
local clients = vim.lsp.get_clients()
for _, client in ipairs(clients) do
  print(client.name, client.id)
end

