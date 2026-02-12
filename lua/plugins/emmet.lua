return {
  {
    "mattn/emmet-vim",
    ft = { "html", "css", "javascript", "javascriptreact" },
    init = function()
      vim.g.user_emmet_expandabbr_key = "<Tab>"
    end,
    config = function()
      vim.cmd("EmmetInstall")  -- Pastikan di-run ketika plugin loaded
    end,
  },
}
