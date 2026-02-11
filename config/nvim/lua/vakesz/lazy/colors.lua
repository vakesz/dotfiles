return {
    "folke/tokyonight.nvim",
    name = "tokyonight",
    lazy = false,
    priority = 1000,

    config = function()
        require("tokyonight").setup({
            style = "night",
            transparent = true,
            styles = {
                comments = { italic = true },
                keywords = { bold = true },
                sidebars = "transparent",
                floats = "transparent",
            },
            on_highlights = function(hl, _)
                hl.Type = { italic = true, bold = true }
            end,
        })

        vim.cmd.colorscheme("tokyonight-night")
    end,
}
