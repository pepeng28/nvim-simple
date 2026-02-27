
-- =========================================
-- Feline Statusline (Termux Optimized)
-- =========================================

-- =========================
-- Theme
-- =========================
local theme = {
  abu    = "#000000",
  bg     = "#19212E",
  fg     = "#C7C7CA",
  green  = "#79DCAA",
  --yellow = "#FFE59E",
  yellow = "#FFFF00",
  red    = "#F87070",
  blue   = "#5FB0FC",
  aqua   = "#7AB0DF",
  purple = "#C397D8",
  cyan = "#70C0BA",
  gray = "#222730",
  lime = "#54CED6",
  orange = "#FFD064",
  pink = "#D997C8",
}
local bg_color = theme.abu

local mode_theme = {
  NORMAL   = theme.green,
  INSERT   = theme.aqua,
  VISUAL   = theme.yellow,
  REPLACE  = theme.purple,
  COMMAND  = theme.blue,
  TERMINAL = theme.aqua,
}

local modes = setmetatable({
  n  = "N",  no = "N",
  v  = "V",  V  = "VL",
  s  = "S",  S  = "SL",
  i  = "I",  ic = "I",
  R  = "R",  Rv = "VR",
  c  = "C",
  r  = "P",  rm = "M",
  ["!"] = "SH",
  t  = "T",
}, {
  __index = function()
    return "-"
  end,
})

-- =========================
-- Require Feline
-- =========================
local ok, feline = pcall(require, "feline")
if not ok then
  return
end

local vi_mode_provider = require("feline.providers.vi_mode")

-- =========================
-- Git Cache (NO LAG)
-- =========================
local git_cache = {
  branch = "",
  status = "clean",
}

local function update_git()
  local git_dir = vim.fn.finddir(".git", ".;")
  if git_dir == "" then
    git_cache.branch = ""
    git_cache.status = "clean"
    return
  end

  -- ambil branch
  local branch = vim.fn.system("git branch --show-current 2>/dev/null")
    :gsub("\n", "")

  if branch == "" then
    branch = "(detached)"
  end

  git_cache.branch = " " .. branch

  -- cek status repo
  local status = vim.fn.system("git status --porcelain 2>/dev/null")

  if status == "" then
    git_cache.status = "clean"
  elseif status:match("^M") or status:match("^%sM") then
    git_cache.status = "dirty"
  else
    git_cache.status = "staged"
  end
end

vim.api.nvim_create_autocmd(
  { "BufEnter", "BufWritePost", "DirChanged" },
  {
    callback = function()
      update_git()
    end,
  }
)

update_git()

-- =========================
-- Components
-- =========================
local component = {}

-- =========================
-- Git Branch (Kiri)
-- =========================
component.git_branch = {
  provider = function() return git_cache.branch end,
  hl = function()
    if git_cache.status == "dirty" then
      return { fg = theme.red, bg = theme.abu, style = "bold" }
    elseif git_cache.status == "staged" then
      return { fg = theme.yellow, bg = theme.abu, style = "bold" }
    else
      return { fg = theme.green, bg = theme.abu, style = "bold" }
    end
  end,
  left_sep  = 'block',   -- kosongkan separator
  right_sep = 'block',   -- kosongkan separator
}

-- =========================
-- Mode
-- =========================
component.vim_mode = {
  provider = function()
    return modes[vim.api.nvim_get_mode().mode]
  end,

  hl = function()
    return {
      fg    = bg_color,
      bg    = vi_mode_provider.get_mode_color(),
      style = "bold",
    }
  end,

  left_sep  = "block",
  right_sep = "block",
}

-- =========================
-- File Type
-- =========================
component.file_type = {
  provider = {
    name = "file_type",
    opts = { filetype_icon = true },
  },
  hl = { fg = theme.fg, bg = bg_color },

  left_sep  = "block",
  right_sep = "block",
}

-- =========================
-- LSP
-- =========================
component.lsp = {
  provider = function()
    if not rawget(vim, "lsp") then
      return ""
    end

    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
      return ""
    end

    return "󱓈 El-Coding"
  end,

  hl = { fg = theme.green, bg = bg_color, style = "bold" },

  right_sep = "block",
}
-- =========================
-- Diagnostics
-- =========================
component.diagnostic_errors = {
  provider = "diagnostic_errors",
  hl = { fg = theme.red, bg = bg_color },
}

component.diagnostic_warnings = {
  provider = "diagnostic_warnings",
  hl = { fg = theme.yellow, bg = bg_color },
}

component.diagnostic_info = {
  provider = "diagnostic_info",
  hl = { fg = theme.blue, bg = bg_color },
}

component.diagnostic_hints = {
  provider = "diagnostic_hints",
  hl = { fg = theme.aqua, bg = bg_color },
}

-- =========================
-- Scroll Bar
-- =========================
component.scroll_bar = {
  provider = function()
    local chars = setmetatable({
      " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ",
      " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ",
    }, { __index = function() return " " end })
    local line_ratio = vim.api.nvim_win_get_cursor(0)[1] / vim.api.nvim_buf_line_count(0)
    local position = math.floor(line_ratio * 100)

    local icon = chars[math.floor(line_ratio * #chars)] .. position
    if position <= 5 then
      icon = " TOP"
    elseif position >= 95 then
      icon = " BOT"
    end
    return icon
  end,
  hl = function()
    local position = math.floor(vim.api.nvim_win_get_cursor(0)[1] / vim.api.nvim_buf_line_count(0) * 100)
    local fg
    local style

    if position <= 5 then
      fg = "aqua"
      style = "bold"
    elseif position >= 95 then
      fg = "red"
      style = "bold"
    else
      fg = "yellow"
      style = nil
    end
    return {
      fg = fg,
      style = style,
      bg = "abu",
    }
  end,
  left_sep = "block",
  right_sep = "block",
}
-- =========================
-- Setup
-- =========================
feline.setup({
  components = {
    active = {
      -- Kiri
      { component.git_branch },

      -- Spacer Tengah
      {
        {
          --provider = "",
          hl = { bg = theme.bg },
        },
      },

      -- Kanan
      {
        component.vim_mode,
        component.file_type,
        component.lsp,
        component.diagnostic_errors,
        component.diagnostic_warnings,
        component.diagnostic_info,
        component.diagnostic_hints,
        component.scroll_bar,
      },
    },
  },

  theme = theme,
  vi_mode_colors = mode_theme,
})
