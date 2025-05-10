local notify = require("notify")

notify.setup({
    render = "compact",
    -- Default timeout for notifications
    timeout = 2500,
})

vim.keymap.set("n", "<Esc>", function()
	notify.dismiss()
end, { desc = "dismiss notify popup" })
