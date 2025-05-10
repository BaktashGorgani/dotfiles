-- IMPORTANT: make sure to setup neodev BEFORE lspconfig
require("neodev").setup({
    library = { plugins = { "nvim-dap-ui" }, types = true },
    -- add any options here, or leave empty to use the default settings
})

local lsp_zero = require('lsp-zero')

---@diagnostic disable-next-line: unused-local
lsp_zero.on_attach(function(client, bufnr)
    -- see :help lsp-zero-keybindings
    -- to learn the available actions
    lsp_zero.default_keymaps({
        buffer = bufnr,
        preserve_mappings = false,
    })
end)

-- here you can setup the language servers

require'lspconfig'.jedi_language_server.setup{}
require'lspconfig'.gopls.setup{}
require'lspconfig'.hyprls.setup{}
require'lspconfig'.bashls.setup{}

require('flutter-tools').setup({
    debugger = {
        run_via_dap = true,
    },
    lsp = {
        capabilities = lsp_zero.get_capabilities()
    },
})

require'lspconfig'.lua_ls.setup {
    on_init = function(client)
        local path = client.workspace_folders[1].name
        if not vim.loop.fs_stat(path..'/.luarc.json') and not vim.loop.fs_stat(path..'/.luarc.jsonc') then
            client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
                Lua = {
                    runtime = {
                        -- Tell the language server which version of Lua you're using
                        -- (most likely LuaJIT in the case of Neovim)
                        version = 'LuaJIT'
                    },
                    -- Make the server aware of Neovim runtime files
                    workspace = {
                        checkThirdParty = false,
                        library = {
                            vim.env.VIMRUNTIME
                            -- "${3rd}/luv/library"
                            -- "${3rd}/busted/library",
                        }
                        -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
                        -- library = vim.api.nvim_get_runtime_file("", true)
                    }
                }
            })

            client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
        end
        return true
    end
}

-- keymaps

vim.keymap.set("n", "<M-CR>", "<cmd>lua vim.lsp.buf.code_action()<cr>")
