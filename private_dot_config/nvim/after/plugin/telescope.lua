local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>pf', "<cmd>lua require'telescope.builtin'.find_files({no_ignore=true})<cr>", {})
vim.keymap.set('n', '<leader>pg', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)

--Extension keymaps
vim.keymap.set("n", "<leader>u", "<cmd>Telescope undo<cr>")
vim.keymap.set("n", "<leader>z", "<cmd>Telescope aerial<cr>")
vim.keymap.set("n", "<leader>f", "<cmd>Telescope flutter commands<cr>")
vim.keymap.set("n", "<leader>n", "<cmd>Telescope notify<cr>")
