-- Configure the rose-pine colorscheme
-- Docs: https://github.com/rose-pine/neovim

local function ColorMyPencils(color)
    color = color or "rose-pine-moon" -- fallback colorscheme
    vim.cmd.colorscheme(color)
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" }) -- keep background transparent
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" }) -- floating windows transparency
end

return {
    {
        "rose-pine/neovim",
        name = "rose-pine",
        lazy = false, -- load during startup
        priority = 1000, -- load before other colorschemes
        config = function()
            require('rose-pine').setup({
                disable_background = false, -- use theme's background color
                styles = {
                    italic = false, -- disable italic styles
                },
            })
            ColorMyPencils()
        end
    },
}