-- lua/plugins/lazy/feline.lua
return {
    "famiu/feline.nvim",
    dependencies = { "kyazdani42/nvim-web-devicons" },
    config = function()
        -- load statusline setelah plugin siap
        local ok, _ = pcall(require, "statusline")
        if not ok then
            vim.notify("Failed to load statusline.lua", vim.log.levels.WARN)
        end
    end
}
