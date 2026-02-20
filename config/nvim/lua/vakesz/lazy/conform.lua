-- Formatting plugin that wraps multiple formatters
-- Docs: https://github.com/stevearc/conform.nvim

return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>ff",
            function()
                require("conform").format({ async = true, lsp_format = "fallback" })
            end,
            mode = { "n", "v" },
            desc = "Format buffer",
        },
    },
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" },
                go = { "gofmt", "goimports" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                vue = { "prettier" },
                css = { "prettier" },
                scss = { "prettier" },
                html = { "prettier" },
                json = { "prettier" },
                yaml = { "prettier" },
                markdown = { "prettier" },
                python = { "ruff_fix", "ruff_format" },
                c = { "clang_format" },
                cpp = { "clang_format" },
                objc = { "clang_format" },
                objcpp = { "clang_format" },
                swift = { "swift_format" },
            },
            format_on_save = function(bufnr)
                -- Disable format on save for certain filetypes
                local disable_filetypes = { c = true, cpp = true }
                return {
                    lsp_format = disable_filetypes[vim.bo[bufnr].filetype] and "never" or "fallback",
                }
            end,
        })
    end,
}
