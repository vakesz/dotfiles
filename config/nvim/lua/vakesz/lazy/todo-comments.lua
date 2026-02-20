-- Highlight and search TODO/FIXME/HACK comments
-- Docs: https://github.com/folke/todo-comments.nvim

return {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    keys = {
        { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
        { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
        { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
    },
    opts = {},
}
