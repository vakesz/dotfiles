-- Treesitter syntax highlighting and context
-- Docs: https://github.com/nvim-treesitter/nvim-treesitter

return {
    {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        require("nvim-treesitter.configs").setup({
            ensure_installed = {
                "vimdoc", "lua", "python", "javascript", "typescript", "tsx",
                "bash", "go", "rust", "c", "cpp", "json", "yaml", "toml", "perl",
                "markdown", "markdown_inline", "html", "css", "dockerfile",
            },
            sync_install = false,
            auto_install = true,

            indent = {
                enable = true
            },

            highlight = {
                enable = true,
                disable = function(lang, buf)
                    -- Disable treesitter for large files to improve performance
                    local max_filesize = 100 * 1024 -- 100 KB
                    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
                    if ok and stats and stats.size > max_filesize then
                        vim.notify(
                            "File larger than 100KB treesitter disabled for performance",
                            vim.log.levels.WARN,
                            {title = "Treesitter"}
                        )
                        return true
                    end
                end,

                additional_vim_regex_highlighting = { "markdown" },
            },
        })
    end
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        opts = { enable = true },
    }
}
