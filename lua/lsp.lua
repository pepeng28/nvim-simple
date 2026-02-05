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



