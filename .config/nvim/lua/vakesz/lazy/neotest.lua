-- Testing framework
-- Docs: https://github.com/nvim-neotest/neotest

return {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-neotest/nvim-nio", -- async library
        "nvim-lua/plenary.nvim", -- utility functions
        "nvim-treesitter/nvim-treesitter", -- syntax trees
        "fredrikaverpil/neotest-golang", -- Go adapter
        "nvim-neotest/neotest-python", -- Python adapter
        "olimorris/neotest-phpunit", -- PHP adapter (optional)
        "lawrence-laz/neotest-zig", -- Zig adapter (optional)
    },
    config = function()
        require("neotest").setup({
            adapters = {
                -- Go test adapter
                require("neotest-golang")({
                    go_test_args = {
                        "-v",
                        "-race",
                        "-count=1",
                        "-timeout=60s",
                    },
                }),

                -- Python test adapter (pytest)
                require("neotest-python")({
                    dap = {
                        justMyCode = false,
                        console = "integratedTerminal",
                    },
                    args = { "--log-level", "DEBUG", "-vv" },
                    runner = "pytest",
                    python = function()
                        -- Try to use virtual environment
                        local cwd = vim.fn.getcwd()
                        if vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                            return cwd .. '/.venv/bin/python'
                        elseif vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                            return cwd .. '/venv/bin/python'
                        else
                            return 'python3'
                        end
                    end,
                }),

                -- Zig test adapter
                require("neotest-zig")({
                    dap = {
                        adapter = "codelldb",
                    },
                }),
            },
            -- Configure output and summary windows
            output = {
                open_on_run = true,
            },
            quickfix = {
                enabled = true,
                open = false,
            },
            status = {
                enabled = true,
                virtual_text = true,
                signs = true,
            },
        })

        -- Key mappings for testing
        vim.keymap.set("n", "<leader>tc", function()
            require("neotest").run.run() -- run nearest test
        end, { desc = "Run nearest test" })

        vim.keymap.set("n", "<leader>tf", function()
            require("neotest").run.run(vim.fn.expand("%")) -- run current file
        end, { desc = "Run current test file" })

        vim.keymap.set("n", "<leader>td", function()
            require("neotest").run.run({ strategy = "dap" }) -- debug nearest test
        end, { desc = "Debug nearest test" })

        vim.keymap.set("n", "<leader>ts", function()
            require("neotest").summary.toggle() -- toggle test summary
        end, { desc = "Toggle test summary" })

        vim.keymap.set("n", "<leader>to", function()
            require("neotest").output.open({ enter = true }) -- open test output
        end, { desc = "Open test output" })

        vim.keymap.set("n", "<leader>tS", function()
            require("neotest").run.stop() -- stop running tests
        end, { desc = "Stop running tests" })
    end
}