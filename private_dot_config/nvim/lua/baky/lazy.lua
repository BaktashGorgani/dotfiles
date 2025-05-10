local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end

local function get_git_diff(staged)
    local cmd = staged and "git diff --staged" or "git diff"
    local handle = io.popen(cmd)
    if not handle then
        return ""
    end

    local result = handle:read("*a")
    handle:close()
    return result
end

vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {
            -- add any options here
        },
        dependencies = {
            -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
            "MunifTanjim/nui.nvim",
            -- OPTIONAL:
            --   `nvim-notify` is only needed, if you want to use the notification view.
            --   If not available, we use `mini` as the fallback
            "rcarriga/nvim-notify",
        }
    },
    {
        'nvim-telescope/telescope.nvim', tag = '0.1.5',
        -- or                              , branch = '0.1.x',
        dependencies = {
            "nvim-lua/plenary.nvim",
            "debugloop/telescope-undo.nvim",
        },
        config = function()
            require("telescope").setup({})
            require("telescope").load_extension("undo")
            require("telescope").load_extension("aerial")
            require("telescope").load_extension("flutter")
        end,
    },
    {
        "craftzdog/solarized-osaka.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
    },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
    },
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
            "MunifTanjim/nui.nvim",
            "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
        }
    },
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" }
    },
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' }
    },
    {
        'stevearc/aerial.nvim',
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "nvim-tree/nvim-web-devicons"
        },
    },
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        opts = {} -- this is equalent to setup({}) function
    },
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({
                -- Configuration here, or leave empty to use defaults
            })
        end
    },
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
    },
    {
        'fisadev/vim-isort',
        ft = 'python',
        config =function ()
            vim.cmd('autocmd BufWritePre *.py execute ":Isort"')
        end
    },
    {
        'psf/black',
        branch = 'stable',
        ft = 'python',
        config =function ()
            vim.cmd('autocmd BufWritePre *.py execute ":Black"')
        end
    },
    {
        "0x00-ketsu/maximizer.nvim",
    },
    {'echasnovski/mini.nvim', version = false},
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end,
        opts = {
        },
    },
    {
        'akinsho/flutter-tools.nvim',
        lazy = false,
        dependencies = {
            'nvim-lua/plenary.nvim',
            'stevearc/dressing.nvim', -- optional for vim.ui.select
        },
        config = true,
    },
    {'wakatime/vim-wakatime', lazy = false},
    {"mfussenegger/nvim-dap"},
    {"mfussenegger/nvim-dap-python"},
    {"tpope/vim-fugitive"},
    --- Uncomment these if you want to manage the language servers from neovim
    {'williamboman/mason.nvim'},
    {'williamboman/mason-lspconfig.nvim'},

    {'VonHeikemen/lsp-zero.nvim', branch = 'v3.x'},
    {'neovim/nvim-lspconfig'},
    {'hrsh7th/cmp-nvim-lsp'},
    {'hrsh7th/nvim-cmp'},
    {'saadparwaiz1/cmp_luasnip'},
    {'momota/cisco.vim'},
    {
        "L3MON4D3/LuaSnip",
        dependencies = { "rafamadriz/friendly-snippets" },
    },
    { "Nash0x7E2/awesome-flutter-snippets" },
    { "rafamadriz/friendly-snippets" },
    {'airblade/vim-gitgutter'},
    {'jeetsukumaran/vim-pythonsense'},
    {'michaeljsmith/vim-indent-object'},
    {'kkoomen/vim-doge', build = ':call doge#install()'},
    {'andweeb/presence.nvim'},
    {'tiagofumo/vim-nerdtree-syntax-highlight'},
    {'ryanoasis/vim-devicons'},
    {'nvim-tree/nvim-web-devicons'},
    {'adelarsq/vim-devicons-emoji'},
    {'akinsho/bufferline.nvim', version = "*", dependencies = 'nvim-tree/nvim-web-devicons'},
    {'rafi/awesome-vim-colorschemes'},
    {'AndreM222/copilot-lualine'},
    {'mfussenegger/nvim-lint'},
    {'HiPhish/rainbow-delimiters.nvim'},
    {'momota/cisco.vim'},
    {'rrethy/vim-illuminate'},
    {"folke/neodev.nvim", opts = {}},
    {
        -- https://github.com/f-person/git-blame.nvim
        'f-person/git-blame.nvim',
        event = 'VeryLazy',
        opts = {
            date_format = '%m/%d/%y %H:%M:%S', -- more concise date format
        }
    },
    {
        -- https://github.com/theHamsta/nvim-dap-virtual-text
        'theHamsta/nvim-dap-virtual-text',
        lazy = true,
        opts = {
            -- Display debug text as a comment
            commented = true,
            -- Customize virtual text
            ---@diagnostic disable-next-line: unused-local
            display_callback = function(variable, buf, stackframe, node, options)
                if options.virt_text_pos == 'inline' then
                    return ' = ' .. variable.value
                else
                    return variable.name .. ' = ' .. variable.value
                end
            end,
        }
    },
    {
        -- https://github.com/rcarriga/nvim-dap-ui
        'rcarriga/nvim-dap-ui',
        event = 'VeryLazy',
        dependencies = {
            -- https://github.com/mfussenegger/nvim-dap
            'mfussenegger/nvim-dap',
            -- https://github.com/theHamsta/nvim-dap-virtual-text
            'theHamsta/nvim-dap-virtual-text', -- inline variable text while debugging
            -- https://github.com/nvim-telescope/telescope-dap.nvim
            'nvim-telescope/telescope-dap.nvim', -- telescope integration with dap
            "nvim-neotest/nvim-nio",
        },
    },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        branch = "main",
        dependencies = {
            { "zbirenbaum/copilot.lua" },
            { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
        },
        build = "make tiktoken", -- Only on MacOS or Linux
        opts = {
            -- See Configuration section for options
        },
        -- See Commands section for default commands if you want to lazy load on them
    },
})
