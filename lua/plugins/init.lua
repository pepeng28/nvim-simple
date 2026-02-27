

-- lua/plugins/init.lua
local function safe_require(name)
  local ok, mod = pcall(require, name)
  if not ok then
    print("Failed to load " .. name)
    return
  end
  if type(mod) == "table" and mod.setup then
    mod.setup()
  end
end

require("plugins.winbarEl").setup({
  winbar_bg = "#000000",
})
safe_require("plugins.menuEl")
safe_require("plugins.disable_italic")

