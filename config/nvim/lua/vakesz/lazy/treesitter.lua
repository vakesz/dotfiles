-- Treesitter syntax highlighting and context
-- Docs: https://github.com/nvim-treesitter/nvim-treesitter

return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").setup({})

            -- Add bundled queries to runtimepath so vim.treesitter.start() finds highlights.scm
            local plugin_dir = vim.fn.fnamemodify(debug.getinfo(require("nvim-treesitter").setup, "S").source:sub(2), ":p:h:h:h")
            local runtime_dir = vim.fs.joinpath(plugin_dir, "runtime")
            if not vim.list_contains(vim.opt.rtp:get(), runtime_dir) then
                vim.opt.rtp:prepend(runtime_dir)
            end

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
