-- Collection of minimal, fast, and powerful plugins
-- Docs: https://github.com/echasnovski/mini.nvim

return {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
        -- Better statusline
        require("mini.statusline").setup({ use_icons = true })

        -- Indent guides with scope highlighting
        require("mini.indentscope").setup({
            symbol = "│",
            options = { try_as_border = true },
        })

        -- Surround plugin (add/delete/change surroundings)
        -- sa" to surround with ", sd" to delete ", sr"' to replace " with '
        require("mini.surround").setup()

        -- Better buffer deletion (preserves window layout)
        require("mini.bufremove").setup()

        -- Add keymap for buffer deletion
        vim.keymap.set("n", "<leader>bd", function()
            require("mini.bufremove").delete(0, false)
        end, { desc = "Delete buffer" })

        vim.keymap.set("n", "<leader>bD", function()
            require("mini.bufremove").delete(0, true)
        end, { desc = "Delete buffer (force)" })
    end,
}
