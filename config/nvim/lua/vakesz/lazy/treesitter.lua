-- Treesitter syntax highlighting and context
-- Docs: https://github.com/nvim-treesitter/nvim-treesitter

return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup({})

            -- Install parsers (async, no-op if already installed)
            require("nvim-treesitter").install({
                "vimdoc", "lua", "python", "javascript", "typescript", "tsx",
                "bash", "go", "rust", "c", "cpp", "json", "yaml", "toml", "perl",
                "markdown", "markdown_inline", "html", "css", "dockerfile",
            })

            -- Enable treesitter highlighting and indentation for all filetypes
            vim.api.nvim_create_autocmd("FileType", {
                callback = function(args)
                    -- Skip large files for performance
                    local max_filesize = 100 * 1024 -- 100 KB
                    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
                    if ok and stats and stats.size > max_filesize then
                        vim.notify(
                            "File larger than 100KB treesitter disabled for performance",
                            vim.log.levels.WARN,
                            { title = "Treesitter" }
                        )
                        return
                    end

                    pcall(vim.treesitter.start)
                    vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })
        end,
    },

    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = { "nvim-treesitter/nvim-treesitter" },
        opts = {},
    },
}
