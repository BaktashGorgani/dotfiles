local luasnip = require("luasnip")
vim.keymap.set({"i"}, "<CR>", function() luasnip.expand() end, {silent = true})
vim.keymap.set({"i", "s"}, "<Tab>", function() luasnip.jump( 1) end, {silent = true})
vim.keymap.set({"i", "s"}, "<S-Tab>", function() luasnip.jump(-1) end, {silent = true})

vim.keymap.set({"i", "s"}, "<C-q>", function()
    if luasnip.choice_active() then
        luasnip.change_choice(1)
    end
end, {silent = true})
