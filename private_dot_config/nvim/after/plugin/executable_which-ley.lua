local wk = require("which-key")

wk.setup({
    triggers_blacklist = {
        i = { "<leader>" },
    },
})

wk.add({
    {
        { "<leader><leader>", desc = "Source file" },
        { "<leader>a", desc = "Add to Harpoon" },
        { "<leader>b", group = "Dap Breakpoints" },
        { "<leader>ba", desc = "List breakpoints" },
        { "<leader>bb", desc = "Toggle breakpoint" },
        { "<leader>bc", desc = "Set breakpoint" },
        { "<leader>bl", desc = "Log point message" },
        { "<leader>br", desc = "Clear breakpoints" },
        { "<leader>d", group = "Dap" },
        { "<leader>d?", desc = "Scopes" },
        { "<leader>dc", desc = "Continue" },
        { "<leader>dd", desc = "Disconnect" },
        { "<leader>de", desc = "Diagnostics" },
        { "<leader>df", desc = "Frames" },
        { "<leader>dh", desc = "Commands" },
        { "<leader>di", desc = "Hover" },
        { "<leader>dj", desc = "Step over" },
        { "<leader>dk", desc = "Step into" },
        { "<leader>dl", desc = "Run last" },
        { "<leader>do", desc = "Step out" },
        { "<leader>dr", desc = "Toggle repl" },
        { "<leader>dt", desc = "Terminate" },
        { "<leader>g", group = "Git" },
        { "<leader>gb", desc = "Git blame" },
        { "<leader>gs", desc = "Git stash" },
        { "<leader>gz", desc = "Git zip" },
        { "<leader>h", desc = "Git hunk" },
        { "<leader>j", group = "Json" },
        { "<leader>jb", desc = "Beautify" },
        { "<leader>m", group = "Maximizer" },
        { "<leader>mm", desc = "Maximize" },
        { "<leader>mr", desc = "Restore" },
        { "<leader>mt", desc = "Toggle" },
        { "<leader>p", group = "Project" },
        { "<leader>pf", desc = "Find files" },
        { "<leader>pg", desc = "Git files" },
        { "<leader>ps", desc = "Grep string" },
        { "<leader>t", group = "Dap Test" },
        { "<leader>tc", desc = "Test class" },
        { "<leader>tm", desc = "Test method" },
        { "<leader>x", desc = "Make file executable" },
    }
})
