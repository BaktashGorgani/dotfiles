local opts = {
    layouts = {
        {
            elements = {
                {
                    id = "scopes",
                    size = 0.35
                },
                {
                    id = "watches",
                    size = 0.35
                },
                {
                    id = "stacks",
                    size = 0.15
                },
                {
                    id = "breakpoints",
                    size = 0.15
                }
            },
            size = 65,
            position = "left", -- Can be "left" or "right"
        },
        {
            elements = {
                "console",
            },
            size = 14,
            position = "bottom", -- Can be "bottom" or "top"
        },
        {
            elements = {
                "repl",
            },
            size = 14,
            position = "bottom", -- Can be "bottom" or "top"
        },
    },
}



local dap, dapui = require("dap"), require("dapui")
dapui.setup(opts)
dap.listeners.before.attach.dapui_config = function()
    dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
    dapui.open()
end
