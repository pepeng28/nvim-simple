

local function safe_require(name)
local ok, mod = pcall(require, name)
  if not ok then return end
  if type(mod) == "table" and mod.setup then
		          mod.setup()
	end
end

safe_require("winbarEl")
safe_require("menuEl")
safe_require("disable_italic")
