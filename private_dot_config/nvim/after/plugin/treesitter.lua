local configs = require("nvim-treesitter.configs")

configs.setup({
    ensure_installed = {
        "c",
        "lua",
        "vim",
        "vimdoc",
        "query",
        "elixir",
        "heex",
        "javascript",
        "html",
        "python",
        "go"
    },
    sync_install = false,
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
})

-- for hyprlang
vim.filetype.add({
  pattern = { [".*/hypr/.*%.conf"] = "hyprlang" },
})
