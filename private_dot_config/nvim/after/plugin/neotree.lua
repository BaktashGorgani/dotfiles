vim.keymap.set("n", "<leader>v", "<cmd>Neotree toggle<cr>")

require("neo-tree").setup({
    close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
    default_component_configs = {
        file_size = {
            enabled = true,
            required_width = 36, -- min width of window required to show this column
        },
        type = {
            enabled = true,
            required_width = 90, -- min width of window required to show this column
        },
        last_modified = {
            enabled = true,
            required_width = 55, -- min width of window required to show this column
        },
        created = {
            enabled = true,
            required_width = 75, -- min width of window required to show this column
        },
        symlink_target = {
            enabled = true,
        },
    },
    window = {
        width = 35,
    },
    filesystem = {
        filtered_items = {
            visible = true, -- when true, they will just be displayed differently than normal items
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_hidden = false, -- only works on Windows for hidden files/directories
        },
        follow_current_file = {
            enabled = true, -- This will find and focus the file in the active buffer every time
            --               -- the current file is changed while the tree is open.
            leave_dirs_open = true, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
        },
    },
    buffers = {
        follow_current_file = {
            enabled = true, -- This will find and focus the file in the active buffer every time
            --              -- the current file is changed while the tree is open.
            leave_dirs_open = true, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
        },
    }
})
