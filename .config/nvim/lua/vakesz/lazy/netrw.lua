-- Enhance built-in netrw with icons
-- Docs: https://github.com/prichrd/netrw.nvim

return {
    "prichrd/netrw.nvim",
    lazy = false, -- load during startup so netrw shows icons immediately
    dependencies = { "echasnovski/mini.icons" },

    opts = {
        use_devicons = true, -- enable icons from mini.icons
    },

    config = function(_, opts)
        require("netrw").setup(opts)

        -- Configure built-in netrw behavior
        vim.g.netrw_browse_split = 0  -- open files in current window
        vim.g.netrw_banner = 0         -- hide the banner
        vim.g.netrw_winsize = 25       -- set netrw window width to 25%
    end,
}