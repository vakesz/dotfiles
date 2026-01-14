-- GitHub colorscheme with transparent background
-- Docs: https://github.com/projekt0n/github-nvim-theme

return {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,

    config = function()
        require('github-theme').setup({
            options = {
                transparent = true, -- transparent background
                terminal_colors = true,
                dim_inactive = false,
                styles = {
                    comments = "italic",
                    keywords = "bold",
                    types = "italic,bold",
                },
            },
        })

        vim.cmd.colorscheme("github_dark_colorblind")

        -- Ensure transparent background
        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
        vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    end,
}