-- Show available keybindings in a popup as you type.
-- Docs: https://github.com/folke/which-key.nvim

return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer Local Keymaps (which-key)",
        },
    },
    config = function()
        local wk = require("which-key")
        wk.setup()

        -- Register leader key groups
        wk.add({
            { "<leader>c", group = "Code" },
            { "<leader>d", group = "Debug" },
            { "<leader>f", desc = "Format" },
            { "<leader>g", group = "Git" },
            { "<leader>h", group = "Git Hunks" },
            { "<leader>p", group = "Project/Find" },
            { "<leader>t", group = "Test" },
            { "<leader>v", group = "LSP" },
            { "<leader>x", group = "Diagnostics" },
        })
    end,
}
