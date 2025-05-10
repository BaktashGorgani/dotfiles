local bufferline = require("bufferline")

vim.opt.termguicolors = true
bufferline.setup({
    options = {
        indicator = {
            buffer_close_icon = ' ',
            modified_icon = '●',
            close_icon = ' ',
        },
        hover = {
            enabled = true,
            delay = 200,
            reveal = {'close'}
        },
        offsets = {
            {
                filetype = "neo-tree",
                text = "File Explorer",
                separator = true,
            },
        },
    },
})
