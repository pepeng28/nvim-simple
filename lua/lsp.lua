-- ====================================================
-- LSP MODERN NEO 0.11+ — TERMUX FIX VERSION
-- NO DEPRECATED, NO EXIT 127
-- ====================================================

-------------------------------------------------------
-- 0. FIX PATH TERMUX (INI KUNCI UTAMA)
-------------------------------------------------------
vim.env.PATH =
  "/data/data/com.termux/files/usr/bin:" ..
  vim.env.PATH

-------------------------------------------------------
-- 1. CMP SETUP
-------------------------------------------------------
local cmp = require("cmp")

cmp.setup({
  snippet = {
    expand = function(args)
      vim.fn["vsnip#anonymous"](args.body)
    end,
  },

  mapping = cmp.mapping.preset.insert({
    ["<C-n>"]     = cmp.mapping.select_next_item(),
    ["<C-p>"]     = cmp.mapping.select_prev_item(),
    ["<CR>"]      = cmp.mapping.confirm({ select = true }),
    ["<C-Space>"] = cmp.mapping.complete(),
  }),

  sources = {
    { name = "nvim_lsp" },
    { name = "vsnip" },
    { name = "buffer" },
  },
})

-------------------------------------------------------
-- 2. CAPABILITIES
-------------------------------------------------------
local capabilities =
  require("cmp_nvim_lsp").default_capabilities()

-------------------------------------------------------
-- 3. ON ATTACH
-------------------------------------------------------
local navic = require("nvim-navic")

local on_attach = function(client, bufnr)

  if client:supports_method("textDocument/documentSymbol") then
    navic.attach(client, bufnr)
  end

  local opts = { buffer = bufnr }

  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "K",  vim.lsp.buf.hover, opts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)

  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

  vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
  vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
end

-------------------------------------------------------
-- 4. MASON
-------------------------------------------------------
require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "ts_ls",
    "pyright",
    "html",
  },
})

-------------------------------------------------------
-- 5. LSP MODERN API (TANPA lspconfig lama)
-------------------------------------------------------

-- LUA ------------------------------------------------
vim.lsp.config("lua_ls", {

  -- ABSOLUTE PATH BIAR TERMUX AMAN
  cmd = {
    "/data/data/com.termux/files/usr/bin/lua-language-server"
  },

  on_attach = on_attach,
  capabilities = capabilities,

  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      runtime = {
        version = "LuaJIT",
      },
    },
  },
})

vim.lsp.enable("lua_ls")

-- TYPESCRIPT -----------------------------------------
vim.lsp.config("ts_ls", {
  on_attach = on_attach,
  capabilities = capabilities,
})

vim.lsp.enable("ts_ls")

-- PYTHON ---------------------------------------------
vim.lsp.config("pyright", {
  on_attach = on_attach,
  capabilities = capabilities,
})

vim.lsp.enable("pyright")

-- HTML -----------------------------------------------
vim.lsp.config("html", {
  on_attach = on_attach,
  capabilities = capabilities,
})

vim.lsp.enable("html")
