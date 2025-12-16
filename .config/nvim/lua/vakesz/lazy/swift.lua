-- Swift/iOS development support
-- Docs: https://github.com/xbase-lab/xbase
-- Docs: https://github.com/wojciech-kulik/xcodebuild.nvim
-- LSP: sourcekit-lsp comes with Xcode

return {
    -- Xcode project integration with build/test/debug support
    {
        "wojciech-kulik/xcodebuild.nvim",
        dependencies = {
            "nvim-telescope/telescope.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
        },
        config = function()
            require("xcodebuild").setup({
                -- Configuration for Xcode builds in Neovim
                code_coverage = {
                    enabled = true,
                },
                commands = {
                    -- Commands are automatically registered
                    cache_devices = true,
                },
                logs = {
                    auto_open_on_failed_tests = true,
                    auto_focus = true,
                    auto_close_on_success = false,
                    notify = function(message, severity)
                        vim.notify(message, severity)
                    end,
                },
            })

            -- Key mappings for Xcode commands
            vim.keymap.set("n", "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle Xcodebuild Logs" })
            vim.keymap.set("n", "<leader>xb", "<cmd>XcodebuildBuild<cr>", { desc = "Build Project" })
            vim.keymap.set("n", "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", { desc = "Build & Run Project" })
            vim.keymap.set("n", "<leader>xt", "<cmd>XcodebuildTest<cr>", { desc = "Run Tests" })
            vim.keymap.set("n", "<leader>xT", "<cmd>XcodebuildTestClass<cr>", { desc = "Run This Test Class" })
            vim.keymap.set("n", "<leader>xs", "<cmd>XcodebuildSelectScheme<cr>", { desc = "Select Scheme" })
            vim.keymap.set("n", "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", { desc = "Select Device" })
            vim.keymap.set("n", "<leader>xp", "<cmd>XcodebuildPicker<cr>", { desc = "Show All Xcodebuild Actions" })
            vim.keymap.set("n", "<leader>xc", "<cmd>XcodebuildToggleCodeCoverage<cr>", { desc = "Toggle Code Coverage" })
            vim.keymap.set("n", "<leader>xC", "<cmd>XcodebuildShowCodeCoverageReport<cr>", { desc = "Show Code Coverage Report" })
            vim.keymap.set("n", "<leader>xq", "<cmd>Telescope quickfix<cr>", { desc = "Show QuickFix List" })
        end,
    },
}
