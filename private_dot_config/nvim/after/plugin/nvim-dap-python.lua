require('dap-python').setup('~/.virtualenvs/debugpy/bin/python')

vim.keymap.set("n", '<leader>tc', function()
    if vim.bo.filetype == 'python' then
        require('dap-python').test_class();
    end
end)

vim.keymap.set("n", '<leader>tm', function()
    if vim.bo.filetype == 'python' then
        require('dap-python').test_method();
    end
end)
