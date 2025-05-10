vim.g.mapleader = " "

--Move between buffers
vim.keymap.set("n", "<C-A-h>", "<cmd>bp<cr>")
vim.keymap.set("n", "<C-A-l>", "<cmd>bn<cr>")

--Close buffer
vim.keymap.set("n", "<leader>bd", "<cmd>b#<bar>bd#<cr>")
--Move to any window using alt plus movement keys
vim.keymap.set('t', '<A-h>', [[<C-\><C-N><C-w>h]])
vim.keymap.set('t', '<A-j>', [[<C-\><C-N><C-w>j]])
vim.keymap.set('t', '<A-k>', [[<C-\><C-N><C-w>k]])
vim.keymap.set('t', '<A-l>', [[<C-\><C-N><C-w>l]])
vim.keymap.set('i', '<A-h>', [[<C-\><C-N><C-w>h]])
vim.keymap.set('i', '<A-j>', [[<C-\><C-N><C-w>j]])
vim.keymap.set('i', '<A-k>', [[<C-\><C-N><C-w>k]])
vim.keymap.set('i', '<A-l>', [[<C-\><C-N><C-w>l]])
vim.keymap.set('n', '<A-h>', [[<C-w>h]])
vim.keymap.set('n', '<A-j>', [[<C-w>j]])
vim.keymap.set('n', '<A-k>', [[<C-w>k]])
vim.keymap.set('n', '<A-l>', [[<C-w>l]])

--Clear search highlights
vim.keymap.set("n", "<leader>h", "<cmd>noh<cr>")

--Space t to open terminal
vim.keymap.set("n", "<leader>t", "<cmd>terminal<cr>")

--Be able to escape from terminal mode
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]])

--Resize based on splits
vim.keymap.set("n", "<Insert>",[[<C-w>=]])

--Fill Screen vertically
vim.keymap.set("n", "<Home>", [[<C-w>_]])

--Fill Screen horizontally
vim.keymap.set("n", "<End>", [[<C-w>|]])

--For vertical windows, resize windows horizontally using + and -
vim.keymap.set("n", "+", "<cmd>vert res +5<cr>")
vim.keymap.set("n", "-", "<cmd>vert res -5<cr>")

--For horizontal windows, resize windows vertically using PgUp and PgDn
vim.keymap.set("n", "<PageUp>", "<cmd>res +5<cr>")
vim.keymap.set("n", "<PageDown>", "<cmd>res -5<cr>")

--JSON Beautify
vim.keymap.set("n", "<leader>jb", "<cmd>%!python -m json.tool<cr>")

--Move selected line / block of text in visual mode
vim.keymap.set("v", "K", ":move '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":move '>+1<CR>gv=gv")

--Keep cursor after joining lines
vim.keymap.set("n", "J", "mzJ`z")

--System clipboard
vim.keymap.set("v", "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set("v", "<leader>p", [["+p]])
vim.keymap.set("n", "<leader>p", [["+p]])
vim.keymap.set("n", "<leader>P", [["+P]])

--CTRL + C to Escape
vim.keymap.set("i", "<C-c>", "<Esc>")

--Replace word under cursor
vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

--Make file executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

--Source file
vim.keymap.set("n", "<leader><leader>", function()
    vim.cmd("so")
end)
