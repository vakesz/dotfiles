-- Fuzzy finder over lists
-- Docs: https://github.com/nvim-telescope/telescope.nvim

return {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    cmd = "Telescope",

    dependencies = {
        "nvim-lua/plenary.nvim",
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            cond = function() return vim.fn.executable("make") == 1 end,
        },
        "nvim-telescope/telescope-ui-select.nvim",
        "nvim-telescope/telescope-file-browser.nvim",
    },

    keys = {
        { "<leader>pf", "<cmd>Telescope find_files<cr>", desc = "Find files" },
        { "<C-p>", "<cmd>Telescope git_files<cr>", desc = "Git files" },
        { "<leader>ps", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
        { "<leader>pb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
        { "<leader>vh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
        { "<leader>pws", function()
            require("telescope.builtin").grep_string({ search = vim.fn.expand("<cword>") })
        end, desc = "Grep word under cursor" },
        { "<leader>pWs", function()
            require("telescope.builtin").grep_string({ search = vim.fn.expand("<cWORD>") })
        end, desc = "Grep WORD under cursor" },
        { "<leader>pv", vim.cmd.Ex, desc = "Open netrw" },
        { "<leader>pe", "<cmd>Telescope file_browser path=%:p:h select_buffer=true<cr>", desc = "File browser" },
    },

    config = function()
        local telescope = require("telescope")
        telescope.setup({
            defaults = {
                sorting_strategy = "ascending",
                layout_config = {
                    prompt_position = "top",
                },
            },
            extensions = {
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = true,
                    override_file_sorter = true,
                    case_mode = "smart_case",
                },
                ["ui-select"] = require("telescope.themes").get_dropdown({}),
                file_browser = {},
            },
        })

        pcall(telescope.load_extension, "fzf")
        pcall(telescope.load_extension, "ui-select")
        pcall(telescope.load_extension, "file_browser")
    end,
}
