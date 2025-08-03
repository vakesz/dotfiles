-- Pretty diagnostics list
-- Docs: https://github.com/folke/trouble.nvim

return {
    {
        "folke/trouble.nvim",
        config = function()
            require("trouble").setup({
                icons = false, -- disable icons to keep it minimal
            })

            vim.keymap.set("n", "<leader>tt", function()
                require("trouble").toggle() -- toggle Trouble window
            end)

            vim.keymap.set("n", "[t", function()
                require("trouble").next({skip_groups = true, jump = true}); -- next item
            end)

            vim.keymap.set("n", "]t", function()
                require("trouble").previous({skip_groups = true, jump = true}); -- previous item
            end)

        end
    },
}