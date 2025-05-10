vim.cmd[[set background=dark]]
vim.cmd[[colorscheme onedark]]

vim.api.nvim_set_hl(0, "Search", {
    bold = true,
    italic = true,
    underline = true,
    fg = "NvimDarkGrey1",
    bg = "NvimDarkGreen",
})

vim.api.nvim_set_hl(0, "IncSearch", {
    bold = true,
    italic = true,
    underline = true,
    fg = "NvimDarkGrey1",
    bg = "NvimDarkGreen",
})

vim.api.nvim_set_hl(0, "CurSearch", {
    bold = true,
    italic = true,
    underline = true,
    fg = "NvimDarkGreen",
    bg = "NvimDarkGrey1",
})
