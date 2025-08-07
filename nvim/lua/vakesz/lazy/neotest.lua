-- Testing framework
-- Docs: https://github.com/nvim-neotest/neotest

return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-neotest/nvim-nio", -- async library
        "nvim-lua/plenary.nvim", -- utility functions
        "antoinemadec/FixCursorHold.nvim", -- fix CursorHold events
        "nvim-treesitter/nvim-treesitter", -- syntax trees
        "fredrikaverpil/neotest-golang", -- Go adapter
    },
    config = function()
        require("neotest").setup({
            adapters = {
                require("neotest-golang"), -- enable Go test adapter
            },
        })

        vim.keymap.set("n", "<leader>tc", function()
            require("neotest").run.run() -- run nearest test
        end)

        vim.keymap.set("n", "<leader>tf", function()
            require("neotest").run.run(vim.fn.expand("%")) -- run current file
        end)
    end
}