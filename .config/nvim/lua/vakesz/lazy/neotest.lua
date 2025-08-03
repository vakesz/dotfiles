return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-neotest/nvim-nio",
        "nvim-lua/plenary.nvim",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-treesitter/nvim-treesitter",
        "fredrikaverpil/neotest-golang",
    },
    config = function()
        require("neotest").setup({
            adapters = {
                require("neotest-golang"),
            },
        })

        vim.keymap.set("n", "<leader>tc", function()
            require("neotest").run.run()
        end)

        vim.keymap.set("n", "<leader>tf", function()
            require("neotest").run.run(vim.fn.expand("%"))
        end)
    end
}