--Git pull(fetch & merge), push, and status
vim.keymap.set("n", "<leader>gs", vim.cmd.Git);
vim.keymap.set("n", "<leader>gf", "<cmd>Git pull<cr>")
vim.keymap.set("n", "<leader>gp", "<cmd>Git push<cr>")

--Git Log
vim.keymap.set("n", "<leader>gl", "<cmd>Git log<cr>")

--Git stash and pop
vim.keymap.set("n", "<leader>gst", "<cmd>Git stash<cr>")
vim.keymap.set("n", "<leader>gsp", "<cmd>Git stash pop<cr>")

--Git zip
vim.keymap.set("n", "<leader>gz", "<cmd>Git archive --format zip --output git.zip main<cr>")

--Git add
vim.keymap.set("n", "<leader>ga", "<cmd>Git add %<cr>")
