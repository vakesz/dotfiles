-- Fuzzy finder over lists
-- Docs: https://github.com/nvim-telescope/telescope.nvim

return {
    "nvim-telescope/telescope.nvim",

    tag = "0.1.5", -- pin to stable release

    dependencies = {
        "nvim-lua/plenary.nvim", -- required utility functions
        { -- native fzf for performance
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            cond = function() return vim.fn.executable("make") == 1 end,
        },
        { -- improve vim.ui.select
            "nvim-telescope/telescope-ui-select.nvim",
        },
    },

    config = function()
        local telescope = require('telescope')
        telescope.setup({
            -- ...existing config (using defaults for core)
            extensions = {
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = true,
                    override_file_sorter = true,
                    case_mode = "smart_case",
                },
                ["ui-select"] = require("telescope.themes").get_dropdown({})
            },
        })
        -- Load extensions (pcall to avoid errors if build skipped)
        pcall(telescope.load_extension, 'fzf')
        pcall(telescope.load_extension, 'ui-select')

        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>pf', builtin.find_files, {}) -- search files
        vim.keymap.set('n', '<C-p>', builtin.git_files, {}) -- search git tracked files
        vim.keymap.set('n', '<leader>pws', function()
            local word = vim.fn.expand("<cword>")
            builtin.grep_string({ search = word }) -- grep current word
        end)
        vim.keymap.set('n', '<leader>pWs', function()
            local word = vim.fn.expand("<cWORD>")
            builtin.grep_string({ search = word }) -- grep WORD under cursor
        end)
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") }) -- grep prompt
        end)
        vim.keymap.set('n', '<leader>vh', builtin.help_tags, {}) -- search help tags
    end
}