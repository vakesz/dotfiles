return {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
        render_modes = { "n", "c" },
        anti_conceal = { enabled = false },
        win_options = {
            conceallevel = { default = 0, rendered = 2 },
        },
    },
}
