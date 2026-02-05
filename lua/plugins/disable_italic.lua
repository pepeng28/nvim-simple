-- Fungsi untuk matikan italic tapi tetap simpan warna
local function disable_italic_preserve_color()
    for _, group in ipairs(vim.fn.getcompletion("", "highlight")) do
        local ok, hl = pcall(vim.api.nvim_get_hl_by_name, group, true)
        if ok and hl.italic then
            -- ambil foreground color jika ada
            local fg = hl.foreground and string.format("#%06x", hl.foreground) or nil
            local bg = hl.background and string.format("#%06x", hl.background) or nil

            -- matikan italic tapi tetap pakai warna lama
            vim.api.nvim_set_hl(0, group, {
                italic = false,
                fg = fg,
                bg = bg,
            })
        end
    end
end

-- Jalankan saat startup
disable_italic_preserve_color()

-- Jalankan ulang tiap buffer baru, ganti colorscheme, atau reload highlight
vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter", "ColorScheme"}, {
    callback = function()
        disable_italic_preserve_color()
    end,
})


