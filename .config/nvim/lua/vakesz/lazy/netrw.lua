-- Enhance built-in netrw with icons
-- Docs: https://github.com/prichrd/netrw.nvim

-- TODO: unsure whether to keep this or switch to a different file explorer
--       like nvim-tree or neo-tree

return {
    "prichrd/netrw.nvim",

    lazy = false, -- load during startup so netrw shows icons immediately

    dependencies = {
        "nvim-tree/nvim-web-devicons", -- provides file type icons
    },

    opts = {
        use_devicons = true, -- enable icons from nvim-web-devicons
    },
}