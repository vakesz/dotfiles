return {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,

    config = function()
        require("rose-pine").setup({
            dark_variant = "moon",
            styles = {
                bold = true,
                italic = true,
                transparency = true,
            },
            highlight_groups = {
                Comment = { italic = true },
                Keyword = { bold = true },
                Type = { italic = true, bold = true },
            },
        })

        vim.cmd.colorscheme("rose-pine-moon")
    end,
}
