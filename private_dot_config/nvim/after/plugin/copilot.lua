vim.keymap.set("n", "<leader>c", "<cmd>Copilot panel<cr>")
require('copilot').setup({
    suggestion = {
        auto_trigger = true,
        keymap = {
            accept = "<leader><Tab>",
            accept_word = "<M-l>",
            accept_line = "<M-C-l>",
        }
    }
})
