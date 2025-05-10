vim.api.nvim_set_keymap('n', '<leader>mt', '<cmd>lua require("maximizer").toggle()<CR>', {silent = true, noremap = true})
vim.api.nvim_set_keymap('n', '<leader>mm', '<cmd>lua require("maximizer").maximize()<CR>', {silent = true, noremap = true})
vim.api.nvim_set_keymap('n', '<leader>mr', '<cmd>lua require("maximizer").restore()<CR>', {silent = true, noremap = true})
