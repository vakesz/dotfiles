return {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },
    opts = {
        anti_conceal = {
            enabled = false,
        },
    },
    config = function(_, opts)
        require("render-markdown").setup(opts)

        local group = vim.api.nvim_create_augroup("RenderMarkdownToggle", { clear = true })
        vim.api.nvim_create_autocmd("FileType", {
            group = group,
            pattern = "markdown",
            callback = function()
                vim.opt_local.conceallevel = 2
            end,
        })
        vim.api.nvim_create_autocmd("InsertEnter", {
            group = group,
            pattern = "*.md",
            callback = function()
                vim.cmd("RenderMarkdown disable")
                vim.opt_local.conceallevel = 0
            end,
        })
        vim.api.nvim_create_autocmd("InsertLeave", {
            group = group,
            pattern = "*.md",
            callback = function()
                vim.opt_local.conceallevel = 2
                vim.cmd("RenderMarkdown enable")
            end,
        })
    end,
}
