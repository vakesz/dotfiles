-- Fuzzy finder over lists
-- Docs: https://github.com/nvim-telescope/telescope.nvim

return {
    "nvim-telescope/telescope.nvim",

    tag = "0.1.5", -- pin to stable release

    dependencies = {
        "nvim-lua/plenary.nvim", -- required utility functions
    },

    config = function()
        require('telescope').setup({}) -- use defaults

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